//
//  KeyValue.swift
//  LarkMine
//
//  Created by panbinghua on 2022/8/10.
//

import Foundation
import LarkStorage
import RustPB

extension KVStores {
    struct Mine {
        static let domain = Domain.biz.core.child("Mine")

        /// 构建用户维度的 `KVStore`
        static func build(forUser userId: String) -> KVStore {
            return KVStores.udkv(space: .user(id: userId), domain: domain)
        }
    }

    struct Setting {
        static let domain = Domain.biz.setting

        /// 构建用户维度的 `KVStore`
        static func build(forUser userId: String) -> KVStore {
            return KVStores.udkv(space: .user(id: userId), domain: domain)
        }
    }
}

// support `KVKey`
extension Settings_V1_MessengerNotificationSetting: KVNonOptionalValue {}

extension KVKeys {
    struct Mine {
        // unused
        // static let city = KVKey<String?>("user_city")
        // static let stickerLastSyncTime = KVKey("sticker_last_sync_time", default: 0.0)
        static let department = KVKey("user_department", default: "")
        static let organization = KVKey<String?>("user_organization")
        static let description = KVKey<String?>("user_description")
        static let descriptionType = KVKey("user_description_type", default: 0)
        static let enableAnotherName = KVKey("enable_another_name", default: false)
        static let anotherName = KVKey("another_name", default: "")

        // 活动模块相关
        static let activitySummaryFlag = KVKey("activity_award_banner_summary", default: false)
        static let activitySummaryURL = KVKey<String?>("activity_award_banner_summary_url")
        static let activityAwardAlreadyEnterFlag = KVKey("activity_award_already_enter", default: false)

        // Onboarding
        static let upgradeTeamMineBadgeShowed = KVKey("onboarding_upgrade_team_mine_badge_showed", default: false)
    }

    struct Setting {
        struct Notification {
            static let notificationSettings = KVKey("notificationSettings", default: Settings_V1_MessengerNotificationSetting())
            static let switchState = KVKey<Int?>("switchState")
            static let specificOptions = KVKey<Int?>("specificOptions")
            static let specialFocusOptions = KVKey<Int?>("specialFocusOptions")
        }

        struct MultiUserNotification {
            static let lastOperationTime = KVKey<Double?>("lastOperationTime")
        }

        struct General {
            public static let wifiSwitch4G = KVKey("wifiSwitch4G", default: true)
        }
    }
}
