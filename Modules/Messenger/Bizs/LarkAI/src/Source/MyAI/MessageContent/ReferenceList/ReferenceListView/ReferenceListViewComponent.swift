//
//  ReferenceListViewComponent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/4/10.
//

import Foundation
import LKRichView
import AsyncComponent
import ThreadSafeDataStructure

public class ReferenceListViewProps: ASComponentProps {
    /// 需要展示的文档
    public var referenceList: SafeArray<LKRichElement> = [] + .readWriteLock
    /// 是否展示所有的文档
    public var needShowAllReferenceList: Bool = true
    /// 点击回调
    public weak var tagAEventDelegate: ReferenceListTagAEventDelegate?
    public weak var showMoreDelegate: ReferenceListShowMoreDelegate?
}

public final class ReferenceListViewComponent<C: AsyncComponent.Context>: ASComponent<ReferenceListViewProps, EmptyState, ReferenceListView, C> {
    /// 持有一份ReferenceListLayout，避免多线程问题
    private var layout: Atomic<ReferenceListLayout> = Atomic<ReferenceListLayout>()

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func update(view: ReferenceListView) {
        super.update(view: view)
        view.tagAEventDelegate = self.props.tagAEventDelegate
        view.showMoreDelegate = self.props.showMoreDelegate
        if let layout = self.layout.wrappedValue { view.setup(layout: layout) }
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        guard !self.props.referenceList.isEmpty else { return .zero }
        if self.props.needShowAllReferenceList {
            self.layout.wrappedValue = ReferenceListLayout.layoutForAll(props: self.props, size: size)
        } else {
            self.layout.wrappedValue = ReferenceListLayout.layoutForTrip(props: self.props, size: size)
        }
        return self.layout.wrappedValue?.size ?? .zero
    }
}
