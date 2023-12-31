//
//  NetworkMonitor.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/2/2.
//

import Foundation
import Network
import Reachability
import LarkContainer

public enum NetworkStatus: CustomStringConvertible {
    case unavailable, wifi, cellular
    public var description: String {
        switch self {
        case .cellular: return "Cellular"
        case .wifi: return "WiFi"
        case .unavailable: return "No Connection"
        }
    }
}

public struct NetWorkMonitorConfig {

    public enum Method: String {
        case reachability
        case pathMonitor
    }

    fileprivate let method: Method // 监听方式
    fileprivate let debouncerInterval: TimeInterval? // 网络信号变化聚合时间，当网络变化时候，会出现抖动，所以在debouncerInterval之后真正触发请求，避免由于网络抖动带来的多次请求
    let userResolver: UserResolver
    public init(userResolver: UserResolver, method: Method, debouncerInterval: TimeInterval? = nil) throws {
        self.userResolver = userResolver
        let settings = try userResolver.resolve(assert: Settings.self)
        let disablePathMonitor: Bool
        if settings.enableSecuritySettingsV2.isTrue {
            disablePathMonitor = SCSetting.staticBool(scKey: .disableNetworkPathMonitor, userResolver: userResolver)
        } else {
            disablePathMonitor = settings.disableNetworkPathMonitor.isTrue
            SCLogger.info("\(SettingsImp.CodingKeys.disableNetworkPathMonitor.rawValue) \(disablePathMonitor)", tag: SettingsImp.logTag)
        }
        self.method = disablePathMonitor ? .reachability : method
        self.debouncerInterval = debouncerInterval
        SCLogger.info("lsc network: config init", additionalData: ["method": self.method.rawValue])
    }
}

public protocol NetworkChangeMonitorProtocol {
    var updateHandler: ((NetworkStatus) -> Void)? { get set }
    func start()
    func stop()
}

public final class NetworkChangeMonitor: NetworkChangeMonitorProtocol {

    var monitor: NetworkChangeMonitorProtocol
    public var updateHandler: ((NetworkStatus) -> Void)?
    var debouncer: Debouncer
    var isInitialNetworkChange = true

    public init(config: NetWorkMonitorConfig) {
        switch config.method {
        case .reachability:
            monitor = ReachabilityMonitor()
        case .pathMonitor:
            if #available(iOS 12.0, *) {
                let fgService = try? config.userResolver.resolve(assert: SCFGService.self)
                let enableOptPathMonitor = fgService?.realtimeValue(.enableOptNetworkMonitor) ?? false
                if enableOptPathMonitor {
                    monitor = SCNetworkPathMonitorWrapper()
                } else {
                    monitor = NWNetworkMonitorWrapper()
                }
            } else {
                monitor = ReachabilityMonitor()
            }
        }

        debouncer = Debouncer(interval: config.debouncerInterval ?? 0)

        monitor.updateHandler = { [weak self] status in
            guard let self = self else { return }
            /// Ignore first network change when initializing to avoid duplicated requests
            /// https://meego.feishu.cn/larksuite/issue/detail/5643932
            if self.isInitialNetworkChange {
                self.isInitialNetworkChange = false
                return
            }

            self.debouncer.callback = { [weak self] in
                guard let self else { return }
                self.updateHandler?(status)
            }
            self.debouncer.call()
        }
    }

    public func start() {
        monitor.start()
    }

    public func stop() {
        monitor.stop()
    }
}

extension Reachability.Connection {
    var status: NetworkStatus {
        switch self {
        case .none:
            return .unavailable
        case .wifi:
            return .wifi
        case .cellular:
            return .cellular
        }
    }
}

final class ReachabilityMonitor: NetworkChangeMonitorProtocol {
    let reachability = Reachability()

    var updateHandler: ((NetworkStatus) -> Void)?

    func start() {
        guard let reachability = reachability else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)

        do {
            try reachability.startNotifier()
            SCLogger.info("lsc network: reachability monitor start")
        } catch {
            SCLogger.error("lsc network: unable to start notifier")
        }
    }

    @objc
    func reachabilityChanged(note: Notification) {
        if let reachability = note.object as? Reachability {
            SCLogger.info("lsc network: reachability monitor receives network change callback")
            DispatchQueue.main.async { [weak self] in
                self?.updateHandler?(reachability.connection.status)
            }
        }
    }

    func stop() {
        guard let reachability = reachability else { return }
        SCLogger.info("lsc network: reachability monitor stop")
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
}
