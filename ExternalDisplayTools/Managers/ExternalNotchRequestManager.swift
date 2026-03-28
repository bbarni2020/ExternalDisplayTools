import Combine
import Foundation

@MainActor
final class ExternalNotchRequestManager: ObservableObject {
    static let shared = ExternalNotchRequestManager()

    @Published private(set) var activeRequest: ExternalNotchRequest?

    private var dismissWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        NowPlayingMetadataManager.shared.$title
            .sink { _ in }
            .store(in: &cancellables)

        MusicManager.shared.$isPlayerIdle
            .sink { _ in }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            ScreenStateManager.shared.$isScreenLocked,
            ScreenStateManager.shared.$isScreenSaverActive
        )
            .map { isLocked, isScreenSaverActive in
                isLocked || isScreenSaverActive
            }
            .sink { [weak self] isRestricted in
                guard isRestricted else { return }
                self?.clearActiveRequest(closeNotch: true)
            }
            .store(in: &cancellables)
    }

    func handle(url: URL) {
        guard !ScreenStateManager.shared.isInteractionRestricted else { return }
        guard activeRequest == nil else { return }
        guard let request = ExternalNotchRequestParser.parse(url: url) else { return }

        activeRequest = request
        NotchViewCoordinator.shared.openNotch()

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.clearActiveRequest(closeNotch: true)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + request.duration, execute: workItem)
    }

    private func clearActiveRequest(closeNotch: Bool) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        if closeNotch {
            NotchViewCoordinator.shared.closeNotch()
        }
        activeRequest = nil
    }
}
