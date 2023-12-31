//
//  MailSettingSwitchCell.swift
//  Action
//
//  Created by TangHaojin on 2019/7/29.
//

import UIKit
import LarkUIKit
import UniverseDesignSwitch

protocol MailSettingSwitchDelegate: AnyObject {
    func didChangeSettingSwitch(_ status: Bool)
}

class MailSettingSwitchCell: MailSettingBaseCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    weak var settingSwitchDelegate: MailSettingSwitchDelegate?
    /// icon （在moreActionView里可能会需要）
    private var iconImageView = UIImageView()
    /// 开关
    private lazy var switchButton: UDSwitch = UDSwitch()
    private var switchHandlerEnable = true

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.backgroundColor = UIColor.ud.bgFloat

        /// 开关，居中
        self.contentView.addSubview(self.switchButton)
        /// 设置水平方向抗压性
        self.switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.switchButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        self.switchButton.valueChanged = { [weak self] value in
            guard let self = self else { return }
            if self.switchHandlerEnable {
                self.switchButtonClicked(value: value)
            } else {
                self.switchHandlerEnable = true
            }
        }

        /// 标题，距离头部底部为16，居中 距离开关16
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.textAlignment = .left
        self.contentView.addSubview(self.titleLabel)

        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(self.switchButton.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }

        arrowImageView.isHidden = true
        arrowImageView.image = Resources.mail_setting_icon_arrow
        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
           make.centerY.equalToSuperview()
           make.right.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSwitchButton(_ isOn: Bool) {
        switchHandlerEnable = false
        var inStranger = false
        if let strangerItem = item as? MailSettingStrangerModel {
            inStranger = true
            let result = strangerItem.switchHandler(isOn)
            MailLogger.info("[mail_stranger] setting cell setSwitchButton result: \(result) value: \(isOn)")
        }
        switchButton.setOn(isOn, animated: true, ignoreValueChanged: inStranger)
        switchHandlerEnable = true
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingPushModel {
            titleLabel.isHidden = false
            switchButton.isHidden = false
            titleLabel.text = currItem.title
            switchButton.setOn(currItem.status, animated: false, ignoreValueChanged: true)
            arrowImageView.isHidden = !currItem.hasMore
            switchButton.isHidden = currItem.hasMore
            if switchButton.isEnabled {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchNotificationOnKey
            } else {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchNotificationOffKey
            }
        } else if let currItem = item as? MailSettingSwitchModel {
            titleLabel.isHidden = false
            switchButton.isHidden = false
            titleLabel.text = currItem.title
            switchButton.setOn(currItem.status, animated: false, ignoreValueChanged: true)
            arrowImageView.isHidden = true
            if switchButton.isEnabled {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchNotificationOnKey
            } else {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchNotificationOffKey
            }
        } else if let currentItem = item as? MailSettingSmartInboxModel {
            titleLabel.isHidden = false
            switchButton.isHidden = false
            titleLabel.text = currentItem.title
            switchButton.setOn(currentItem.status,
                               animated: false,
                               ignoreValueChanged: true)
            arrowImageView.isHidden = true
            if switchButton.isEnabled {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchSmartInboxOnKey
            } else {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchSmartInboxOffKey
            }
        } else if let currentItem = item as? MailSettingStrangerModel {
            titleLabel.isHidden = false
            switchButton.isHidden = false
            titleLabel.text = currentItem.title
            switchButton.setOn(currentItem.status,
                               animated: false,
                               ignoreValueChanged: true)
            arrowImageView.isHidden = true
            if switchButton.isEnabled {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchStrangerOnKey
            } else {
                switchButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwitchStrangerOffKey
            }
        } else if let currentItem = item as? MailSettingConversationModel {
            titleLabel.isHidden = false
            switchButton.isHidden = false
            titleLabel.text = currentItem.title
            switchButton.setOn(currentItem.status,
                               animated: false,
                               ignoreValueChanged: true)
            arrowImageView.isHidden = true
        }
    }
    private func setupIcon(icon: UIImage){
        let offset: CGFloat = 12
        let topOffset: CGFloat = 13
        let iconSize = CGSize(width: 20, height: 20)
        iconImageView.tintColor = UIColor.ud.iconN1
        iconImageView.image = icon
        contentView.addSubview(iconImageView)
        iconImageView.isHidden = false
        iconImageView.snp.makeConstraints { (make) in
            make.left.left.equalToSuperview().offset(offset)
            make.centerY.equalToSuperview()
            make.size.equalTo(iconSize)
        }
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(offset)
            make.right.equalTo(switchButton.snp.left).offset(-offset)
            make.top.equalToSuperview().offset(topOffset)
            make.bottom.equalToSuperview().offset(-topOffset)
        }
    }
    func switchButtonClicked(value: Bool) {
        if let switchItem = item as? MailSettingSwitchModel {
            switchItem.switchHandler(value)
            settingSwitchDelegate?.didChangeSettingSwitch(value)
        } else if let smartInboxItem = item as? MailSettingSmartInboxModel {
            smartInboxItem.switchHandler(value)
        } else if let strangerItem = item as? MailSettingStrangerModel {
            let result = strangerItem.switchHandler(value)
            MailLogger.info("[mail_stranger] setting cell switchButtonClicked result: \(result) value: \(value)")
            switchButton.setOn(result, animated: true, ignoreValueChanged: result)
        } else if let pushItem = item as? MailSettingPushModel {
            pushItem.switchHandler(value)
        } else if let conversationItem = item as? MailSettingConversationModel {
            conversationItem.switchHandler(value)
        }
    }
}

extension MailSettingSwitchCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let inputItem = item as? MailSettingInputModel, let text = textField.text {
            inputItem.textfieldHandler(text)
        }
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCount = textField.text?.count ?? 0
        if currentCount + string.count > 205 {
            if let window = textField.window {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Signature_Toast, on: window,
                                       event: ToastErrorEvent(event: .signature_edit_max_characters))
            }
            return false
        }
        return true
    }
}
