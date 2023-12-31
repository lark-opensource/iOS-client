//
//  MailSendController+SharedAccount.swift
//  MailSDK
//
//  Created by majx on 2020/6/18.
//

import Foundation

extension MailSendController {
    func getCurrentAccount(complete: ((MailAccount?) -> Void)?) {
        if let account = self.baseInfo.currentAccount {
            complete?(account)
            return
        }
        let currentAccount = Store.settingData.getCachedCurrentAccount()
        self.baseInfo.currentAccount = currentAccount
        complete?(currentAccount)
    }
}
