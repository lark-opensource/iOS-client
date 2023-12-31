//
//  ActionButtonViewComponent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/5/15.
//

import Foundation
import AsyncComponent
import LarkAIInfra
import ThreadSafeDataStructure
import LarkMessengerInterface

public class ActionButtonViewProps: ASComponentProps {
    /// 要展示的所有按钮
    public var actionButtons: SafeArray<MyAIChatModeConfig.ActionButton> = [] + .readWriteLock
    /// 点击回调
    public weak var delegate: ActionButtonViewDelegate?
}

public final class ActionButtonViewComponent<C: AsyncComponent.Context>: ASComponent<ActionButtonViewProps, EmptyState, ActionButtonView, C> {
    /// 持有一份ActionButtonLayout，避免多线程问题
    private var layout: Atomic<ActionButtonLayout> = Atomic<ActionButtonLayout>()

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func update(view: ActionButtonView) {
        super.update(view: view)
        view.delegate = self.props.delegate
        if let layout = self.layout.wrappedValue { view.setup(layout: layout) }
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        guard !self.props.actionButtons.isEmpty else { return .zero }

        self.layout.wrappedValue = ActionButtonLayout.layoutForAll(props: self.props, size: size)
        return self.layout.wrappedValue?.size ?? .zero
    }
}
