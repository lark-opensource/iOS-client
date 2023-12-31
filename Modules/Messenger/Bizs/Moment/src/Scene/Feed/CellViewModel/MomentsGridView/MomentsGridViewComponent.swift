//
//  MomentsGridViewComponent.swift
//  Moment
//
//  Created by liluobin on 2021/1/9.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

final class MomentsGridViewComponent<C: BaseMomentContext>: ASComponent<MomentsGridViewComponent.Props, EmptyState, MomentsGridView, C> {

    final class Props: ASComponentProps {
        public var preferMaxWidth: CGFloat = 0
        public var hostSize: CGSize = .zero
        public var imageInfoProps: [ImageInfoProp] = []
        public var shouldAnimating: Bool = false
    }

    /// 显式的声明这个Component是否对应一个复合UIView。即这个Component对应的UIView组件内部会有自包含的子view。是组件层面上的叶子结，RenderTree到UIViewTree同步的那一刻，在Component的isLeaf为true并且isComplex为true时，不去继续递归处理ta的子view
    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }
    /// 处理叶子节点的自撑开大小计算规则。
    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return MomentsGridLayout.girdViewSizeFor(preferMaxWidth: props.preferMaxWidth, hostWidth: props.hostSize.width, imageList: props.imageInfoProps)
    }
    /// 一定在主线程执行。每次从RenderTree到UIView同步的时候会针对每个节点执行updateView
    public override func update(view: MomentsGridView) {
        super.update(view: view)
        view.updateView(imageList: props.imageInfoProps)
        MomentsGridLayout.layoutForItemViewsWith(preferMaxWidth: props.preferMaxWidth, hostWidth: props.hostSize.width, imageViewItems: view.itemViews)
        view.toggleAnimation(props.shouldAnimating)
    }

    public override func create(_ rect: CGRect) -> MomentsGridView {
        return MomentsGridView(imageList: props.imageInfoProps)
    }
}
