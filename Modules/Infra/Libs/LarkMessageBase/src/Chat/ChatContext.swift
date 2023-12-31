//
//  ChatContext.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/3/31.
//

import UIKit
import Foundation
import class LarkModel.Message
import RxSwift
import RxRelay
import LKLoadable
import LarkContainer

public typealias ChatCellViewModel = LarkMessageBase.CellViewModel<ChatContext>
public typealias ChatMessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageCellViewModel<M, D, ChatContext>
public typealias ChatMessageSubFactory = MessageSubFactory<ChatContext>
public typealias ChatMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageSubViewModel<M, D, ChatContext>

public protocol ChatSelectedMessageContext {
    var id: String { get }
    var type: Message.TypeEnum { get }
    var message: Message? { get }
    var extraInfo: [String: Any] { get }
}

extension ChatSelectedMessageContext {
    public var extraInfo: [String: Any] { return [:] }
}

extension Message: ChatSelectedMessageContext {
    public var message: Message? {
        return self
    }
}

public protocol ChatPageAPI: UIViewController {
    /// 多选信号
    var inSelectMode: Observable<Bool> { get }

    /// 选中的消息
    var selectedMessages: BehaviorRelay<[ChatSelectedMessageContext]> { get }
    /// 进入多选状态
    ///
    /// - Parameter messageId: 消息id
    func startMultiSelect(by messageId: String)

    /// 停止多选态
    func endMultiSelect()

    /// 增加或取消多选消息
    ///
    /// - Parameter messageId: 消息id
    func toggleSelectedMessage(by messageId: String)

    /// reload多行
    ///
    /// - Parameters:
    ///   - current: 当前行的消息id
    ///   - others: 其他行一起更新的行的消息ids
    func reloadRows(current: String, others: [String])

    /// 多选转发时传入这些消息的根帖子ID, 目前只有私有话题群转发使用
    func originMergeForwardId() -> String?
}

public final class ChatContext: PageContext {
    public weak var chatPageAPI: ChatPageAPI?
}

public final class ChatMessageSubFactoryRegistery: MessageSubFactoryRegistery<ChatContext> {
    private static var factoryTypes: [ChatMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: ChatMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: ChatMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: ChatContext, defaultFactory: MessageSubFactory<ChatContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = ChatMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = ChatMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

//密聊SubFactory注册容器
public final class CryptoChatMessageSubFactoryRegistery: MessageSubFactoryRegistery<ChatContext> {
    private static var factoryTypes: [ChatMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: ChatMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: ChatMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: ChatContext, defaultFactory: MessageSubFactory<ChatContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = CryptoChatMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = CryptoChatMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class NormalChatCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
    private static var obseverGenerators: [(UserResolver) -> CellLifeCycleObsever] = []

    public static func register(obseverGenerator: @escaping (UserResolver) -> CellLifeCycleObsever) {
        Self.obseverGenerators.append(obseverGenerator)
    }
    public static func register(obseverGenerator: @escaping () -> CellLifeCycleObsever) {
        Self.obseverGenerators.append { _ in obseverGenerator() }
    }

    public init(userResolver: UserResolver) {
        let obsevers: [CellLifeCycleObsever] = Self.obseverGenerators.map({ generator in
            generator(userResolver)
        })
        super.init(obsevers: obsevers)
    }
}
