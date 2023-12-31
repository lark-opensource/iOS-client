//
//  SCNetworkPathMonitorWrapper.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/11/27.
//

import Network

public let networkMonitorQueue = DispatchQueue(label: "lark.scs.network_change_monitor")
fileprivate let SCNetworkChangeNotification = Notification.Name("SCNetworkChangeNotification")
fileprivate let networkLogger = SCLogger(tag: "lsc_network")

fileprivate class SCNetworkPathMonitor {
    static let pathMonitor = NWPathMonitor()
    @SafeWrapper static var referenceCount: Int32 = 0
    @SafeWrapper static var started: Bool = false
    
    func start() {
        Self.referenceCount += 1

        networkLogger.info("SCNetworkPathMonitor start begin, reference count: \(Self.referenceCount)")
        guard !Self.started else {
            return
        }
        Self.started = true
        Self.pathMonitor.pathUpdateHandler = { newPath in
            networkLogger.info("SCNetworkPathMonitor network change")
            NotificationCenter.default.post(name: SCNetworkChangeNotification, object: newPath)
        }
        Self.pathMonitor.start(queue: networkMonitorQueue)
        networkLogger.info("SCNetworkPathMonitor start")
    }
    
    func stop() {
        guard Self.referenceCount > 0 else { return }
        Self.referenceCount -= 1
        networkLogger.info("reference count decrease 1. Reference count: \(Self.referenceCount)")
        if Self.referenceCount <= 0 {
            Self.started = false
            Self.pathMonitor.cancel()
            networkLogger.info("SCNetworkPathMonitor stop")
        }
    }
}

@available(iOS 12.0, *)
final class SCNetworkPathMonitorWrapper: NetworkChangeMonitorProtocol {
    private let scMonitor: SCNetworkPathMonitor = SCNetworkPathMonitor()
    private var observer: NSObjectProtocol?
    var updateHandler: ((NetworkStatus) -> Void)?
    
    deinit {
        stop()
    }
    
    func start() {
        networkLogger.info("sc network path monitor start")
        observer = NotificationCenter.default.addObserver(forName: SCNetworkChangeNotification, object: nil, queue: .main, using: { [weak self] noti in
            networkLogger.info("sc network path monitor receives network change callback")
            guard let updateHandler = self?.updateHandler else {
                networkLogger.info("sc network path monitor updateHandler is nil")
                return
            }
            guard let path = noti.object as? NWPath else {
                networkLogger.info("sc network path monitor path is nil")
                return
            }
            networkLogger.info("sc network path monitor execute updateHandler with path: \(path)")
            if path.status != .satisfied {
                updateHandler(.unavailable)
            } else if path.availableInterfaces.contains(where: { $0.type == .wifi }) {
                updateHandler(.wifi)
            } else {
                updateHandler(.cellular)
            }
        })
        scMonitor.start()
    }

    func stop() {
        guard let observer else { 
            networkLogger.info("sc network path monitor already stopped")
            return 
        }
        networkLogger.info("sc network path monitor stop")
        scMonitor.stop()
        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
    }
}
