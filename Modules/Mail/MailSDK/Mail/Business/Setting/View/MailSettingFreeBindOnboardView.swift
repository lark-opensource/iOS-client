//
//  MailSettingFreeBindOnboardView.swift
//  MailSDK
//
//  Created by ByteDance on 2023/8/17.
//

import UIKit
import RxSwift
import UniverseDesignFont
import UniverseDesignColor
import LarkIllustrationResource
import UniverseDesignButton
import SnapKit

class MailSettingFreeBindOnboardView: UIView {
    var gotoBind: (() -> Void)?
    private let topMargin: CGFloat
    private let containerView = UIView()
    private let imageView = {
        let view = UIImageView()
        view.image = LarkIllustrationResource.Resources.initializationFunctionEmail
        return view
    }()
    private let button = {
        let btn = UDButton(UDButtonUIConifg.primaryBlue)
        btn.setTitle(BundleI18n.MailSDK.Mail_Settings_SupportGmailMicrosoft_LinkAccount_Button, for: .normal)
        btn.addTarget(self, action: #selector(buttonClick(sender:)), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return btn
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(topMargin: CGFloat) {
        self.topMargin = topMargin
        super.init(frame: .zero)
        setup()
    }
    
    private func setup() {
        self.backgroundColor = UIColor.ud.bgBase
        addSubview(containerView)
        containerView.backgroundColor = .clear
        containerView.addSubview(imageView)
        containerView.addSubview(button)
        
        // 相对整个屏幕居中，需要减去顶部statusbar和navibar高度
        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-topMargin/2.0)
        }
        
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(250)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        button.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.width.equalTo(335)
            make.height.equalTo(48)
            make.top.equalTo(imageView.snp.bottom).offset(24)
        }
    }
    @objc
    func buttonClick(sender: UIButton) {
        gotoBind?()
    }
}
