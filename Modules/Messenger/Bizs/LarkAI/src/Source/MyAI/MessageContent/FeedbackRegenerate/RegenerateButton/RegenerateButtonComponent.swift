//
//  RegenerateButtonComponent.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/26.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont

final public class RegenerateButtonComponentProps: ASComponentProps {
    /// 线程安全，copy from MaskPostViewComponent.Props
    private var unfairLock = os_unfair_lock_s()

    public var buttonEnable: Bool = true

    public var iconKey: UDIconType = .resetOutlined
    public var iconColor: UIColor = UIColor.ud.textCaption
    public var iconRotate: Bool = false

    private var _onTapped: (() -> Void)?
    public var onTapped: (() -> Void)? {
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

public final class RegenerateButtonComponent<C: Context>: ASComponent<RegenerateButtonComponentProps, EmptyState, RegenerateButton, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> RegenerateButton {
        return RegenerateButton(frame: rect)
    }

    public override func update(view: RegenerateButton) {
        super.update(view: view)

        view.setup(props: self.props)
        // 移除button上之前绑定的所有点击事件，否则cell复用时，同一个button，可能会被绑定到多个点击事件上
        view.removeTarget(nil, action: nil, for: .touchUpInside)
        if self.props.onTapped != nil {
            view.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        }
    }

    @objc
    private func tapped() {
        self.props.onTapped?()
    }
}
