//
//  PolicyEngineDowngradeDebugHandler.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/2/16.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkPolicyEngine
import LarkContainer
import EENavigator

final class PolicyEngineDowngradeDebugHandler: PolicyEngineFastPassDebugHandler {
    override func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]],
                                completed: @escaping (String?) -> Void) {
        guard let pointKey = sectionContentMap[pointCutInfoListStr]?[safeAccess: 0]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "PointKey无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            return
        }
        
        var params: [String: Any] = [:]
        if let baseParamList = sectionContentMap[baseParamListStr] {
            for item in baseParamList {
                guard let value = item.realValue else {
                    guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                    let dialog = UIAlertController(title: "Error", message: "\(item.key)无效", preferredStyle: .alert)
                    Navigator.shared.present(dialog, from: fromVC)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        dialog.dismiss(animated: true)
                    }
                    return
                }
                params[item.key ?? ""] = value
            }
        }
        
        do {
            let userStorage = serviceImpl.storage
            let pointcutList: [String: PointCutModel]? = try userStorage?.get(key: kPointCutInfoCacheKey, space: .global)
            let pointcut = pointcutList?[pointKey]
            if let tenantKey = pointcut?.contextDerivation["TENANT_ID"] {
                params[tenantKey] = params["TENANT_ID"]
            }
            if let objectTenantKey = pointcut?.contextDerivation["OBJECT_TENANT_ID"] {
                params[objectTenantKey] = params["OBJECT_TENANT_ID"]
            }
        } catch {

        }

        var validateRequest = ValidateRequest(pointKey: pointKey, entityJSONObject: params)
        
        let engineService = try? self.userResolver.resolve(assert: PolicyEngineService.self)
        guard let response = engineService?.downgradeDecision(request: validateRequest) else {
            completed("Fail to select downgrade response. engine: \(engineService)")
            return
        }
        completed("\(response)")
    }
}
