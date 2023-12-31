//
//  LarKAddressBookInterface.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2021/2/21.
//

import UIKit
import Foundation
import Contacts
import UniverseDesignColor
import UniverseDesignTheme

public typealias AuthorityReqSuccessCallback = ((ContactsDataInfo) -> Void)
public typealias AuthorityReqFailedCallback = ((AuthorityReqFailedInfo) -> Void)
public typealias AuthorityReqFailedInfo = (status: CNAuthorizationStatus, error: NSError?)
typealias ContactsReqSuccessCallback = ((ContactsDataInfo) -> Void)
typealias ContactsReqFailedCallback = ((NSError) -> Void)

public struct ContactAuthorityAlertInfo {
    // alert
    public let textInfo: ContactAlertTextInfo?
    // 展示页面
    public let hostProvider: UIViewController
    public init(textInfo: ContactAlertTextInfo? = nil,
                hostProvider: UIViewController) {
        self.textInfo = textInfo
        self.hostProvider = hostProvider
    }
}

public struct ContactAlertTextInfo {
    // alert标题
    public let title: String
    // alert内容
    public let message: String?
    public init(title: String,
                message: String? = nil) {
        self.title = title
        self.message = message
    }
}

/// 读取通讯录业务类型枚举
public enum BizType {
    case onboarding
    case contact
}

// 通讯录联系人数据
public struct ContactsDataInfo {
    public let allContacts: [AddressBookContact]
    public let orderedContacts: [String: [AddressBookContact]]
    public let sortedContactKeys: [String]
}

public typealias ContactRequestAccessCompletionHandler = (Bool, Error?) -> Void

public enum ContactContentType: String {
    case email
    case phone
}

public enum AddressBookDataType {
    case email
    case phone
    case all
}

/// 列表选择类型 单选/多选
public enum ContactTableSelectType {
    /// 单选
    case single
    /// 多选
    case multiple
}

// 用户标签
public struct ContactTag {
    public let tagContent: String
    public let backgroundColor: UIColor
    public let font: UIFont
    public let textColor: UIColor
    public init(
        tagContent: String,
        backgroundColor: UIColor = UIColor.ud.B100,
        font: UIFont = .systemFont(ofSize: 11),
        textColor: UIColor = UIColor.ud.B700
    ) {
        self.tagContent = tagContent
        self.backgroundColor = backgroundColor
        self.font = font
        self.textColor = textColor
    }
}

// 用户标识类型
public enum ContactPointType {
    case phone
    case email
}
