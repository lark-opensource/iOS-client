//
//  MockFeedAPI.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/4.
//

import Foundation
import LarkSDKInterface
import LarkOpenFeed
import RustPB
import ServerPB
import RxSwift
import RxRelay
import LarkModel
@testable import LarkFeed

final class MockFeedAPI: FeedAPI {

    let disposeBag = DisposeBag()

    func getFeedCardsV4(filterType: Feed_V1_FeedFilter.TypeEnum,
                        boxId: Int?,
                        cursor: Feed_V1_FeedCursor?,
                        count: Int,
                        spanID: UInt64?,
                        feedRuleMd5: String,
                        traceId: String) -> Observable<GetFeedCardsResult> {
        return MockNetWorkResponse.getFeedCardsSubject.asObservable()
    }

    func getFeedCards(filterType: Feed_V1_FeedFilter.TypeEnum, pullType: FeedPullType, feedCardID: String?, cursor: Int?, spanID: UInt64?, count: Int) -> Observable<GetFeedCardsResult> {
        return MockNetWorkResponse.getFeedCardsSubject.asObservable()
    }

    func getNextUnreadFeedCardsV4(filterType: Feed_V1_FeedFilter.TypeEnum, cursor: Feed_V1_FeedCursor?, feedRuleMd5: String, traceId: String) -> Observable<NextUnreadFeedCardsResult> {
        return MockNetWorkResponse.getNextUnreadFeedCardsSubject.asObservable()
    }

    func setFeedCardsIntoBox(feedCardId: String) -> Observable<String> {
        return MockNetWorkResponse.setFeedCardsIntoBoxSubject.asObservable()
    }

    func deleteFeedCardsFromBox(feedCardId: String, isRemind: Bool) -> Observable<Void> {
        return MockNetWorkResponse.deleteFeedCardsFromBoxSubject.asObservable()
    }

    func updateFeedCard(feedId: String, mute: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    func loadShortcuts(strategy: Basic_V1_SyncDataStrategy) -> Observable<FeedContextResponse> {
        return MockNetWorkResponse.loadShortcutsSubject.asObservable()
    }

    func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        return MockNetWorkResponse.createShortcutsSubject.asObservable()
    }

    func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        return MockNetWorkResponse.deleteShortcutsSubject.asObservable()
    }

    func update(shortcut: Feed_V1_Shortcut, newPosition: Int) -> Observable<Void> {
        return MockNetWorkResponse.updateSubject.asObservable()
    }

    func removeFeedCard(channel: Basic_V1_Channel, feedType: Basic_V1_FeedCard.EntityType?) -> Observable<Void> {
        return MockNetWorkResponse.removeFeedCardSubject.asObservable()
    }

    func peakFeedCard(by id: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        return MockNetWorkResponse.peakFeedCardSubject.asObservable()
    }

    func moveToDone(feedId: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        return MockNetWorkResponse.moveToDoneSubject.asObservable()
    }

    func flagFeedCard(_ id: String, isFlaged: Bool, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        return MockNetWorkResponse.flagFeedCardSubject.asObservable()
    }

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview> {
        return MockNetWorkResponse.markFeedCardSubject.asObservable()
    }

    func markChatLaunch(feedId: String, entityType: Basic_V1_FeedCard.EntityType) {
        //        return MockNetWorkResponse.markchatL.asObservable()
    }

    func updateChatRemind(chatId: String, isRemind: Bool) -> Observable<Im_V1_UpdateChatResponse> {
        return MockNetWorkResponse.updateChatRemindSubject.asObservable()
    }

    func updateMicroAppRemind(microAppId: String, isRemind: Bool) -> Single<Openplatform_V1_SetAppNotificationSwitchResponse> {
        return MockNetWorkResponse.updateMicroAppRemindSubject.asObservable().asSingle()
    }

    func updateSubscriptionRemind(subscriptionId: String, isRemind: Bool) -> Single<Openplatform_V1_SetSubscriptionNotifyResponse> {
        return MockNetWorkResponse.updateSubscriptionRemindSubject.asObservable().asSingle()
    }

    func preloadFeedCards(by ids: [String], feedPosition: Int32?) -> Observable<Void> {
        return MockNetWorkResponse.preloadFeedCardsSubject.asObservable()
    }

    func getFeedFilterSettings(needAll: Bool, tryLocal: Bool) -> Observable<Feed_V1_GetFeedFilterSettingsResponse> {
        return MockNetWorkResponse.getFeedFilterSettingsSubject.asObservable()
    }

    func updateFeedFilterSettings(filterEnable: Bool, showMute: Bool?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return MockNetWorkResponse.updateFeedFilterSettingsSubject.asObservable()
    }

    func updateAtFilterSettings(showAtAllInAtFilter: Bool) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return MockNetWorkResponse.updateAtFilterSettingsSubject.asObservable()
    }

    func saveFeedFiltersSetting(_ filterEnable: Bool?,
                                _ commonlyUsedFilters: [Feed_V1_FeedFilter]?,
                                _ usedFilters: [Feed_V1_FeedFilter],
                                _ filterDisplayFeedRule: [Int32: Feed_V1_DisplayFeedRule],
                                _ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return MockNetWorkResponse.saveFeedFiltersSettingSubject.asObservable()
    }

    func updateMsgDisplayRuleMap(_ displayFeedRuleMap: [Int32: Feed_V1_DisplayFeedRule]?,
                                 _ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return MockNetWorkResponse.updateMsgDisplayRuleMapSubject.asObservable()
    }

    func getAllBadge() -> Observable<Feed_V1_GetAllBadgeResponse> {
        return MockNetWorkResponse.getAllBadgeSubject.asObservable()
    }

    func getThreeColumnsSettings(tryLocal: Bool) -> Observable<Feed_V1_GetThreeColumnsSettingResponse> {
        return MockNetWorkResponse.getThreeColumnsSettingsSubject.asObservable()
    }

    func updateThreeColumnsSettings(showEnable: Bool, scene: Feed_V1_ThreeColumnsSetting.TriggerScene) -> Observable<Feed_V1_SetThreeColumnsSettingResponse> {
        return MockNetWorkResponse.updateThreeColumnsSettingsSubject.asObservable()
    }

    func updateCommonlyUsedFilters(_ commonlyUsedFilters: [Feed_V1_FeedFilter]) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return MockNetWorkResponse.updateCommonlyUsedFiltersSubject.asObservable()
    }

    func getUnreadFeedsNum() -> Observable<Feed_V1_GetUnreadFeedsResponse> {
        return MockNetWorkResponse.getUnreadFeedsNumSubject.asObservable()
    }

    func getAllLabels(pageCount: Int32, maxTimes: Int) -> Observable<[FeedLabelPreview]> {
        return MockNetWorkResponse.getAllLabelsSubject.asObservable()
    }

    func getLabels(position: Int64?, count: Int32) -> Observable<GetLabelsResponse> {
        return MockNetWorkResponse.getLabelsSubject.asObservable()
    }

    func getLabelFeeds(labelId: Int64, nextCursor: Feed_V1_GroupCursor?, count: Int32, orderBy: Feed_V1_FeedGroupItemOrderRule) -> Observable<GetLabelFeedsResponse> {
        return MockNetWorkResponse.getLabelFeedsSubject.asObservable()
    }

    func getLabelsForFeed(feedId: String) -> Observable<GetLabelsForFeedResponse> {
        return MockNetWorkResponse.getLabelsForFeedSubject.asObservable()
    }

    func createLabel(labelName: String, feedId: Int64?) -> Observable<CreateLabelResponse> {
        return MockNetWorkResponse.createLabelSubject.asObservable()
    }

    func updateLabelInfo(id: Int64, name: String) -> Observable<UpdateLabelResponse> {
        return MockNetWorkResponse.updateLabelInfoSubject.asObservable()
    }

    func deleteLabel(id: Int64) -> Observable<UpdateLabelResponse> {
        return MockNetWorkResponse.deleteLabelSubject.asObservable()
    }

    func addItemIntoLabel(labelId: Int64, itemIds: [Int64]) -> Observable<UpdateLabelResponse> {
        return MockNetWorkResponse.addItemIntoLabelSubject.asObservable()
    }

    func updateLabel(feedId: Int64, updateLabels: [Int64], deleteLabels: [Int64]) -> Observable<UpdateLabelResponse> {
        return MockNetWorkResponse.updateLabelSubject.asObservable()
    }

    func deleteLabelFeed(feedId: Int64, labelId: Int64) -> Observable<UpdateLabelResponse> {
        return MockNetWorkResponse.deleteLabelFeedSubject.asObservable()
    }

    func getTeams() -> Observable<GetTeamsResult> {
        return MockNetWorkResponse.getTeamsSubject.asObservable()
    }

    func getChats(parentIDs: [Int]) -> Observable<GetChatsResult> {
        return MockNetWorkResponse.getChatsSubject.asObservable()
    }

    func preloadItems(parentIds: [Int]) -> Observable<Im_V1_PreloadItemsResponse> {
        return MockNetWorkResponse.preloadItemsSubject.asObservable()
    }

    func hideTeamChat(chatId: Int, isHidden: Bool) -> Observable<Im_V1_PatchItemResponse> {
        return MockNetWorkResponse.hideTeamChatSubject.asObservable()
    }

    func setAppNotificationRead(appID: String, seqID: String) -> Observable<Void> {
        return MockNetWorkResponse.setAppNotificationReadSubject.asObservable()
    }

    func clearSingleBadge(taskID: String, feeds: [Feed_V1_FeedCardBadgeIdentity]) -> Observable<Void> {
        return MockNetWorkResponse.clearSingleBadgeSubject.asObservable()
    }

    func clearTeamBadge(taskID: String, teams: [Int64]) -> Observable<Void> {
        return MockNetWorkResponse.clearTeamBadgeSubject.asObservable()
    }

    func clearLabelBadge(taskID: String, labels: [Feed_V1_TagIdentity]) -> Observable<Void> {
        return MockNetWorkResponse.clearLabelBadgeSubject.asObservable()
    }

    func clearFilterGroupBadge(taskID: String, filters: [Feed_V1_FeedFilter.TypeEnum]) -> Observable<Void> {
        return MockNetWorkResponse.clearFilterGroupBadgeSubject.asObservable()
    }

    func getBatchFeedsActionState(feeds: [Feed_V1_FeedCardBadgeIdentity],
                                  filters: [Feed_V1_FeedFilter.TypeEnum],
                                  teams: [Int64], tags: [Feed_V1_TagIdentity],
                                  queryMuteAtAll: Bool) -> Observable<Feed_V1_QueryMuteFeedCardsResponse> {
        return MockNetWorkResponse.getBatchFeedsActionStateSubject.asObservable()
    }

    func setBatchFeedsState(taskID: String,
                            feeds: [Feed_V1_FeedCardBadgeIdentity],
                            filters: [Feed_V1_FeedFilter.TypeEnum],
                            teams: [Int64],
                            tags: [Feed_V1_TagIdentity],
                            action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType) -> Observable<Void> {
        return MockNetWorkResponse.setBatchFeedsStateSubject.asObservable()
    }

    func appFeedCardButtonCallback(buttonId: String) -> Observable<ServerPB_Feed_AppFeedCardButtonCallbackResponse> {
        return MockNetWorkResponse.appFeedCardButtonCallbackSubject.asObservable()
    }

    func getFeedActionSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> RxSwift.Observable<RustPB.Feed_V1_GetFeedActionSettingResponse> {
        return MockNetWorkResponse.getFeedActionSettingSubject.asObservable()
    }
    func updateFeedActionSetting(setting: RustPB.Feed_V1_FeedSlideActionSetting) -> RxSwift.Observable<RustPB.Feed_V1_UpdateFeedActionSettingResponse> {
        return MockNetWorkResponse.updateFeedActionSettingSubject.asObservable()
    }
}
