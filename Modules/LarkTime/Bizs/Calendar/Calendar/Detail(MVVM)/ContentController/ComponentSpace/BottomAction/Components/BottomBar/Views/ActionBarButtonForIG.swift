//
//  ActionBarButton.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/9/13.
//

import UIKit
import Foundation
import LarkInteraction
import UniverseDesignIcon

final class ActionBarButtonForIG: UIButton {

    func setupButton(with type: ButtonType) {

        layer.borderWidth = 1
        layer.cornerRadius = 6
        semanticContentAttribute = .forceRightToLeft

        let config = type.getContent()
        let highlightedColor = config.style.contentColor.withAlphaComponent(0.4)
        layer.ud.setBorderColor(config.style.borderColor)
        backgroundColor = config.style.backgroundColor
        setTitleColor(config.style.contentColor, for: .normal)
        setTitleColor(highlightedColor, for: .highlighted)

        setTitle(config.content.titleStr, for: .normal)
        setImage(config.content.icon, for: .normal)
        setImage(config.content.icon?.ud.withTintColor(highlightedColor),
                 for: .highlighted)

        if config.content.icon != nil && config.content.titleStr != nil {
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        }
        titleLabel?.font = UIFont.ud.body0(.fixed)
        if #available(iOS 13.4, *) {
            lkPointerStyle = PointerStyle(
                effect: .lift,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let width = interaction.view?.bounds.width,
                          let height = interaction.view?.bounds.height else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: width, height: height), 8)
                }))
        }
    }

    func startAnimation() {
        guard let icon = self.imageView else { return }
        self.setImage(UDIcon.getIconByKey(.chatLoadingOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault), for: .normal)
        self.isUserInteractionEnabled = false
        startZRotation()
    }

    func stopAnimation() {
        guard let icon = self.imageView else { return }
        icon.layer.removeAllAnimations()
        self.isUserInteractionEnabled = true
        self.setImage(UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 16, height: 16)).renderColor(with: .n2), for: .normal)
    }

    private func startZRotation(duration: CFTimeInterval = 1, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        guard let icon = self.imageView else { return }
        if self.layer.animation(forKey: "transform.rotation.z") != nil {
            return
        }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: Double.pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        icon.layer.add(animation, forKey: "transform.rotation.z")
    }

    struct Style {
        var contentColor = UIColor.ud.textTitle
        var backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        var borderColor = UIColor.ud.lineBorderComponent

        static let iconSize = CGSize(width: 16, height: 16)
    }

    struct Content {
        var titleStr: String?
        var icon: UIImage?
    }

    enum ButtonType {
        case accept
        case reject
        case tentative
        case join

        case hasAccepted
        case hasRejected
        case hasBeenTentative

        case reply

        func getContent() -> (style: Style, content: Content) {
            var style = Style()
            var content = Content()
            switch self {
            case .accept:
                content.titleStr = BundleI18n.Calendar.Calendar_Detail_Accept
            case .reject:
                content.titleStr = BundleI18n.Calendar.Calendar_Detail_Refuse
            case .tentative:
                content.titleStr = BundleI18n.Calendar.Calendar_Detail_Maybe
            case .join:
                content.titleStr = BundleI18n.Calendar.Calendar_Share_Join
            case .hasAccepted:
                style.backgroundColor = UIColor.ud.functionSuccessFillTransparent01
                style.borderColor = UIColor.ud.functionSuccessContentDefault
                style.contentColor = UIColor.ud.functionSuccessContentDefault
                content.titleStr = BundleI18n.Calendar.Calendar_Detail_Accepted
                content.icon = UDIcon.getIconByKey(.downOutlined, iconColor: style.contentColor, size: Style.iconSize)
            case .hasRejected:
                style.backgroundColor = UIColor.ud.functionDangerFillTransparent01
                style.borderColor = UIColor.ud.functionDangerContentDefault
                style.contentColor = UIColor.ud.functionDangerContentDefault
                content.titleStr = BundleI18n.Calendar.Calendar_Detail_Refused
                content.icon = UDIcon.getIconByKey(.downOutlined, iconColor: style.contentColor, size: Style.iconSize)
            case .hasBeenTentative:
                style.backgroundColor = UIColor.ud.N50
                style.borderColor = UIColor.ud.N500
                style.contentColor = UIColor.ud.textTitle
                content.titleStr = BundleI18n.Calendar.Calendar_Legacy_EventInvitationReplyMaybe_Dropdown
                content.icon = UDIcon.getIconByKey(.downOutlined, iconColor: style.contentColor, size: Style.iconSize)
            case .reply:
                style.contentColor = UIColor.ud.iconN2
                content.icon = UDIcon.getIconByKey(.replyCnOutlined, iconColor: style.contentColor, size: Style.iconSize)
            }
            return (style, content)
        }
    }

}
