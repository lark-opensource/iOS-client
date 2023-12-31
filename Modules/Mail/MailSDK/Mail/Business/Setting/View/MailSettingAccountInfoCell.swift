//
//  MailSettingAccountInfoCell.swift
//  MailSDK
//
//  Created by majx on 2020/9/11.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignFont

class MailSettingAccountInfoCell: UITableViewCell {
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    private let nameLabel: UILabel = UILabel()
    private let addressLabel: UILabel = UILabel()
    private let warningLabel: UILabel = UILabel()
    private let avatarView: MailAvatarImageView = MailAvatarImageView()

    let disposeBag = DisposeBag()

    weak var dependency: MailSettingAccountCellDependency?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = .clear
        contentView.addSubview(avatarView)
        contentView.addSubview(warningIcon)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(warningLabel)

        nameLabel.font = UDFont.title4
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 0
        nameLabel.textAlignment = .center

        addressLabel.font = UDFont.body2
        addressLabel.textColor = UIColor.ud.textPlaceholder
        addressLabel.numberOfLines = 0
        addressLabel.textAlignment = .center

        warningLabel.font = UIFont.systemFont(ofSize: 14)
        warningLabel.textColor = UIColor.ud.functionDangerContentDefault
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center

        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 30
        avatarView.snp.makeConstraints { (make) in
            make.top.equalTo(24)
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.centerX.equalToSuperview()
        }
        warningIcon.isHidden = true
        warningIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.bottom.trailing.equalTo(avatarView)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarView.snp.bottom).offset(12)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }

        addressLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }

        warningLabel.isHidden = true
        warningLabel.snp.makeConstraints { (make) in
            make.top.equalTo(addressLabel.snp.bottom).offset(6)
            make.height.equalTo(0)
            make.bottom.equalTo(-8)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
    }

    func setCellInfo() {
        if let accountInfo = item as? MailSettingAccountInfoModel {
            nameLabel.text = accountInfo.name
            addressLabel.text = accountInfo.address

            if accountInfo.isShared {
                avatarView.setAvatar(with: accountInfo.name)
            } else {
                MailModelManager.shared.getUserAvatarKey(userId: accountInfo.accountId)
                .subscribe(onNext: { [weak self] (avatarKey) in
                    guard let `self` = self else { return }
                    self.avatarView.set(name: accountInfo.name,
                                        avatarKey: avatarKey,
                                        entityId: accountInfo.accountId,
                                        image: nil)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    self.avatarView.setAvatar(with: accountInfo.name)
                }).disposed(by: disposeBag)
            }

            if accountInfo.type == .refreshAccount {
                warningIcon.isHidden = false
                warningLabel.isHidden = false
                switch accountInfo.type {
                case .refreshAccount:
                    warningLabel.text = BundleI18n.MailSDK.Mail_Mailbox_PleaseLinkAgain
                default:
                    break
                }
                warningLabel.snp.updateConstraints { (make) in
                    make.height.equalTo(20)
                    make.bottom.equalTo(-8)
                }
            } else if accountInfo.type == .reVerify {
                warningIcon.isHidden = false
                warningLabel.isHidden = true
                warningLabel.text = nil
                warningLabel.snp.updateConstraints { (make) in
                    make.height.equalTo(0)
                    make.bottom.equalTo(-8)
                }
            } else {
                warningIcon.isHidden = true
                warningLabel.isHidden = true
                warningLabel.text = nil
                warningLabel.snp.updateConstraints { (make) in
                    make.height.equalTo(0)
                    make.bottom.equalTo(-8)
                }
            }
        }
    }

    lazy var warningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.mail_setting_icon_warn
        return imageView
    }()
}
