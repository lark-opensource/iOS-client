//
//  ChatCardButtonComponent.swift
//  Todo
//
//  Created by 张威 on 2020/11/29.
//

import AsyncComponent
import UniverseDesignFont

// nolint: magic number
final class ChatCardButtonComponentProps: ASComponentProps {
    var normalTitle: String?
    var selectedTitle: String?
    var disabledTitle: String?
    var normalTitleColor: UIColor?
    var selectedTitleColor: UIColor?
    var disabledTitleColor: UIColor?
    var font: UIFont = UDFont.systemFont(ofSize: 14)
    var isDisabled: Bool = false
    var onTap: (() -> Void)?
    var backgroundColor: UIColor = .clear
}

final class ChatCardButtonComponent<C: Context>: ASComponent<ChatCardButtonComponentProps, EmptyState, UIButton, C> {

    override func update(view: UIButton) {
        super.update(view: view)
        view.setTitle(props.normalTitle, for: .normal)
        view.setTitle(props.selectedTitle, for: .selected)
        view.setTitle(props.disabledTitle, for: .disabled)
        view.setTitleColor(props.normalTitleColor, for: .normal)
        view.setTitleColor(props.selectedTitleColor, for: .selected)
        view.setTitleColor(props.disabledTitleColor, for: .disabled)
        view.titleLabel?.font = props.font
        view.isEnabled = !props.isDisabled
        view.backgroundColor = props.backgroundColor

        view.removeTarget(nil, action: #selector(onClick), for: .touchUpInside)
        view.addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }

    override var isComplex: Bool { true }

    @objc
    private func onClick() {
        props.onTap?()
    }
}
