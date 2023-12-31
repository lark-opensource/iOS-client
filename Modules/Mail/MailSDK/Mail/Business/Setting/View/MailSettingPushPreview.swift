//
//  MailSettingPushPreview.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/7/2.
//

import Foundation
import UIKit
import FigmaKit
import SnapKit
import UniverseDesignIcon

//enum MailPushPreviewType {
////    case unknown
//    case banner
//    case chatBot
//}

class MailSettingPushPreview: UIView {
    var type: MailChannelPosition = .push

    lazy var dialogBox = UIView()
    lazy var bannerTipView = UIView()
    lazy var iconView = UIImageView()
    lazy var iconBackgroundView = UIView()
    lazy var textLabel = UILabel()
    lazy var desView = SquircleView()
    lazy var desEndView = SquircleView()

    func setTypeAndLayoutView(_ type: MailChannelPosition) {
        reset()
        self.type = type
        setupViews(type)
    }
    func reset() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        dialogBox.snp.removeConstraints()
        bannerTipView.snp.removeConstraints()
        iconView.snp.removeConstraints()
        iconBackgroundView.snp.removeConstraints()
        textLabel.snp.removeConstraints()
        desView.snp.removeConstraints()
        desEndView.snp.removeConstraints()
    }

    func setupViews(_ type: MailChannelPosition) {
        let roundView = SquircleView()
        roundView.cornerRadius = 8
        roundView.cornerSmoothness = .natural
        roundView.backgroundColor = UIColor.ud.bgFloatOverlay
        addSubview(roundView)
        roundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconBackgroundView.isHidden = true
        iconBackgroundView.backgroundColor = .ud.colorfulIndigo
        iconBackgroundView.layer.cornerRadius = 12

        dialogBox.backgroundColor = UIColor.ud.bgBody
        dialogBox.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        dialogBox.layer.borderWidth = 1.0
        dialogBox.layer.cornerRadius = 4.0

        textLabel.text = BundleI18n.MailSDK.Mail_Settings_YouHaveNewEmail // "📮 你有一封新邮件"
        textLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)

        desView.backgroundColor = UIColor.ud.N200
        desView.cornerRadius = 4
        desView.cornerSmoothness = .natural

        addSubview(dialogBox)
        addSubview(iconBackgroundView)
        addSubview(iconView)
        addSubview(textLabel)
        addSubview(desView)

        switch type {
        case .push:
            textLabel.textColor = UIColor.ud.textTitle

            dialogBox.snp.makeConstraints { make in
                make.width.equalTo(247)
                make.height.equalTo(74)
                make.center.equalToSuperview()
            }

            iconBackgroundView.isHidden = true

            iconView.image = Resources.appIcon
            iconView.snp.makeConstraints { make in
                make.left.equalTo(26)
                make.top.equalTo(24)
                make.width.height.equalTo(14)
            }

            textLabel.snp.makeConstraints { make in
                make.centerX.equalTo(dialogBox)
                make.top.equalTo(46)
                make.width.equalTo(227)
            }

            desView.snp.makeConstraints { make in
                make.top.equalTo(67)
                make.width.equalTo(227)
                make.height.equalTo(11)
                make.centerX.equalTo(dialogBox)
            }

        case .bot:

            dialogBox.snp.makeConstraints { make in
                make.width.equalTo(215)
                make.height.equalTo(74)
                make.top.equalTo(16)
                make.left.equalTo(48)
            }

            insertSubview(bannerTipView, belowSubview: textLabel)
            bannerTipView.backgroundColor = UIColor.ud.indigo
            let rounded = UIBezierPath(roundedRect: CGRect(origin: .zero, size: CGSize(width: 213, height: 24)),
                                       byRoundingCorners: [.topLeft, .topRight],
                                       cornerRadii: CGSize(width: 4.0, height: 4.0))
            let shaper = CAShapeLayer()
            shaper.path = rounded.cgPath
            bannerTipView.layer.mask = shaper
            bannerTipView.snp.makeConstraints { make in
                make.top.left.width.equalTo(dialogBox).inset(1)
                make.height.equalTo(24)
            }

            iconBackgroundView.isHidden = false
            iconBackgroundView.snp.makeConstraints { make in
                make.left.top.equalTo(16)
                make.width.height.equalTo(24)
            }

            iconView.image = UDIcon.mailFilled.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = .ud.staticWhite
            iconView.snp.makeConstraints { make in
                make.center.equalTo(iconBackgroundView.snp.center)
                make.width.height.equalTo(12)
            }

            textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            textLabel.snp.makeConstraints { make in
                make.centerX.equalTo(dialogBox)
                make.top.equalTo(22)
                make.width.equalTo(195)
            }

            desView.snp.makeConstraints { make in
                make.top.equalTo(48)
                make.width.equalTo(195)
                make.height.equalTo(11)
                make.centerX.equalTo(dialogBox)
            }

            desEndView.backgroundColor = UIColor.ud.N200
            desEndView.cornerRadius = 4
            desEndView.cornerSmoothness = .natural
            addSubview(desEndView)
            desEndView.snp.makeConstraints { make in
                make.top.equalTo(desView.snp.bottom).offset(8)
                make.left.equalTo(desView)
                make.width.equalTo(85)
                make.height.equalTo(11)
            }

        @unknown default:
            break
        }

    }
}
