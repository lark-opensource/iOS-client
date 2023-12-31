//
//  NetworkChangeMonitor.swift
//
//  Created by Nix Wang on 2022/1/18.
//

import Network
import Reachability
import LKCommonsLogging
import LarkSecurityComplianceInfra
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

protocol NetworkChangeMonitorProtocol {
    var updateHandler: ((NetworkStatus) -> Void)? { get set }
    func start()
    func stop()
}

final class NetworkChangeMonitor: NetworkChangeMonitorProtocol {
    static let logger = Logger.log(NetworkChangeMonitor.self, category: "SecurityAudit.NetworkChangeMonitor")

    var monitor: NetworkChangeMonitorProtocol
    var updateHandler: ((NetworkStatus) -> Void)?
    let debouncer = Debouncer(interval: 2.0)
    var isInitialNetworkChange = true
    let userResolver: UserResolver

    enum Method {
        case reachability
        case pathMonitor
    }

    init(userResolver: UserResolver, method: Method = .pathMonitor) {
        self.userResolver = userResolver
        let disablePathMonitor: Bool
        let settings = try? userResolver.resolve(assert: Settings.self)
        if (settings?.enableSecuritySettingsV2).isTrue {
            disablePathMonitor = SCSetting.staticBool(scKey: .disableNetworkPathMonitor, userResolver: userResolver)
        } else {
            disablePathMonitor = settings?.disableNetworkPathMonitor ?? false
            SCLogger.info("\(SettingsImp.CodingKeys.disableNetworkPathMonitor.rawValue) \(disablePathMonitor)", tag: SettingsImp.logTag)
        }
        switch method {
        case .reachability:
            monitor = ReachabilityMonitor()
        case .pathMonitor:
            if #available(iOS 12.0, *), !disablePathMonitor {
                monitor = NWNetworkMonitorWrapper()
            } else {
                monitor = ReachabilityMonitor()
            }
        }

        monitor.updateHandler = { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }

                /// Ignore first network change when initializing to avoid duplicated requests
                /// https://meego.feishu.cn/larksuite/issue/detail/5643932
                if self.isInitialNetworkChange {
                    Self.logger.info("n_action_permission_ignore_first_network_change")
                    self.isInitialNetworkChange = false
                    return
                }

                Self.logger.info("n_action_permission_network_changed")

                self.debouncer.callback = { [weak self] in
                    Self.logger.info("NetworkChangeMonitor did call")
                    self?.updateHandler?(status)
                }
                self.debouncer.call()
            }
        }
    }

    func start() {
        monitor.start()
    }

    func stop() {
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
    // swiftlint:disable:next superfluous_disable_command force_cast
    let reachability = Reachability()
    // swiftlint:disable:previous superfluous_disable_command force_cast

    var updateHandler: ((NetworkStatus) -> Void)?

    func start() {
        guard let reachability else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)

        do {
            try reachability.startNotifier()
            SCLogger.info("security audit network: reachability monitor start")
        } catch {
            print("Unable to start notifier")
        }
    }

    @objc
    func reachabilityChanged(note: Notification) {
        if let reachability = note.object as? Reachability {
            updateHandler?(reachability.connection.status)
        }
    }

    func stop() {
        reachability?.stopNotifier()
        if let reachability {
            NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        }
    }
}

@available(iOS 12.0, *)
final class NWNetworkMonitorWrapper: NetworkChangeMonitorProtocol {
    private let monitor = NWPathMonitor()
    var updateHandler: ((NetworkStatus) -> Void)?

    func start() {
        SCLogger.info("security audit network: path monitor start")
        monitor.pathUpdateHandler = { [weak self] path in
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
    }
}

final class Debouncer {

    // Callback to be debounced
    // Perform the work you would like to be debounced in this callback.
    var callback: (() -> Void)?

    private let interval: TimeInterval // Time interval of the debounce window

    init(interval: TimeInterval) {
        self.interval = interval
    }

    private var timer: Timer?

    // Indicate that the callback should be called. Begins the debounce window.
    func call() {
        // Invalidate existing timer if there is one
        DispatchQueue.main.async {
            self.timer?.invalidate()
            // Begin a new timer from now
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: false, block: { [weak self] _ in
                assert(self?.callback != nil)
                self?.callback?()
                self?.callback = nil
            })
        }
    }
}
