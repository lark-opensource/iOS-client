//
//  UIImageViewComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/21.
//

import UIKit
import Foundation
import TangramComponent
import LarkInteraction

public final class UIImageViewComponentProps: Props {
    public var contentMode: UIView.ContentMode = .scaleToFill
    public var setImage: EquatableWrapper<ImageViewWrapper.SetImageTask?> = .init(value: nil)
    public var onTap: EquatableWrapper<ImageViewWrapper.ImageViewTapped?> = .init(value: nil)
    // 是否是头像，对齐PC & Android，头像默认为圆形，不支持配置，需要在此处开一个口子处理
    public var isAvatar: Bool = false

    public init() {}

    public func clone() -> UIImageViewComponentProps {
        let clone = UIImageViewComponentProps()
        clone.setImage = setImage
        clone.onTap = onTap
        clone.contentMode = contentMode
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? UIImageViewComponentProps else { return false }
        return setImage == old.setImage &&
            onTap == old.onTap &&
            contentMode == old.contentMode
    }
}

public final class UIImageViewComponent<C: Context>: RenderComponent<UIImageViewComponentProps, ImageViewWrapper, C> {
    public override func update(_ view: ImageViewWrapper) {
        super.update(view)
        view.contentMode = props.contentMode
        view.setImageTask = props.setImage.value
        view.onTap = props.onTap.value
        if props.isAvatar {
            view.layer.cornerRadius = min(view.bounds.width, view.bounds.height) / 2
        }
    }
}
