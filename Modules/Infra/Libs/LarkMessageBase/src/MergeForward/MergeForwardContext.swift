//
//  MergeForwardContext.swift
//  LarkMessageBase
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import AsyncComponent

public typealias MergeForwardCellViewModel = LarkMessageBase.CellViewModel<MergeForwardContext>
public typealias MergeForwardMessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageCellViewModel<M, D, MergeForwardContext>
public typealias MergeForwardMessageSubFactory = MessageSubFactory<MergeForwardContext>
public typealias MergeForwardMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency> =
    MessageSubViewModel<M, D, MergeForwardContext>

public protocol MergeForwardPageAPI: UIViewController {
    /// reload多行
    ///
    /// - Parameters:
    ///   - current: 当前行的消息id
    ///   - others: 其他行一起更新的行的消息ids
    func reloadRows(current: String, others: [String])
}

public final class MergeForwardContext: PageContext {
    /// 合并转发类型
    public enum MergeForwardType {
        /// 普通默认的合并转发
        case normal
        /// 内容预览的合并转发
        case contentPreview
        /// 目标预览的合并转发
        case targetPreview
    }
    public weak var chatPageAPI: MergeForwardPageAPI?
    /// 合并转发类型
    public var mergeForwardType: MergeForwardType = .normal
    /// 展示预览消息条数上限提示
    public var showPreviewLimitTip: Bool = false
}

public final class MergeForwardMessageSubFactoryRegistery: MessageSubFactoryRegistery<MergeForwardContext> {
    private static var factoryTypes: [MergeForwardMessageSubFactory.Type] = []
    private static var subFactoryTypes: [SubType: MergeForwardMessageSubFactory.Type] = [:]

    public static func register(_ factoryType: MergeForwardMessageSubFactory.Type) {
        if factoryType.subType == .content {
            factoryTypes.append(factoryType)
        } else {
            subFactoryTypes[factoryType.subType] = factoryType
        }
    }

    public init(context: MergeForwardContext, defaultFactory: MessageSubFactory<MergeForwardContext>? = nil) {
        MessageSubFactoryRegistery.lazyLoadRegister("ChatCellFactory")
        let factories = MergeForwardMessageSubFactoryRegistery.factoryTypes
            .map { $0.init(context: context) }
        let subFactories = MergeForwardMessageSubFactoryRegistery.subFactoryTypes
            .mapValues { $0.init(context: context) }
        super.init(
            defaultFactory: defaultFactory ?? DefaultContentFactory(context: context),
            messageFactories: factories,
            subFactories: subFactories
        )
    }
}

public final class MergeForwardCellLifeCycleObseverRegister: CellLifeCycleObseverRegister {
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
