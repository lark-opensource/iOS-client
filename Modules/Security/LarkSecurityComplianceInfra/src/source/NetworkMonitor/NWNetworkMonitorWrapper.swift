//
//  SCNetworkPathMonitor.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/11/22.
//
import Network

@available(iOS 12.0, *)
final class NWNetworkMonitorWrapper: NetworkChangeMonitorProtocol {
    private let monitor: NWPathMonitor = NWPathMonitor()
    var updateHandler: ((NetworkStatus) -> Void)?
    
    func start() {
        SCLogger.info("lsc network: path monitor start")
        monitor.pathUpdateHandler = { [weak self] path in
            SCLogger.info("lsc network: path monitor receives network change callback")
            if path.status != .satisfied {
                self?.updateHandler?(.unavailable)
            } else if path.availableInterfaces.contains(where: { $0.type == .wifi }) {
                self?.updateHandler?(.wifi)
            } else {
                self?.updateHandler?(.cellular)
            }
        }
        monitor.start(queue: networkMonitorQueue)
    }

    func stop() {
        monitor.cancel()
        SCLogger.info("lsc network: path monitor stop")
    }
}
