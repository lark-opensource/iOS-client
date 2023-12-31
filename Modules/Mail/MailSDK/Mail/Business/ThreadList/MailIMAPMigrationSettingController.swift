//
//  MailIMAPMigrationSettingController.swift
//  MailSDK
//
//  Created by ByteDance on 2023/9/21.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkAlertController
import RxSwift
import RustPB
import LarkSplitViewController
import EENavigator
import UniverseDesignColor
import LarkUIKit
import UniverseDesignButton
import FigmaKit
import UniverseDesignCheckBox

class MailIMAPMigrationSettingController: MailBaseViewController {
    var cancelBlock: ((UIViewController) -> Void)?
    var gotoNext: ((MailIMAPMigrationInfo) -> Void)?
    // MARK: state
    private var migrationInfo: MailIMAPMigrationInfo
    private var account: MailAccount
    private var cancelAble: Bool // 是否可取消搬家
    private var accountContext: MailAccountContext
    
    // MARK: UI elements
    private lazy var gradientView = LinearGradientView()
    private lazy var iconView = UIImageView()
    private lazy var titleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descLabel = {
        let label = UILabel()
        let text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_ConfirmReceiveAllSettingsPage_Desc(account.accountAddress,
                                                                                                    migrationInfo.provider.info.0)
        let paragraphStyle = NSMutableParagraphStyle()
        let font = UIFont.systemFont(ofSize: 14)
        paragraphStyle.lineSpacing = 8 - (font.lineHeight - font.pointSize)
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption,
                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: attributes)
        label.attributedText = attributedString
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var guideBtn: UIButton = {
        let iconWidth = 14.0
        let space = 1.0
        let btn = UIButton()
        let title = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_ConfirmReceiveAllSettingsPage_SeeHowTo_TextBurtton
        let font = UIFont.systemFont(ofSize: 14)
        btn.titleLabel?.font = font
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.setTitle(title, for: .normal)
        btn.tintColor = UIColor.ud.primaryContentDefault
        btn.setImage(UDIcon.rightOutlined.ud.resized(to: CGSize(width: iconWidth, height: iconWidth)).withRenderingMode(.alwaysTemplate), for: .normal)
        btn.addTarget(self, action: #selector(gotoGuide), for: .touchUpInside)
        let textWidth = title.getWidth(font: font)
        btn.imageEdgeInsets = UIEdgeInsets(top: space, left: textWidth + space, bottom: space, right: -(textWidth + space))
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(iconWidth + space), bottom: 0, right: iconWidth + space)
        btn.hitTestEdgeInsets = UIEdgeInsets(edges: -5)
        return btn
    }()
    
    private lazy var checkBoxContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.isUserInteractionEnabled = false
        checkBox.isSelected = false
        return checkBox
    }()
    
    private lazy var checkBoxLabel: UILabel = {
        let label = UILabel()
        let disclaimerString = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_ConfirmReceiveAllSettingsPage_Done_RadioButton
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attributedString = NSMutableAttributedString(string: disclaimerString,
                                                         attributes: attributes)
        label.attributedText = attributedString
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var nextButton: UDButton = {
        let config = UDButtonUIConifg.makeLoginButtonConfig()
        let btn = UDButton()
        btn.layer.cornerRadius = 10
        btn.layer.masksToBounds = true
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_ConfirmReceiveAllSettingsPage_Next_Button, for: .normal)
        btn.config = config
        btn.isEnabled = false
        btn.addAction { [weak self] in
            guard let self = self else { return }
            MailTracker.log(event: "email_mail_mig_setting_click", params: ["mail_service": self.migrationInfo.provider.rawValue,
                                                                            "mail_account_type": Store.settingData.getMailAccountType(),
                                                                            "click": "next"])
            self.gotoNext?(self.migrationInfo)
        }
        return btn
    }()
    private lazy var cancelButton: UDButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.primaryContentDefault)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.primaryContentPressed)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let config = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: disableColor,
                                      loadingIconColor: nil,
                                      type: .middle)
        let button = UDButton()
        button.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_LoginPage_NotNow_Button, for: .normal)
        button.config = config
        button.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
        return button
    }()

    init(state: Email_Client_V1_IMAPMigrationState, accountContext: MailAccountContext, account: MailAccount, cancelAble: Bool) {
        let provider = IMAPMigrationProvider(rawValue: state.imapProvider) ?? .other
        self.migrationInfo = MailIMAPMigrationInfo(provider: provider, authType: state.authType, migrationID: state.migrationID)
        self.account = account
        self.cancelAble = cancelAble
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
        self.isNavigationBarHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        addTapGesture()
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        return accountContext
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        checkBoxContainer.addGestureRecognizer(tap)
    }

    func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody

        gradientView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 240)
        gradientView.direction = .topToBottom
        let upColor = UIColor.mail.rgb("#E3EBFC") & UIColor.mail.rgb("#121429")
        let downColor = UIColor.mail.rgb("#FFFFFF") & UIColor.mail.rgb("#191919")
        gradientView.colors = [upColor, downColor]
        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(240)
        }

        let imageView = UIImageView()
        imageView.image = Resources.image(named: "bg_light")
        imageView.frame = gradientView.frame
        view.addSubview(imageView)
        
        let configInfo = migrationInfo.provider.info
        titleLabel.text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationPage_Title
        iconView.image = configInfo.1
        iconView.contentMode = .scaleAspectFit
        view.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(52)
            make.width.height.equalTo(55)
            make.left.equalTo(16)
        }

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        view.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.top.equalTo(iconView.snp.bottom).offset(8)
        }
        
        view.addSubview(guideBtn)
        guideBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.top.equalTo(descLabel.snp.bottom).offset(8)
        }
        view.addSubview(checkBoxContainer)
        checkBoxContainer.snp.makeConstraints { make in
            make.top.equalTo(guideBtn.snp.bottom).offset(26)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        checkBoxContainer.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        checkBoxContainer.addSubview(checkBoxLabel)
        checkBoxLabel.snp.makeConstraints { make in
            make.centerY.equalTo(checkBox)
            make.left.equalTo(checkBox.snp.right).offset(8)
            make.right.equalToSuperview()
        }
        
        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.top.equalTo(checkBoxContainer.snp.bottom).offset(24)
            make.height.equalTo(48)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        setupCancelButtonIfNeed()
    }
    
    private func setupCancelButtonIfNeed() {
        guard cancelAble else {
            return
        }
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.width.equalTo(view.frame.width - 48)
            make.centerX.equalTo(nextButton)
            make.top.equalTo(nextButton.snp.bottom).offset(12)
        }
    }
    
    // MARK: Actions
    
    @objc
    func didTap() {
        checkBox.isSelected = !checkBox.isSelected
        nextButton.isEnabled = checkBox.isSelected
    }
    
    @objc
    func didClickCancel() {
        cancelBlock?(self)
    }
    
    @objc
    func gotoGuide() {
        MailTracker.log(event: "email_mail_mig_setting_click", params: ["mail_service": self.migrationInfo.provider.rawValue,
                                                                        "mail_account_type": Store.settingData.getMailAccountType(),
                                                                        "click": "how_to_set"])
        guard let localLink = serviceProvider?.provider.settingConfig?.linkConfig?.migrationSetting.localLink else {
            MailLogger.info("[mail_client] [imap_migration] no link config")
            return
        }
        guard let url = URL(string: localLink) else {
            MailLogger.info("[mail_client] [imap_migration] initialize url failed")
            return
        }
        UIApplication.shared.open(url)
    }
}
