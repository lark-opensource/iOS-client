//
//  Module.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/1/4.
//

import Foundation
import RustPB
import LarkModel
import LarkSceneManager
import RxSwift
import RxCocoa
import LarkContainer

// feed card module 管理器，持有业务module
public class FeedCardModuleManager {
    // 上下文
    public let feedCardContext: FeedCardContext
    // 管理的各个子module
    private static var moduleTypeList: [FeedCardBaseModule.Type] = []
    public let modules: [FeedPreviewType: FeedCardBaseModule]
    // 注入的组件工厂
    public let componentFactories: [FeedCardComponentType: FeedCardBaseComponentFactory]

    public required init(feedCardContext: FeedCardContext) {
        self.feedCardContext = feedCardContext
        var _modules: [FeedPreviewType: FeedCardBaseModule] = [:]
        let modules = Self.moduleTypeList.map({ $0.init(feedCardContext: feedCardContext) })
        modules.forEach { subModule in
            _modules[subModule.type] = subModule
        }
        self.componentFactories = FeedCardComponentFactoryRegister.getAllFactory(feedCardContext: feedCardContext)
        self.modules = _modules
    }

    // 注入module接口，由各个业务方注入module
    public static func register(moduleType: FeedCardBaseModule.Type) {
        moduleTypeList.append(moduleType)
    }
}

open class FeedCardBaseModule: UserResolverWrapper {
    // 用户态容器
    public var userResolver: LarkContainer.UserResolver {
        self.feedCardContext.userResolver
    }

    // feed card 上下文
    public let feedCardContext: FeedCardContext

    public required init(feedCardContext: FeedCardContext) {
        self.feedCardContext = feedCardContext
    }

    // [必须实现]表明自己是xx业务类型
    open var type: FeedPreviewType {
        assertionFailure("must override")
        return .unknown
    }

    // [必须实现] model 交由 业务方去处理，将 pb 转换成 xxx feed preview，比如 doc feed preview
    open func transform(pb: Feed_V1_FeedEntityPreview) -> FeedPreview? {
        assertionFailure("must override")
        return nil
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用，比如标签、标记等业务
    open func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        assertionFailure("must override")
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .unknown
        return FeedPreviewBizData(
            entityId: feedPreview.id,
            shortcutChannel: shortcutChannel)
    }

    // [必须实现] 向feed card容器提供组装组件的配置信息。如果提供的默认的组装信息，已经满足业务方，则不需要重新配置，否则需要重写packInfo
    open var packInfo: FeedCardComponentPackInfo {
        return FeedCardComponentPackInfo.default()
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    open func customComponentVM(componentType: FeedCardComponentType, feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        return nil
    }

    // [必须实现] 控制 feed card 是否显示
    open func isShow(feedPreview: FeedPreview,
                     filterType: Feed_V1_FeedFilter.TypeEnum,
                     selectedStatus: Bool) -> Bool {
        return true
    }

    // [可选实现] feed card 即将上屏时会调用
    open func willDisplay() {}

    // 返回从右往左滑动的 actions，返回 [] 可禁用从右往左滑动手势，返回过滤后的从右往左滑动的 actions
    open func leftActionTypes(feedPreview: FeedPreview,
                              types: [FeedCardSwipeActionType]) -> [FeedCardSwipeActionType] {
        return types
    }

    // 返回从左往右滑动的 actions，返回 [] 可禁用从左往右滑动手势，返回过滤后的从左往右滑动的 actions
    open func rightActionTypes(feedPreview: FeedPreview,
                               types: [FeedCardSwipeActionType]) -> [FeedCardSwipeActionType] {
        return types
    }

    // 返回长按弹起menu的 actions，返回 [] 可禁用从长按手势，返回过滤后的长按弹起menu的 actions
    open func longPressActionTypes(feedPreview: FeedPreview,
                                   types: [FeedCardLongPressActionType]) -> [FeedCardLongPressActionType] {
        return types
    }

    // 是否支持mute操作
    open func isSupportMute(feedPreview: FeedPreview) -> Bool {
        return true
    }

    // mute操作，由各业务实现
    open func setMute(feedPreview: FeedPreview) -> Single<Void> {
        assertionFailure("must override")
        return .just(())
    }

    // 是否支持打标签操作
    open func isSupprtLabel(feedPreview: FeedPreview) -> Bool {
        return false
    }

    // 用于返回 cell 拖拽手势
    open func supportDragScene(feedPreview: FeedPreview) -> Scene? {
        return nil
    }

// MARK: - FeedAction能力
    // [可选实现] 依据事件返回业务方需要展示的 Action 类型集合
    open func getActionTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        assertionFailure("must override")
        return []
    }

    // [可选实现] Action 结果交由业务方判断是否需要处理, 返回 ture 则执行 handleActionResultByBiz, 返回 false 则执行 handler 默认操作
    open func needHandleActionResult(type: FeedActionType, error: Error?) -> Bool { return false }

    // [可选实现] Action结果交由业务方处理,与 handler 默认操作互斥执行
    open func handleActionResultByBiz(type: FeedActionType, model: FeedActionModel, error: Error?) {}
}
