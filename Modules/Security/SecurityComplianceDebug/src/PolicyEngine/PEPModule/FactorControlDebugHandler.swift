//
//  FactorControlDebugHandler.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/2/14.
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


final class FactorControlDebugHandler {
    let userResolver: UserResolver
    let userService: PassportUserService?

    let pointCutInfoListStr = "点位"
    let baseParamListStr = "基础参数"
    let additionParamListStr = "额外参数"
    let factorListStr = "特征因子"
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.userService = try? resolver.resolve(assert: PassportUserService.self)
    }

    func generateModel() -> SCDebugFormViewModel {
        let pointCutInfoList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "PointKey", valueType: .string, choiceList: PointKey.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "并发数", valueType: .int, choiceList: nil),
        ]
        let baseParamList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "entityDomain", valueType: .string, choiceList: EntityDomain.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "entityType", valueType: .string, choiceList: EntityType.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "entityOperate", valueType: .string, choiceList: EntityOperate.allCases.map { $0.rawValue }),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "operatorTenantId", valueType: .int, choiceList: [userService?.userTenant.tenantID ?? ""]),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", key: "operatorUid", valueType: .int, choiceList: [userService?.user.userID ?? ""])
        ]

        let model = SCDebugFormViewModel(sectionList: [
            SCDebugSectionViewModel(sectionName: pointCutInfoListStr, fieldList: pointCutInfoList),
            SCDebugSectionViewModel(sectionName: baseParamListStr, fieldList: baseParamList),
            SCDebugSectionViewModel(sectionName: additionParamListStr, fieldList: [], addibleFieldType: [SCDebugCustomizedKeyValueViewCell.self]),
            SCDebugSectionViewModel(sectionName: factorListStr, fieldList: [], addibleFieldType: [SCDebugCustomizedValueOnlyViewCell.self])
        ])
        model.handler = self
        return model
    }
}

extension FactorControlDebugHandler: SCDebugFormViewModelHandler {
    func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]],
                       completed: @escaping (String?) -> Void) {
        guard let pointCutInfoList = sectionContentMap[pointCutInfoListStr],
              let baseParamList = sectionContentMap[additionParamListStr],
              let additionParamList = sectionContentMap[additionParamListStr],
              let factorList = sectionContentMap[factorListStr] else {
            completed(nil)
            return
        }
        guard let pointKey = pointCutInfoList[safeAccess: 0]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "PointKey无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        guard let validateCount = pointCutInfoList[safeAccess: 1]?.realValue as? Int, validateCount > 0 else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let dialog = UIAlertController(title: "Error", message: "并发数设置无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        var params: [String: Any] = [:]
        for item in baseParamList {
            guard let value = item.realValue else {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let dialog = UIAlertController(title: "Error", message: "\(item.key)无效", preferredStyle: .alert)
                Navigator.shared.present(dialog, from: fromVC)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    dialog.dismiss(animated: true)
                }
                completed(nil)
                return
            }
            params[item.key ?? ""] = value
        }
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

        var factors = [String]()
        for item in factorList {
            if item === factorList.last {
                continue
            }
            guard let value = item.realValue as? String else {
                guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let dialog = UIAlertController(title: "Error", message: "factor 因子无效，请选择String类型，并填写正确", preferredStyle: .alert)
                Navigator.shared.present(dialog, from: fromVC)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    dialog.dismiss(animated: true)
                }
                completed(nil)
                return
            }
            factors.append(value)
        }

        var request = CheckPointcutRequest(pointKey: pointKey, entityJSONObject: params, factors: factors)
        var requestMap = [String: CheckPointcutRequest]()
        for _ in 0...validateCount-1 {
            requestMap[UUID().uuidString] = request
        }


        let engineService = try? userResolver.resolve(assert: PolicyEngineService.self)
        engineService?.checkPointcutIsControlledByFactors(requestMap: requestMap, callback: { [weak self] retMap in
            let result = retMap.values.reduce("", { partialResult, response in
                return "\(partialResult)\n-------------\n\n\(response)"
            })
            completed(result)
        })
    }

}
