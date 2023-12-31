//
//  BaseKeyboardSendButton.swift
//  LarkKeyboardView
//
//  Created by ByteDance on 2022/8/30.
//

import UIKit
import Foundation
import UniverseDesignIcon

open class BaseKeyboardSendButton: KeyboardIconButton {
    public var onTapCallback: (() -> Void)?
    public var onLongPressCallback: (() -> Void)?
    private let longPressDuration: TimeInterval
    public init(enable: Bool, longPressDuration: TimeInterval) {
        self.longPressDuration = longPressDuration
        super.init(frame: .zero, key: KeyboardItemKey.send.rawValue)
        setImage(UDIcon.sendColorful.ud.withTintColor(UIColor.ud.colorfulBlue), for: .normal)
        setImage(UDIcon.sendColorful.ud.withTintColor(UIColor.ud.colorfulBlue).ud.withTintColor(.ud.iconDisabled), for: .disabled)
        setImage(Resources.sent_shadow, for: .selected)
        setImage(Resources.sent_shadow, for: .highlighted)
        hitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        self.lu.addTapGestureRecognizer(action: #selector(onTap), target: self)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(gesture:)))
        long.minimumPressDuration = self.longPressDuration
        self.addGestureRecognizer(long)
        self.isEnabled = enable
        self.isUserInteractionEnabled = enable
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTap() {
        onTapCallback?()
    }

    @objc
    private func onLongPress(gesture: UIGestureRecognizer) {
        if gesture.state != .began {
            //仅在began时响应事件
            return
        }
        onLongPressCallback?()
    }
}
