//
//  FilterActionHandler.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/11/7.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkOpenFeed
import UniverseDesignShadow
import UniverseDesignColor
import LarkUIKit
import LarkMessengerInterface
import EENavigator
import UniverseDesignActionPanel
import UniverseDesignToast

enum FilterGroupAction {
    case firstLevel(Feed_V1_FeedFilter.TypeEnum)
    case secondLevel(FilterSubSelectedTab)
}

enum FilterGroupActionSheetStyle {
    case noDisplay
    case oneDisplay(FilterGroupActionType)
    case moreDisplay([FilterGroupActionType])
}

enum FilterGroupActionType: Equatable {
    case mute(FilterGroupActionDisplayType)
    case clearBadge
    case atAll(FilterGroupActionDisplayType)
    case displayRule

    static func == (lhs: FilterGroupActionType, rhs: FilterGroupActionType) -> Bool {
        switch (lhs, rhs) {
        case (.mute(let lt), .mute(let rt)): return lt == rt
        case (.clearBadge, .clearBadge): return true
        case (.atAll(let lt), .atAll(let rt)): return lt == rt
        case (.displayRule, .displayRule): return true
        default: return false
        }
    }
}

enum FilterGroupActionDisplayType: Int {
    case unknown
    case on
    case off
}

// 一级分组事件处理器
final class FilterActionHandler {
    let disposeBag = DisposeBag()
    let groupActionSubject: PublishSubject<FilterGroupAction> = PublishSubject()
    let userResolver: UserResolver
    let filterDataStore: FilterDataStore
    let feedAPI: FeedAPI
    // 批量清理badge
    let batchClearBadgeService: BatchClearBagdeService
    // 批量免打扰
    let batchMuteFeedCardsService: BatchMuteFeedCardsService
    let feedContextService: FeedContextService
    let muteActionSetting: FeedSetting.FeedGroupActionSetting
    let clearBadgeActionSetting: FeedSetting.FeedGroupActionSetting
    let atAllSetting: FeedAtAllSetting
    let displayRuleSetting: FeedSetting.FeedGroupActionSetting
    init(userResolver: UserResolver,
         feedContextService: FeedContextService,
         filterDataStore: FilterDataStore,
         feedAPI: FeedAPI,
         batchMuteFeedCardsService: BatchMuteFeedCardsService,
         batchClearBadgeService: BatchClearBagdeService,
         muteActionSetting: FeedSetting.FeedGroupActionSetting,
         clearBadgeActionSetting: FeedSetting.FeedGroupActionSetting,
         atAllSetting: FeedAtAllSetting,
         displayRuleSetting: FeedSetting.FeedGroupActionSetting
    ) throws {
        self.userResolver = userResolver
        self.feedContextService = feedContextService
        self.filterDataStore = filterDataStore
        self.feedAPI = feedAPI
        self.batchMuteFeedCardsService = batchMuteFeedCardsService
        self.batchClearBadgeService = batchClearBadgeService
        self.muteActionSetting = muteActionSetting
        self.clearBadgeActionSetting = clearBadgeActionSetting
        self.atAllSetting = atAllSetting
        self.displayRuleSetting = displayRuleSetting
    }
}

extension FilterActionHandler {
    // 一级分组
    func tryShowFilterActionsSheet(filterType: Feed_V1_FeedFilter.TypeEnum,
                                   isTab: Bool = false,
                                   view: UIView?) {
        guard let from = feedContextService.page,
              let name = FeedFilterTabSourceFactory.source(for: filterType)?.titleProvider(),
              let filterModel = self.filterDataStore.pushFeedPreview?.filtersInfo[filterType] else {
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: "batch action error")
            FeedExceptionTracker.FeedCard.batch(node: .tryShowFilterActionsSheet, info: info)
            return
        }
        let preCheckActions = preCheck(filterType: filterModel.type, isTab: isTab)
        if !preCheckActions.isEmpty {
            getBatchFeedsActionState(filterType: filterType, preCheckActions: preCheckActions)
                .timeout(.milliseconds(self.atAllSetting.timeout), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] response in
                    guard let self = self else { return }
                    self.tryShowSheet(filterType: filterType, name: name, filterModel: filterModel, response: response, view: view, from: from)
                }, onError: { [weak self] _ in
                    guard let self = self else { return }
                    self.tryShowSheet(filterType: filterType, name: name, filterModel: filterModel, response: nil, view: view, from: from)
                }).disposed(by: disposeBag)
        } else {
            tryShowSheet(filterType: filterType, name: name, filterModel: filterModel, response: nil, view: view, from: from)
        }
    }

    func tryShowSheet(filterType: Feed_V1_FeedFilter.TypeEnum,
                      name: String,
                      filterModel: PushFeedFilterInfo,
                      response: RustPB.Feed_V1_QueryMuteFeedCardsResponse?,
                      isTab: Bool = false,
                      view: UIView?,
                      from: UIViewController) {
        let actionTypes = self.getAllActionTypes(filterModel: filterModel, response: response, isTab: isTab)
        let sheetStyle = self.getSheetStyle(actionTypes: actionTypes)
        self.showFirstOrSecondSheet(style: sheetStyle,
                       name: name,
                       filterModel: filterModel,
                       isTab: isTab,
                       view: view,
                       from: from)
    }

    // 第一步：判断哪些action需要通过请求接口来获取前置条件
    func preCheck(filterType: Feed_V1_FeedFilter.TypeEnum, isTab: Bool) -> [FilterGroupActionType] {
        var checkActions: [FilterGroupActionType] = []
        if self.preCheckClearBadge(filterType: filterType) {
            checkActions.append(.clearBadge)
        }
        if self.preCheckMute(filterType: filterType, isTab: isTab) {
            checkActions.append(.mute(.unknown))
        }
        if self.preCheckAtAll(filterType: filterType) {
            checkActions.append(.atAll(.unknown))
        }
        if self.preCheckDisplayRule(filterType: filterType) {
            checkActions.append(.displayRule)
        }
        return checkActions
    }

    // 第二步：组装需要的actions
    func getAllActionTypes(filterModel: PushFeedFilterInfo,
                           response: RustPB.Feed_V1_QueryMuteFeedCardsResponse?,
                           isTab: Bool) -> [FilterGroupActionType] {
        var actionTypes: [FilterGroupActionType] = getDefaultActionTypes(filterModel: filterModel, isTab: isTab)
        guard let response = response else { return actionTypes }
        if let action = self.getMuteActionType(response: response, filterType: filterModel.type, isTab: isTab) {
            actionTypes.append(action)
        }
        if let action = self.getAtAllActionType(response: response, filterType: filterModel.type) {
            actionTypes.append(action)
        }
        if let action = self.getDisplayRuleActionType(filterType: filterModel.type) {
            actionTypes.append(action)
        }
        return actionTypes
    }

    private func getDefaultActionTypes(filterModel: PushFeedFilterInfo, isTab: Bool) -> [FilterGroupActionType] {
        var actionTypes: [FilterGroupActionType] = []
        if let action = getClearBadgeActionType(filterModel: filterModel, isTab: isTab) {
            actionTypes.append(action)
        }
        return actionTypes
    }

    // 第三步：根据组装好的actions，判断sheet的展现形式
    func getSheetStyle(actionTypes: [FilterGroupActionType]) -> FilterGroupActionSheetStyle {
        guard !actionTypes.isEmpty else { return .noDisplay }
        if actionTypes.count == 1, let actionType = actionTypes.first {
            return .oneDisplay(actionType)
        }
        return .moreDisplay(actionTypes)
    }

    // 第四步：根据已处理的sheet展现形式，进行展示sheet
    private func showFirstOrSecondSheet(style: FilterGroupActionSheetStyle,
                           name: String,
                           filterModel: PushFeedFilterInfo,
                           isTab: Bool,
                           view: UIView?,
                           from: UIViewController) {
        var showClearBadge = false
        var showMute = false
        var muteAtAll = false
        var remindAtAll = false
        var showDisplayRule = false

        switch style {
        case .noDisplay:
            return
        case .oneDisplay(let actionType):
            switch actionType {
            case .mute(let displayType):
                showMute = true
                self.showMuteSheet(filterType: filterModel.type, displayType: displayType, view: view, from: from)
            case .clearBadge:
                showClearBadge = true
                self.showClearBadgeSheet(filterType: filterModel.type, view: view, from: from)
            case .atAll(let displayType):
                muteAtAll = displayType == .on
                remindAtAll = displayType == .off
                self.showAtAllSheet(filterType: filterModel.type, displayType: displayType, view: view, from: from)
            case .displayRule:
                showDisplayRule = true
                self.showDisplayRuleSheet(filterType: filterModel.type, view: view, from: from)
            }
        case .moreDisplay(let actionTypes):
            actionTypes.forEach { action in
                switch action {
                case .clearBadge: showClearBadge = true
                case .mute(_): showMute = true
                case .atAll(let displayType):
                    muteAtAll = displayType == .on
                    remindAtAll = displayType == .off
                case .displayRule: showDisplayRule = true
                }
            }
            self.showFirstSheet(name: name,
                                filterType: filterModel.type,
                                actionTypes: actionTypes,
                                view: view,
                                from: from)
        @unknown default:
            return
        }
        if isTab {
            FeedTracker.GroupAction.Click.ClearBadgeMsgTab(showClearBadge: showClearBadge)
        } else {
            FeedTracker.GroupAction.Click.fixedTabLongPressClick(filterModel.type)
        }
        FeedTracker.GroupAction.View(showMute: showMute, showClearBadge: showClearBadge, muteAtAll: muteAtAll, remindAtAll: remindAtAll)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func showFirstSheet(name: String,
                                filterType: Feed_V1_FeedFilter.TypeEnum,
                                actionTypes: [FilterGroupActionType],
                                view: UIView?,
                                from: UIViewController) {
        var actionItems: [UniverseDesignActionPanel.UDActionSheetItem] = []
        actionTypes.forEach { type in
            switch type {
            case .mute(let displayType):
                let muteActionItem = getMuteActionItem(displayType: displayType,
                                                          filterType: filterType,
                                                          view: view,
                                                          from: from)
                actionItems.append(muteActionItem)
            case .clearBadge:
                let clearActionItem = getClearActionItem(filterType: filterType,
                                                            view: view,
                                                            from: from)
                actionItems.append(clearActionItem)
            case .atAll(let displayType):
                let clearActionItem = getAtAllActionItem(displayType: displayType,
                                                            filterType: filterType,
                                                            view: view,
                                                            from: from)
                actionItems.append(clearActionItem)
            case .displayRule:
                let displayRuleItem = getDisplayRuleActionItem(filterType: filterType,
                                                               view: view,
                                                               from: from)
                actionItems.append(displayRuleItem)
            @unknown default:
                break
            }
        }
        guard !actionItems.isEmpty else { return }
        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(name)
        actionItems.forEach { item in
            actionSheet.addItem(item)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Project_T_CancelButton)
        self.userResolver.navigator.present(actionSheet, from: from)
    }
}

// 批量清理badge
extension FilterActionHandler {
    func preCheckClearBadge(filterType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        return false
    }

    func getClearBadgeActionType(filterModel: PushFeedFilterInfo,
                                 isTab: Bool) -> FilterGroupActionType? {
        let clearSetting: Bool
        if isTab {
            clearSetting = clearBadgeActionSetting.msgTab
        } else {
            clearSetting = clearBadgeActionSetting.groupSetting.check(feedGroupPBType: filterModel.type)
        }
        let isValidFeed = filterModel.unread > 0 || filterModel.muteUnread > 0
        let showClearBadge = clearSetting && isValidFeed
        if showClearBadge {
            return .clearBadge
        } else {
            return nil
        }
    }

    private func getClearActionItem(filterType: Feed_V1_FeedFilter.TypeEnum,
                                    view: UIView?,
                                    from: UIViewController) -> UniverseDesignActionPanel.UDActionSheetItem {
        let item = UniverseDesignActionPanel.UDActionSheetItem(title: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Button, action: { [weak self, weak from] in
            guard let self = self, let from = from else { return }
            self.showClearBadgeSheet(filterType: filterType, view: view, from: from)
            FeedTracker.GroupAction.Click.TryClearBadge()
        })
        return item
    }

    private func showClearBadgeSheet(filterType: Feed_V1_FeedFilter.TypeEnum, view: UIView?, from: UIViewController) {
        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(BundleI18n.LarkFeed.Lark_Core_DismissAllMultipleChats_Title)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Ignore_Button, action: { [weak self] in
            self?.clearBadgeRequest(filterType: filterType)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Cancel_Button)
        self.userResolver.navigator.present(actionSheet, from: from)
        FeedTracker.GroupAction.ConfirmView()
    }

    func clearBadgeRequest(filterType: Feed_V1_FeedFilter.TypeEnum) {
        if let filterModel = self.filterDataStore.pushFeedPreview?.filtersInfo[filterType] {
            FeedTracker.GroupAction.Click.ConfirmClearBadge(type: filterType, unmute: filterModel.unread, mute: filterModel.muteUnread)
        }
        let taskID = UUID().uuidString
        batchClearBadgeService.addTaskID(taskID: taskID)
        feedAPI.clearFilterGroupBadge(taskID: taskID, filters: [filterType]).subscribe().disposed(by: disposeBag)
    }
}

// 批量mute
extension FilterActionHandler {
    func preCheckMute(filterType: Feed_V1_FeedFilter.TypeEnum, isTab: Bool) -> Bool {
        let showMuteSetting: Bool
        if isTab {
            showMuteSetting = muteActionSetting.msgTab
        } else {
            showMuteSetting = muteActionSetting.groupSetting.check(feedGroupPBType: filterType)
        }
        return showMuteSetting
    }

    // 查询是否存在 免打扰、at all 提醒的feed
    private func getBatchFeedsActionState(filterType: Feed_V1_FeedFilter.TypeEnum, preCheckActions: [FilterGroupActionType]) -> Observable<RustPB.Feed_V1_QueryMuteFeedCardsResponse> {
        let queryMuteAtAll = preCheckActions.contains(.atAll(.unknown))
        return feedAPI.getBatchFeedsActionState(feeds: [], filters: [filterType], teams: [], tags: [], queryMuteAtAll: queryMuteAtAll)
    }

    func getMuteActionType(response: RustPB.Feed_V1_QueryMuteFeedCardsResponse,
                           filterType: Feed_V1_FeedFilter.TypeEnum,
                           isTab: Bool) -> FilterGroupActionType? {
        guard preCheckMute(filterType: filterType, isTab: isTab) else { return nil }
        let showMute = response.feedCount > 0
        if showMute {
            let isMute = response.hasUnmuteFeeds_p
            if isMute {
                return .mute(.on)
            } else {
                return .mute(.off)
            }
        }
        return nil
    }

    private func getMuteActionItem(displayType: FilterGroupActionDisplayType,
                                   filterType: Feed_V1_FeedFilter.TypeEnum,
                                   view: UIView?,
                                   from: UIViewController) -> UniverseDesignActionPanel.UDActionSheetItem {
        let text: String
        if displayType == .on {
            text = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_Mute_Button
        } else {
            text = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_Unmute_Button
        }
        let item = UniverseDesignActionPanel.UDActionSheetItem(title: text, action: { [weak self, weak from] in
            guard let self = self, let from = from else { return }
            self.showMuteSheet(filterType: filterType, displayType: displayType, view: view, from: from)
        })
        return item
    }

    private func showMuteSheet(filterType: Feed_V1_FeedFilter.TypeEnum, displayType: FilterGroupActionDisplayType, view: UIView?, from: UIViewController) {
        let title: String
        let confirmText: String
        let isMute = displayType == .on
        if isMute {
            title = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Title
            confirmText = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Mute_Button
        } else {
            title = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmUnmute_Title
            confirmText = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmUnmute_Unmute_Button
        }
        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: confirmText, action: { [weak self] in
            guard let self = self else { return }
            self.muteRequest(filterType: filterType, mute: isMute)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Cancel_Button)
        self.userResolver.navigator.present(actionSheet, from: from)
    }

    private func muteRequest(filterType: Feed_V1_FeedFilter.TypeEnum, mute: Bool) {
        let taskID = UUID().uuidString
        batchMuteFeedCardsService.addTaskID(taskID: taskID, mute: mute)
        feedAPI.setBatchFeedsState(taskID: taskID, feeds: [], filters: [filterType], teams: [], tags: [], action: mute ? .mute : .remind)
            .subscribe()
            .disposed(by: disposeBag)
    }
}

// 批量at all
extension FilterActionHandler {
    func preCheckAtAll(filterType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        return atAllSetting.groupSetting.check(feedGroupPBType: filterType)
    }

    func getAtAllActionType(response: RustPB.Feed_V1_QueryMuteFeedCardsResponse,
                            filterType: Feed_V1_FeedFilter.TypeEnum) -> FilterGroupActionType? {
        guard preCheckAtAll(filterType: filterType) else { return nil }
        // muteAtAllType: mute at all功能的展示方式, 仅在req.query_mute_at_all为true时返回
        switch response.muteAtAllType {
        case .unknown, .shouldNotDisplay:
            // 不应该展示功能入口，即没有群聊时
            return nil
        case .displayMuteAtAll:
            // 应当展示关闭at all提醒，即所选feeds中还有开启at all提醒时
            return .atAll(.on)
        case .displayRemindAtAll:
            // 应当展示开启at all提醒，即所选feeds已全部关闭at all提醒时
            return .atAll(.off)
        @unknown default:
            return nil
        }
    }

    private func getAtAllActionItem(displayType: FilterGroupActionDisplayType,
                                    filterType: Feed_V1_FeedFilter.TypeEnum,
                                    view: UIView?,
                                    from: UIViewController) -> UniverseDesignActionPanel.UDActionSheetItem {
        let text: String
        let muteAtAll = displayType == .on
        if muteAtAll {
            text = BundleI18n.LarkFeed.Lark_IM_MuteTagAllMentions_Button
        } else {
            text = BundleI18n.LarkFeed.Lark_IM_UnmuteTagAllMentions_Button
        }
        let item = UniverseDesignActionPanel.UDActionSheetItem(title: text, action: { [weak self, weak from] in
            guard let self = self, let from = from else { return }
            self.showAtAllSheet(filterType: filterType, displayType: displayType, view: view, from: from)
            FeedTracker.GroupAction.Click.FirstOpenAtAll(openAtAll: muteAtAll, filter: filterType)
        })
        return item
    }

    private func showAtAllSheet(filterType: Feed_V1_FeedFilter.TypeEnum, displayType: FilterGroupActionDisplayType, view: UIView?, from: UIViewController) {
        let title: String
        let confirmText: String
        let muteAtAll = displayType == .on
        if muteAtAll {
            title = BundleI18n.LarkFeed.Lark_IM_MuteAllMentionsInAllChats_Title
            confirmText = BundleI18n.LarkFeed.Lark_IM_MuteAllMentionsInAllChats_Mute_Button
        } else {
            title = BundleI18n.LarkFeed.Lark_IM_UnmuteAllMentionsInAllChats_Title
            confirmText = BundleI18n.LarkFeed.Lark_IM_UnmuteAllMentionsInAllChats_Unmute_Button
        }
        let config = UDActionSheetUIConfig(isShowTitle: true)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: confirmText, action: { [weak self] in
            guard let self = self else { return }
            self.atAllRequest(filterType: filterType, muteAtAll: muteAtAll)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Cancel_Button)
        self.userResolver.navigator.present(actionSheet, from: from)
        FeedTracker.GroupAction.ConfirmView(openAtAll: muteAtAll, type: FilterGroupAction.firstLevel(filterType))
    }

    private func atAllRequest(filterType: Feed_V1_FeedFilter.TypeEnum, muteAtAll: Bool) {
        let action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType = muteAtAll ? .muteAtAll : .remindAtAll
        let taskID = UUID().uuidString
        feedAPI.setBatchFeedsState(taskID: taskID, feeds: [], filters: [filterType], teams: [], tags: [], action: action).subscribe().disposed(by: disposeBag)
        FeedTracker.GroupAction.Click.ConfirmOpenAtAll(openAtAll: muteAtAll, type: FilterGroupAction.firstLevel(filterType))
    }
}

// 消息展示设置
extension FilterActionHandler {
    func preCheckDisplayRule(filterType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        let settingCheck: Bool
        if filterType == .tag || filterType == .team {
            // 一级团队和标签分组默认不展示入口
            settingCheck = false
        } else {
            settingCheck = displayRuleSetting.groupSetting.check(feedGroupPBType: filterType)
        }
        return Feed.Feature(userResolver).groupSettingEnable && Feed.Feature(userResolver).groupSettingOptEnable && settingCheck
    }

    func getDisplayRuleActionType(filterType: Feed_V1_FeedFilter.TypeEnum) -> FilterGroupActionType? {
        guard preCheckDisplayRule(filterType: filterType) else { return nil }
        return .displayRule
    }

    private func getDisplayRuleActionItem(filterType: Feed_V1_FeedFilter.TypeEnum,
                                          view: UIView?,
                                          from: UIViewController) -> UniverseDesignActionPanel.UDActionSheetItem {
        let item = UniverseDesignActionPanel.UDActionSheetItem(title: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_Button, action: { [weak self, weak from] in
            guard let self = self, let from = from else { return }
            self.presentDisplayRulePage(filterType: filterType, from: from)
        })
        return item
    }

    private func showDisplayRuleSheet(filterType: Feed_V1_FeedFilter.TypeEnum, view: UIView?, from: UIViewController) {
        let title = FeedFilterTabSourceFactory.source(for: filterType)?.titleProvider() ?? ""
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: !title.isEmpty))
        if !title.isEmpty {
            actionSheet.setTitle(title)
        }
        actionSheet.addItem(getDisplayRuleActionItem(filterType: filterType, view: view, from: from))
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_Cancel_Button)
        self.userResolver.navigator.present(actionSheet, from: from)
    }

    private func presentDisplayRulePage(filterType: Feed_V1_FeedFilter.TypeEnum, from: UIViewController) {
        FeedTracker.GroupAction.Click.ShowMsgDisplayRule(filter: filterType)
        let selectedItem = self.filterDataStore.displayRuleMap[filterType] ?? FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: [.showAll], filterType: filterType)
        let filterName = FeedFilterTabSourceFactory.source(for: filterType)?.titleProvider() ?? ""
        let body = FeedMsgDisplaySettingBody(filterName: filterName, currentItem: selectedItem)
        body.selectObservable.subscribe(onNext: { [weak self, weak from] item in
            guard let self = self, let from = from else { return }
            FeedTracker.GroupAction.Click.SaveMsgDisplayRule(filter: filterType, ruleChanged: selectedItem.selectedTypes != item.selectedTypes)
            self.updateDisplayRuleRequest(item, from)
        }).disposed(by: disposeBag)
        self.userResolver.navigator.present(body: body,
                                            wrap: LkNavigationController.self,
                                            from: from,
                                            prepare: { $0.modalPresentationStyle = .formSheet },
                                            animated: true)
    }

    private func updateDisplayRuleRequest(_ item: FeedMsgDisplayFilterItem, _ from: UIViewController) {
        guard let rule = FiltersModel.transformToFeedRule(userResolver: userResolver, item) else { return }
        let ruleMap = [Int32(item.filterType.rawValue): rule]
        feedAPI.updateMsgDisplayRuleMap(ruleMap, nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak from] _ in
                guard let from = from, let window = from.currentWindow() else { return }
                UDToast.showSuccess(with: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettingsSaved_Toast, on: window)
            }, onError: { [weak from] _ in
                guard let from = from, let window = from.currentWindow() else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettingsSaveFailed_Toast, on: window)
            }).disposed(by: disposeBag)
    }
}
