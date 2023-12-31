//
//  PolicyEngineFastPassDebugHandler.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/2/16.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkSecurityCompliance
import LarkPolicyEngine
import LarkContainer
import EENavigator
import LarkAccountInterface
import LarkSnCService

class PolicyEngineFastPassDebugHandler: UserResolverWrapper, SCDebugFormViewModelHandler {
    var userResolver: UserResolver

    let pointCutInfoListStr = "点位"
    let baseParamListStr = "基础参数"

    @InjectedSafeLazy var userService: PassportUserService
    @Provider var serviceImpl: PolicyEngineSnCService

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func generateModel() -> SCDebugFormViewModel {
        let pointCutInfoList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", 
                                                  key: "PointKey",
                                                  valueType: .string,
                                                  choiceList: PointKey.allCases.map { $0.rawValue }),
        ]
        let baseParamList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", 
                                                  key: "TENANT_ID",
                                                  valueType: .int,
                                                  choiceList: [userService.userTenant.tenantID]),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", 
                                                  key: "OBJECT_TENANT_ID",
                                                  valueType: .int,
                                                  choiceList: [userService.userTenant.tenantID]),
        ]
        let model = SCDebugFormViewModel(sectionList: [
                    SCDebugSectionViewModel(sectionName: pointCutInfoListStr, fieldList: pointCutInfoList),
                    SCDebugSectionViewModel(sectionName: baseParamListStr, fieldList: baseParamList)
                ])
        model.handler = self
        return model
    }

    func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]],
                       completed: @escaping (String?) -> Void) {
        guard let pointKey = sectionContentMap[pointCutInfoListStr]?[safeAccess: 0]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
            }
            let dialog = UIAlertController(title: "Error", message: "PointKey无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        var params: [String: Any] = [:]
        if let baseParamList = sectionContentMap[baseParamListStr] {
            for item in baseParamList {
                if let value = item.realValue {
                    params[item.key ?? ""] = value
                }
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
        guard let response = engineService?.enableFastPass(request: validateRequest) else {
            completed("Fail to select fast pass response. engine: \(engineService)")
            return
        }
        completed("fast pass result: \(response)")
    }
}
