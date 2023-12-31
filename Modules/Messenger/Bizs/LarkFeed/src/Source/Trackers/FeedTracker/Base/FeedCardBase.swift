//
//  FeedCardBase.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/9/4.
//

import Foundation
import LarkModel
import RustPB
import LKCommonsTracker
import LarkFeedBase
import LarkOpenFeed

extension FeedTracker {
    struct FeedCard {
        static func Name(feedPreviewPBType: Basic_V1_FeedCard.EntityType) -> String {
            switch feedPreviewPBType {
            case .chat:
                return "chat"
            case .myAi:
                return "myai"
            case .email:
                return "email"
            case .docFeed:
                return "docFeed"
            case .thread:
                return "thread"
            case .box:
                return "box"
            case .openapp:
                return "openapp"
            case .topic:
                return "topic"
            case .unknownEntity:
                return "unknownEntity"
            case .emailRootDraft:
                return "emailRootDraft"
            case .subscription:
                return "subscription"
            case .msgThread:
                return "msgThread"
            case .appFeed:
                return "app_feed"
            @unknown default:
                return "unknown"
            }
        }

        static func appFeedBizType(appFeedCardType: Feed_V1_AppFeedCardType) -> String {
            switch appFeedCardType {
            case .unknownAppFeedCardType:
                return "unknown"
            case .mail:
                return "mail"
            case .calendar:
                return "cal"
            case .open:
                return "open"
            @unknown default:
                return "unknown"
            }
        }

        /// 左键点击置顶区的文档头像
        static func BaseParams(feedPreview: FeedPreview,
                               basicData: IFeedPreviewBasicData? = nil,
                               bizData: FeedPreviewBizData? = nil) -> [AnyHashable: TeaDataType] {
            var params: [AnyHashable: TeaDataType] = [:]
    //            let topValue: String
    //            if basicData.isTempTop {
    //                topValue = "temporary_top_show"
    //            } else {
    //                topValue = "temporary_top_disappear"
    //            }
    //            params["update_type"] = topValue
            if let basicData = basicData {
                params["is_top"] = basicData.isTempTop ? "true" : "false"
                params["feed_tab"] = FeedGroupData.name(groupType: basicData.groupType)
                params["feed_card_type"] = FeedTracker.FeedCard.Name(feedPreviewPBType: feedPreview.basicMeta.feedPreviewPBType)
                if feedPreview.basicMeta.feedPreviewPBType == .appFeed {
                    params["biz_type"] = FeedTracker.FeedCard.appFeedBizType(appFeedCardType: feedPreview.preview.appFeedCardData.type)
                    params["app_id"] = String(feedPreview.preview.appFeedCardData.appID)
                }
                params["biz_id"] = feedPreview.basicMeta.bizId
            }
            params["app_feed_card_id"] = feedPreview.id
            //params["cta_element"] = cta_element
            //params["event_status"] = event_status
            return params
        }
    }
}
