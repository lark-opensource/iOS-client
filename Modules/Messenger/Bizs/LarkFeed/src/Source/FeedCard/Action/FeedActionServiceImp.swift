//
//  FeedActionServiceImp.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/8/17.
//

import LarkContainer
import LarkModel
import LarkOpenFeed
import LarkMessengerInterface
import RustPB
import LarkPerf

final class FeedActionServiceImp: FeedActionService {
    private let context: FeedCardContext
    private lazy var manager: FeedCardModuleManager? = {
        try? context.userResolver.resolve(type: FeedCardModuleManager.self)
    }()

    private lazy var teamAction: TeamActionService? = {
        try? context.userResolver.resolve(assert: TeamActionService.self)
    }()

    private lazy var feedSetting: FeedSettingStore? = {
        try? context.userResolver.resolve(assert: FeedSettingStore.self)
    }()

    required init(context: FeedCardContext) {
        self.context = context
    }

    // 依据手势事件获取使用方补充的 SupplementTypes（业务方不感知）
    func getSupplementTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var types: [FeedActionType] = []
        switch event {
        case .leftSwipe:
            types.append(.teamHide)
        case .rightSwipe:
            break
        case .longPress:
            FeedDebug.executeTask {
                types.append(.debug)
            }
            types.append(.joinTeam)
        @unknown default:
            break
        }
        return types
    }

    // 依据手势事件获取Biz决策的 BizTypes (使用方可以不感知)
    func getBizTypes(model: FeedActionModel, event: FeedActionEvent, useSetting: Bool) -> [FeedActionType] {
        var types: [FeedActionType] = []
        if let bizModule = manager?.modules[model.feedPreview.basicMeta.feedCardType] {
            if Feed.Feature(context.userResolver).feedActionSettingEnable && useSetting {
                return supportActionTypes(bizModule: bizModule, model: model, event: event)
            } else {
                // 获取 Biz 自定义的 actionItemTypes
                types += bizModule.getActionTypes(model: model, event: event)
                types = types.filter({ actionType in
                    if actionType == .shortcut {
                        if !Feed.Feature.shortcutEnabled(context.userResolver) {
                            return false
                        }
                    }
                    return true
                })
                FeedDebug.executeTask {
                    types.append(.debug)
                }
            }
        }
        return types
    }
    // 获取该Feed支持的所有操作，左滑+优化+长按 取并集 并且和设置取交集
    private func supportActionTypes(bizModule: FeedCardBaseModule, model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var typeSet: Set<FeedActionType> = []
        if event == .longPress { // 长按保持不变
            typeSet.formUnion(Set(bizModule.getActionTypes(model: model, event: .longPress)))
        } else {
            typeSet.formUnion(Set(bizModule.getActionTypes(model: model, event: .leftSwipe)))
            typeSet.formUnion(Set(bizModule.getActionTypes(model: model, event: .rightSwipe)))
            typeSet.formUnion(Set(bizModule.getActionTypes(model: model, event: .longPress)))
        }
        var types = Array(typeSet).filter({ actionType in
            if actionType == .shortcut {
                if !Feed.Feature.shortcutEnabled(context.userResolver) {
                    return false
                }
            }
            return true
        })
        FeedDebug.executeTask {
            types.append(.debug)
        }
        return intersectWithSetting(types: types, event: event)
    }

    private func intersectWithSetting(types: [FeedActionType], event: FeedActionEvent) -> [FeedActionType] {
        switch event {
        case .leftSwipe:
            guard self.feedSetting?.currentActionSetting.leftSlideOn == true,
                    let slideSettings = self.feedSetting?.currentActionSetting.leftSlideSettings else { return [] }
            let settingTypes = slideSettings.compactMap { $0.actionType }
            return intersection(supportTypes: types, settingTypes: settingTypes)

        case .rightSwipe:
            guard self.feedSetting?.currentActionSetting.rightSlideOn == true,
                    let slideSettings = self.feedSetting?.currentActionSetting.rightSlideSettings else { return [] }
            let settingTypes = slideSettings.compactMap { $0.actionType }
            return intersection(supportTypes: types, settingTypes: settingTypes)
        case .longPress:
            return types
        @unknown default:
            assertionFailure("unkown event \(event)")
            return []
        }
    }

    private func intersection(supportTypes: [FeedActionType], settingTypes: [FeedActionType]) -> [FeedActionType] {
        var result = [FeedActionType]()
        settingTypes.forEach { type in // 使用setting返回的顺序
            if supportTypes.contains(type) {
                result.append(type)
            }
        }
        return result
    }

    // 依据 Types 集合转成对应的 Action 实例
    public func transformToActionItems(model: FeedActionModel, types: [FeedActionType], event: FeedActionEvent) -> [FeedActionBaseItem] {
        // FG开启时，左右滑的数据已经根据设置排序并去重
        if Feed.Feature(context.userResolver).feedActionSettingEnable && event != .longPress {
            // 先对数组元素做有效过滤
            let validTypes = filterOutValidTypes(model: model, types: types)
            // 数据格式转换
            var actionItems: [FeedActionBaseItem] = []
            validTypes.forEach { type in
                if let actionItem = _getFeedActionItem(model: model, type: type) {
                    actionItems.append(actionItem)
                }
            }
            return actionItems
        } else { // FG关闭或长按
            // 先对数组元素做去重和有效过滤
            let unduplicatedValidTypes = filterOutValidTypes(model: model, types: Array(Set(types)))
            // 再按统一排序规则 sort 数据
            var sortedTypes = FeedActionType.sort(unduplicatedValidTypes)
            if event == .leftSwipe {
                // 由于左滑Action顺序是自右向左排,所以这里取倒序
                sortedTypes.reverse()
            }
            // 数据格式转换
            var actionItems: [FeedActionBaseItem] = []
            sortedTypes.forEach { type in
                if let actionItem = _getFeedActionItem(model: model, type: type) {
                    actionItems.append(actionItem)
                }
            }
            return actionItems
        }
    }

    private func _getFeedActionItem(model: FeedActionModel, type: FeedActionType) -> FeedActionBaseItem? {
        guard let factory = FeedActionFactoryManager.findFactory(feedPreview: model.feedPreview, type: type) else { return nil }
        var handler = factory.createActionHandler(model: model, context: context)
        handler.delegate = self
        return FeedActionItem(type: factory.type,
                              viewModel: factory.createActionViewModel(model: model, context: context),
                              handler: handler,
                              bizType: factory.bizType)
    }
}

extension FeedActionServiceImp {
    /// 筛出 Feed 侧许可的 ActionType 集合
    private func filterOutValidTypes(model: FeedActionModel, types: [FeedActionType]) -> [FeedActionType] {
        return types.compactMap { originType -> FeedActionType? in
            switch originType {
            case .shortcut:
                if model.bizType != .done, Feed.Feature.shortcutEnabled(context.userResolver) { return originType }
            case .flag:
                if model.bizType != .done { return originType }
            case .joinTeam:
                if model.bizType != .done,
                   model.groupType != .team,
                   let service = teamAction, service.enableJoinTeam(feedPreview: model.feedPreview) {
                    return originType
                }
            case .label:
                if model.bizType != .done, Feed.Feature.labelEnabled { return originType }
            case .clearBadge:
                if model.feedPreview.basicMeta.unreadCount > 0,
                   FeedSetting(context.userResolver)
                    .getFeedCardClearBadgeSetting()
                    .check(feedPreviewPBType: model.feedPreview.basicMeta.feedPreviewPBType) {
                    return originType
                }
            case .blockMsg:
                if Feed.Feature(context.userResolver).isChatForbiddenEnable { return originType }
            case .mute:
                if model.bizType != .done, model.bizType != .box { return originType }
            case .done:
                if model.bizType == .inbox { return originType }
            case .deleteLabel:
                if model.bizType == .label, Feed.Feature.labelEnabled { return originType }
            case .teamHide:
                if model.groupType == .team { return originType }
            case .debug, .jump, .removeFeed:
                return originType
            @unknown default:
                return nil
            }
            return nil
        }
    }
}

extension FeedActionServiceImp: FeedActionHandlerDelegate {
    /// 决议 Action 结果处理方
    public func handleActionResult(handler: FeedActionHandlerInterface,
                                   type: FeedActionType,
                                   model: FeedActionModel,
                                   error: Error?) {
        if let bizModule = manager?.modules[model.feedPreview.basicMeta.feedCardType],
           bizModule.needHandleActionResult(type: type, error: error) {
            bizModule.handleActionResultByBiz(type: type, model: model, error: error)
        } else {
            handler.handleResultByDefault(error: error)
        }
    }

    public func trackHandle(status: FeedActionStatus,
                            type: FeedActionType,
                            model: FeedActionModel) {
        switch type {
        // 通用 FeedAction 在 Handler 内做埋点上报
        case .shortcut, .label, .deleteLabel, .debug, .removeFeed, .done, .clearBadge:
            break
        // 使用方补充的 FeedAction
        case .flag:
            trackFlagAction(status: status, model: model)
        case .joinTeam:
            trackJoinTeamAction(status: status, model: model)
        case .teamHide:
            break
        // 业务方提供的 FeedAction
        case .blockMsg:
            break
        case .mute:
            trackMuteAction(status: status, model: model)
        case  .jump:
            trackJumpAction(status: status, model: model)
        @unknown default:
            break
        }
    }
}

extension FeedActionServiceImp {
    private func trackFlagAction(status: FeedActionStatus, model: FeedActionModel) {
        if case .willHandle = status {
            if model.event == .longPress {
                FeedTracker.Press.Click.Flag(
                    feedPreview: model.feedPreview,
                    basicData: model.basicData)
                FeedTracker.Press.Click.Item(
                    itemValue: FeedActionType.clickTrackValue(type: .flag, feedPreview: model.feedPreview),
                    feedPreview: model.feedPreview,
                    basicData: model.basicData)
            }
        } else if case .didHandle(let error) = status {
            if error == nil, model.event == .leftSwipe, let groupType = model.groupType {
                FeedTracker.Leftslide.Click.Flag(
                    toFlag: !model.feedPreview.basicMeta.isFlaged,
                    feedPreview: model.feedPreview,
                    basicData: model.basicData,
                    bizData: model.bizData)
            }
        }
    }

    private func trackJoinTeamAction(status: FeedActionStatus, model: FeedActionModel) {
        if case .willHandle = status {
            if model.event == .longPress {
                FeedTracker.Press.Click.Item(
                    itemValue: FeedActionType.clickTrackValue(type: .joinTeam, feedPreview: model.feedPreview),
                    feedPreview: model.feedPreview,
                    basicData: model.basicData)
            }
        }
    }

    private func trackMuteAction(status: FeedActionStatus, model: FeedActionModel) {
        if case .willHandle = status {
            if model.event == .longPress {
                FeedTracker.Press.Click.Item(
                    itemValue: FeedActionType.clickTrackValue(type: .mute, feedPreview: model.feedPreview),
                    feedPreview: model.feedPreview,
                    basicData: model.basicData)
            }
        }
    }

    private func trackJumpAction(status: FeedActionStatus, model: FeedActionModel) {
        let feedThreeBarService = try? context.userResolver.resolve(assert: FeedThreeBarService.self)
        var unfoldStatus: String?
        if let unfold = feedThreeBarService?.padUnfoldStatus {
            unfoldStatus = unfold ? "unfold" : "fold"
        }
        if case .didHandle(_) = status {
            switch model.feedPreview.basicMeta.feedCardType {
            case .chat:
                FeedTracker.Main.Click.Chat(feed: model.feedPreview,
                                            filter: context.feedContextService.dataSourceAPI?.currentFilterType,
                                            iPadStatus: unfoldStatus)
                ClientPerf.shared.singleEvent("feed router to chat",
                                              params: ["chatId": model.feedPreview.id],
                                              cost: nil)

            case .thread:
                FeedTracker.Main.Click.Chat(feed: model.feedPreview,
                                            filter: context.feedContextService.dataSourceAPI?.currentFilterType,
                                            iPadStatus: unfoldStatus)
            case .docFeed:
                FeedTracker.Main.Click.Doc(feed: model.feedPreview,
                                           filter: context.feedContextService.dataSourceAPI?.currentFilterType,
                                           iPadStatus: unfoldStatus)
            case .box:
                FeedTeaTrack.trackClickChatbox()
            case .unknown, .subscription, .microApp, .topic, .msgThread, .appFeed, .mailFeed, .calendar, .openAppFeed:
                break
            @unknown default:
                break
            }
        }
    }
}
