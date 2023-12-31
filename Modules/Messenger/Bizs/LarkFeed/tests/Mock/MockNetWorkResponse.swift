//
//  MockNetWorkResponse.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/4.
//

import RxSwift
import RxRelay
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import ServerPB
import LarkModel
@testable import LarkFeed

struct MockNetWorkResponse {

    // MARK: 1. getFeedCards
    static var getFeedCardsSubject = BehaviorSubject<GetFeedCardsResult>(value: GetFeedCardsResult(filterType: MockFeed.defaultFilter,
                                                                                                   feeds: [],
                                                                                                   nextCursor: Feed_V1_FeedCursor.min,
                                                                                                   timeCost: 0,
                                                                                                   tempFeedIds: [],
                                                                                                   feedRuleMd5: MockFeed.feedRuleMd5,
                                                                                                   traceId: MockFeed.traceId))

    static func getFeedCardsTriggerResult(_ result: GetFeedCardsResult) {
        let updatedResult = GetFeedCardsResult(filterType: MockFeed.defaultFilter,
                                               feeds: result.feeds,
                                               nextCursor: result.nextCursor,
                                               timeCost: result.timeCost,
                                               tempFeedIds: result.tempFeedIds,
                                               feedRuleMd5: MockFeed.feedRuleMd5,
                                               traceId: MockFeed.traceId)
        MockNetWorkResponse.getFeedCardsSubject.onNext(updatedResult)
    }

    func getFeedCardsTriggerError(_ error: Error) {
        MockNetWorkResponse.getFeedCardsSubject.onError(error)
    }

    // MARK: 2. getNextUnreadFeedCards
    static var getNextUnreadFeedCardsSubject = PublishSubject<NextUnreadFeedCardsResult>()

    static func getNextUnreadFeedCardsTriggerResult(_ result: NextUnreadFeedCardsResult) {
        let updatedResult = NextUnreadFeedCardsResult(filterType: MockFeed.defaultFilter,
                                                      previews: result.previews,
                                                      nextCursor: result.nextCursor,
                                                      tempFeedIds: result.tempFeedIds,
                                                      feedRuleMd5: MockFeed.feedRuleMd5,
                                                      traceId: MockFeed.traceId)
        MockNetWorkResponse.getNextUnreadFeedCardsSubject.onNext(updatedResult)
    }

    func getNextUnreadFeedCardsTriggerError(_ error: Error) {
        MockNetWorkResponse.getNextUnreadFeedCardsSubject.onError(error)
    }

    // MARK: 3. setFeedCardsIntoBox
    static var setFeedCardsIntoBoxSubject = PublishSubject<String>()

    static func setFeedCardsIntoBoxTriggerResult(_ result: String) {
        MockNetWorkResponse.setFeedCardsIntoBoxSubject.onNext(result)
    }

    func setFeedCardsIntoBoxTriggerError(_ error: Error) {
        MockNetWorkResponse.setFeedCardsIntoBoxSubject.onError(error)
    }

    // MARK: 4. deleteFeedCardsFromBox
    static var deleteFeedCardsFromBoxSubject = PublishSubject<Void>()

    static func deleteFeedCardsFromBoxTriggerResult() {
        MockNetWorkResponse.deleteFeedCardsFromBoxSubject.onNext(())
    }

    func deleteFeedCardsFromBoxTriggerError(_ error: Error) {
        MockNetWorkResponse.deleteFeedCardsFromBoxSubject.onError(error)
    }

    // MARK: 5. loadShortcuts
    static var loadShortcutsSubject = PublishSubject<FeedContextResponse>()

    // MARK: 6. createShortcuts
    static var createShortcutsSubject = PublishSubject<Void>()

    // MARK: 7. deleteShortcuts
    static var deleteShortcutsSubject = PublishSubject<Void>()

    // MARK: 8. update
    static var updateSubject = PublishSubject<Void>()

    // MARK: 9. removeFeedCard
    static var removeFeedCardSubject = PublishSubject<Void>()

    // MARK: 10. peakFeedCard
    static var peakFeedCardSubject = PublishSubject<Void>()

    // MARK: 11. moveToDone
    static var moveToDoneSubject = PublishSubject<Void>()

    // MARK: 12. flagFeedCard
    static var flagFeedCardSubject = PublishSubject<Void>()

    // MARK: 13. markFeedCard
    static var markFeedCardSubject = PublishSubject<FeedPreview>()

    // MARK: 14. markChatLaunch
    //    static var markChatLaunchSubject = PublishSubject<Void>()

    // MARK: 15: updateChatRemind
    static var updateChatRemindSubject = PublishSubject<Im_V1_UpdateChatResponse>()

    // MARK: 16: updateMicroAppRemind
    static var updateMicroAppRemindSubject = PublishSubject<Openplatform_V1_SetAppNotificationSwitchResponse>()

    // MARK: 17: updateSubscriptionRemind
    static var updateSubscriptionRemindSubject = PublishSubject<Openplatform_V1_SetSubscriptionNotifyResponse>()

    // MARK: 18: preloadFeedCards
    static var preloadFeedCardsSubject = PublishSubject<Void>()

    // MARK: 19: getFeedFilterSettings
    static var getFeedFilterSettingsSubject = PublishSubject<Feed_V1_GetFeedFilterSettingsResponse>()

    // MARK: 20: updateFeedFilterSettings
    static var updateFeedFilterSettingsSubject = PublishSubject<Feed_V1_UpdateFeedFilterSettingsResponse>()

    // MARK: 21: updateAtFilterSettings
    static var updateAtFilterSettingsSubject = PublishSubject<Feed_V1_UpdateFeedFilterSettingsResponse>()

    // MARK: 22: saveFeedFiltersSetting
    static var saveFeedFiltersSettingSubject = PublishSubject<Feed_V1_UpdateFeedFilterSettingsResponse>()

    // MARK: 23: updateMsgDisplayRuleMap
    static var updateMsgDisplayRuleMapSubject = PublishSubject<Feed_V1_UpdateFeedFilterSettingsResponse>()

    // MARK: 24: getAllBadge
    static var getAllBadgeSubject = PublishSubject<Feed_V1_GetAllBadgeResponse>()

    // MARK: 25: getThreeColumnsSettings
    static var getThreeColumnsSettingsSubject = PublishSubject<Feed_V1_GetThreeColumnsSettingResponse>()

    // MARK: 26: updateThreeColumnsSettings
    static var updateThreeColumnsSettingsSubject = PublishSubject<Feed_V1_SetThreeColumnsSettingResponse>()

    // MARK: 27: updateCommonlyUsedFilters
    static var updateCommonlyUsedFiltersSubject = PublishSubject<Feed_V1_UpdateFeedFilterSettingsResponse>()

    // MARK: 28: getUnreadFeedsNum
    static var getUnreadFeedsNumSubject = PublishSubject<Feed_V1_GetUnreadFeedsResponse>()

    // MARK: 29: getAllLabels
    static var getAllLabelsSubject = PublishSubject<[FeedLabelPreview]>()

    // MARK: 30: getLabels
    static var getLabelsSubject = PublishSubject<GetLabelsResponse>()

    // MARK: 31: getLabelFeeds
    static var getLabelFeedsSubject = PublishSubject<GetLabelFeedsResponse>()

    // MARK: 32: getLabelsForFeed
    static var getLabelsForFeedSubject = PublishSubject<GetLabelsForFeedResponse>()

    // MARK: 33: createLabel
    static var createLabelSubject = PublishSubject<CreateLabelResponse>()

    // MARK: 34: updateLabelInfo
    static var updateLabelInfoSubject = PublishSubject<UpdateLabelResponse>()

    // MARK: 35: deleteLabel
    static var deleteLabelSubject = PublishSubject<UpdateLabelResponse>()

    // MARK: 36: addItemIntoLabel
    static var addItemIntoLabelSubject = PublishSubject<UpdateLabelResponse>()

    // MARK: 37: updateLabel
    static var updateLabelSubject = PublishSubject<UpdateLabelResponse>()

    // MARK: 38: deleteLabelFeed
    static var deleteLabelFeedSubject = PublishSubject<UpdateLabelResponse>()

    // MARK: 39: getTeams
    static var getTeamsSubject = PublishSubject<GetTeamsResult>()

    // MARK: 40: getChats
    static var getChatsSubject = PublishSubject<GetChatsResult>()

    // MARK: 41: preloadItems
    static var preloadItemsSubject = PublishSubject<Im_V1_PreloadItemsResponse>()

    // MARK: 42: hideTeamChat
    static var hideTeamChatSubject = PublishSubject<Im_V1_PatchItemResponse>()

    // MARK: 43: setAppNotificationRead
    static var setAppNotificationReadSubject = PublishSubject<Void>()

    // MARK: 44: clearSingleBadge
    static var clearSingleBadgeSubject = PublishSubject<Void>()

    // MARK: 45: clearTeamBadge
    static var clearTeamBadgeSubject = PublishSubject<Void>()

    // MARK: 46: clearLabelBadge
    static var clearLabelBadgeSubject = PublishSubject<Void>()

    // MARK: 47: clearFilterGroupBadge
    static var clearFilterGroupBadgeSubject = PublishSubject<Void>()

    // MARK: 48: getBatchFeedsActionState
    static var getBatchFeedsActionStateSubject = PublishSubject<Feed_V1_QueryMuteFeedCardsResponse>()

    // MARK: 49: setBatchFeedsState
    static var setBatchFeedsStateSubject = PublishSubject<Void>()

    // MARK: 50: appFeedCardButtonCallback
    static var appFeedCardButtonCallbackSubject = PublishSubject<ServerPB_Feed_AppFeedCardButtonCallbackResponse>()

    // MARK: 51: getFeedActionSetting
    static var getFeedActionSettingSubject = PublishSubject<RustPB.Feed_V1_GetFeedActionSettingResponse>()

    // MARK: 52: updateFeedActionSetting
    static var updateFeedActionSettingSubject = PublishSubject<RustPB.Feed_V1_UpdateFeedActionSettingResponse>()
}
