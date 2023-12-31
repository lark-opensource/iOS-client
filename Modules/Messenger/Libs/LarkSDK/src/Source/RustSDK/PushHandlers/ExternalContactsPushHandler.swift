//
//  ExternalContactsPushHandler.swift
//  LarkSDK
//
//  Created by 姚启灏 on 2018/8/17.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkFeatureGating
import LarkModel
import LKCommonsLogging

final class ExternalContactsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    static var logger = Logger.log(ExternalContactsPushHandler.self, category: "Rust.PushHandler.ExternalContactsPushHandler")

    func process(push message: RustPB.Im_V1_PushContact) {
        let contact = Contact.transform(pb: message.contact)
        if let pbChatter = message.entity.chatters[contact.chatterId] {
            let chatter = LarkModel.Chatter.transform(pb: pbChatter)
            contact.chatter = chatter
        }

        // 联系人二期FG
        let contactInfo: ContactInfo = ContactInfo.transform(contactInfoPB: message.contactInfo)
        let isDelete: Bool = message.contactInfo.op == .operationDelete
        let conactPushInfo = ExternalContactPushInfo(contactInfo: contactInfo, isDeleted: isDelete)
        self.pushCenter?.post(
            PushNewExternalContacts(contactPushInfos: [conactPushInfo])
        )
        ExternalContactsPushHandler.logger.debug("ExternalContactsPushHandler push new contact, fg open",
                                                 additionalData: ["userID": "\(contactInfo.userID)",
                                                                  "isDeleted": "\(contact.isDeleted)"])
    }
}
