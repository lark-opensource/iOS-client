//
//  CollaboratorSendMessageView.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/6.
//

import Foundation
import SKUIKit
import SKResource
import LarkUIKit
import LarkButton
import UniverseDesignColor
import UniverseDesignCheckBox
import SKFoundation

protocol CollaboratorBottomViewDelegate: AnyObject {
    func handleButtonClicked(_ bottomView: CollaboratorBottomView, isSelect: Bool)
    func handleHintLabelClicked(_ bottomView: CollaboratorBottomView)
    func updateCollaboratorBottomViewConstraints(_ bottomView: CollaboratorBottomView)
    func handleSinglePageSelectViewClicked(_ bottomView: CollaboratorBottomView, isSelect: Bool)
    func handleForceSelectNotificationIcon(_ bottomView: CollaboratorBottomView)
    func handleForceSelectSinglePageIcon(_ bottomView: CollaboratorBottomView)
}

struct CollaboratorBottomViewLayoutConfig {
    var showNotification: Bool = false
    var isNotificationEnable: Bool = true
    var forceSelectNotification: Bool = false
    var showHintLabel: Bool = true
    var hintLabelText: String = ""
    var hintlabelTapEnable: Bool = false
    var inviteButtonText: String = ""
    var textViewPlaceHolder: String = ""
    var showTextView: Bool = true
    var textViewHintText: String = ""
    var showSinglePageView: Bool = false
    var onlySinglePage: Bool = false
    var isChildPageEnable: Bool = true
}

class CollaboratorBottomView: UIView, UITextViewDelegate {

    public var confirmButtonTappedBlock: ((CollaboratorBottomView) -> Void)?
    public var isSelect: Bool = true
    private var isShowTextViewHint: Bool = false
    public var userGroupDisAble: Bool = false
    public weak var delegate: CollaboratorBottomViewDelegate?
    var layoutConfig: CollaboratorBottomViewLayoutConfig = CollaboratorBottomViewLayoutConfig()
    public var singlePageSelected: Bool {
        return singlePageView.isSelect
    }

    /// 输入框
    private(set) lazy var textView: SKUDBaseTextView = setupTextView()

    private lazy var seperateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()
    private lazy var bottomBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UDColor.bgBody
        return backgroundView
    }()
    private lazy var notificationCheckBox: UDCheckBox = {
        let view = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig()) { [weak self] _ in
            self?.didClickedNotificationCheckBox()
        }
        view.isSelected = true
        return view
    }()
    private lazy var notificationMaskButton: UIButton = {
        let button = UIButton()
        button.isEnabled = false
        button.addTarget(self, action: #selector(didClickNotificationMaskButton), for: .touchUpInside)
        return button
    }()
    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        return label
    }()
    private lazy var textViewHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        return label
    }()
    private lazy var inviteButton: UIButton = {
        let confirmButton = TypeButton(style: .normalA)
        confirmButton.isEnabled = true
        confirmButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.sizeToFit()
        confirmButton.docs.addStandardLift()
        return confirmButton
    }()

    private lazy var singlePageView: SinglePageView = {
        let singlePageView = SinglePageView()
        return singlePageView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(_ layoutConfig: CollaboratorBottomViewLayoutConfig) {
        self.layoutConfig = layoutConfig
        self.backgroundColor = UDColor.bgBody
        addSubview(bottomBackgroundView)
        bottomBackgroundView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        if layoutConfig.showNotification {
            bottomBackgroundView.addSubview(notificationCheckBox)
            notificationCheckBox.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.size.equalTo(18)
                make.centerY.equalToSuperview()
            }
            bottomBackgroundView.addSubview(notificationMaskButton)
            notificationMaskButton.snp.makeConstraints { (make) in
                make.size.equalTo(notificationCheckBox)
                make.center.equalTo(notificationCheckBox)
            }
        }

        bottomBackgroundView.addSubview(inviteButton)
        let width = self.width(withFont: inviteButton.titleLabel?.font, text: layoutConfig.inviteButtonText)
        inviteButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(width + 30)
            make.height.equalTo(28)
            make.centerY.equalToSuperview()
        }
        if layoutConfig.showHintLabel {
            bottomBackgroundView.addSubview(hintLabel)
            hintLabel.snp.makeConstraints { (make) in
                if layoutConfig.showNotification {
                    make.left.equalTo(notificationCheckBox.snp.right).offset(8)
                } else {
                    make.left.equalToSuperview().offset(20)
                }
                make.height.equalTo(20)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(inviteButton.snp.left).offset(-10)
            }
        }

        addSubview(seperateLine)
        seperateLine.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.right.equalToSuperview()
        }

        addSubview(singlePageView)
        singlePageView.delegate = self
        singlePageView.isHidden = !layoutConfig.showSinglePageView
        singlePageView.snp.makeConstraints { make in
            make.top.equalTo(seperateLine.snp.bottom)
            make.left.right.equalToSuperview()
            if !layoutConfig.showSinglePageView {
                make.height.equalTo(0)
            }
        }

    
        addSubview(textViewHintLabel)
        textViewHintLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(0)
            make.bottom.equalTo(bottomBackgroundView.snp.top)
        }
        
        addSubview(textView)
        if layoutConfig.showTextView {
            if UserScopeNoChangeFG.WJS.baseFormShareNotificationV2 { textView.isHidden = false }
            textView.snp.makeConstraints { (make) in
                make.top.equalTo(singlePageView.snp.bottom).offset(10)
                make.bottom.equalTo(textViewHintLabel.snp.top)
                make.left.right.equalToSuperview().inset(16)
                make.height.greaterThanOrEqualTo(36)
                make.height.lessThanOrEqualTo(100)
            }
            textView.isHidden = false
        } else {
            if UserScopeNoChangeFG.WJS.baseFormShareNotificationV2 { textView.isHidden = true }
            textView.snp.makeConstraints { (make) in
                make.top.equalTo(singlePageView.snp.bottom).offset(10)
                make.bottom.equalTo(textViewHintLabel.snp.top)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(0)
            }
            textView.isHidden = true
        }
        textViewHintLabel.text = layoutConfig.textViewHintText
        if !layoutConfig.textViewPlaceHolder.isEmpty {
            textView.placeholder = layoutConfig.textViewPlaceHolder
        } else if layoutConfig.onlySinglePage {
            textView.placeholder = BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_SendNote_Placeholder
        } else {
            textView.placeholder = BundleI18n.SKResource.Doc_Permission_AddUserAddNotesHint()
        }
        
        if layoutConfig.hintlabelTapEnable {
            hintLabel.isUserInteractionEnabled = true
            hintLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickHintLabel)))
        } else {
            hintLabel.isUserInteractionEnabled = false
        }

        hintLabel.text = layoutConfig.hintLabelText
        inviteButton.setTitle(layoutConfig.inviteButtonText, withFontSize: 14, fontWeight: .regular, color: UDColor.primaryOnPrimaryFill, forState: .normal)

        if layoutConfig.showNotification {
            if layoutConfig.isNotificationEnable {
                notificationCheckBox.isEnabled = true
                hintLabel.textColor = UDColor.textTitle
                userGroupDisAble = false
            } else {
                isSelect = false
                updateNotificationSelectState(isSelect: false)
                delegate?.handleButtonClicked(self, isSelect: false)
                notificationCheckBox.isEnabled = false
                userGroupDisAble = true
                notificationMaskButton.isEnabled = true
                hintLabel.textColor = UDColor.textDisabled
            }
        }

        singlePageView.setCheckBox(isSelected: layoutConfig.isChildPageEnable)
        
        if layoutConfig.forceSelectNotification {
            forceSelectNotificationIcon()
            singlePageView.setCheckBox(isSelected: false)
            
            if layoutConfig.onlySinglePage {
                singlePageView.setCheckBox(isEnabled: false)
            }
        } else {
            notificationMaskButton.isEnabled = false
        }
    }

    func disableNotificationIcon() {
        guard layoutConfig.showNotification else { return }
        guard layoutConfig.isNotificationEnable else { return }
        layoutConfig.isNotificationEnable = false
        isSelect = false
        updateNotificationSelectState(isSelect: false)
        delegate?.handleButtonClicked(self, isSelect: false)
        notificationCheckBox.isEnabled = false
        hintLabel.textColor = UDColor.textDisabled
        notificationMaskButton.isEnabled = true
        userGroupDisAble = true
    }
    
    func forceSelectNotificationIcon() {
        layoutConfig.isNotificationEnable = false
        isSelect = true
        updateNotificationSelectState(isSelect: true)
        delegate?.handleButtonClicked(self, isSelect: true)
        notificationCheckBox.isEnabled = false
        hintLabel.textColor = UDColor.N900
        notificationMaskButton.isEnabled = true
    }

    private func setupTextView() -> SKUDBaseTextView {
        let textView = SKUDBaseTextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholder = BundleI18n.SKResource.Doc_Permission_AddUserAddNotesHint()
        textView.delegate = self
        textView.bounces = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        textView.maxHeight = 36
        textView.textDragInteraction?.isEnabled = false
        textView.returnKeyType = .next
        textView.backgroundColor = UDColor.bgBody
        if SKDisplay.pad {
            let enterKey = UIKeyCommand(input: "\u{D}", modifierFlags: [], action: #selector(enterHandler(_:)))
            let shiftEnterKey = UIKeyCommand(input: "\u{D}", modifierFlags: .shift, action: #selector(shiftEnterHandler(_:)))
            textView.customKeyCommands.append(shiftEnterKey)
            textView.customKeyCommands.append(enterKey)
        }
        return textView
    }
    private func width(withFont font: UIFont?, text string: String?) -> CGFloat {
        guard let text = string, let sizeFont = font  else {
            return 0
        }
        let attributes = [NSAttributedString.Key.font: sizeFont]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let r = text.boundingRect(with: CGSize(width: bounds.width, height: 100), options: option, attributes: attributes, context: nil)
        return ceil(r.width)
    }

    @objc
    private func didClickHintLabel() {
        delegate?.handleHintLabelClicked(self)
    }
    
    @objc
    private func didClickNotificationMaskButton() {
        self.delegate?.handleForceSelectNotificationIcon(self)
    }
    
    @objc
    private func didClickSinglePageCheckBoxButton() {
        if layoutConfig.onlySinglePage {
            self.delegate?.handleForceSelectSinglePageIcon(self)
        }
    }

    @objc
    private func didClickedNotificationCheckBox() {
        self.isSelect = !self.isSelect
        updateNotificationSelectState(isSelect: self.isSelect)
        self.delegate?.handleButtonClicked(self, isSelect: self.isSelect)
    }

    public func updateNotificationSelectState(isSelect: Bool) {
        self.isSelect = isSelect
        notificationCheckBox.isSelected = isSelect
        updateTextViewLayoutToShowIfNeeded(isShow: isSelect)
        updateTextViewHint()
    }

    private func updateTextViewLayoutToShowIfNeeded(isShow: Bool) {
        guard self.layoutConfig.showTextView else { return }
        
        if isShow {
            textView.snp.remakeConstraints { (make) in
                make.top.equalTo(singlePageView.snp.bottom).offset(10)
                make.bottom.equalTo(textViewHintLabel.snp.top)
                make.left.right.equalToSuperview().inset(16)
                make.height.greaterThanOrEqualTo(36)
                make.height.lessThanOrEqualTo(100)
            }
            textView.isHidden = false
        } else {
            textView.snp.remakeConstraints { (make) in
                make.top.equalTo(singlePageView.snp.bottom).offset(10)
                make.bottom.equalTo(textViewHintLabel.snp.top)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(0)
            }
            textView.isHidden = true
        }
    }

    @objc
    private func shiftEnterHandler(_ command: UIKeyCommand) {
        /// 快捷键换行
        if textView.isFirstResponder {
            textView.insertText("\n")
        }
    }

    @objc
    private func enterHandler(_ command: UIKeyCommand) {

    }

    @objc
    private func didTapConfirm() {
        confirmButtonTappedBlock?(self)
    }
    
    func setTextViewHint(isShow: Bool) {
        if self.isShowTextViewHint == isShow {
            return
        }
        self.isShowTextViewHint = isShow
        updateTextViewHint()
    }
    
    private func updateTextViewHint() {
        let show = (self.isSelect && self.isShowTextViewHint) ? true : false
        if textViewHintLabel.superview != nil {
            textViewHintLabel.snp.updateConstraints { (make) in
                make.height.equalTo(show ? 20 : 0)
            }
        }
        delegate?.updateCollaboratorBottomViewConstraints(self)
    }
}

extension CollaboratorBottomView: SinglePageViewDelegate {
    func handleDisabledCheckBoxClicked(_ bottomView: SinglePageView) {
        delegate?.handleForceSelectSinglePageIcon(self)
    }
    
    func handleButtonClicked(_ bottomView: SinglePageView, isSelect: Bool) {
        self.delegate?.handleSinglePageSelectViewClicked(self, isSelect: isSelect)
    }
}


protocol SinglePageViewDelegate: AnyObject {
    func handleButtonClicked(_ bottomView: SinglePageView, isSelect: Bool)
    func handleDisabledCheckBoxClicked(_ bottomView: SinglePageView)
}

class SinglePageView: UIView {
    public var isSelect: Bool = true
    public weak var delegate: SinglePageViewDelegate?

    private lazy var seperateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    private lazy var checkBox: UDCheckBox = {
        let view = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig()) { [weak self] _ in
            self?.didClickedCheckBox()
        }
        view.isSelected = true
        return view
    }()
    
    private lazy var maskButton: UIButton = {
        let button = UIButton()
        button.isEnabled = false
        button.addTarget(self, action: #selector(didClickMaskButton), for: .touchUpInside)
        return button
    }()

    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.text = BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_AllowAccess_box
        return label
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        addSubview(checkBox)
        addSubview(maskButton)
        addSubview(hintLabel)
        addSubview(placeholderLabel)

        checkBox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(18)
            make.centerY.equalToSuperview()
        }
        
        maskButton.snp.makeConstraints { make in
            make.size.equalTo(checkBox)
            make.center.equalTo(checkBox)
        }

        hintLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(8)
            make.top.equalToSuperview().offset(14)
            make.right.lessThanOrEqualToSuperview().offset(-10)
        }

        placeholderLabel.snp.makeConstraints { (make) in
            make.top.equalTo(hintLabel.snp.bottom)
            make.left.equalTo(checkBox.snp.right).offset(8)
            make.bottom.equalToSuperview().offset(-14)
            make.right.lessThanOrEqualToSuperview().offset(-10)
        }
        updateSelectState(isSelect: isSelect)
    }

    @objc
    private func didClickedCheckBox() {
        self.isSelect = !self.isSelect
        updateSelectState(isSelect: self.isSelect)
        self.delegate?.handleButtonClicked(self, isSelect: self.isSelect)
    }
    
    @objc
    private func didClickMaskButton() {
        self.delegate?.handleDisabledCheckBoxClicked(self)
    }

    private func updateSelectState(isSelect: Bool) {
        self.isSelect = isSelect
        checkBox.isSelected = isSelect
        if isSelect {
            placeholderLabel.text = BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_AllowAccess_OnDesc
        } else {
            placeholderLabel.text = BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_AllowAccess_OffDesc
        }
    }
    
    func setCheckBox(isSelected: Bool) {
        self.isSelect = isSelected
        updateSelectState(isSelect: self.isSelect)
    }
    
    func setCheckBox(isEnabled: Bool) {
        checkBox.isEnabled = isEnabled
        maskButton.isEnabled = !isEnabled
    }
}
