//
//  NameCardEditBody.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/13.
//

import Foundation
import EENavigator
import LarkSDKInterface

public struct NameCardEditBody: PlainBody {
    public static let pattern = "//client/mine/namecardEdit"
    public var id: String?
    public var email: String?
    public var source: String?
    public var name: String?
    public let accountID: String
    public var accountList: [MailAccountBriefInfo]
    public var callback: ((Bool) -> Void)?

    public init(id: String? = nil,
                email: String? = nil,
                name: String? = nil,
                source: String? = nil,
                accountID: String,
                accountList: [MailAccountBriefInfo] = [],
                callback: ((Bool) -> Void)? = nil) {
        self.id = id
        self.email = email
        self.source = source
        self.name = name
        self.accountID = accountID
        self.accountList = accountList
        self.callback = callback
    }
}
