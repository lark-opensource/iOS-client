//
//  KVKeys.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/8/9.
//

import Foundation
import LarkStorage

public extension KVKeys {
    // 通用的才放这里， key应该放在自己业务里面
    struct SettingStore {
        public struct Notification {
            public static let whenPCOnline = KVKey<Int?>("specialFocusOptions")
            public static let offDuringCalls = KVKey("offDuringCalls", default: false)
            public static let showMessageDetail = KVKey("showMessageDetail", default: true)
            public static let adminCloseShowDetail = KVKey("adminCloseShowDetail", default: false)
        }

        struct General {
            public static func chatSupportAvatarLeftRight(default value: Bool) -> KVKey<Bool> {
                return KVKey("chatSupportAvatarLeftRight", default: value)
            }
        }

//        public struct Effiency {
//            public static let  smartReplyEnable
//            public static let  smartActionEnable
//            public static let  smartComposeMessageEnable
//            public static let  smartComposeMailEnable
//            public static let  smartComposeDocEnable
//            public static let  enterpriseEntityWordTenantSwitchEnable
//            public static let  enterpriseEntityWordMessageEnable
//            public static let  enterpriseEntityWordDocEnable
//            public static let  smartCorrectEnable
//        }
    }
}
