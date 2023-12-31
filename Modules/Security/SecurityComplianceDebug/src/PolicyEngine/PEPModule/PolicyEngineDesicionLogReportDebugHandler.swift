//
//  PolicyEngineDesicionLogReportDebugHandler.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/8/23.
//

import Foundation
import EENavigator
import LarkPolicyEngine
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkUIKit
import LarkContainer

final class PolicyEngineDesicionLogReportDebugHandler: UserResolverWrapper, SCDebugFormViewModelHandler {
    var userResolver: UserResolver

    let baseInfoListStr = "基础信息"
    
    @ScopedProvider private var engineService: PolicyEngineService?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func generateModel() -> SCDebugFormViewModel {
        let baseInfoList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", 
                                                  key: "evaluateUk",
                                                  valueType: .string),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell", 
                                                  key: "operateTime",
                                                  valueType: .string,
                                                  choiceList: [String(Int64(Date().timeIntervalSince1970))]),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",
                                                  key: "policySetKeys",
                                                  valueType: .string),
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",
                                                  key: "重复次数",
                                                  valueType: .int),
        ]
        let model = SCDebugFormViewModel(sectionList: [
            SCDebugSectionViewModel(sectionName: baseInfoListStr, fieldList: baseInfoList)
        ])
        model.handler = self
        return model
    }

    private func convertToEvaluateInfo(evaluateUk: String, operateTime: String, policySetKeys: String, count: Int) -> [EvaluateInfo] {
        let policySetKeysList: [String] = policySetKeys.components(separatedBy: ";")
        let evaluateInfo = EvaluateInfo(evaluateUk: evaluateUk, operateTime: operateTime, policySetKeys: policySetKeysList)
        var evaluateInfoList: [EvaluateInfo] = []
        for _ in 1...count {
            evaluateInfoList.append(evaluateInfo)
        }
        return evaluateInfoList
    }

    func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]],
                       completed: @escaping (String?) -> Void) {
        guard let evaluateUk = sectionContentMap[baseInfoListStr]?[safeAccess: 0]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
            }
            let dialog = UIAlertController(title: "Error", message: "evaluateUk无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        guard let operateTime = sectionContentMap[baseInfoListStr]?[safeAccess: 1]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
             }
            let dialog = UIAlertController(title: "Error", message: "operateTime无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        guard let policySetKeys = sectionContentMap[baseInfoListStr]?[safeAccess: 2]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
             }
            let dialog = UIAlertController(title: "Error", message: "policySetKeys无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        guard let count = sectionContentMap[baseInfoListStr]?[safeAccess: 3]?.realValue as? Int else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
             }
            let dialog = UIAlertController(title: "Error", message: "policySetKeys无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        engineService?.reportRealLog(evaluateInfoList: convertToEvaluateInfo(evaluateUk: evaluateUk, operateTime: operateTime, policySetKeys: policySetKeys, count: count))
        completed("看日志")
    }
}
