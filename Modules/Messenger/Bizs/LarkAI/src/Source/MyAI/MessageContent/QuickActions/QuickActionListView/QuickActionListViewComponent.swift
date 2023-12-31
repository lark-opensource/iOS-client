//
//  QuickActionListViewComponent.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import LarkAIInfra

// MARK: - Props

final class QuickActionListViewComponentProps: ASComponentProps {

    var isLoading: Bool = false
    var quickActionList: [AIQuickActionModel] = []

    /// 线程安全，copy from MaskPostViewComponent.Props
    private var unfairLock = os_unfair_lock_s()
    private var _onTapped: ((AIQuickActionModel) -> Void)?
    var onTapped: ((AIQuickActionModel) -> Void)? {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer { os_unfair_lock_unlock(&unfairLock) }
            return _onTapped
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _onTapped = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }
}

// MARK: - Component

final class QuickActionListViewComponent<C: Context>: ASComponent<QuickActionListViewComponentProps, EmptyState, QuickActionListView, C> {
    /// 持有一份QuickActionListViewLayout，避免多线程问题
    private var layout: Atomic<QuickActionListViewLayout> = Atomic<QuickActionListViewLayout>()

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func create(_ rect: CGRect) -> QuickActionListView {
        return QuickActionListView(frame: rect)
    }

    override func update(view: QuickActionListView) {
        super.update(view: view)

        if let layout = self.layout.wrappedValue {
            view.setup(layout: layout, onTapped: props.onTapped)
        }
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        let newLayout = QuickActionListViewLayout.layout(props: props, size: size)
        self.layout.wrappedValue = newLayout
        return newLayout.size
    }
}
