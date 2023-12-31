//
//  AddrBookContactCellViewModel.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/13.
//

import Foundation
import LarkSDKInterface
import RxCocoa

final class AddrBookContactCellViewModel {
    var contactModel: AddrBookContactModel

    init(contactModel: AddrBookContactModel) {
        self.contactModel = contactModel
    }

    func finishInviteOrAddFriend() {
        switch contactModel.contactType {
        case .using:
            updateUsingContactStatus(.contactStatusRequest)
        case .notYet:
            finishInvite()
        }
    }

    func updateUsingContactStatus(_ contactStatus: UserContactStatus) {
        guard var usingContact = contactModel.usingContact else {
            return
        }
        usingContact.contactStatus = contactStatus
        contactModel = AddrBookContactModel(contactType: contactModel.contactType,
                                                      usingContact: usingContact)
    }

    private func finishInvite() {
        guard let notYetContact = contactModel.notYetContact else {
            return
        }
        let newValue = NotYetUsingContact(addressBookContact: notYetContact.addressBookContact,
                                          inviteStatus: .invited,
                                          addressBookContactType: notYetContact.addressBookContactType)
        contactModel = AddrBookContactModel(contactType: contactModel.contactType, notYetContact: newValue)
    }
}
