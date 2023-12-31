//
//  PolicyEngineValidateDebugHandler.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/3.
//

import UIKit
import SnapKit
import EENavigator
import LarkPolicyEngine
import LarkAccountInterface
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkUIKit
import LarkContainer

final class PolicyEngineValidateDebugHandler: UserResolverWrapper {
    var userResolver: UserResolver

    @InjectedSafeLazy var userService: PassportUserService

    let baseParamListStr = "点位"
    let pointCutInfoListStr = "基础参数"
    let additionParamListStr = "额外参数"

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func generateModel() -> SCDebugFormViewModel {
        let baseParamList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "entityDomain", 
                                                  choiceList: EntityDomain.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "fileBizDomain", 
                                                  choiceList: EntityDomain.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "entityType",
                                                  choiceList: EntityType.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "entityOperate", 
                                                  choiceList: EntityOperate.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "operatorTenantId", 
                                                  valueType: .int, choiceList: [userService.userTenant.tenantID]),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "operatorUid", 
                                                  valueType: .int, choiceList: [userService.user.userID]),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "IS_PRE_EVALUATE", 
                                                  choiceList: ["true", "false"])
        ]
        let pointCutInfoList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "PointKey", 
                                                  choiceList: PointKey.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "并发数",
                                                  valueType: .int),
        ]
        let model = SCDebugFormViewModel(sectionList: [
            SCDebugSectionViewModel(sectionName: baseParamListStr, fieldList: baseParamList),
            SCDebugSectionViewModel(sectionName: pointCutInfoListStr, fieldList: pointCutInfoList),
            SCDebugSectionViewModel(sectionName: additionParamListStr, fieldList: [], addibleFieldType: [SCDebugCustomizedValueOnlyViewCell.self])
        ])
        model.handler = self
        return model
    }
}

extension PolicyEngineValidateDebugHandler: SCDebugFormViewModelHandler {
    func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]], completed: @escaping (String?) -> Void) {
        let pointCutInfoList = sectionContentMap[pointCutInfoListStr]
        let baseParamList = sectionContentMap[baseParamListStr]
        let additionParamList = sectionContentMap[additionParamListStr]
        guard let pointKey = pointCutInfoList?[safeAccess: 0]?.realValue as? String else {
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

        guard let validateCount = pointCutInfoList?[safeAccess: 1]?.realValue as? Int, validateCount > 0 else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
            }
            let dialog = UIAlertController(title: "Error", message: "并发数设置无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        var params: [String: Any] = [:]
        if let baseParamList {
            for item in baseParamList {
                guard let value = item.realValue else {
                    guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                        completed(nil)
                        return
                    }
                    let dialog = UIAlertController(title: "Error", message: "\(item.key)无效", preferredStyle: .alert)
                    Navigator.shared.present(dialog, from: fromVC)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        dialog.dismiss(animated: true)
                    }
                    completed(nil)
                    return
                }
                if item.key == "IS_PRE_EVALUATE" {
                    params["base"] = [
                        "GUARDIAN_EVALUATOR_OPTION": [
                            "IS_PRE_EVALUATE": value as? String == "true"
                        ]
                    ]
                } else {
                    params[item.key ?? ""] = value
                }
            }
        }

        if let additionParamList {
            for item in additionParamList {
                if item === additionParamList.last {
                    continue
                }
                guard let key = item.key, let value = item.realValue, key.count > 0 else {
                    guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                    let dialog = UIAlertController(title: "Error", message: "额外参数Key：\(item.key)，Value：\(item.value)无效", preferredStyle: .alert)
                    Navigator.shared.present(dialog, from: fromVC)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                        dialog.dismiss(animated: true)
                    }
                    completed(nil)
                    return
                }
                params[key] = value
            }
        }

        var validateRequest = ValidateRequest(pointKey: pointKey, entityJSONObject: params)
        var requestMap = [String: ValidateRequest]()
        for _ in 0...validateCount-1 {
            requestMap[UUID().uuidString] = validateRequest
        }
        let engineService = try? self.userResolver.resolve(assert: PolicyEngineService.self)
        engineService?.asyncValidate(requestMap: requestMap, callback: { [weak self] responseMap in
            let result = responseMap.values.reduce("", { partialResult, response in
                return "\(partialResult)\n-------------\n\n\(response)"
            })
            completed(result)
        })
    }


}
