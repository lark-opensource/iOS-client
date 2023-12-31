//
//  MailDeletedOauthView.swift
//  MailSDK
//
//  Created by tanghaojin on 2020/7/2.
//

import UIKit

class MailDeletedOauthView: UIView {
    required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    private func setup() {
        let imageView = UIImageView(image: Store.settingData.mailClient ? Resources.mail_client_tab_delete : Resources.mail_client_delete)
        addSubview(imageView)
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        addSubview(textLabel)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let attributedString = NSAttributedString(string: BundleI18n.MailSDK.Mail_Client_AccessRevokeEmailTabDisappearNotice,
                                                                   attributes: [.font: UIFont.systemFont(ofSize: 16),
                                                                              .foregroundColor: UIColor.ud.textPlaceholder,
                                                                              .paragraphStyle: paragraphStyle])

        textLabel.attributedText = attributedString

        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 100, height: 100))
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
        }
        textLabel.snp.makeConstraints { (make) in
            make.width.equalTo(302)
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(16)
        }
    }
}
