//
//  UIImage+Calendar.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/14.
//  Copyright © 2017年 EE. All rights reserved.
//

import UIKit
import LarkTag
import UniverseDesignTheme
import UniverseDesignIcon
import LarkUIKit

extension UIImage: CalendarExtensionCompatible {
    /// 抗锯齿 加一个像素的边框 image也同时变大了
    public func antiAlias() -> UIImage {
        let rect = CGRect(x: 1,
                          y: 1,
                          width: self.size.width,
                          height: self.size.height)
        let size = CGSize(width: self.size.width + 2,
                          height: self.size.height + 2)
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: rect)
        }
    }

    // image with rounded corners
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        return UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            draw(in: rect)
        }
    }
}

extension CalendarExtension where BaseType == UIImage {
    public static func image(named: String) -> UIImage {
        let image = UIImage(named: named, in: Config.CalendarBundle, compatibleWith: nil)
        assertLog(image != nil)
        return image ?? UIImage()
    }

    public static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            assertionFailureLog()
            return UIImage()
        }
        context.setFillColor(color.cgColor)
        context.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    public static func currentTabSelectedImage(uiCurrentDate: Date = Date()) -> UIImage {
        switch uiCurrentDate.day {
        case 1: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar1Colorful)
        case 2: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar2Colorful)
        case 3: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar3Colorful)
        case 4: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar4Colorful)
        case 5: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar5Colorful)
        case 6: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar6Colorful)
        case 7: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar7Colorful)
        case 8: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar8Colorful)
        case 9: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar9Colorful)
        case 10: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar10Colorful)
        case 11: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar11Colorful)
        case 12: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar12Colorful)
        case 13: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar13Colorful)
        case 14: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar14Colorful)
        case 15: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar15Colorful)
        case 16: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar16Colorful)
        case 17: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar17Colorful)
        case 18: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar18Colorful)
        case 19: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar19Colorful)
        case 20: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar20Colorful)
        case 21: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar21Colorful)
        case 22: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar22Colorful)
        case 23: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar23Colorful)
        case 24: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar24Colorful)
        case 25: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar25Colorful)
        case 26: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar26Colorful)
        case 27: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar27Colorful)
        case 28: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar28Colorful)
        case 29: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar29Colorful)
        case 30: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar30Colorful)
        case 31: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar31Colorful)
        default: return UDIcon.getIconByKeyNoLimitSize(.tabCalendar1Colorful)
        }
    }

    public static func currentTabUnSelectedImage(uiCurrentDate: Date = Date()) -> UIImage {
        switch uiCurrentDate.day {
        case 1: return UDIcon.getIconByKeyNoLimitSize(.calendar1Filled)
        case 2: return UDIcon.getIconByKeyNoLimitSize(.calendar2Filled)
        case 3: return UDIcon.getIconByKeyNoLimitSize(.calendar3Filled)
        case 4: return UDIcon.getIconByKeyNoLimitSize(.calendar4Filled)
        case 5: return UDIcon.getIconByKeyNoLimitSize(.calendar5Filled)
        case 6: return UDIcon.getIconByKeyNoLimitSize(.calendar6Filled)
        case 7: return UDIcon.getIconByKeyNoLimitSize(.calendar7Filled)
        case 8: return UDIcon.getIconByKeyNoLimitSize(.calendar8Filled)
        case 9: return UDIcon.getIconByKeyNoLimitSize(.calendar9Filled)
        case 10: return UDIcon.getIconByKeyNoLimitSize(.calendar10Filled)
        case 11: return UDIcon.getIconByKeyNoLimitSize(.calendar11Filled)
        case 12: return UDIcon.getIconByKeyNoLimitSize(.calendar12Filled)
        case 13: return UDIcon.getIconByKeyNoLimitSize(.calendar13Filled)
        case 14: return UDIcon.getIconByKeyNoLimitSize(.calendar14Filled)
        case 15: return UDIcon.getIconByKeyNoLimitSize(.calendar15Filled)
        case 16: return UDIcon.getIconByKeyNoLimitSize(.calendar16Filled)
        case 17: return UDIcon.getIconByKeyNoLimitSize(.calendar17Filled)
        case 18: return UDIcon.getIconByKeyNoLimitSize(.calendar18Filled)
        case 19: return UDIcon.getIconByKeyNoLimitSize(.calendar19Filled)
        case 20: return UDIcon.getIconByKeyNoLimitSize(.calendar20Filled)
        case 21: return UDIcon.getIconByKeyNoLimitSize(.calendar21Filled)
        case 22: return UDIcon.getIconByKeyNoLimitSize(.calendar22Filled)
        case 23: return UDIcon.getIconByKeyNoLimitSize(.calendar23Filled)
        case 24: return UDIcon.getIconByKeyNoLimitSize(.calendar24Filled)
        case 25: return UDIcon.getIconByKeyNoLimitSize(.calendar25Filled)
        case 26: return UDIcon.getIconByKeyNoLimitSize(.calendar26Filled)
        case 27: return UDIcon.getIconByKeyNoLimitSize(.calendar27Filled)
        case 28: return UDIcon.getIconByKeyNoLimitSize(.calendar28Filled)
        case 29: return UDIcon.getIconByKeyNoLimitSize(.calendar29Filled)
        case 30: return UDIcon.getIconByKeyNoLimitSize(.calendar30Filled)
        case 31: return UDIcon.getIconByKeyNoLimitSize(.calendar31Filled)
        default: return UDIcon.getIconByKeyNoLimitSize(.calendar1Filled)
        }
    }

    public class func verticalGradientImage(fromColor: UIColor, toColor: UIColor, size: CGSize, locations: [CGFloat]) -> UIImage {
        if #available(iOS 13.0, *) {
            // 防止Trait不对
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
            UITraitCollection.current = correctTrait
        }
        return UIGraphicsImageRenderer(size: size).image { context in
            let colorspace = CGColorSpaceCreateDeviceRGB()
            let gradientNumberOfLocations: size_t = 2
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            fromColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            toColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            let gradientComponents = [r1, g1, b1, a1, r2, g2, b2, a2]
            let gradient = CGGradient(colorSpace: colorspace, colorComponents: gradientComponents, locations: locations, count: gradientNumberOfLocations)
            if let gradient = gradient{
                context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions())
            }
        }
    }

    public class func image(withColor color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: cornerRadius)
            color.setFill()
            path.fill()
        }
    }

    public class func externalImageWhite(text: String? = nil, width: CGFloat) -> UIImage {
        let label = TagWrapperView.titleTagView(for: .calendarExternalGrey)
        if let text = text {
            label.text = text
        }
        return draw(label, width: width)
    }

    public class func externalImageOrange() -> UIImage {
        let label = TagWrapperView.titleTagView(for: .external)
        return draw(label)
    }

    private class func draw(_ label: UIView, width: CGFloat? = nil) -> UIImage {
        label.invalidateIntrinsicContentSize()
        if let width = width,
           width < label.intrinsicContentSize.width {
            label.frame = CGRect(x: 0, y: 0, width: width, height: 16)
        } else {
            label.frame = CGRect(x: 0, y: 0, width: label.intrinsicContentSize.width, height: 16)
        }
        label.layoutIfNeeded()
        label.setNeedsLayout()
        let size = CGSize(width: label.frame.width, height: 16)
        return UIGraphicsImageRenderer(size: size).image { context in
            label.layer.allowsEdgeAntialiasing = true
            label.layer.render(in: context.cgContext)
        }
    }
}
