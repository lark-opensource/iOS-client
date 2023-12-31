//
//  LarkMagicInterceptorImpl.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/9.
//

import UIKit
import Foundation
import LarkContainer
import LKCommonsLogging

final class LarkMagicInterceptorManager {
    var larkMagicDependency: LarkMagicDependency?
    private var interceptors: [String: ScenarioInterceptor] = [:]
    private let defaultInterceptor: DefaultInterceptor
    static let logger = Logger.log(LarkMagicInterceptorManager.self, category: "LarkMagic")

    init() {
        defaultInterceptor = DefaultInterceptor()
    }

    func canShow(scenarioID: String) -> Bool {
        guard let larkMagicDependency else {
            return false
        }
        guard defaultInterceptor.canShowMagic() else {
            // 系统拦截
            LarkMagicTracker.trackInterceptEvent(reason: "system")
            return false
        }

        let conflictResult = larkMagicDependency.checkConflict()
        guard !conflictResult.isConflict else {
            // 有冲突
            LarkMagicTracker.trackInterceptEvent(reason: "suite", conflictResult.extra)
            LarkMagicInterceptorManager.logger.info("intercepte",
                                                    additionalData: conflictResult.extra)
            return false
        }

        if #available(iOS 13.0, *) {
            let count = UIApplication.shared.connectedScenes.count
            guard count == 1 else {
                LarkMagicInterceptorManager.logger.info("mutil Scenes",
                                                        additionalData: ["connectedScenes": "\(count)"])
                return false
            }
        }

        guard let interceptor = interceptors[scenarioID] else {
            // 没有拦截器默认返回true
            return true
        }

        let canShow = interceptor.canShowMagic()
        if !canShow {
            // 业务方拦截
            LarkMagicTracker.trackInterceptEvent(reason: "custom")
        }
        return canShow
    }

    func registerInterceptor(_ scenarioID: String, _ interceptor: ScenarioInterceptor) {
        interceptors[scenarioID] = interceptor
        LarkMagicInterceptorManager.logger.info("register interceptor", additionalData: ["scenarioID": scenarioID])
    }

    func unregisterInterceptor(_ scenarioID: String) {
        interceptors.removeValue(forKey: scenarioID)
        LarkMagicInterceptorManager.logger.info("unregister interceptor", additionalData: ["scenarioID": scenarioID])
    }

    func removeAllInterceptors() {
        interceptors.removeAll()
    }
}
