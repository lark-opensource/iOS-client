//
//  AuthorizationRiskReminderViewModel.swift
//  LarkAccount
//
//  Created by au on 2023/5/9.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LKCommonsLogging

/// https://bytedance.feishu.cn/docx/Y2S8dNOvkoHLpzxTW18cggGbnKc
final class AuthorizationRiskReminderViewModel: SSOBaseViewModel {
    
    let stepInfo: QRCodeLoginConfirmInfo
    let isMultiLogin: Bool
    
    init(resolver: UserResolver?, authType: SSOAuthType, stepInfo: QRCodeLoginConfirmInfo, isMultiLogin: Bool) {
        self.stepInfo = stepInfo
        self.isMultiLogin = isMultiLogin
        super.init(resolver: resolver, info: authType)
    }
}
