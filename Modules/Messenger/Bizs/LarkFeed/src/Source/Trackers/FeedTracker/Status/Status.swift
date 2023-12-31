//
//  Status.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import LKCommonsTracker
import Homeric
import RustPB
import LarkModel
import LarkFeedBase
import LarkOpenFeed

/// 「feed流」Feed状态变更
extension FeedTracker {
    struct Status {}
}

extension FeedTracker.Status {
    enum FeedStatusUpdateType: String {
        case title = "2"
        case avatar = "3"
        case badge = "5"
        case displayTime = "6"
        case rankTime = "7"
        case done = "8"
        case unDone = "9"
        case mute = "10"
        case unMute = "11"
        case tempTop = "12"
        case unTempTop = "13"
        case button = "14"
    }
    static func update(oldViewModel: FeedCardCellViewModel,
                       newFeedModel: FeedCardCellViewModel,
                       basicData: IFeedPreviewBasicData,
                       bizData: FeedPreviewBizData) {
        var params: [AnyHashable: Any] = [:]
        let updateTypes = feedUpdates(new: newFeedModel, old: oldViewModel)
        guard !updateTypes.isEmpty else { return }
        params["update_type"] = updateTypes
        params += FeedTracker.FeedCard.BaseParams(feedPreview: newFeedModel.feedPreview,
                                        basicData: basicData,
                                        bizData: bizData)
        Tracker.post(TeaEvent(Homeric.FEED_APP_FEED_CARD_UPDATE_STATUS, params: params))
    }

    private static func feedUpdates(new: FeedCardCellViewModel, old: FeedCardCellViewModel) -> [String] {
        let oldPreveiw = old.feedPreview
        let newPreview = new.feedPreview
        guard oldPreveiw.basicMeta.feedPreviewPBType == .appFeed else {
            return []
        }
        var updateTypes = [String]()
        if oldPreveiw.uiMeta.name != newPreview.uiMeta.name {
            updateTypes.append(FeedStatusUpdateType.title.rawValue)
        }
        if oldPreveiw.uiMeta.avatarKey != newPreview.uiMeta.avatarKey {
            updateTypes.append(FeedStatusUpdateType.avatar.rawValue)
        }
        if oldPreveiw.basicMeta.unreadCount != newPreview.basicMeta.unreadCount {
            updateTypes.append(FeedStatusUpdateType.badge.rawValue)
        }
        if oldPreveiw.uiMeta.displayTime != newPreview.uiMeta.displayTime {
            updateTypes.append(FeedStatusUpdateType.displayTime.rawValue)
        }
        if oldPreveiw.basicMeta.rankTime != newPreview.basicMeta.rankTime {
            updateTypes.append(FeedStatusUpdateType.rankTime.rawValue)
        }
        if oldPreveiw.basicMeta.feedCardBaseCategory != newPreview.basicMeta.feedCardBaseCategory {
            if newPreview.basicMeta.feedCardBaseCategory == .done {
                updateTypes.append(FeedStatusUpdateType.done.rawValue)
            } else {
                updateTypes.append(FeedStatusUpdateType.unDone.rawValue)
            }
        }
        if oldPreveiw.isRemind != newPreview.isRemind {
            if newPreview.isRemind {
                updateTypes.append(FeedStatusUpdateType.unMute.rawValue)
            } else {
                updateTypes.append(FeedStatusUpdateType.mute.rawValue)
            }
        }
        if old.basicData.isTempTop != new.basicData.isTempTop {
            if new.basicData.isTempTop {
                updateTypes.append(FeedStatusUpdateType.tempTop.rawValue)
            } else {
                updateTypes.append(FeedStatusUpdateType.unTempTop.rawValue)
            }
        }
        if oldPreveiw.uiMeta.buttonData != newPreview.uiMeta.buttonData {
            updateTypes.append(FeedStatusUpdateType.button.rawValue)
        }

        return updateTypes
    }
}
