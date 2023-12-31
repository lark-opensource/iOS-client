//
//  OnBoardingBannerView.swift
//  LarkFeedBanner
//
//  Created by ByteDance on 2022/9/27.
//

import UIKit
import Foundation
import UniverseDesignIcon
import EENavigator
import LarkUIKit
import LKCommonsTracker
import Homeric
import LarkContainer

enum OnBoardingBannerType: Int {
    case bannerType = 1
    case buttonType = 2
}

public final class OnBoardingBannerView: UIView {

    lazy var icon = UIImageView()

    lazy var titleLabel = UILabel()

    lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        let pureImage = UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault)
        btn.setBackgroundImage(pureImage, for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        btn.layer.cornerRadius = 6
        btn.clipsToBounds = true
        btn.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return btn
    }()

    lazy var contentContainer = UIView()

    var applink: String = ""
    // 1 -  banner样式， 2 - 按钮样式
    var bannerType: OnBoardingBannerType = .bannerType
    var resolver: UserResolver

    public init?(frame: CGRect, item: OnboardingBannerItem, resolver: UserResolver) {
       guard let bannerData = item.bannerData?.customBanner.data.data(using: .utf8),
             let jsonObject = try? JSONSerialization.jsonObject(with: bannerData, options: []) as? [String: Any],
             let bannerType = jsonObject["bannerType"] as? Int,
             let title = jsonObject["title"] as? String,
             let btnText = jsonObject["btnText"] as? String,
             let applinks = jsonObject["applink"] as? [String: String],
             let iosApplink = applinks["ios"],
             item.display else {
           return nil
       }
       self.resolver = resolver
       super.init(frame: frame)
       self.applink = iosApplink
       self.bannerType = OnBoardingBannerType(rawValue: bannerType) ?? .bannerType
       self.backgroundColor = UIColor.ud.bgBody
       if self.bannerType == .bannerType {
            setupBannerStyle(title: title, btnText: btnText)
        } else {
            setupButtonStyle(title: title)
        }
       Tracker.post(TeaEvent(Homeric.FEED_BANNER_VIEW, params: [
        "type": self.bannerType == .bannerType ? "banner" : "button"
       ]))
    }

    private func setupBannerStyle(title: String, btnText: String) {
        // 样式一：按钮+文案
        contentContainer.backgroundColor = UIColor.ud.functionInfoFillSolid02
        contentContainer.layer.cornerRadius = 6
        contentContainer.clipsToBounds = true
        icon.image = UDIcon.getIconByKey(.tabContactsColorful, iconColor: UIColor.ud.colorfulBlue)
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.textColor = UIColor.ud.B800
        self.addSubview(contentContainer)
        contentContainer.addSubview(icon)
        contentContainer.addSubview(titleLabel)
        contentContainer.addSubview(button)
        icon.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.width.height.equalTo(16)
            make.top.equalTo(14)
        }
        button.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.right.equalTo(-12)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalTo(button.snp.left).offset(-12)
        }
        contentContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(titleLabel.snp.height).offset(24).priority(.medium)
            make.height.greaterThanOrEqualTo(44).priority(.required)
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
        titleLabel.text = title
        button.setTitle(btnText, for: .normal)
    }

    private func setupButtonStyle(title: String) {
        // 样式二：只有邀请按钮
        contentContainer.backgroundColor = UIColor.ud.primaryContentDefault
        contentContainer.layer.cornerRadius = 6
        contentContainer.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapButton))
        self.addGestureRecognizer(tap)
        icon.image = UDIcon.getIconByKey(.tabContactsColorful, iconColor: UIColor.ud.primaryOnPrimaryFill)
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        let layoutContainer = UIView()
        contentContainer.addSubview(layoutContainer)
        layoutContainer.addSubview(icon)
        layoutContainer.addSubview(titleLabel)
        self.addSubview(contentContainer)
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalToSuperview()
            make.top.equalTo(titleLabel).offset(3)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        layoutContainer.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.right.equalTo(titleLabel.snp.right)
            make.width.lessThanOrEqualToSuperview().offset(-16)
        }
        contentContainer.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.height.equalTo(titleLabel.snp.height).offset(14).priority(.medium)
            make.height.greaterThanOrEqualTo(36).priority(.required)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didTapButton() {
        guard let url = URL(string: applink),
              let window = resolver.navigator.mainSceneWindow else {
            return
        }
        Tracker.post(TeaEvent(Homeric.FEED_BANNER_CLICK, params: [
            "click": "invite_now",
            "type": bannerType == .bannerType ? "banner" : "button",
            "target": "none"
        ]))
        resolver.navigator.present(url, wrap: LkNavigationController.self, from: window)
    }
}
