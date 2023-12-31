//
//  MailMessageListController+Component.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/12/4.
//

import Foundation
import WebKit

extension MailMessageListController: MailMessageEventHandleComponentDelegate {
    func componentViewController() -> UIViewController {
        return self
    }

    var currentMailItem: MailItem {
        return mailItem
    }
}
