//
//  UIImageUtils.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2021/3/12.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    public class func imageWithColor(_ color: UIColor) -> UIImage {

        let rect = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }
}
