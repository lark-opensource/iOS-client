//
//  UIButton+Calendar.swift
//  Calendar
//
//  Created by jiayi zou on 2018/11/7.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import LarkButton
import LarkExtensions
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignTheme

extension CalendarExtension where BaseType == UIButton {
    public static func button() -> UIButton {
        let button = UIButton()
        button.increaseClickableArea()
        return button
    }

    public static func button(type: UIButton.ButtonType) -> UIButton {
        let button = TypeButton(type: type)
        button.increaseClickableArea()
        return button
    }

    public static func newEventRepeatEndButton() -> UIButton {
        let button = NewEventRepeatEndButton(type: .custom)
        button.accessibilityIdentifier = "Calendar.NewEventRepeatEndButton"
        button.increaseClickableArea()
        return button
    }
}

private final class NewEventRepeatEndButton: UIButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesEnded(touches, with: event)
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesCancelled(touches, with: event)
        super.touchesCancelled(touches, with: event)
    }
}

extension UIButton {
    public func increaseClickableArea(top: CGFloat = -5,
                               left: CGFloat = -5,
                               bottom: CGFloat = -5,
                               right: CGFloat = -5) {
        self.hitTestEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }

    public func setHighlitedImageWithColor(_ color: UIColor = UIColor.ud.N300.withAlphaComponent(0.5)) {
        let image = UIImage.cd.from(color: color)
        self.setBackgroundImage(image, for: .highlighted)
    }

}
