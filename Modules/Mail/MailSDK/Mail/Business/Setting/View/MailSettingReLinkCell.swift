//
//  MailSettingReLinkCell.swift
//  MailSDK
//
//  Created by majx on 2020/9/22.
//
import UIKit
import RxSwift
import UniverseDesignFont
import UniverseDesignColor

class MailSettingRelinkCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    var item: MailSettingItemProtocol? {
        didSet {
            guard let currItem = item as? MailSettingRelinkModel else { return }
            switch currItem.type {
            case .gmail, .exchange:
                relinkLabel.text = BundleI18n.MailSDK.Mail_Mailbox_LinkAgain
            case .mailClient:
                relinkLabel.text = BundleI18n.MailSDK.Mail_ThirdClient_VerifiedAgain
            default:
                break
            }
        }
    }
    private let relinkLabel: UILabel = UILabel()

    let disposeBag = DisposeBag()
    weak var dependency: MailSettingAccountCellDependency?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(relinkLabel)
        relinkLabel.font = UIFont.systemFont(ofSize: 16)
        relinkLabel.textColor = UIColor.ud.primaryContentDefault
        relinkLabel.numberOfLines = 0
        relinkLabel.text = BundleI18n.MailSDK.Mail_Mailbox_LinkAgain
        relinkLabel.sizeToFit()
        relinkLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bindCellClick)))
    }
}

extension MailSettingRelinkCell {
    @objc
    func bindCellClick() {
        if let currItem = item as? MailSettingRelinkModel {
            switch currItem.type {
            case .gmail:
                dependency?.jumpGoogleOauthPage(type: .google)
            case .exchange:
                dependency?.jumpGoogleOauthPage(type: .exchange)
            case .mailClient:
                dependency?.jumpAdSetting(currItem.accountId, provider: currItem.provider)
            default:
                break
            }
        }
    }
}
