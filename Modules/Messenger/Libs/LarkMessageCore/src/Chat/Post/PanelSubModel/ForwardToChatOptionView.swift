//
//  SyncToChatOptionView.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/14.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import SnapKit
import UniverseDesignCheckBox
import UniverseDesignColor
import LarkMessengerInterface
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkSetting
import LarkModel
import LKCommonsTracker
import RichLabel
import LarkLocalizations

// 是否同步转发到会话的勾选框的View
public final class SyncToChatOptionViewServiceImp: SyncToChatOptionViewDelegate, SyncToChatOptionViewService {

    public var showSyncToCheckBox = false {
        didSet {
            updateOptionView()
        }
    }

    public var isKeyboardFold = true {
        didSet {
            updateOptionView()
        }
    }

    public var forwardToChat = false {
        didSet {
            updateOptionStatus()
        }
    }

    private var canSyncToChat: Bool {
        FeatureGatingManager.realTimeManager.featureGatingValue(with: "messenger.message.thread_also_sendto_group")
    }

    private func updateOptionView() {
        // 不允许展示checkbox的场景不展示
        if !showSyncToCheckBox {
            updateInnerShownStatus(false)
            updateComposeShownStatus(false)
        // 键盘收起的场景小输入框不展示，大的富文本编辑器输入框展示
        } else if isKeyboardFold {
            updateInnerShownStatus(false)
            updateComposeShownStatus(true)
        // 键盘展开的场景大小输入框都展示
        } else {
            updateInnerShownStatus(true)
            updateComposeShownStatus(true)
        }
    }

    private func updateOptionStatus() {
        inputOptionView.optionButton.isSelected = forwardToChat
        composeOptionView.optionButton.isSelected = forwardToChat
    }

    private func updateInnerShownStatus(_ showCheckBox: Bool) {
        inputOptionView.isHidden = !showCheckBox
        inputOptionView.snp.updateConstraints { make in
            make.height.equalTo(showCheckBox ? 37 : 0)
        }
    }

    private func updateComposeShownStatus(_ showCheckBox: Bool) {
        composeOptionView.isHidden = !showCheckBox
        composeOptionView.snp.updateConstraints { make in
            make.height.equalTo(showCheckBox ? 49 : 0)
        }
    }

    private lazy var inputOptionView: SyncToChatOptionView = {
        let view = SyncToChatOptionView(delegate: self)
        view.container.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.bottom.equalToSuperview().priority(.required)
            make.top.equalToSuperview().offset(20)
        }
        return view
    }()

    private lazy var composeOptionView: SyncToChatOptionView = {
        let view = SyncToChatOptionView(delegate: self)
        view.container.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4).priority(.required)
            make.right.equalToSuperview().priority(.required)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        return view
    }()

    func checkBoxTapped(_ checkBox: UDCheckBox) {
        forwardToChat = !checkBox.isSelected
        inputOptionView.optionButton.isSelected = forwardToChat
        composeOptionView.optionButton.isSelected = forwardToChat
    }

    public func getView(isInComposeView: Bool, chat: Chat?) -> UIView? {
        guard let chat = chat, chat.chatMode != .threadV2, !chat.isPrivateMode, !chat.displayInThreadMode, !chat.isFrozen else {
            return nil
        }
        updateOptionStatus()
        guard canSyncToChat else { return nil }
        updateOptionView()
        return isInComposeView ? composeOptionView : inputOptionView
    }

    public func messageWillSend(chat: Chat) {
        forwardToChat = false
    }

    public func updateText(chat: Chat, showFromChat: Bool) {
        /// 输入框的提示固定文案
        let text = if chat.type == .p2P {
            BundleI18n.LarkMessageCore.Lark_IM_AlsoSendChat_InputField_Checkbox
        } else {
            BundleI18n.LarkMessageCore.Lark_IM_AlsoSendGroup_InputField_Checkbox
        }
        Self.updateHintText(view: inputOptionView, text)
        Self.updateHintText(view: composeOptionView, text)
    }

    private static func updateHintText(view: SyncToChatOptionView, _ text: String) {
        view.hintLabel.text = text
    }
}

protocol SyncToChatOptionViewDelegate: AnyObject {
    func checkBoxTapped(_ checkBox: UDCheckBox)
    var forwardToChat: Bool { get }
}

final class SyncToChatOptionView: UIView {
    lazy var optionButton: UDCheckBox = {
        let view = UDCheckBox(boxType: .multiple) { [weak self] _ in
            self?.handleTapText()
        }
        view.isSelected = self.delegate?.forwardToChat ?? false
        return view
    }()

    lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.text = BundleI18n.LarkMessageCore.Lark_IM_AlsoSendGroup_InputField_Checkbox
        label.font = .ud.body2
        label.textColor = .ud.textCaption
        return label
    }()

    lazy var container = UIView()
    fileprivate weak var delegate: SyncToChatOptionViewDelegate?

    init(delegate: SyncToChatOptionViewDelegate) {
        super.init(frame: .zero)
        self.delegate = delegate
        container.addSubview(optionButton)
        container.addSubview(hintLabel)
        addSubview(container)
        optionButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(14)
            make.centerY.equalToSuperview()
        }
        hintLabel.snp.makeConstraints { make in
            make.left.equalTo(optionButton.snp.right).offset(6)
            make.right.lessThanOrEqualToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }
        hintLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapText)))
        hintLabel.isUserInteractionEnabled = true
    }

    @objc
    private func handleTapText() {
        delegate?.checkBoxTapped(optionButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
