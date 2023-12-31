//
//  ContactPickerProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/8/30.
//

import Foundation
import RustPB
import LarkModel

public final class MailContactPickerResItem {
    public enum ItemType {
        case chatter
        case group
        case external
        case nameCard
        case sharedMailbox
        case mailGroup
        case unknown
    }

    public let displayName: String
    public let email: String
    public let entityId: String
    public let type: ItemType
    public var avatarKey: String?
    public var tenantId: String?

    public init(displayName: String,
                email: String,
                entityId: String,
                type: ItemType,
                avatarKey: String?,
                tenantId: String? = nil) {
        self.displayName = displayName
        self.email = email
        self.entityId = entityId
        self.type = type
        self.avatarKey = avatarKey
        self.tenantId = tenantId
    }
}

public final class MailContactPickerParams {
    public var title: String = ""
    public var loadingText: String = ""
    public var maxSelectCount: Int = 500
    public var defaultSelectedMails: [String] = []
    /// 写信页已添加收件人的数量
    public var selectedCount: Int = 0
    public var pickerDepartmentFG: Bool = false
    public var mailAccount: Email_Client_V1_MailAccount?
    public var selectedCallback: (([MailContactPickerResItem]) -> Void)?
    public var selectedCallbackWithNoEmail: (([MailContactPickerResItem], [MailContactPickerResItem]) -> Void)?
}

public protocol ContactPickerProxy {
    func presentMailContactPicker(params: MailContactPickerParams, vc: UIViewController)
    func presentContactSearchPicker(title: String, confirmText: String, selected: [LarkModel.PickerItem], delegate: SearchPickerDelegate, vc: UIViewController)
}
