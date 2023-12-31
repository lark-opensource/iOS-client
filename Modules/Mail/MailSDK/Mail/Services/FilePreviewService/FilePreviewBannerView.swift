//
//  FilePreviewBannerView.swift
//  MailSDK
//
//  Created by Ender on 2023/3/22.
//

import Foundation
import UniverseDesignNotice

class FilePreviewBannerView: UDNotice, UDNoticeDelegate {
    var termsAction: (() -> Void)? = nil
    var supportAction: (() -> Void)? = nil
    private let termsLink = "terms://"

    init() {
        let string = BundleI18n.MailSDK.Mail_UserAgreementViolated_Banner(BundleI18n.MailSDK.Mail_UserAgreementViolated_UserAgreement_Banner())
        let termsRange = (string as NSString).range(of: BundleI18n.MailSDK.Mail_UserAgreementViolated_UserAgreement_Banner())
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
        let str = NSMutableAttributedString(string: string, attributes: attributes)
        str.addAttributes([.link: termsLink], range: termsRange)
        var bannerViewConfig = UDNoticeUIConfig(type: .error, attributedText: str)
        bannerViewConfig.leadingButtonText = BundleI18n.MailSDK.Mail_UserAgreementViolated_ContactSupport_Button
        super.init(config: bannerViewConfig)
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handleLeadingButtonEvent(_ button: UIButton) {
        supportAction?()
    }

    func handleTrailingButtonEvent(_ button: UIButton) {}

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        if URL.absoluteString == termsLink {
            termsAction?()
        }
    }
}
