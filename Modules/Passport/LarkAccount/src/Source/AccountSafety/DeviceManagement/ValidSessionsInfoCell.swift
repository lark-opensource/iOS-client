//
//  ValidSessionsInfoCell.swift
//  Lark
//
//  Created by zc09v on 2017/11/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import LarkUIKit
import LarkExtensions
import LarkAccountInterface
import UniverseDesignButton
import UIKit

class ValidSessionsInfoCell: UITableViewCell {
    typealias AccountSafetyResources = BundleResources.LarkAccount.AccountSafety

    var sessionInfo: LoginDevice?
    var kickSession: ((String, String, UIView) -> Void)?

    private lazy var typeIcon: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var deviceNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private lazy var statusLabel: DeviceLabel = {
        let label = DeviceLabel()
        label.text = BundleI18n.suiteLogin.Lark_LoginError_DeviceManage_Notice
        return label
    }()
    private lazy var osLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private lazy var loginTimeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private lazy var mySessionTagLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = I18N.Lark_Legacy_MineDataMydevice
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    private lazy var offlineButton: UDButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent, backgroundColor: UIColor.ud.bgBody, textColor: UIColor.ud.textTitle)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent, backgroundColor: UIColor.ud.udtokenBtnSeBgNeutralHover, textColor: UIColor.ud.textTitle)
        var config = UDButtonUIConifg(normalColor: normalColor, pressedColor: pressedColor, type: .small, radiusStyle: .square)
        config.type = .small
        let button = UDButton(config)
        button.setTitle(I18N.Lark_Legacy_Logout, for: .normal)
        button.addTarget(self, action: #selector(offlineButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var bottomLineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault //lk.commonTableSeparatorColor
        return line
    }()
    
    public var isLastCell: Bool = false {
        didSet {
            self.bottomLineView.isHidden = isLastCell ? true : false
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        setContentCompressionResistancePriority(.required, for: .horizontal)
        
        contentView.addSubview(typeIcon)
        contentView.addSubview(osLabel)
        contentView.addSubview(loginTimeLabel)
        contentView.addSubview(mySessionTagLabel)
        contentView.addSubview(offlineButton)
        contentView.addSubview(bottomLineView)
        
        typeIcon.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.top.equalTo(10)
            make.width.height.equalTo(20)
        }

        let deviceNameStack = UIStackView(arrangedSubviews: [deviceNameLabel, statusLabel])
        contentView.addSubview(deviceNameStack)
        deviceNameStack.axis = .horizontal
        deviceNameStack.spacing = 4
        deviceNameStack.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(typeIcon.snp.right).offset(15)
            make.right.lessThanOrEqualTo(offlineButton.snp.left).offset(-Self.rightItemSpace)
        }

        osLabel.snp.makeConstraints { (make) in
            make.top.equalTo(deviceNameLabel.snp.bottom).offset(4)
            make.left.equalTo(deviceNameLabel.snp.left)
            make.right.lessThanOrEqualTo(offlineButton.snp.left).offset(-Self.rightItemSpace)
        }

        loginTimeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(osLabel.snp.bottom).offset(2)
            make.left.equalTo(osLabel.snp.left)
            make.right.lessThanOrEqualTo(offlineButton.snp.left).offset(-Self.rightItemSpace)
            make.bottom.equalToSuperview().offset(-Self.rightItemSpace)
        }

        mySessionTagLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
        }

        offlineButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        offlineButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(28.0)
        }

        bottomLineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    private func updateUI() {
        var loginDataStr = ""
        guard let info = sessionInfo else {
            return
        }
        if info.loginTime > 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(info.loginTime))
            loginDataStr = Self.dateFormater.string(from: date)
        }
        // 取到时间加空格，否则不加
        loginTimeLabel.attributedText = getAttributedString(
            text: """
                  \(I18N
                    .Lark_NewSettings_DeviceManagementLastLoginTime)\(loginDataStr)
                  """,
            lineHeight: Self.detailLineHeight
        )
        switch info.terminal {
        case .ios, .android, .unknown:
            typeIcon.image = AccountSafetyResources.phone_icon.ud.withTintColor(UIColor.ud.textCaption)
        case .pc, .web:
            typeIcon.image = info.terminal == .pc ? AccountSafetyResources.pc_icon.ud.withTintColor(UIColor.ud.textCaption) : AccountSafetyResources.web_icon.ud.withTintColor(UIColor.ud.textCaption)
        @unknown default:
            assert(false, "new value")
        }
        if !info.os.isEmpty {
            osLabel.attributedText = getAttributedString(
                text: "\(I18N.Lark_NewSettings_DeviceManagementOS)\(info.os)",
                lineHeight: Self.detailLineHeight
            )
        } else {
            osLabel.attributedText = getAttributedString(
                text: "\(I18N.Lark_NewSettings_DeviceManagementOS)\(I18N.Lark_Legacy_MineDataUnkowndevidemodel)",
                lineHeight: Self.detailLineHeight
            )
        }
        if !info.name.isEmpty {
            deviceNameLabel.text = info.name
        } else {
            deviceNameLabel.text = I18N.Lark_Legacy_OldDevice()
        }

        if info.isCurrent {
            mySessionTagLabel.alpha = 1
            offlineButton.alpha = 0
        } else {
            mySessionTagLabel.alpha = 0
            offlineButton.alpha = 1
        }
        
        statusLabel.isHidden = !(info.isAbnormal ?? false)
    }

    func set(sessionInfo: LoginDevice) {
        self.sessionInfo = sessionInfo

        updateUI()
    }

    @objc
    private func offlineButtonClick(_ sender: UIButton) {
        guard let id = self.sessionInfo?.id, !id.isEmpty else {
            return
        }
        self.kickSession?(id, deviceNameLabel.text ?? "", sender)
    }

    func getAttributedString(text: String, lineHeight: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        return NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }

    static let dateFormater: DateFormatter = {
        let formater = DateFormatter()
        formater.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formater
    }()

    static let titleLineHeight: CGFloat = 24
    static let detailLineHeight: CGFloat = 20
    static let rightItemSpace: CGFloat = 16
}
