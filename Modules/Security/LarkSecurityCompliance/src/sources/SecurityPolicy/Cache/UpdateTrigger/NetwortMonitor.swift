//
//  NetwortMonitor.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/9/28.
//

import Network
import Reachability
import LarkSecurityComplianceInfra
import LarkContainer

public enum NetworkStatus: CustomStringConvertible {
    case unavailable, wifi, cellular
    public var description: String {
        switch self {
        case .cellular: return "Cellular"
        case .wifi: return "Wi-Fi"
        case .unavailable: return "No Connection"
        }
    }
}

protocol NetworkMonitorProtocol {
    var handler: ((NetworkStatus) -> Void)? { get set }
    func start()
    func stop()
}

final class NetworkMonitor: NetworkMonitorProtocol, UserResolverWrapper {
    var handler: ((NetworkStatus) -> Void)?

    @ScopedProvider var settings: Settings?

    private lazy var debounce = {
        guard let timeInterval = settings?.fileStrategyUpdateFrequencyControl else { return Debouncer() }
        return Debouncer(timerInterval: Double(timeInterval))
    }()

    private var monitor: NetworkMonitorProtocol

    private var isInitialNetworkChange = true

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        let disablePathMonitor: Bool
        let settings = try? userResolver.resolve(assert: Settings.self)
        if (settings?.enableSecuritySettingsV2).isTrue {
            disablePathMonitor = SCSetting.staticBool(scKey: .disableNetworkPathMonitor, userResolver: userResolver)
        } else {
            disablePathMonitor = settings?.disableNetworkPathMonitor ?? false
            SCLogger.info("\(SettingsImp.CodingKeys.disableNetworkPathMonitor.rawValue) \(disablePathMonitor)", tag: SettingsImp.logTag)
        }
        if #available(iOS 12.0, *), !disablePathMonitor {
            monitor = NWNetWorkMonitorWrapper()
        } else {
            monitor = ReachabilityWrapper()
        }
        monitor.handler = { [weak self] status in
            DispatchQueue.runOnMainQueue {
                guard let self else { return }
                self.debounce.callback = { [weak self] in
                    guard let self else { return }
                    if self.isInitialNetworkChange {
                        self.isInitialNetworkChange = false
                    } else {
                        self.handler?(status)
                    }
                }
                self.debounce.call()
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

final class ReachabilityWrapper: NetworkMonitorProtocol {
    var handler: ((NetworkStatus) -> Void)?

    let monitor = Reachability()

    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: .reachabilityChanged, object: monitor)
        do {
            try monitor?.startNotifier()
            SCLogger.info("security policy network: reachability monitor start")
        } catch {
            SPLogger.error("security policy: unable to start notifier")
        }
    }

    func stop() {
        monitor?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: monitor)
    }

    @objc
    func reachabilityChanged() {
        guard let monitor = monitor else { return }
        if monitor.isReachable {
            handler?(.unavailable)
        } else if monitor.isReachableViaWWAN {
            handler?(.cellular)
        } else {
            handler?(.wifi)
        }
    }
}

@available(iOS 12.0, *)
final class NWNetWorkMonitorWrapper: NetworkMonitorProtocol {
    var handler: ((NetworkStatus) -> Void)?
    private let monitor = NWPathMonitor()

    func start() {
        SCLogger.info("security policy network: path monitor start")
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            switch path.status {
            case .satisfied:
                if path.usesInterfaceType(.wifi) {
                    self.handler?(.wifi)
                } else {
                    self.handler?(.cellular)
                }
            case .unsatisfied:
                self.handler?(.unavailable)
            default:
                break
            }
        }
        monitor.start(queue: networkMonitorQueue)
    }

    func stop() {
        monitor.cancel()
    }
}

final class Debouncer {
    private var timeInterval: TimeInterval
    var timer: Timer?
    var callback: (() -> Void)?

    init(timerInterval: TimeInterval = TimeInterval(2.0)) {
        self.timeInterval = timerInterval
    }

    deinit {
        timer?.invalidate()
    }

    func call() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: false) { [weak self] _ in
            self?.callback?()
            self?.timer?.invalidate()
        }
    }
}
