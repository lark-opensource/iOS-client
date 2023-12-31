//
//  MailSettingPushCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/7/2.
//

import Foundation
import UniverseDesignCheckBox
import RxSwift

class MailSettingPushCell: UITableViewCell {
    let disposeBag = DisposeBag()
    private let titleLabel: UILabel = UILabel()
    private let detailLabel: UILabel = UILabel()
    private var checkBox: UDCheckBox = UDCheckBox()
    private var tipView: MailSettingPushPreview = MailSettingPushPreview()
    private var checkBoxIsSelected = false
    private var checkBoxIsEnabled = false

    weak var dependency: MailSettingStatusCellDependency?
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    var superViewWidth: CGFloat = 279

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tipView.isHidden = true
    }

    func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(checkBox)
        contentView.addSubview(tipView)

        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(14)
            make.width.height.equalTo(20)
        }

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.centerY.equalTo(checkBox)
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(22)
        }
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        detailLabel.isHidden = true
        detailLabel.numberOfLines = 0

        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCell)))
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    @objc
    func didClickCell() {
        if let pushItem = item as? MailSettingPushModel {
            updateStatus(isSelected: !checkBox.isSelected, isEnabled: true)
            pushItem.switchHandler(checkBox.isSelected)
        } else if let scopeItem = item as? MailSettingPushScopeModel {
            scopeItem.clickHandler()
        } else if let typeItem = item as? MailSettingPushTypeModel {
            if (typeItem.channel == 1 && typeItem.type == .push && checkBox.isSelected) ||
                (typeItem.channel == 2 && typeItem.type == .bot && checkBox.isSelected) {
                MailRoundedHUD.showWarning(with: BundleI18n.MailSDK.Mail_Settings_NotificationFormCantBeEmpty, on: self)
            } else {
                updateStatus(isSelected: !checkBox.isSelected, isEnabled: true)
                typeItem.switchHandler(checkBox.isSelected)
            }
        }
    }

    func updateStatus(isSelected: Bool, isEnabled: Bool) {
        self.checkBoxIsSelected = isSelected
        self.checkBoxIsEnabled = isEnabled
        self.checkBox.isSelected = isSelected
        self.checkBox.isEnabled = isEnabled
    }

    func setCellInfo() {
        titleLabel.isHidden = true
        detailLabel.isHidden = true
        tipView.isHidden = true
        if let current = item as? MailSettingPushModel {
            titleLabel.isHidden = false
            titleLabel.text = current.title
        } else if let current = item as? MailSettingPushScopeModel {
            titleLabel.isHidden = false
            titleLabel.text = current.title
        } else if let current = item as? MailSettingPushTypeModel {
            titleLabel.isHidden = false
            titleLabel.text = current.title
            tipView.isHidden = false
            tipView.setTypeAndLayoutView(current.type)
            if current.type == .bot && Store.settingData.hasMailClient() {
                detailLabel.isHidden = false
                detailLabel.text = BundleI18n.MailSDK.Mail_ThirdClient_SettingsWontApplyToConnectedAccounts
                detailLabel.snp.remakeConstraints { (make) in
                    make.left.equalTo(titleLabel)
                    make.top.equalTo(titleLabel.snp.bottom).offset(2)
                    make.width.equalTo(superViewWidth)
                    if let height = detailLabel.text?.getTextHeight(font: UIFont.systemFont(ofSize: 14.0, weight: .regular), width: superViewWidth) {
                        make.height.equalTo(height)
                    } else {
                        make.height.equalTo(20)
                    }
                }
                tipView.snp.remakeConstraints { (make) in
                    make.left.equalTo(detailLabel)
                    make.top.equalTo(detailLabel.snp.bottom).offset(12)
                    make.width.equalTo(279)
                    make.height.equalTo(106)
                }
            } else {
                tipView.snp.remakeConstraints { (make) in
                    make.left.equalTo(titleLabel)
                    make.top.equalTo(titleLabel.snp.bottom).offset(12)
                    make.width.equalTo(279)
                    make.height.equalTo(106)
                }
            }
        }
    }

    func updateUIConfig(boxType: UDCheckBoxType, config: UDCheckBoxUIConfig) {
        self.checkBox.updateUIConfig(boxType: boxType, config: config)
    }
}
