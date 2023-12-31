//
//  MailSettingAccountCell.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/11/14.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkTag
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignTag

protocol MailSettingAccountCellDependency: AnyObject {
    var disposeBag: DisposeBag { get }
    var serviceProvider: MailSharedServicesProvider? { get }
    func jumpGoogleOauthPage(type: MailOAuthURLType)
    func jumpSettingOfAccount(_ accountId: String)
    func jumpAdSetting(_ accountId: String, provider: MailTripartiteProvider)
}

extension MailSettingAccountCellDependency where Self: UIViewController {
    func jumpGoogleOauthPage(type: MailOAuthURLType) {
        MailDataServiceFactory
        .commonDataService?
            .getGoogleOrExchangeOauthUrl(type: type, emailAddress: nil, fromVC: self)
        .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] (string, _, _) in
            guard let `self` = self, let url = URL(string: string) else {
                return
            }
            self.serviceProvider?.alertHelper.openGoogleOauthPage(url: url, fromVC: self)
        }, onError: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Common_NetworkError, on: self.view,
                                       event: ToastErrorEvent(event: .mailclient_oauth_get_url_fail))
        }).disposed(by: disposeBag)
    }
}

class MailSettingAccountCell: MailSettingAccountBaseCell {
    weak var dependency: MailSettingAccountCellDependency?
    lazy var accountTag: UDTag = {
        let tagConfig: UDTagConfig.TextConfig = .init(textColor: UIColor.ud.udtokenTagTextSRed, backgroundColor: UIColor.ud.udtokenTagBgRed)
        let accountTag = UDTag(text: BundleI18n.MailSDK.Mail_SharedEmail_SharedAccountTag, textConfig: tagConfig)
        return accountTag
    }()

    lazy var mailClientTag: UDTag = {
        let tagConfig: UDTagConfig.TextConfig = .init(textColor: UIColor.ud.udtokenTagNeutralTextNormal, backgroundColor: UIColor.ud.udtokenTagNeutralBgNormal)
        let mailClientTag = UDTag(text: BundleI18n.MailSDK.Mail_ThirdClient_Connected, textConfig: tagConfig)
        mailClientTag.layer.cornerRadius = 4
        mailClientTag.layer.masksToBounds = true
        return mailClientTag
    }()


    override func didClickCell() {
        if let currItem = item as? MailSettingAccountModel {
            switch currItem.type {
            case .noAccountAttach:
                dependency?.jumpGoogleOauthPage(type: MailOAuthURLType.google)
            case .exchangeNewUser:
                dependency?.jumpGoogleOauthPage(type: MailOAuthURLType.exchange)
            default:
                if let accoundId = item?.accountId, currItem.showDetail {
                    dependency?.jumpSettingOfAccount(accoundId)
                }
            }
        }
    }

    override func setCellInfo() {
        if let item = item as? MailSettingAccountModel {
            titleLabel.text = item.title
            subTitleLabel.text = item.subTitle
            accountTag.isHidden = true
            mailClientTag.isHidden = true
            warningIcon.isHidden = true

            if item.isMailClient {
                mailClientTag.isHidden = false
            } else if item.isShared {
                accountTag.isHidden = false
                accountTag.text = BundleI18n.MailSDK.Mail_Mailbox_Public
                let tagConfig: UDTagConfig.TextConfig = .init(textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
                accountTag.updateUI(textConfig: tagConfig)
                accountTag.layer.cornerRadius = 4
                accountTag.layer.masksToBounds = true
            } else {
                accountTag.isHidden = true
            }

            showArrow = item.showDetail
            if item.type == .noAccountAttach || item.type == .exchangeNewUser {
                warningIcon.isHidden = false
                accountTag.isHidden = true
                titleLabel.text = BundleI18n.MailSDK.Mail_Setting_LinkCorporateEmail

                if item.type == .noAccountAttach {
                    avatarView.imageView.image = Resources.mail_client_account_gmail_icon
                    subTitleLabel.text = BundleI18n.MailSDK.Mail_Setting_LinkCorporateEmailDescription
                } else {
                    avatarView.imageView.image = Resources.exchange_icon_round
                    subTitleLabel.text = BundleI18n.MailSDK.Mail_Outlook_OnlySupportBusinessOutlookAccount
                }
                showArrow = true
            } else {
                if item.isShared {
                    avatarView.setAvatar(with: item.title)
                } else {
                    MailModelManager.shared.getUserAvatarKey(userId: item.accountId)
                    .subscribe(onNext: { [weak self] (avatarKey) in
                        guard let `self` = self else { return }
                        self.avatarView.set(name: item.title,
                                            avatarKey: avatarKey,
                                            entityId: item.accountId,
                                            image: nil)
                    }, onError: { [weak self] (error) in
                        guard let `self` = self else { return }
                        self.avatarView.setAvatar(with: item.title)
                    }).disposed(by: disposeBag)
                }
            }

            if item.type == .refreshAccount || item.type == .reVerify {
                warningIcon.isHidden = false
                switch item.type {
                case .refreshAccount:
                    accountTag.text = BundleI18n.MailSDK.Mail_Mailbox_AccountsExpired
                case .reVerify:
                    accountTag.text = BundleI18n.MailSDK.Mail_ThirdClient_Expired
                default:
                    break
                }
                accountTag.isHidden = false
                let tagConfig: UDTagConfig.TextConfig = .init(textColor: UIColor.ud.udtokenTagTextSRed, backgroundColor: UIColor.ud.udtokenTagBgRed)
                accountTag.updateUI(textConfig: tagConfig)
            }
            
            var tags: [UDTag] = []
            if !accountTag.isHidden {
                tags.append(accountTag)
            }
            if !mailClientTag.isHidden {
                tags.append(mailClientTag)
            }
            setupTags(with: tags)
        }
    }

}
