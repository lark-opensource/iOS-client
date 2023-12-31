//
//  UDButtonComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/21.
//

import UIKit
import Foundation
import UniverseDesignButton
import TangramComponent

public final class UDButtonComponentProps: Props {
    public static var defaultIconSize: CGFloat { 16.auto() }
    public typealias UDButtonTapped = () -> Void
    public typealias SetImageTask = (UDButton) -> Void

    public var config: EquatableWrapper<UDButtonUIConifg> = .init(value: UDButtonUIConifg.defaultConfig)
    public var isEnabled: Bool = true
    public var isHighlighted: Bool = false
    public var isLoading: Bool = false
    public var iconSize: CGFloat = 16
    // title暂时只支持normal状态下的，因为UDButton.sizeToFit需要用title算大小
    public var title: String = ""
    public var onTap: EquatableWrapper<UDButtonTapped?> = .init(value: nil)
    public var setImage: EquatableWrapper<SetImageTask?> = .init(value: nil)

    public init() {}

    public func clone() -> UDButtonComponentProps {
        let clone = UDButtonComponentProps()
        clone.config = config
        clone.isEnabled = isEnabled
        clone.isHighlighted = isHighlighted
        clone.isLoading = isLoading
        clone.iconSize = iconSize
        clone.title = title
        clone.onTap = onTap
        clone.setImage = setImage
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? UDButtonComponentProps else { return false }
        return config == old.config &&
            isEnabled == old.isEnabled &&
            isHighlighted == old.isHighlighted &&
            isLoading == old.isLoading &&
            iconSize == old.iconSize &&
            title == old.title &&
            onTap == old.onTap &&
            setImage == old.setImage
    }
}

public final class UDButtonComponent<C: Context>: RenderComponent<UDButtonComponentProps, UDButtonWrapper, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return UDButtonWrapper.sizeToFit(size, iconSize: props.iconSize, title: props.title, type: props.config.value.type)
    }

    public override func update(_ view: UDButtonWrapper) {
//        super.update(view)
        style.applyToView(view.button)
        view.button.config = props.config.value
        view.button.isEnabled = props.isEnabled
        view.button.isHighlighted = props.isHighlighted
        if props.isLoading {
            view.button.showLoading()
        } else {
            view.button.hideLoading()
        }

        view.button.setTitle(props.title, for: .normal)
        if let setImage = props.setImage.value {
            setImage(view.button)
        } else {
            view.button.setImage(nil, for: .normal)
            view.button.setImage(nil, for: .highlighted)
        }

        if props.onTap.value != nil {
            // 移除button上之前绑定的所有点击事件，否则cell复用时，同一个button，可能会被绑定到多个点击事件上
            view.button.removeTarget(nil, action: nil, for: .touchUpInside)
            view.button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        } else {
            view.button.removeTarget(self, action: #selector(tapped), for: .touchUpInside)
        }
    }

    @objc
    private func tapped() {
        props.onTap.value?()
    }
}
