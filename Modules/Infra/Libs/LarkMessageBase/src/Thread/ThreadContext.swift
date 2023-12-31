//
//  Context.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//


import Foundation
public typealias ThreadCellViewModel = CellViewModel<ThreadContext>
public typealias ThreadMessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageCellViewModel<M, D, ThreadContext>
public typealias ThreadMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageSubViewModel<M, D, ThreadContext>
public typealias ThreadMessageSubFactory = MessageSubFactory<ThreadContext>

public typealias ThreadDetailCellViewModel = CellViewModel<ThreadDetailContext>
public typealias ThreadDetailMessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageCellViewModel<M, D, ThreadDetailContext>
public typealias ThreadDetailSubViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageSubViewModel<M, D, ThreadDetailContext>
public typealias ThreadDetailSubFactory = MessageSubFactory<ThreadDetailContext>

public final class ThreadContext: PageContext {
    public var isPreview: Bool = false
    public weak var chatPageAPI: ChatPageAPI?
    /// 展示预览消息条数上限提示
    public var showPreviewLimitTip: Bool = false
}

public final class ThreadDetailContext: PageContext {
    public weak var chatPageAPI: ChatPageAPI?
    public var isPreview: Bool = false
}

final public class ThreadChatSubFactoryRegistery: MessageSubFactoryRegistery<ThreadContext> {
    private static var factoryTypes: [ThreadMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: ThreadMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: ThreadMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: ThreadContext, defaultFactory: MessageSubFactory<ThreadContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = ThreadChatSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = ThreadChatSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

final public class ThreadDetailSubFactoryRegistery: MessageSubFactoryRegistery<ThreadDetailContext> {
    private static var factoryTypes: [ThreadDetailSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: ThreadDetailSubFactory.Type] = [:]

    public static func register(_ factoryType: ThreadDetailSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: ThreadDetailContext, defaultFactory: MessageSubFactory<ThreadDetailContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = ThreadDetailSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = ThreadDetailSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

/// ReplyInThreadForwardDetailViewModel使用的是threadPostForwardDetail的scene，不能复用ReplyInThreadSubFactoryRegistery
/// https://bytedance.feishu.cn/docx/QQLtdJSXwoEkV9x4TGMcdKGWnFc
final public class ReplyInThreadForwardDetailSubFactoryRegistery: MessageSubFactoryRegistery<ThreadDetailContext> {
    private static var factoryTypes: [ThreadDetailSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: ThreadDetailSubFactory.Type] = [:]

    public static func register(_ factoryType: ThreadDetailSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: ThreadDetailContext, defaultFactory: MessageSubFactory<ThreadDetailContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = ReplyInThreadForwardDetailSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = ReplyInThreadForwardDetailSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

final public class ReplyInThreadSubFactoryRegistery: MessageSubFactoryRegistery<ThreadDetailContext> {
    private static var factoryTypes: [ThreadDetailSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: ThreadDetailSubFactory.Type] = [:]

    public static func register(_ factoryType: ThreadDetailSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: ThreadDetailContext, defaultFactory: MessageSubFactory<ThreadDetailContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = ReplyInThreadSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = ReplyInThreadSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class ThreadChatCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
    private static var obseverGenerators: [() -> CellLifeCycleObsever] = []

    public static func register(obseverGenerator: @escaping () -> CellLifeCycleObsever) {
        Self.obseverGenerators.append(obseverGenerator)
    }

    public init() {
        let obsevers: [CellLifeCycleObsever] = Self.obseverGenerators.map({ generator in
            generator()
        })
        super.init(obsevers: obsevers)
    }
}

public final class ThreadDetailCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
    private static var obseverGenerators: [() -> CellLifeCycleObsever] = []

    public static func register(obseverGenerator: @escaping () -> CellLifeCycleObsever) {
        Self.obseverGenerators.append(obseverGenerator)
    }

    public init() {
        let obsevers: [CellLifeCycleObsever] = Self.obseverGenerators.map({ generator in
            generator()
        })
        super.init(obsevers: obsevers)
    }
}
