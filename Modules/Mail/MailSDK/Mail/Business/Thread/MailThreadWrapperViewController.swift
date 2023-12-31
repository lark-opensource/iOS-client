//
//  MailThreadWrapperViewController.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/9/24.
//

import LarkUIKit
import RxSwift

enum MailThreadWrapperFrom {
    case multiScene
}

final class MailSettingWrapper {
    static func getSettingController(userContext: MailUserContext) -> MailSettingViewController {
        let settingPage = MailSettingViewController(userContext: userContext)
        settingPage.isPrimarySetting = true
        return settingPage
    }

    static func getAliasSettingController(accountContext: MailAccountContext) -> MailSettingAliasViewController {
        let settingPage = MailSettingAliasViewController(accountContext: accountContext, viewModel: MailSettingViewModel(accountContext: accountContext), accountId: accountContext.accountID)
        return settingPage
    }
}
