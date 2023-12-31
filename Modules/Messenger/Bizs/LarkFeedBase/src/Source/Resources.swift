//
//  Resources.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/11.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import CoreGraphics

public final class Resources {
    public final class LarkFeedBase {
        static let feedTeamOutline = UDIcon.getIconByKey(.belongOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN3)
        static let feedAlertsOff = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN3)
        static let pinNotifyClock = UDIcon.getIconByKey(.bellOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let pinNotifyClockClose = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let slideAlertsOffIcon = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 18, height: 18))
            .ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        static let slideBellIcon = UDIcon.getIconByKey(.bellOutlined, size: CGSize(width: 18, height: 18))
            .ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        // TODO: open feed 这些写明的数字跟组件里的布局是否强关联
        public static let avatarBorderWidth: CGFloat = 3
        public static let urgentBorderImage = createCircleImage(radius: FeedCardAvatarComponentView.Cons.borderSize,
                                                                borderWidth: LarkFeedBase.avatarBorderWidth,
                                                        borderColor: UDColor.R500)
        static let badge_at_icon = UDIcon.getIconByKey(.atOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        public static let atAllImage = createCircleImage(radius: Cons.radius,
                                                         borderWidth: Cons.borderWidth,
                                                         borderColor: UIColor.ud.rgb(0x3370FF),
                                                         lineDashPattern: [Cons.lineDashPattern, Cons.lineDashPattern])
        public static let atMeImage = createCircleImage(radius: Cons.radius,
                                                        borderWidth: Cons.borderWidth,
                                                        borderColor: UIColor.ud.rgb(0x3377FF))
    }

    enum Cons {
        static let radius: CGFloat = 13
        static let borderWidth: CGFloat = 1.5
        static let lineDashPattern: CGFloat = 2.5
    }

    static func createCircleImage(radius: CGFloat, borderWidth: CGFloat, borderColor: UIColor, lineDashPattern: [CGFloat]? = nil) -> UIImage {
        // 计算圆环视图的尺寸
        let size = CGSize(width: radius * 2 + borderWidth * 2, height: radius * 2 + borderWidth * 2)

        // 创建图像上下文
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }

        // 设置线条样式
        context.setLineWidth(borderWidth)
        context.setLineCap(.round)
        if let lineDashPattern = lineDashPattern {
            context.setLineDash(phase: 0, lengths: lineDashPattern)
        }

        // 设置描边颜色
        context.setStrokeColor(borderColor.cgColor)

        // 创建圆环路径
        let circlePath = UIBezierPath(ovalIn: CGRect(x: borderWidth / 2, y: borderWidth / 2, width: size.width - borderWidth, height: size.height - borderWidth))

        // 绘制圆环路径
        context.addPath(circlePath.cgPath)
        context.strokePath()

        // 从图像上下文获取图像
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }
}
