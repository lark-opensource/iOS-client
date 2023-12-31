//
//  SecurityUpdateNotificationCenterService.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/15.
//

import Foundation
import LarkContainer
import LarkPolicyEngine
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

protocol SecurityUpdateNotificationCenterService {
    func registeObserver(observer: SecurityUpdateObserver)
}
extension SecurityPolicyV2 {
    class SecurityUpdateNotificationCenter: SecurityUpdateNotificationCenterService {
        private var observers: [SecurityUpdateObserver] = []
        private let netWorkMonitor: NetworkChangeMonitor
        private let userResolver: UserResolver

        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            let config = try NetWorkMonitorConfig(userResolver: userResolver,
                                                  method: .pathMonitor,
                                                  debouncerInterval: 2)
            self.netWorkMonitor = NetworkChangeMonitor(config: config)
            setUpObserver()
            // 如果不延迟，observers 来不及接收到启动信号
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                self.observers.forEach { $0.notify(trigger: .constructor) }
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            netWorkMonitor.stop()
        }

        func registeObserver(observer: SecurityUpdateObserver) {
            DispatchQueue.runOnMainQueue {
                self.observers.append(observer)
            }
        }

        private func setUpObserver() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

            netWorkMonitor.updateHandler = { [weak self] _ in
                guard let self else { return }
                DispatchQueue.runOnMainQueue {
                    self.observers.forEach { $0.notify(trigger: .networkChange) }
                }
            }
            netWorkMonitor.start()

            try? StrategyEngineCaller(userResolver: userResolver).register(observer: self)

        }

        @objc
        func onDidBecomeActive() {
            observers.forEach { $0.notify(trigger: .becomeActive) }
        }
    }
}

extension SecurityPolicyV2.SecurityUpdateNotificationCenter: LarkPolicyEngine.Observer {
    func notify(event: LarkPolicyEngine.Event) {
        switch event {
        case .decisionContextChanged:
            DispatchQueue.runOnMainQueue {
                self.observers.forEach { $0.notify(trigger: .strategyEngine) }
            }
        @unknown default:
            break
        }
    }
}

protocol SecurityUpdateObserver {
    func notify(trigger: SecurityPolicyV2.UpdateTrigger)
}

extension SecurityPolicyV2 {
    enum UpdateTrigger {
        case constructor
        case becomeActive
        case networkChange
        case strategyEngine

        var callTrigger: StrategyEngineCallTrigger {
            switch self {
            case .constructor:
                return .constructor
            case .becomeActive:
                return .becomeActive
            case .networkChange:
                return .networkChange
            case .strategyEngine:
                return .strategyEngine
            }
        }
    }
}
