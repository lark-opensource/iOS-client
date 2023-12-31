//
//  ContactCellViewModel.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/30.
//

import Foundation
import UIKit

final class ContactCellViewModel {

    enum ProfileContentType {
        case image
        case text
    }

    private(set) var contact: AddressBookContact
    var contactSelectType: ContactTableSelectType
    var blocked: Bool = false
    var selected: Bool = false
    var contactTag: ContactTag?
    var profileType: ProfileContentType {
        return (contact.thumbnailProfileImage != nil) ? .image : .text
    }

    var content: String? {
        switch contact.contactPointType {
        case .phone:
            return contact.phoneNumber
        case .email:
            return contact.email
        }
    }

    init(contact: AddressBookContact,
         contactSelectType: ContactTableSelectType,
         contactTag: ContactTag?,
         blocked: Bool = false) {
        self.contact = contact
        self.contactSelectType = contactSelectType
        self.contactTag = contactTag
        self.blocked = blocked
    }
}
