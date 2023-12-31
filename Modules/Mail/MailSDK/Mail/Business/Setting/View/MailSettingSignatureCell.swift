//
//  MailSettingSignatureCell.swift
//  MailSDK
//
//  Created by majx on 2020/1/9.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignFont
import UniverseDesignIcon

protocol MailSettingSignatureCellDependency: AnyObject {
    func jumpSignatureSettingPage(accountId: String)
}

class MailSettingSignatureCell: MailSettingBaseCell {
    let disposeBag = DisposeBag()
    weak var dependency: MailSettingSignatureCellDependency?

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    override func setupViews() {
        super.setupViews()
        statusLabel.isHidden = FeatureManager.realTimeOpen(.enterpriseSignature)
    }

    @objc
    override func didClickCell() {
        if let model = item as? MailSettingSignatureModel {
            if model.accountId.isEmpty {
                MailLogger.error("accountId is empty")
            }
            dependency?.jumpSignatureSettingPage(accountId: model.accountId)
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailSettingSignatureModel {
            titleLabel.text = currItem.title
            statusLabel.text = currItem.status ? BundleI18n.MailSDK.Mail_Setting_EmailEnabled : BundleI18n.MailSDK.Mail_Setting_EmailNotEnabled
        }
    }
}

protocol MailSettingDraftLangCellDependency: AnyObject {
    func jumpDraftLangSettingPage()
}

class MailSettingDraftLandCell: MailSettingBaseCell {
    let disposeBag = DisposeBag()
    var userContext: MailUserContext?
    weak var dependency: MailSettingDraftLangCellDependency?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.ud.bgFloat
    }

    @objc
    override func didClickCell() {
        if (item as? MailDraftLangModel) != nil {
            dependency?.jumpDraftLangSettingPage()
        }
    }

    override func setCellInfo() {
        if let currItem = item as? MailDraftLangModel {
            titleLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefix
            switch currItem.currentLanguage {
            case .auto:
                if FeatureManager.open(.aiBlock) {
                    if userContext?.featureManager.open(.replyLangOpt, openInMailClient: true) == true && userContext?.user.isOverSea == true {
                        statusLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixEn
                    } else {
                        statusLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixCn
                    }
                } else {
                    statusLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixAuto
                }
            case .zh:
                statusLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixCn
            case .us:
                statusLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixEn
            @unknown default:
                ()
            }
            
        }
    }
}

class DraftLangSettingCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.ud.textTitle
        l.font = UIFont.systemFont(ofSize: 16)
        return l
    }()
    lazy var contentLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.ud.textPlaceholder
        l.font = UIFont.systemFont(ofSize: 14)
        return l
    }()

    lazy var selectView: UDCheckBox = {
        let v = UDCheckBox(boxType: .list, config: UDCheckBoxUIConfig(), tapCallBack: nil)
        v.isUserInteractionEnabled = false
        return v
    }()
    override var isSelected: Bool {
        didSet {
            selectView.isSelected = isSelected
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : UIColor.ud.bgFloat
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(selectView)
        selectView.snp.makeConstraints { (make) in
            make.height.width.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        let hasContent = Store.settingData.clientStatus != .coExist
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(12)
            make.left.equalTo(16)
            make.height.equalTo(22)
            make.right.equalToSuperview().offset(hasContent ? -48 :-12)
        }
        if hasContent {
            contentView.addSubview(contentLabel)
            contentLabel.snp.makeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom)
                make.left.equalTo(titleLabel.snp.left)
                make.right.equalTo(titleLabel.snp.right)
                make.height.equalTo(22)
                make.bottom.equalToSuperview().offset(-12)
            }
        }
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
