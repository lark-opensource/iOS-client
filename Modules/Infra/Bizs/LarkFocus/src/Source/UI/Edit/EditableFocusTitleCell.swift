//
//  EditableFocusTitleCell.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/31.
//

import Foundation
import UIKit
import EENavigator
import LarkEmotion
import LarkInteraction
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignShadow
import UniverseDesignActionPanel
import LarkNavigator
import LarkContainer

final class EditableFocusTitleCell: UITableViewCell, FocusTitleCell {

    var onBeginEditingIcon: (() -> Void)?
    var onBeginEditingTitle: (() -> Void)?
    var onEditing: (() -> Void)?
    var onReachLimitation: (() -> Void)?
    var onTextCountChange: ((Int) -> Void)?

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    var iconKey: String? {
        didSet {
            if let key = iconKey {
                iconView.config(with: key)
            } else {
                iconView.image = Cons.placeholderIcon
            }
        }
    }

    var focusName: String? {
        get { textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) }
        set { textField.text = newValue }
    }

    private lazy var iconWrapper: UIButton = {
        let view = UIButton()
        return view
    }()

    private lazy var iconView: FocusImageView = {
        let imageView = FocusImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var editButtonWrapper = UIView()

    private lazy var iconEditButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.bgFloat
        let icon = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(icon, for: .normal)
        return button
    }()

    private lazy var textField: UDTextField = {
        let textField = UDTextField()
        textField.cornerRadius = 6
        textField.config.font = UIFont.systemFont(ofSize: 16)
        textField.config.isShowBorder = true
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textField.placeholder = BundleI18n.LarkFocus.Lark_Profile_EnterStatusName
        textField.delegate = self
        textField.input.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(style: .default, reuseIdentifier: "EditableFocusTitleCell")
        selectionStyle = .none
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        contentView.addSubview(iconWrapper)
        contentView.addSubview(textField)
        iconWrapper.addSubview(iconView)
        contentView.addSubview(editButtonWrapper)
        editButtonWrapper.addSubview(iconEditButton)
    }

    private func setupConstraints() {
        iconWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(72)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        textField.snp.makeConstraints { make in
            make.top.equalTo(iconWrapper.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-3)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
        editButtonWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.bottom.equalTo(iconWrapper).offset(-1)
            make.trailing.equalTo(iconWrapper).offset(2)
        }
        iconEditButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAppearance() {
        backgroundColor = .clear
        iconWrapper.backgroundColor = UIColor.ud.bgFloat
        iconWrapper.layer.cornerRadius = 36
        iconWrapper.layer.masksToBounds = true
        iconWrapper.addTarget(self, action: #selector(didTapIcon(_:)), for: .touchUpInside)
        iconEditButton.addTarget(self, action: #selector(didTapIcon(_:)), for: .touchUpInside)
        editButtonWrapper.layer.ud.setShadow(type: .s2Down)
        iconEditButton.layer.cornerRadius = 12
        iconEditButton.layer.masksToBounds = true
        if #available(iOS 13.4, *) {
            let iconAction = PointerInteraction(style: PointerStyle(effect: .lift))
            iconWrapper.addLKInteraction(iconAction)
        }
    }

    @objc
    private func didTapIcon(_ sender: UIButton) {
        textField.resignFirstResponder()
        guard let parentVC = parentViewController else { return }
        let iconPicker = FocusIconPickerController(userResolver: userResolver, sourceView: sender)
        iconPicker.onSelect = { [weak self] iconKey in
            self?.iconKey = iconKey
        }
        userResolver.navigator.present(iconPicker, from: parentVC)
        onBeginEditingIcon?()
    }
}

// MARK: - Text limitation

extension EditableFocusTitleCell: UDTextFieldDelegate {

    /// 20 个中文字符
    var textLimit: Int { 40 }

    var currentTextCount: Int {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return 0 }
        return getLength(forText: text)
    }

    /// 按照特定字符计数规则，获取字符串长度
    ///
    /// 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            return res + min(char.utf8.count, 2)
        }
    }

    // 按照特定字符计数规则，截取字符串
    private func getPrefix(_ maxLength: Int, forText text: String) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, 2)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }

    @objc
    private func textFieldDidChange() {
        onEditing?()
        let limit = textLimit
        let textView = textField.input
        let currentText = textField.input.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var selectedLength = 0
        if let range = textView.markedTextRange {
            selectedLength = textView.offset(from: range.start, to: range.end)
        }
        let contentLength = max(0, currentText.count - selectedLength)
        let validText = String(currentText.prefix(contentLength))
        let validLength = getLength(forText: validText)
        // 有文字输入，且没有指定 icon 时，展示显示默认的 icon
        if iconKey == nil {
            iconView.image = validLength == 0 ? Cons.placeholderIcon : Cons.defaultIcon
        }
        // 对超过限制的文字做截取处理
        if validLength > limit {
            let trimmedText = getPrefix(limit, forText: currentText)
            textView.text = trimmedText
            onReachLimitation?()
            onTextCountChange?(getLength(forText: trimmedText))
        } else {
            onTextCountChange?(getLength(forText: validText))
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditingTitle?()
    }
}

extension EditableFocusTitleCell {

    enum Cons {
        static var defaultIcon: UIImage? {
            return FocusManager.getFocusIcon(byKey: "Status_PrivateMessage")
        }

        static var placeholderIcon: UIImage {
            return defaultIcon ?? EmotionResouce.placeholder
        }
    }
}
