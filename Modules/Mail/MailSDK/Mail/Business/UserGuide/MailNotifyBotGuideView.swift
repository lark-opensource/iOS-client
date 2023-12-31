//
//  MailNotifyBotGuideView.swift
//  MailSDK
//
//  Created by lisi on 2022/4/19.
//

import Foundation
import LarkGuideUI
import UIKit
import SnapKit
import LarkLocalizations

protocol MailNotifyBotGuideViewDelegate: AnyObject {
    func didNotifyBotClickSkip(dialogView: GuideCustomView)
    func didNotifyBotClickOpen(dialogView: GuideCustomView)
}

final class MailNotifyBotGuideView : GuideCustomView {
    weak var notifyBotDelegate: MailNotifyBotGuideViewDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(delegate: LarkGuideUI.GuideCustomViewDelegate) {
        super.init(delegate: delegate)
        setupViews()
    }
    
    init(delegate: LarkGuideUI.GuideCustomViewDelegate , notifyBotDelegate: MailNotifyBotGuideViewDelegate) {
        super.init(delegate: delegate)
        self.notifyBotDelegate = notifyBotDelegate
        setupViews()
    }
    
    override var intrinsicContentSize: CGSize {
        var viewHeight: CGFloat = Layout.bannerHeight
        let textPrepareSize = CGSize(width: Layout.viewWidth - Layout.contentInset * 2,
                                     height: CGFloat.greatestFiniteMagnitude)
        let titleHeight = titleText.sizeThatFits(textPrepareSize).height
        let detailHeight = detailText.sizeThatFits(textPrepareSize).height
        viewHeight += Layout.titleTop + titleHeight
        viewHeight += Layout.detailTop + detailHeight
        
        if isVerticalButton() {
            viewHeight += Layout.buttonTop + Layout.buttonHeight*2 +  Layout.buttonMargin + Layout.buttonInset
        } else {
            viewHeight += Layout.buttonTop + Layout.buttonHeight + Layout.buttonInset
        }
        return CGSize(width: Layout.viewWidth, height: viewHeight)
    }
    
    func isVerticalButton() -> Bool {
        switch LanguageManager.currentLanguage {
        case .ja_JP,.zh_CN,.zh_HK,.zh_TW:
            return false
        default:
            return true
        }
    }
    
    func setupViews() {
        self.backgroundColor = Style.bgViewBackgroundColor
        self.layer.ud.setShadow(type: .s4DownPri)
        self.layer.cornerRadius = Layout.containerCornerRadius
        self.clipsToBounds = true
        
        self.snp.makeConstraints { make in
            make.width.equalTo(self.intrinsicContentSize.width)
            make.height.equalTo(self.intrinsicContentSize.height)
        }
        
        self.addSubview(headerView)
        self.addSubview(footerView)
        headerView.addSubview(bannerView)
        headerView.addSubview(maskHeaderView)
        footerView.addSubview(titleText)
        footerView.addSubview(detailText)
        footerView.addSubview(skipButton)
        footerView.addSubview(okButton)
        
        headerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(Layout.bannerHeight)
        }
        bannerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(Layout.bannerTop)
        }
        maskHeaderView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        footerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        titleText.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.titleTop)
            make.left.equalToSuperview().inset(Layout.titleInset)
            make.right.equalToSuperview().inset(Layout.titleInset)
        }
        detailText.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(Layout.detailTop)
            make.left.equalToSuperview().inset(Layout.titleInset)
            make.right.equalToSuperview().inset(Layout.titleInset)
        }
        
        if isVerticalButton() {
            okButton.snp.makeConstraints { make in
                make.top.equalTo(detailText.snp.bottom).offset(Layout.buttonTop)
                make.left.equalToSuperview().inset(Layout.buttonInset)
                make.right.equalToSuperview().inset(Layout.buttonInset)
                make.height.equalTo(Layout.buttonHeight)
            }
            skipButton.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(Layout.buttonInset)
                make.right.equalToSuperview().inset(Layout.buttonInset)
                make.height.equalTo(Layout.buttonHeight)
                make.bottom.equalToSuperview().inset(Layout.buttonInset)
                make.top.equalTo(okButton.snp.bottom).offset(Layout.buttonMargin)
            }
        } else {
            skipButton.snp.makeConstraints { make in
                make.top.equalTo(detailText.snp.bottom).offset(Layout.buttonTop)
                make.left.equalToSuperview().inset(Layout.buttonInset)
                make.height.equalTo(Layout.buttonHeight)
                make.bottom.equalToSuperview().inset(Layout.buttonInset)
                make.width.equalTo(okButton.snp.width)
            }
            okButton.snp.makeConstraints { make in
                make.top.equalTo(skipButton.snp.top)
                make.left.equalTo(skipButton.snp.right).offset(Layout.buttonMargin)
                make.right.equalToSuperview().inset(Layout.buttonInset)
                make.height.equalTo(Layout.buttonHeight)
                make.bottom.equalToSuperview().inset(Layout.buttonInset)
            }
        }
    }
    
    private let bannerView: UIImageView = {
        let view = UIImageView()
        view.layer.ud.setShadow(type: .s5DownPri)
        let img = Resources.guide_notify_bot_content
        view.image = img
        view.sizeToFit()
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Style.headerBgColor
        return view
    }()
    
    private let footerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let maskHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.fillImgMask
        return view
    }()
    
    private let titleText: UILabel = {
        let label = UILabel()
        label.textColor = Style.textColor
        label.font = Style.titleFont
        label.text = BundleI18n.MailSDK.Mail_Bot_EnabledNotificationsTitle
        label.numberOfLines = 0
        return label
    }()
    
    private let detailText: UILabel = {
        let label = UILabel()
        label.textColor = Style.textColor
        label.font = Style.detailTextFont
        label.text = BundleI18n.MailSDK.Mail_Bot_EnabledNotificationsDesc()
        label.numberOfLines = 0
        return label
    }()
    
    private let skipButton: UIButton = {
        let btn = UIButton()
        btn.layer.borderColor = Style.buttonBgColor.cgColor
        btn.layer.cornerRadius = Layout.containerCornerRadius
        btn.layer.borderWidth = 1
        btn.setTitle(BundleI18n.MailSDK.Mail_Bot_Skip, for: .normal)
        btn.setTitleColor(Style.buttonBgColor, for: .normal)
        btn.titleLabel?.font = Style.buttonTextFont
        btn.addTarget(self, action: #selector(didClickSkipBtn),
                     for: UIControl.Event.touchUpInside)
        return btn
    }()
    
    private let okButton: UIButton = {
        let btn = UIButton()
        btn.clipsToBounds = true
        btn.layer.cornerRadius = Layout.containerCornerRadius
        btn.setTitle(BundleI18n.MailSDK.Mail_Bot_EnableNotifications, for: .normal)
        btn.setTitleColor(Style.bgViewBackgroundColor, for: .normal)
        btn.titleLabel?.font = Style.buttonTextFont
        btn.backgroundColor = Style.buttonBgColor
        btn.addTarget(self, action: #selector(didClickOkBtn),
                                for: UIControl.Event.touchUpInside)
//        btn.setBackgroundImage(UIImage.lu.fromColor(UIColor.white), for: .normal)
        return btn
    }()
    
    @objc private func didClickSkipBtn() {
        notifyBotDelegate?.didNotifyBotClickSkip(dialogView: self)
        closeGuideCustomView(view: self)
    }

    @objc private func didClickOkBtn() {
        notifyBotDelegate?.didNotifyBotClickOpen(dialogView: self)
        closeGuideCustomView(view: self)
    }
}

extension MailNotifyBotGuideView {
    enum Layout {
        static let viewWidth: CGFloat = 300
        static let containerCornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 20
        static let bannerHeight: CGFloat = 187
        static let bannerTop: CGFloat = 16
        static let titleTop: CGFloat = 20
        static let titleInset: CGFloat = 20
        static let detailTop: CGFloat = 8
        static let buttonRadius: CGFloat = 6
        static let buttonInset: CGFloat = 20
        static let buttonHeight: CGFloat = 40
        static let buttonTop: CGFloat = 24
        static let buttonMargin: CGFloat = 12
    }
    enum Style {
        static let titleFont: UIFont = .systemFont(ofSize: 20.0, weight: .medium)
        static let detailTextFont: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
        static let textColor: UIColor = UIColor.ud.primaryOnPrimaryFill
        static let buttonTextFont: UIFont = .systemFont(ofSize: 14.0, weight: .medium)
        static let buttonBgColor: UIColor = UIColor.ud.primaryOnPrimaryFill
        static let headerBgColor = UIColor.ud.B50.alwaysLight
        static let bgViewBackgroundColor = UIColor.ud.primaryFillHover.alwaysLight
    }
}
