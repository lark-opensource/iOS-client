//
//  ApplyCollaborationViewModel.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/7/26.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface

final class MAddContactApplicationViewModel {
    var contacts: [AddExternalContactModel] = []
    var text: String?
    let showCheckBox: Bool

    init(
        contacts: [AddExternalContactModel],
        text: String? = nil,
        showCheckBox: Bool = true
    ) {
        self.contacts = contacts
        self.text = text
        self.showCheckBox = showCheckBox
    }
}
