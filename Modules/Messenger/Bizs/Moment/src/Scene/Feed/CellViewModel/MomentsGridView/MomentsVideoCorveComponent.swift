//
//  MomentsVideoCorveComponent.swift
//  Moments
//
//  Created by liluobin on 2021/3/24.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

final class MomentsVideoCorveComponent<C: BaseMomentContext>: ASComponent<MomentsVideoCorveComponent.Props, EmptyState, MomentsVideoCorveView, C> {

    final class Props: ASComponentProps {
        // 最大宽度
        public var preferMaxWidth: CGFloat = 0
        // 图片的元素size
        public var originSize: CGSize = .zero
        // 设置图片的image
        public var setImageAction: SetImageAction = nil
        // 图片的点击事件
        public var imageClick: ((UIImageView) -> Void)?
        // 图片是否需要覆盖一些图片
        public var coverImage: UIImage?
        public var videoTime: Int32?
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return MomentsVideoCorveView.videoCoverImageSizeWith(originSize: props.originSize, preferMaxWidth: props.preferMaxWidth)
    }
    /// 一定在主线程执行。每次从RenderTree到UIView同步的时候会针对每个节点执行updateView
    public override func update(view: MomentsVideoCorveView) {
        super.update(view: view)
        view.updateViewWith(corveImage: props.coverImage, setImageAction: props.setImageAction, duration: props.videoTime, imageClick: props.imageClick)
    }

    public override func create(_ rect: CGRect) -> MomentsVideoCorveView {
        return MomentsVideoCorveView(coverImage: props.coverImage, setImageAction: props.setImageAction, duration: props.videoTime, imageClick: props.imageClick)
    }
}
