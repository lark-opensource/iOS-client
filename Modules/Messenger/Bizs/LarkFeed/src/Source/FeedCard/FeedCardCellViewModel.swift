//
//  FeedCardCellViewModel.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/12/5.
//

import Foundation
import LarkOpenFeed
import LarkFeedBase
import RustPB
import LarkModel
import RxSwift
import RxDataSources
import RxCocoa
import LarkContainer

final class FeedCardCellViewModel: FeedCardViewModelInterface, UserResolverWrapper {

    let userResolver: UserResolver
    // feed 模型
    // TODO: feedPreview 应该是不可变的
    var feedPreview: FeedPreview
    // 所属分组
    var bizType: FeedBizType {
        basicData.bizType
    }
    var filterType: Feed_V1_FeedFilter.TypeEnum {
        basicData.groupType
    }

    // 对应的业务方
    let feedCardModule: FeedCardBaseModule
    // component vm 集合
    let componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM]
    // 事件监听
    let eventListeners: [FeedCardEventType: [FeedCardComponentType]]
    // 记录每个坑位的单行高度，待优化
    private let singleLineHeightSet: Set<FeedCardComponentType> =
    [.navigation, .subtitle, .digest, .cta]

    // feed 自身/基础数据
    var basicData: LarkOpenFeed.IFeedPreviewBasicData {
        return _basicData
    }

    private let _basicData: FeedPreviewBasicData

    // 关联业务的实体
    let bizData: FeedPreviewBizData

    // 附带的自定义数据
    let extraData: [AnyHashable: Any]

    // 依赖
    let dependency: FeedCardDependency

    static func build(feedPreview: FeedPreview,
                      userResolver: UserResolver,
                      feedCardModuleManager: FeedCardModuleManager,
                      bizType: FeedBizType,
                      filterType: Feed_V1_FeedFilter.TypeEnum,
                      extraData: [AnyHashable: Any]) -> FeedCardCellViewModel? {
        guard let module = feedCardModuleManager.modules[feedPreview.basicMeta.feedCardType] else {
            let errorMsg = "unable to find a available module. \(bizType), \(filterType), \(feedPreview.description)"
            let info = FeedBaseErrorInfo(type: .error(track: false), objcId: feedPreview.id, errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.feedCard(node: .buildFeedCard, info: info)
            return nil
        }

        let cellVM = FeedCardCellViewModel(
            feedPreview: feedPreview,
            componentFactories: feedCardModuleManager.componentFactories,
            feedCardModule: module,
            userResolver: userResolver,
            bizType: bizType,
            filterType: filterType,
            extraData: extraData)
        return cellVM
    }

    // 可在子线程中初始化
    init(feedPreview: FeedPreview,
         componentFactories: [FeedCardComponentType: FeedCardBaseComponentFactory],
         feedCardModule: FeedCardBaseModule,
         userResolver: UserResolver,
         bizType: FeedBizType,
         filterType: Feed_V1_FeedFilter.TypeEnum,
         extraData: [AnyHashable: Any]) {
        self.feedPreview = feedPreview
        self.feedCardModule = feedCardModule
        self.userResolver = userResolver
        self.dependency = FeedCardDependency(userResolver: userResolver)
        self.bizData = feedCardModule.bizData(feedPreview: feedPreview)
        self.extraData = extraData
        self._basicData = FeedPreviewBasicData.buildBasicData(
            feedPreview: feedPreview,
            feedCardModule: self.feedCardModule,
            userResolver: userResolver,
            bizType: bizType,
            filterType: filterType,
            extraData: extraData)
        let result = Self.buildComponentVM(feedPreview: feedPreview,
                                           feedCardModule: feedCardModule,
                                           componentFactories: componentFactories,
                                           filterType: filterType)
        self.componentVMMap = result.componentVMMap
        self.eventListeners = result.eventListeners
    }

    func copy() -> FeedCardCellViewModel {
        guard let feedCardModuleManager = try? resolver.resolve(assert: FeedCardModuleManager.self) else { return self }
        return FeedCardCellViewModel(
            feedPreview: feedPreview,
            componentFactories: feedCardModuleManager.componentFactories,
            feedCardModule: self.feedCardModule,
            userResolver: userResolver,
            bizType: bizType,
            filterType: filterType,
            extraData: extraData)
    }

    // iPad 上的 选中态，标示 Cell 是否被选中
    var selected: Bool = false {
        didSet {
            if oldValue != selected {
                postEvent(eventType: .selected, value: .selected(selected))
            }
        }
    }
}

// MARK: 处理数据
extension FeedCardCellViewModel {
    // 创建各个组件
    private static func buildComponentVM(
        feedPreview: FeedPreview,
        feedCardModule: FeedCardBaseModule,
        componentFactories: [FeedCardComponentType: FeedCardBaseComponentFactory],
        filterType: Feed_V1_FeedFilter.TypeEnum)
    -> (componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM],
        eventListeners: [FeedCardEventType: [FeedCardComponentType]]) {
        let packInfo = feedCardModule.packInfo
        let componentTypesOrder = packInfo.allTypes
        // 根据组装的信息，获取组件工厂，并使用工厂方法初始化组件
        var componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM] = [:]
        var eventListeners: [FeedCardEventType: [FeedCardComponentType]] = [:]
        componentTypesOrder.forEach { type in
            guard let factory = componentFactories[type] else { return }
            let componentVM = FeedCardContext.buildComponentVO(
                componentType: type,
                feedPreview: feedPreview,
                factory: factory,
                feedCardModule: feedCardModule)
            componentVMMap[componentVM.type] = componentVM
            let eventTypes = componentVM.subscribedEventTypes()
            eventTypes.forEach { eventType in
                var componentTypes = eventListeners[eventType] ?? []
                componentTypes.append(componentVM.type)
                eventListeners[eventType] = componentTypes
            }
        }
        return (componentVMMap, eventListeners)
    }
}

// MARK: 处理UI数据
extension FeedCardCellViewModel {
    // 控制 cell 是否显示
    var isShow: Bool {
        return self.feedCardModule.isShow(feedPreview: feedPreview, filterType: filterType, selectedStatus: selected)
    }

    // 在 Feeds Table 中的高度，支持业务方自定义
    var cellRowHeight: CGFloat {
        let baseHeight = FeedCardLayoutCons.vMargin * 2 + FeedCardTitleComponentView.Cons.titleHeight
        var lineHeight: CGFloat = 0
        self.singleLineHeightSet.forEach { type in
            guard let componentVM = componentVMMap[type] as? FeedCardLineHeight else { return }
            lineHeight += componentVM.height
        }
        if lineHeight == 0 {
            // 兜底，避免feed card只留一个title组件的高度
            lineHeight += FeedCardDigestComponentView.Cons.digestHeight
        }
        return baseHeight + lineHeight
    }
}

// MARK: feed 操作事件
extension FeedCardCellViewModel {
    // 返回从左往右滑动的 actions，返回 [] 可禁用从左往右滑动手势
    var leftActionTypes: [FeedCardSwipeActionType] {
        var leftActionTypes: [FeedCardSwipeActionType]
        switch bizType {
        case .inbox:
            leftActionTypes = [.done]
        case .done:
            leftActionTypes = []
        case .box:
            leftActionTypes = []
        case .flag:
            leftActionTypes = []
        case .label:
            leftActionTypes = []
        @unknown default:
            leftActionTypes = []
        }
        return self.feedCardModule.leftActionTypes(feedPreview: self.feedPreview,
                                                   types: leftActionTypes)
    }

    // 返回从右往左滑动的 actions，返回 [] 可禁用从右往左滑动手势
    var rightActionTypes: [FeedCardSwipeActionType] {
        var rightActionTypes: [FeedCardSwipeActionType]
        switch bizType {
        case .inbox:
            rightActionTypes = [.flag, .shortcut]
        case .done:
            rightActionTypes = []
        case .box:
            rightActionTypes = [.flag, .shortcut]
        case .flag:
            rightActionTypes = [.flag, .shortcut]
        case .label:
            rightActionTypes = [.flag, .shortcut]
        @unknown default:
            rightActionTypes = []
        }
        if !rightActionTypes.isEmpty, !Feed.Feature.shortcutEnabled(userResolver) {
            rightActionTypes.removeAll(where: { $0 == .shortcut })
        }
        return self.feedCardModule.rightActionTypes(feedPreview: self.feedPreview,
                                                    types: rightActionTypes)
    }

    // 返回长按出现menu的 actions，返回 [] 可禁用从右往左滑动手势
    func getLongPressActionTypes() -> [FeedCardLongPressActionType] {
        // 判断是否开启标记FG
        var muteEnable = true
        var addLabelEnable = true
        var deleteLabelFeedEnable = false
        var bindTeamEnable = true
        switch bizType {
        case .inbox: break
        case .done:
            muteEnable = false
            addLabelEnable = false
            bindTeamEnable = false
        case .box:
            muteEnable = false
        case .flag: break
        case .label:
            deleteLabelFeedEnable = true
        @unknown default:
            break
        }

        var longPressActionTypes = (leftActionTypes + rightActionTypes).compactMap {
            $0.transform(preview: feedPreview)
        }
        if muteEnable, isSupportMute() {
            longPressActionTypes.append(.mute(isRemind: feedPreview.basicMeta.isRemind))
        }
        let isSupprtLabel = self.feedCardModule.isSupprtLabel(feedPreview: feedPreview)
        if addLabelEnable, isSupprtLabel, Feed.Feature.labelEnabled {
            longPressActionTypes.append(.label)
        }
        if deleteLabelFeedEnable, isSupprtLabel, Feed.Feature.labelEnabled {
            longPressActionTypes.append(.deleteLabelFeed)
        }

        FeedDebug.executeTask {
            longPressActionTypes.append(.debug)
        }

        if self.feedPreview.basicMeta.unreadCount > 0 && FeedSetting(userResolver).getFeedCardClearBadgeSetting().check(feedPreviewPBType: feedPreview.basicMeta.feedPreviewPBType) {
            longPressActionTypes.append(.clearBadge)
        }
        if Feed.Feature(userResolver).isChatForbiddenEnable, feedPreview.preview.chatData.chatterType == .bot {
            longPressActionTypes.append(.chatForbidden(isForbidden: feedPreview.preview.chatData.mutedBotP2P))
        }
        if bindTeamEnable, dependency.bindTeamEnable(feedPreview: feedPreview) {
            longPressActionTypes.append(.team)
        }
        let types = longPressActionTypes.sorted { $0.index < $1.index }
        return self.feedCardModule.longPressActionTypes(feedPreview: self.feedPreview,
                                                        types: types)
    }
}

// MARK: 事件传递相关
extension FeedCardCellViewModel {
    private func postEvent(eventType: FeedCardEventType, value: FeedCardEventValue) {
        eventListeners[eventType]?.forEach { type in
            guard let componentVM = componentVMMap[type]  else { return }
            componentVM.postEvent(type: eventType, value: value, object: componentVM)
        }
    }
}

// MARK: action - 免打扰操作相关
extension FeedCardCellViewModel: BaseFeedTableCellMute {
    func isSupportMute() -> Bool {
        return self.feedCardModule.isSupportMute(feedPreview: feedPreview)
    }

    func setMute() -> Single<Void> {
        return self.feedCardModule.setMute(feedPreview: feedPreview)
    }
}

// MARK: badge style
extension FeedCardCellViewModel {
    // 当 badge style 变化的时候，判断是否需要更新 feed
    func checkUpdateWhenMuteBadgeStyleChange() -> Bool {
        guard !feedPreview.basicMeta.isRemind,
              feedPreview.basicMeta.unreadCount > 0 else { return false }
        return true
    }
}

// MARK: 双击底部消息tab查找未读
extension FeedCardCellViewModel: FeedFinderItem {
    var isRemind: Bool {
        return feedPreview.basicMeta.isRemind
    }

    var unreadCount: Int {
        return feedPreview.basicMeta.unreadCount
    }
}

// MARK: IdentifiableType
extension FeedCardCellViewModel: IdentifiableType {
    var identity: String {
        feedPreview.id
    }
}

// MARK: Equatable
extension FeedCardCellViewModel: Equatable {
    static func == (lhs: FeedCardCellViewModel, rhs: FeedCardCellViewModel) -> Bool {
        return lhs.feedPreview == rhs.feedPreview
    }
}

// TODO: open feed 待feed action上线后移除该接口
extension FeedCardCellViewModel {
    func checkClearBadgeSetting(feedPreviewPBType: Basic_V1_FeedCard.EntityType) -> Bool {
        return FeedSetting(userResolver).getFeedCardClearBadgeSetting().check(feedPreviewPBType: feedPreviewPBType)
    }
}
