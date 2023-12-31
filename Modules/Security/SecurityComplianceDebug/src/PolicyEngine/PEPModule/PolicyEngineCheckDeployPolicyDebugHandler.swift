//
//  PolicyEngineCheckDeployPolicyDebugHandler.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/4/13.
//

import EENavigator
import LarkPolicyEngine
import LarkAccountInterface
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkUIKit
import LarkContainer

final class PolicyEngineCheckDeployPolicyDebugHandler: UserResolverWrapper {

    var userResolver: UserResolver

    let baseInfoListStr = "基础信息"

    @ScopedProvider var userService: PassportUserService?
    @ScopedProvider private var engineService: PolicyEngineService?
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func generateModel() -> SCDebugFormViewModel {
        let baseInfoList = [
            SCDebugFieldViewModel(cellID: "SCDebugChoiceBoxViewCell",
                                                  key: "TenantId",
                                                  valueType: .string,
                                                  choiceList: [self.userService?.userTenant.tenantID ?? ""])
        ]
        let model = SCDebugFormViewModel(sectionList: [
            SCDebugSectionViewModel(sectionName: baseInfoListStr, fieldList: baseInfoList)
        ])
        model.handler = self
        return model
    }
}

extension PolicyEngineCheckDeployPolicyDebugHandler: SCDebugFormViewModelHandler {
    func requestResult(sectionContentMap: [String : [SCDebugFieldViewModel]],
                       completed: @escaping (String?) -> Void) {
        guard let tenantId = sectionContentMap[baseInfoListStr]?[safeAccess: 0]?.realValue as? String else {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else {
                completed(nil)
                return
            }
            let dialog = UIAlertController(title: "Error", message: "TenantId无效", preferredStyle: .alert)
            Navigator.shared.present(dialog, from: fromVC)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                dialog.dismiss(animated: true)
            }
            completed(nil)
            return
        }

        let result = engineService?.enableFetchPolicy(tenantId: tenantId)
        completed(result?.stringValue)
    }
}
