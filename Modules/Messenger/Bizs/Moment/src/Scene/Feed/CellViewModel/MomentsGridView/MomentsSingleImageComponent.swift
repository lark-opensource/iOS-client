//
//  MomentsCorveImageComponent.swift
//  Moment
//
//  Created by bytedance on 2021/1/15.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

final class MomentsSingleImageComponent<C: BaseMomentContext>: ASComponent<MomentsSingleImageComponent.Props, EmptyState, MomentsSingleImageView, C> {

    final class Props: ASComponentProps {
        // 最大宽度
        public var preferMaxWidth: CGFloat = 0
        // 宿主view的size
        public var hostSize: CGSize = .zero
        // 图片的元素size
        public var originSize: CGSize = .zero
        // 设置图片的image
        public var setImageAction: SetImageAction = nil
        // 图片的点击事件
        public var imageClick: ((UIImageView) -> Void)?
        public var shouldAnimating: Bool = false
        //不为nil时表示 view的size被写死为固定大小
        public var fixedSize: CGSize?
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        if let fixedSize = props.fixedSize {
            return fixedSize
        }
        return MomentsGridLayout.calculateSizeAndContentModeWith(originSize: props.originSize, preferMaxWidth: props.preferMaxWidth, hostWidth: props.hostSize.width).0
    }
    /// 一定在主线程执行。每次从RenderTree到UIView同步的时候会针对每个节点执行updateView
    public override func update(view: MomentsSingleImageView) {
        super.update(view: view)
        view.updateViewWith(setImageAction: props.setImageAction, imageClick: props.imageClick)
        view.toggleAnimation(props.shouldAnimating)
    }

    public override func create(_ rect: CGRect) -> MomentsSingleImageView {
        return MomentsSingleImageView(setImageAction: props.setImageAction, imageClick: props.imageClick)
    }

}
