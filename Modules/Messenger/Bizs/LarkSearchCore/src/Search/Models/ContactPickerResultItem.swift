//
//  ContactPickerResultItem.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/4/14.
//

import Foundation
import LarkMessengerInterface
import LarkSDKInterface

public struct ContactPickerResultItem: PickerItemType {
    public var id: String
    public var isCrossTenant: Bool
    public var isPublic: Bool
    public var isDepartment: Bool
    public init(chat: ChatterPickeSelectChatType) {
        self.id = chat.selectedInfoId
        self.isCrossTenant = chat.isCrossTenant
        self.isPublic = chat.isPublic
        self.isDepartment = chat.isDepartment
    }
    public init(externalContact: ContactInfo) {
        self.id = externalContact.userID
        // 外部联系人，所以一定是外部的😅
        self.isCrossTenant = true
        self.isPublic = false
        self.isDepartment = false
    }
}
