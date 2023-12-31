// 
// Created by duanxiaochen.7 on 2019/12/24.
// Affiliated with SpaceKit.
// 
// Description: Onboarding 前端获取完成情况

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation

public final class GetOnboardingStatusesService: BaseJSService {}

extension GetOnboardingStatusesService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.getOnboardingStatuses]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let callback = params["callback"] as? String else {
            DocsLogger.onboardingError("前端要获取引导完成情况，却不给我传回调")
            return
        }
        let keys = params["ids"] as? [String] ?? []
        var json = JSON()
        if keys.isEmpty {
            OnboardingID.allCases.forEach { oid in
                let status = OnboardingManager.shared.hasFinished(oid)
                json[oid.rawValue] = JSON(["is_done": status])
            }
        } else {
            for id in keys where !id.isEmpty {
                if let oid = OnboardingID(rawValue: id) {
                    let status = OnboardingManager.shared.hasFinished(oid)
                    json[oid.rawValue] = JSON(["is_done": status])
                } else {
                    json[id] = JSON(["is_done": false])
                }
            }
        }

        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: json.dictionaryObject, completion: nil)
    }
}

class SetOnboardingFinishedService: BaseJSService {}

extension SetOnboardingFinishedService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.setOnboardingFinished]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let ids = params["ids"] as? [String] else {
            DocsLogger.onboardingError("前端要设置引导完成，传过来的引导列表却不合规")
            return
        }
        ids.forEach { (id) in
            if let oid = OnboardingID(rawValue: id) {
                OnboardingManager.shared.markFinished(for: [oid])
            } else {
                OnboardingManager.shared.markBadgeFinished(for: [id])
            }
        }
    }
}
