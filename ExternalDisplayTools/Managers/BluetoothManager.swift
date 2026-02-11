import Foundation
import Combine
import IOBluetooth

class BluetoothManager: ObservableObject {
    static let shared = BluetoothManager()
    
    @Published private(set) var isConnected: Bool = false
    private(set) var connectedDeviceName: String?
    
    var onDeviceConnected: ((String) -> Void)?
    var onDeviceDisconnected: (() -> Void)?
    
    private var observers: [Any] = []
    private var connectionObserver: NSObjectProtocol?
    private var disconnectionObserver: NSObjectProtocol?
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        connectionObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.IOBluetoothDeviceConnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let device = notification.object as? IOBluetoothDevice {
                self?.handleDeviceConnected(device)
            }
        }
        
        disconnectionObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.IOBluetoothDeviceDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let device = notification.object as? IOBluetoothDevice {
                self?.handleDeviceDisconnected(device)
            }
        }
    }
    
    private func handleDeviceConnected(_ device: IOBluetoothDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.connectedDeviceName = device.name
            
            if let name = device.name {
                self?.onDeviceConnected?(name)
            }
        }
    }
    
    private func handleDeviceDisconnected(_ device: IOBluetoothDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.connectedDeviceName = nil
            self?.onDeviceDisconnected?()
        }
    }
    
    deinit {
        if let observer = connectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = disconnectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension NSNotification.Name {
    static let IOBluetoothDeviceConnected = NSNotification.Name("IOBluetoothDeviceConnected")
    static let IOBluetoothDeviceDisconnected = NSNotification.Name("IOBluetoothDeviceDisconnected")
}
