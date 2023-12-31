//
//  FeedCardComponentUtils.swift
//  LarkFeedBase
//
//  Created by xiaruzhen on 2023/9/3.
//

import Foundation

public extension UIImage {
    static func verticalLineinMiddle(rectSize: CGSize,
                                     rectColor: UIColor,
                                     lineSize: CGSize,
                                     lineColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(rectSize, false /* opaque */, UIScreen.main.scale /* scale */)
        defer { UIGraphicsEndImageContext() }
        var rectPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: rectSize.width, height: rectSize.height), cornerRadius: 0)
        rectColor.setFill()
        rectPath.fill()
        let linePath = UIBezierPath(roundedRect: CGRect(x: rectSize.width / 2, y: (rectSize.height - lineSize.height) / 2, width: lineSize.width, height: lineSize.height), cornerRadius: 0)
        lineColor.setFill()
        linePath.fill()
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
