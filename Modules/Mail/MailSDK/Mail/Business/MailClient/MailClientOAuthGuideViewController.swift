//
//  MailClientOAuthGuideViewController.swift
//  MailSDK
//
//  Created by Quanze Gao on 2023/3/23.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

struct MailClientOAuthGuideViewModel {
    let url: URL
    let serviceIcon: UIImage
    let title: String
    let desctiption: String
    let buttonTitle: String
    let isExchange: Bool
    let migrateProvider: IMAPMigrationProvider?
    
    static func defaultAuthModel(url: URL, type: MailOAuthURLType) -> MailClientOAuthGuideViewModel {
        let title = BundleI18n.MailSDK.Mail_LinkAccount_CompleteAuthorizationInBrowser_Title
        let desctiption = BundleI18n.MailSDK.Mail_LinkAccount_CompleteAuthorizationInBrowser_Desc(type.serviceName)
        let buttonTitle = BundleI18n.MailSDK.Mail_LinkAccount_CompleteAuthorizationInBrowser_ToBrowserMobile_Button
        return MailClientOAuthGuideViewModel(url: url,
                                             serviceIcon: type.serviceIcon,
                                             title: title,
                                             desctiption: desctiption,
                                             buttonTitle: buttonTitle,
                                             isExchange: type == .exchange,
                                             migrateProvider: nil)
    }
    
    static func imapMigrationModel(url: URL, provider: IMAPMigrationProvider) -> MailClientOAuthGuideViewModel {
        let title = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_AuthorizeInBroswerPopUp_Title
        let desctiption = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_AuthorizeInBroswerPopUp_Desc
        let buttonTitle = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_AuthorizeInBroswerPopUp_OpenBrowser_Button
        let icon = UDIcon.getIconByKey(.emailOffice365Colorful, size: CGSize(width: 80, height: 80))
        return MailClientOAuthGuideViewModel(url: url, serviceIcon: icon,
                                             title: title,
                                             desctiption: desctiption,
                                             buttonTitle: buttonTitle,
                                             isExchange: true,
                                             migrateProvider: provider)
        
        
    }
}

extension MailOAuthURLType {
    var serviceIcon: UIImage {
        let serviceIconSize = CGSize(width: 52, height: 52)
        switch self {
        case .google:
            return UDIcon.getIconByKey(.googleColorful, size: serviceIconSize)
        case .exchange:
            return UDIcon.getIconByKey(.emailOffice365Colorful, size: CGSize(width: 80, height: 80))
        @unknown default:
            mailAssertionFailure("Unknown mail service type: \(self)")
            return UDIcon.getIconByKey(.emailOthermailColorful, size: serviceIconSize)
        }
    }
    var serviceName: String {
        switch self {
        case .google:
            return BundleI18n.MailSDK.Mail_ThirdClient_Google
        case .exchange:
            return BundleI18n.MailSDK.Mail_LinkYourBusinessEmailToLark_M365_Text
        @unknown default:
            mailAssertionFailure("Unknown mail service type: \(self)")
            return BundleI18n.MailSDK.Mail_ThirdClient_Others
        }
    }
}

class MailClientOAuthGuideViewController: UIViewController {
    private let model: MailClientOAuthGuideViewModel
    private let container = UIView()
    private let closeButton = UIButton()
    private let mailServiceIcon = UIImageView()
    private let guideTitleLabel = UILabel()
    private let guideDetailLabel = UILabel()
    private let openBrowserButton = UIButton()
    private let dismissBlock: () -> Void
    
    private let containerWidth: CGFloat = 300
    private let serviceIconSize = CGSize(width: 52, height: 52)
    
    init(model: MailClientOAuthGuideViewModel, dismissBlock: @escaping () -> Void) {
        self.model = model
        self.dismissBlock = dismissBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissBlock()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgMask

        container.backgroundColor = .ud.bgFloat
        container.layer.cornerRadius = 8
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.width.equalTo(containerWidth)
            make.center.equalToSuperview()
        }
        
        closeButton.setImage(UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .ud.iconN2
        closeButton.hitTestEdgeInsets = .init(edges: -4)
        closeButton.addAction { [weak self] in
            self?.dismiss(animated: false)
        }
        container.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.right.top.equalToSuperview().inset(16)
        }
        
        mailServiceIcon.image = model.serviceIcon
        mailServiceIcon.contentMode = .scaleAspectFit
        container.addSubview(mailServiceIcon)
        mailServiceIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(model.isExchange ? 46 : 56)
            make.width.height.equalTo(model.isExchange ? 80 : serviceIconSize.width)
        }
        
        guideTitleLabel.numberOfLines = 0
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.lineSpacing = 4
        titleParagraphStyle.alignment = .center
        guideTitleLabel.attributedText = NSAttributedString(
            string: model.title,
            attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .medium),
                         .foregroundColor: UIColor.ud.textTitle,
                         .paragraphStyle: titleParagraphStyle])
        container.addSubview(guideTitleLabel)
        guideTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(25)
            make.top.equalTo(mailServiceIcon.snp.bottom).inset(model.isExchange ? -10 : -20)
        }

        guideDetailLabel.numberOfLines = 0
        let detailParagraphStyle = NSMutableParagraphStyle()
        detailParagraphStyle.lineSpacing = 3
        detailParagraphStyle.alignment = .center
        guideDetailLabel.attributedText = NSAttributedString(
            string: model.desctiption,
            attributes: [.font: UIFont.systemFont(ofSize: 16),
                         .foregroundColor: UIColor.ud.textCaption,
                         .paragraphStyle: detailParagraphStyle])
        container.addSubview(guideDetailLabel)
        guideDetailLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(25)
            make.top.equalTo(guideTitleLabel.snp.bottom).inset(-8)
        }
        
        openBrowserButton.setTitle(model.buttonTitle, for: .normal)
        openBrowserButton.backgroundColor = .ud.primaryContentDefault
        openBrowserButton.layer.cornerRadius = 6
        openBrowserButton.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        openBrowserButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        openBrowserButton.addAction { [weak self] in
            if let provider = self?.model.migrateProvider {
                MailTracker.log(event: "email_mail_mig_o365_waiting_click",
                                params: ["mail_service": provider.rawValue,
                                         "mail_account_type": Store.settingData.getMailAccountType(),
                                         "click": "open_browser"])
            }
            guard let url = self?.model.url else { return }
            UIApplication.shared.open(url)
        }
        container.addSubview(openBrowserButton)
        openBrowserButton.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.top.equalTo(guideDetailLabel.snp.bottom).inset(-28)
        }
    }
}
