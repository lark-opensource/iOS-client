//
//  KVPublic.swift
//  LarkSDKInterface
//
//  Created by zhangwei on 2022/11/25.
//

import Foundation
import LarkStorage
import LarkFeatureGating
import LarkSetting

/// 存放一些 **跨模块共享/Public** 的 KV 数据
public extension KVPublic {

    /// Setting 相关
    struct Setting {
        static let domain = Domain.biz.setting

        public static func chatSupportAvatarLeftRight(fgService: FeatureGatingService?) -> KVPublic.Config<Bool, Global.Type> {
            KVKey("ChatSupportAvatarLeftRight", default: .dynamic {
                // message_bubble_align_left 该 fg 用作默认值的配置
                let value = fgService?.staticFeatureGatingValue(with: "messenger.message_bubble_align_left") ?? false
                return !value
            })
            .config(domain: domain, type: Global.self)
        }
        // 保存加急电话设置是否打开
        public static let enableAddUrgentNum = KVKey("enable_add_urgent_call", default: false)
            .config(domain: domain)
        // 加急电话更新时间
        public static let urgentNumUpdateTime = KVKey<Int64>("urgent_call_update_time", default: 0)
            .config(domain: domain)
        public static let smartComposeMessage = KVKey("smart_compose_message_enable", default: false)
            .config(domain: domain)
        public static let smartComposeMail = KVKey("smart_compose_mail_enable", default: false)
            .config(domain: domain)
        public static let smartComposeDoc = KVKey("smart_compose_doc_enable", default: false)
            .config(domain: domain)
        public static let enterpriseEntityTenantSwitch = KVKey("enterprise_entity_word_tenant_switch_enable", default: false)
            .config(domain: domain)
        public static let enterpriseEntityMessage = KVKey("enterprise_entity_word_message_enable", default: false)
            .config(domain: domain)
        public static let enterpriseEntityDoc = KVKey("enterprise_entity_word_doc_enable", default: false)
            .config(domain: domain)
        public static let enterpriseEntityMinutes = KVKey("enterprise_entity_word_minutes_enable", default: false)
            .config(domain: domain)
        public static let enterpriseName = KVKey("enterprise_name", default: "")
            .config(domain: domain)
        public static let smartCorrect = KVKey("smart_correct_enable", default: false)
            .config(domain: domain)
    }

    /// AI 相关
    public struct AI {
        static let domain = Domain.biz.ai

        public static let mainLanguage = KVKey("ai_translation_main_language", default: "")
            .config(domain: domain, type: User.self)
        public static let lastSelectedTargetLanguage = KVKey("ai_translation_last_selected_target_language", default: "")
            .config(domain: domain, type: User.self)
        public static let messageCharThreshold = KVKey<Int>("ai_translation_message_char_threshold", default: 0)
            .config(domain: domain, type: User.self)
    }

}
