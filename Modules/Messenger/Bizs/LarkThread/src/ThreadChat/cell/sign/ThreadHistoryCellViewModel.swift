//
//  ThreadHistoryCellViewModel.swift
//  LarkThread
//
//  Created by 李勇 on 2020/10/20.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkMessageBase

/// 历史消息分割线
final class ThreadHistoryCellViewModel: SignCellViewModel<ThreadContext> {
    override var identifier: String {
        return "history"
    }
    init(context: ThreadContext) {
        super.init(context: context, binder: ThreadHistoryCellComponentBinder(context: context))
    }
}

final class ThreadHistoryCellComponentBinder<C: SignCellContext>: ComponentBinder<C> {
    private lazy var _component: ThreadHistoryCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ThreadHistoryCellComponent(
            props: ASComponentProps(),
            style: ASComponentStyle(),
            context: context
        )
    }
}
