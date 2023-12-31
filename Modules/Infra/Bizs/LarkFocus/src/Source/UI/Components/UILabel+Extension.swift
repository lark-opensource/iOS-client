//
//  UILabel+Extension.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/20.
//

import Foundation
import UIKit

public extension UILabel {

    /// 判断 UILabel 的文字是否被截断
    var isTruncated: Bool {

        guard let labelText = text else {
            return false
        }

        let labelTextSize = (labelText as NSString).boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil).size

        return labelTextSize.height > bounds.size.height
    }
}
