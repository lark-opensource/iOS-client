//
//  Resources.swift
//  LarkListItem
//
//  Created by 姚启灏 on 2020/7/10.
//

import UIKit
import Foundation
import UniverseDesignIcon

public struct Resources {
    public static let timeZone = UDIcon.getIconByKey(.timeFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    public static let verticalLineImage = getVerticalLineImage()

    private static func getVerticalLineImage() -> UIImage {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16)
        let view = UIView()
        view.frame = CGRect(x: 0, y: 2, width: 1, height: 12)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(view)
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        containerView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
