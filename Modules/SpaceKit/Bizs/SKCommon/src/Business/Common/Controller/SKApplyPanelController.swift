//
//  SKApplyPanelController.swift
//  SKUIKit
//
//  Created by Weston Wu on 2022/10/20.
//

import Foundation
import SKFoundation
import SKResource
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignInput
import LarkLocalizations
import LarkUIKit
import SKUIKit
import SpaceInterface

public struct SKApplyPanelConfig {

    // 审批人信息
    public var userInfo: AuthorizedUserInfo
    // panel 标题
    public var title: String
    // 输入框占位文案
    public var placeHolder: String
    // 确认按钮文案
    public var actionName: String
    // panel 描述内容，入参为 userName，出参为完整文案
    public var contentProvider: (String) -> String
    // 确认事件，入参为 panel 和用户输入的文本
    public var actionHandler: ((SKApplyPanelController, String?) -> Void)?
    // 取消事件，入参为用户输入的文本
    public var cancelHandler: ((String?) -> Void)?
    // 配置 title accessory button 的点击事件，nil 时 button 会隐藏
    public var accessoryHandler: ((SKApplyPanelController) -> Void)?

    public init(userInfo: AuthorizedUserInfo,
                title: String,
                placeHolder: String,
                actionName: String,
                contentProvider: @escaping (String) -> String) {
        self.userInfo = userInfo
        self.title = title
        self.placeHolder = placeHolder
        self.actionName = actionName
        self.contentProvider = contentProvider
        actionHandler = nil
        cancelHandler = nil
        accessoryHandler = nil
    }
}

public final class SKApplyPanelController: SKPanelController, UITextViewDelegate {

    public let config: SKApplyPanelConfig

    private let keyboard = Keyboard()

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(config.title)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        view.accessoryButton.setImage(UDIcon.maybeOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        view.accessoryButton.addTarget(self, action: #selector(didClickAccessoryButton), for: .touchUpInside)
        return view
    }()

    private lazy var tipsLabel: UITextView = {
        let label = UITextView()
        label.attributedText = makeTipsMessage()
        label.isEditable = false
        label.isScrollEnabled = false
        label.delegate = self
        return label
    }()

    private lazy var reasonTextField: UDMultilineTextField = {
        let textFieldConfig = UDMultilineTextFieldUIConfig(backgroundColor: UDColor.bgBase,
                                                           font: .systemFont(ofSize: 16),
                                                           maximumTextLength: 1000,
                                                           minHeight: 75)
        let textField = UDMultilineTextField(config: textFieldConfig)
        textField.placeholder = config.placeHolder
        return textField
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.setTitle(config.actionName, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.addTarget(self, action: #selector(confirmApply), for: .touchUpInside)
        return button
    }()

    public static func createController(config: SKApplyPanelConfig) -> UIViewController {
        let controller = SKApplyPanelController(config: config)
        let naviController = LkNavigationController(rootViewController: controller)
        naviController.setNavigationBarHidden(true, animated: false)
        naviController.transitioningDelegate = controller.panelFormSheetTransitioningDelegate
        naviController.modalPresentationStyle = .formSheet
        naviController.presentationController?.delegate = controller.adaptivePresentationDelegate
        return naviController
    }

    private init(config: SKApplyPanelConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        transitioningDelegate = panelFormSheetTransitioningDelegate
        modalPresentationStyle = .formSheet
        presentationController?.delegate = adaptivePresentationDelegate
        dismissalStrategy = []
    }

    override public func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        headerView.accessoryButton.isHidden = config.accessoryHandler == nil

        containerView.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }

        containerView.addSubview(reasonTextField)
        reasonTextField.snp.makeConstraints { make in
            make.top.equalTo(tipsLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(75)
        }

        containerView.addSubview(applyButton)
        applyButton.snp.makeConstraints { make in
            make.top.equalTo(reasonTextField.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(16)
        }

        setupKeyboardMonitor()
    }

    @objc
    private func confirmApply() {
        let reason = reasonTextField.text.isEmpty ? nil : reasonTextField.text
        config.actionHandler?(self, reason)
    }

    private func makeTipsMessage() -> NSAttributedString {
        let userName = "@" + config.userInfo.getDisplayName()
        let message = config.contentProvider(userName)
        let font = UIFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = max(0, 22 - font.lineHeight)
        let tips = NSMutableAttributedString(string: message,
                                             attributes: [
                                                .font: font,
                                                .paragraphStyle: paragraphStyle,
                                                .foregroundColor: UDColor.textTitle
                                             ])
        if !config.userInfo.getDisplayName().isEmpty {
            let userNameRange = (message as NSString).range(of: userName)
            tips.addAttributes([.link: "lark://openProfile", .foregroundColor: UDColor.primaryContentDefault], range: userNameRange)
        }
        return tips
    }

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if textView == tipsLabel {
            openProfile()
            return false
        }
        return true
    }

    private func openProfile() {
        let profileService = ShowUserProfileService(userId: config.userInfo.userID, fromVC: self)
        HostAppBridge.shared.call(profileService)
    }

    private func setupKeyboardMonitor() {
        keyboard.on(event: .willShow) { [weak self] opt in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.applyButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(16 + opt.endFrame.height)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.applyButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(16 + opt.endFrame.height)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .willHide) { [weak self] _ in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.applyButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(16)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            guard let self = self else { return }
            guard !self.inRegularSizeLayout else { return }
            self.applyButton.snp.updateConstraints { make in
                make.bottom.equalTo(self.containerView.safeAreaLayoutGuide).inset(16)
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        keyboard.start()
    }

    @objc
    override public func didClickMask() {
        super.didClickMask()
        config.cancelHandler?(reasonTextField.text)
    }

    @objc
    private func didClickAccessoryButton() {
        config.accessoryHandler?(self)
    }
}
