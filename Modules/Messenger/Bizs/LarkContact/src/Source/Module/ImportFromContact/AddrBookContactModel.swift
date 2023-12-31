//
//  ImportFromContactModel.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/15.
//

import Foundation
import LarkAddressBookSelector
import LarkContainer
import RustPB
import LarkSDKInterface

struct AddrBookContactModel {
    let contactType: ContactType
    let notYetContact: NotYetUsingContact?
    let usingContact: ContactPointUserInfo?

    init(contactType: ContactType, notYetContact: NotYetUsingContact? = nil, usingContact: ContactPointUserInfo? = nil) {
        self.contactType = contactType
        self.notYetContact = notYetContact
        self.usingContact = usingContact
    }
}

struct NotYetUsingContact {
    enum InviteStatus {
        case invite
        case invited
    }

    let addressBookContact: AddressBookContact
    let inviteStatus: InviteStatus
    let addressBookContactType: ContactContentType
}
