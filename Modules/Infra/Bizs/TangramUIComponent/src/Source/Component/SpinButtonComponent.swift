//
//  SpinButtonComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/5/17.
//

import UIKit
import Foundation
import TangramComponent

public final class SpinButtonComponentProps: Props {
    public var setImage: EquatableWrapper<SpinButton.SetImageTask?> = .init(value: nil)
    public var onTap: EquatableWrapper<SpinButton.TapCallback?> = .init(value: nil)
    public var title: String = ""
    public var titleFont: UIFont = SpinButton.defaultFont
    public var titleColor: UIColor = SpinButton.defaultTitleColor

    public init() {}

    public func clone() -> SpinButtonComponentProps {
        let clone = SpinButtonComponentProps()
        clone.setImage = setImage
        clone.onTap = onTap
        clone.title = title
        clone.titleFont = titleFont.copy() as? UIFont ?? SpinButton.defaultFont
        clone.titleColor = titleColor.copy() as? UIColor ?? SpinButton.defaultTitleColor
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? SpinButtonComponentProps else { return false }
        return setImage == old.setImage &&
            onTap == old.onTap &&
            title == old.title &&
            titleFont == old.titleFont &&
            titleColor == old.titleColor
    }
}

public final class SpinButtonComponent<C: Context>: RenderComponent<SpinButtonComponentProps, SpinButton, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return SpinButton.sizeToFit(size, title: props.title, titleFont: props.titleFont)
    }

    public override func create(_ rect: CGRect) -> SpinButton {
        return SpinButton(frame: rect, title: props.title)
    }

    public override func update(_ view: SpinButton) {
        super.update(view)
        view.onTapped = props.onTap.value
        view.setImageTask = props.setImage.value
        view.titleColor = props.titleColor
        view.update(title: props.title, titleFont: props.titleFont)
    }
}
