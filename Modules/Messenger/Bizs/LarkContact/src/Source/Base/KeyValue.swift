//
//  KeyValue.swift
//  LarkContact
//
//  Created by zhangwei on 2022/12/2.
//

import Foundation
import LarkStorage

let contactDomain = LarkStorage.Domain.biz.core.child("Contact")

extension KVKeys {
    struct Contact {

        /// gloabl scope
        static let permissionAlreadyClosedFlag = KVKey("permission_banner_closed", default: false)

        /// user scope
        static let uploadServerTimelineMark = KVKey<Double?>("upload_server_timelinemark")
        static let uploadContactsMaxNum = KVKey("upload_contacts_max_num", default: 0)
        static let uploadContactsCDMins = KVKey("upload_contacts_cd_mins", default: 0)
        static let applicationBadge = KVKey<Int?>("application_badge")
        static let firstLoginStatus = KVKey("firstLoginStatus", default: false)
        // onboarding
        static let teamConversionContactEntryShowed = KVKey("onboarding_team_conversion_contact_entry_showed", default: false)
        static let onboardingUploadContactsMaxNum = KVKey<Int?>("onboarding_upload_contacts_max_num")
        // invite
        static let hasDisplayExternalInviteGuide = KVKey("hasDisplayExternalInviteGuide", default: false)
    }
}
