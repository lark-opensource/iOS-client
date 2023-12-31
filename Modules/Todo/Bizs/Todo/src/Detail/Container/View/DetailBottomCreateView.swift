//
//  DetailBottomCreateView.swift
//  Todo
//
//  Created by wangwanxin on 2021/12/21.
//

import Foundation
import UniverseDesignButton
import UniverseDesignColor
import CTFoundation
import UIKit
import UniverseDesignCheckBox

/// Detail - Bottom - CreateButton

protocol DetailBottomCreateViewDataType {
    var checkboxTitle: String { get }
    var title: String { get }
    var isEnabled: Bool { get }
}

final class DetailBottomCreateView: UIView, ViewDataConvertible {

    var viewData: DetailBottomCreateViewDataType? {
        didSet {
            sendButton.isEnabled = viewData?.isEnabled ?? false
            sendButton.setTitle(viewData?.title, for: .normal)
            sendButton.setTitle(viewData?.title, for: .disabled)
            sendToChatView.updateTitle(viewData?.checkboxTitle)
        }
    }

    var onClick: (() -> Void)?

    let sendToChatView: DetailBottomSendToChatView
    private lazy var sendButton = initSendButton()

    init(hasSendToChatCheckbox: Bool, isSendToChatCheckboxSelected: Bool) {
        sendToChatView = .init(isSelected: isSendToChatCheckboxSelected)
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBodyOverlay

        addSubview(sendButton)
        sendButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(28)
        }
        sendButton.isEnabled = false
        sendButton.addTarget(self, action: #selector(handleTapped), for: .touchUpInside)

        addSubview(sendToChatView)
        sendToChatView.isHidden = !hasSendToChatCheckbox
        sendToChatView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.right.lessThanOrEqualTo(sendButton.snp.left).offset(-8)
            $0.centerY.equalTo(sendButton)
            $0.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initSendButton() -> UDButton {
        var config = UDButton.secondaryBlue.config
        config.type = .small
        config.radiusStyle = .square
        return UDButton(config)
    }

    @objc
    private func handleTapped() {
        onClick?()
    }
}
