//
//  FeedActionFactoryManager.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2023/6/20.
//

import LarkModel
import RustPB
import LKCommonsLogging

// Action构建管理器
public final class FeedActionFactoryManager {
    static var tempHandler: FeedActionHandlerInterface?

    static let logger = Logger.log(FeedActionFactoryManager.self, category: "LarkOpenFeed")

    private static var factoryBuilderList: [FeedActionFactoryManagerBuilder] = []
    // 注入Action工厂
    public static func register(factory: @escaping FeedActionFactoryManagerBuilder) {
        factoryBuilderList.append(factory)
    }

    // 找到对应 FeedActionBaseFactory
    public static func findFactory(feedPreview: FeedPreview, type: FeedActionType) -> FeedActionBaseFactory? {
        // 优先取 biz 构建的工厂实例
        let bizType = feedPreview.basicMeta.feedCardType
        let bizAllMap = FeedActionFactoryManager.getBizAllFactory() // [actionType: [bizType: actionFactory]]
        if let bizActionMap = bizAllMap[type],
           let actionFactory = bizActionMap[bizType] {
            return actionFactory
        }

        // 其次取 feed 构建的工厂实例
        let feedAllMap = FeedActionFactoryManager.getFeedAllFactory() // [actionType: actionFactory]
        if let actionFactory = feedAllMap[type] {
            return actionFactory
        }

        return nil
    }

    // 获取业务定义的Action工厂
    private static func getBizAllFactory() -> [FeedActionType: [FeedPreviewType: FeedActionBaseFactory]] {
        var factoryMap: [FeedActionType: [FeedPreviewType: FeedActionBaseFactory]] = [:]
        Self.factoryBuilderList.forEach { builder in
            guard let factory = builder(), let bizType = factory.bizType else { return }
            var subFactoryMap = factoryMap[factory.type] ?? [:]
            subFactoryMap[bizType] = factory
            factoryMap[factory.type] = subFactoryMap
        }
        return factoryMap
    }

    // 获取feed定义的action工厂
    private static func getFeedAllFactory() -> [FeedActionType: FeedActionBaseFactory] {
        var factoryMap: [FeedActionType: FeedActionBaseFactory] = [:]
        Self.factoryBuilderList.forEach { builder in
            guard let factory = builder(), factory.bizType == nil else { return }
            factoryMap[factory.type] = factory
        }
        return factoryMap
    }

    // 执行 feed 点击跳转 ActionHandler
    public static func performJumpAction(feedPreview: FeedPreview,
                                         context: FeedCardContext,
                                         from vc: UIViewController?,
                                         basicData: IFeedPreviewBasicData?,
                                         bizData: FeedPreviewBizData?,
                                         extraData: [AnyHashable: Any]) {
        // jump action 不会使用 channel
        let model = FeedActionModel(feedPreview: feedPreview,
                                    channel: Basic_V1_Channel(),
                                    fromVC: vc,
                                    basicData: basicData,
                                    bizData: bizData,
                                    extraData: extraData)
        guard let factory = Self.findFactory(feedPreview: feedPreview, type: .jump) else {
            logger.error("feedlog/feedcard/action. jump factory not exist")
            return
        }
        tempHandler = factory.createActionHandler(model: model, context: context)
        tempHandler?.executeTask()
    }

    // 执行 remove feedcard 操作
    public static func performRemoveFeedAction(feedPreview: FeedPreview,
                                               context: FeedCardContext,
                                               channel: Basic_V1_Channel) {
        let model = FeedActionModel(feedPreview: feedPreview, channel: channel)
        guard let factory = Self.findFactory(feedPreview: feedPreview, type: .removeFeed) else {
            logger.error("feedlog/feedcard/action. removeFeed factory not exist")
            return
        }
        tempHandler = factory.createActionHandler(model: model, context: context)
        tempHandler?.executeTask()
    }

    public static func performSomeActionOnce(type: FeedActionType,
                                             feedPreview: FeedPreview,
                                             context: FeedCardContext,
                                             channel: Basic_V1_Channel,
                                             from vc: UIViewController?) {
        let model = FeedActionModel(feedPreview: feedPreview, channel: channel, fromVC: vc)
        guard let factory = Self.findFactory(feedPreview: feedPreview, type: type) else {
            logger.error("feedlog/feedcard/action. \(type) factory not exist")
            return
        }
        tempHandler = factory.createActionHandler(model: model, context: context)
        tempHandler?.executeTask()
    }
}

public typealias FeedActionFactoryManagerBuilder = () -> FeedActionBaseFactory?

// Action工厂协议
public protocol FeedActionBaseFactory {
    var type: FeedActionType { get }

    var bizType: FeedPreviewType? { get }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface?

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface
}

public extension FeedActionBaseFactory {
    var bizType: FeedPreviewType? { return nil }
    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? { return nil }
}
