import Foundation
import Combine
import CoreGraphics
import ApplicationServices
import Carbon

struct KeySwapRule: Codable, Identifiable, Equatable {
    let id: UUID
    var keyboardType: Int?
    var firstKey: String
    var secondKey: String
    var isEnabled: Bool

    init(id: UUID = UUID(), keyboardType: Int? = nil, firstKey: String, secondKey: String, isEnabled: Bool = true) {
        self.id = id
        self.keyboardType = keyboardType
        self.firstKey = firstKey.lowercased()
        self.secondKey = secondKey.lowercased()
        self.isEnabled = isEnabled
    }
}

final class KeyboardRemapManager: ObservableObject {
    static let shared = KeyboardRemapManager()

    @Published private(set) var rules: [KeySwapRule] = [] {
        didSet { persistRules() }
    }

    @Published var isRemapEnabled: Bool {
        didSet {
            defaults.set(isRemapEnabled, forKey: Keys.remapEnabled)
            if isRemapEnabled {
                guard ensureAccessibilityPermission(prompt: true) else {
                    isRemapEnabled = false
                    return
                }
                startEventTapIfNeeded()
            } else {
                stopEventTap()
            }
        }
    }

    @Published private(set) var seenKeyboardTypes: [Int] = []
    @Published private(set) var accessibilityGranted: Bool
    @Published private(set) var lastStartError: String?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let defaults: UserDefaults
    private var keyCodeToCharacter: [CGKeyCode: String] = [:]
    private var characterToKeyCode: [String: CGKeyCode] = [:]
    private let keyMapLock = NSLock()
    private var inputSourceObserver: Any?

    private enum Keys {
        static let remapEnabled = "settings.keyboard.remapEnabled"
        static let rules = "settings.keyboard.rules"
    }

    var supportedLetters: [String] {
        keyMapLock.lock()
        let values = characterToKeyCode.keys.sorted()
        keyMapLock.unlock()
        return values
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        accessibilityGranted = AXIsProcessTrusted()
        isRemapEnabled = defaults.object(forKey: Keys.remapEnabled) as? Bool ?? false
        loadRules()
        rebuildCharacterMaps()
        observeInputSourceChanges()
        if isRemapEnabled {
            guard ensureAccessibilityPermission(prompt: true) else {
                isRemapEnabled = false
                return
            }
            startEventTapIfNeeded()
        }
    }

    deinit {
        if let inputSourceObserver {
            DistributedNotificationCenter.default().removeObserver(inputSourceObserver)
        }
        stopEventTap()
    }

    func addRule(pair: String, keyboardType: Int?) -> Bool {
        let normalized = pair.lowercased().filter { $0.isLetter || $0.isNumber }
        guard normalized.count == 2 else { return false }
        let chars = Array(normalized)
        guard chars[0] != chars[1] else { return false }
        let first = String(chars[0])
        let second = String(chars[1])
        return addRule(firstKey: first, secondKey: second, keyboardType: keyboardType)
    }

    func addRule(firstKey: String, secondKey: String, keyboardType: Int?) -> Bool {
        let first = normalizedCharacter(firstKey)
        let second = normalizedCharacter(secondKey)
        guard first.count == 1, second.count == 1, first != second else { return false }
        guard keyCode(for: first) != nil, keyCode(for: second) != nil else { return false }

        let ordered = [first, second].sorted()
        let canonicalFirst = ordered[0]
        let canonicalSecond = ordered[1]

        let candidate = KeySwapRule(keyboardType: keyboardType, firstKey: canonicalFirst, secondKey: canonicalSecond)
        if rules.contains(where: { existing in
            existing.keyboardType == candidate.keyboardType
            && Set([existing.firstKey, existing.secondKey]) == Set([candidate.firstKey, candidate.secondKey])
        }) {
            return false
        }

        rules.append(candidate)
        if isRemapEnabled {
            guard ensureAccessibilityPermission(prompt: true) else {
                isRemapEnabled = false
                return true
            }
            startEventTapIfNeeded()
        }
        return true
    }

    func refreshAccessibilityStatus() {
        accessibilityGranted = AXIsProcessTrusted()
        if accessibilityGranted, isRemapEnabled {
            startEventTapIfNeeded()
        }
    }

    @discardableResult
    func ensureAccessibilityPermission(prompt: Bool) -> Bool {
        let trusted: Bool
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            trusted = AXIsProcessTrustedWithOptions(options)
        } else {
            trusted = AXIsProcessTrusted()
        }

        accessibilityGranted = trusted
        if !trusted {
            lastStartError = "Enable Accessibility permission for key remapping."
        } else {
            lastStartError = nil
        }
        return trusted
    }

    func removeRule(id: UUID) {
        rules.removeAll { $0.id == id }
        if rules.isEmpty {
            stopEventTap()
        }
    }

    func updateRule(_ rule: KeySwapRule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
    }

    func keyboardLabel(for keyboardType: Int?) -> String {
        guard let keyboardType else { return "All Keyboards" }
        return "Keyboard Type \(keyboardType)"
    }

    private func loadRules() {
        guard let data = defaults.data(forKey: Keys.rules) else {
            rules = []
            return
        }

        if let decoded = try? JSONDecoder().decode([KeySwapRule].self, from: data) {
            rules = decoded
        } else {
            rules = []
        }
    }

    private func persistRules() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: Keys.rules)
    }

    private func startEventTapIfNeeded() {
        if eventTap != nil || !isRemapEnabled || rules.isEmpty {
            return
        }

        guard ensureAccessibilityPermission(prompt: false) else {
            return
        }

        rebuildCharacterMaps()

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let manager = Unmanaged<KeyboardRemapManager>.fromOpaque(userInfo).takeUnretainedValue()
            return manager.handle(event: event, type: type)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            lastStartError = "Unable to start key remapping event tap."
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            lastStartError = nil
        }
    }

    private func stopEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyboardType = Int(event.getIntegerValueField(.keyboardEventKeyboardType))
        registerKeyboardTypeIfNeeded(keyboardType)

        let originalCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard let originalLetter = character(for: originalCode) else {
            return Unmanaged.passUnretained(event)
        }

        guard let replacementCode = replacementCode(for: originalLetter, keyboardType: keyboardType) else {
            return Unmanaged.passUnretained(event)
        }

        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(replacementCode))
        return Unmanaged.passUnretained(event)
    }

    private func replacementCode(for letter: String, keyboardType: Int) -> CGKeyCode? {
        for rule in rules where rule.isEnabled {
            if let targetType = rule.keyboardType, targetType != keyboardType {
                continue
            }

            if letter == rule.firstKey {
                return keyCode(for: rule.secondKey)
            }

            if letter == rule.secondKey {
                return keyCode(for: rule.firstKey)
            }
        }
        return nil
    }

    private func observeInputSourceChanges() {
        inputSourceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildCharacterMaps()
        }
    }

    private func rebuildCharacterMaps() {
        var nextKeyToCharacter: [CGKeyCode: String] = [:]
        var nextCharacterToKey: [String: CGKeyCode] = [:]

        for key in 0...127 {
            let code = CGKeyCode(key)
            guard let character = characterFromCurrentLayout(for: code) else { continue }
            guard isSupportedInputCharacter(character) else { continue }
            let normalized = normalizedCharacter(character)
            guard normalized.count == 1 else { continue }
            if nextCharacterToKey[normalized] == nil {
                nextCharacterToKey[normalized] = code
            }
            nextKeyToCharacter[code] = normalized
        }

        keyMapLock.lock()
        keyCodeToCharacter = nextKeyToCharacter
        characterToKeyCode = nextCharacterToKey
        keyMapLock.unlock()
    }

    private func characterFromCurrentLayout(for keyCode: CGKeyCode) -> String? {
        guard let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let rawLayoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }

        let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
        guard let layoutPtr = CFDataGetBytePtr(layoutData) else { return nil }

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 8)
        var length = 0

        let result = UCKeyTranslate(
            UnsafePointer<UCKeyboardLayout>(OpaquePointer(layoutPtr)),
            UInt16(keyCode),
            UInt16(kUCKeyActionDown),
            0,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &length,
            &chars
        )

        guard result == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }

    private func isSupportedInputCharacter(_ value: String) -> Bool {
        value.unicodeScalars.allSatisfy { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar)
        }
    }

    private func normalizedCharacter(_ value: String) -> String {
        String(value.lowercased().prefix(1))
    }

    private func character(for keyCode: CGKeyCode) -> String? {
        keyMapLock.lock()
        let value = keyCodeToCharacter[keyCode]
        keyMapLock.unlock()
        return value
    }

    private func keyCode(for character: String) -> CGKeyCode? {
        keyMapLock.lock()
        let value = characterToKeyCode[character]
        keyMapLock.unlock()
        return value
    }

    private func registerKeyboardTypeIfNeeded(_ keyboardType: Int) {
        guard !seenKeyboardTypes.contains(keyboardType) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.seenKeyboardTypes.contains(keyboardType) {
                self.seenKeyboardTypes.append(keyboardType)
                self.seenKeyboardTypes.sort()
            }
        }
    }
}
