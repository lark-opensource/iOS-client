//
//  UILabel+Factory.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/24.
//  Copyright © 2017年 EE. All rights reserved.
//

// Included OSS: YKUtils
// Copyright © 2019年 zqyou.
// spdx license identifier: MIT License

import UIKit

extension UILabel {
    public var isTruncated: Bool {
        guard let labelText = text else {
            return false
        }

        // 计算理论上显示所有文字需要的尺寸
        let rect = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let labelTextSize = (labelText as NSString)
            .boundingRect(with: rect, options: .usesLineFragmentOrigin,
                          attributes: [NSAttributedString.Key.font: self.font as Any],
                          context: nil)

        // 计算理论上需要的行数
        let labelTextLines = Int(ceil(CGFloat(labelTextSize.height) / self.font.lineHeight))

        // 实际可显示的行数
        var labelShowLines = Int(floor(CGFloat(bounds.size.height) / self.font.lineHeight))
        if self.numberOfLines != 0 {
            labelShowLines = min(labelShowLines, self.numberOfLines)
        }

        // 比较两个行数来判断是否需要截断
        return labelTextLines > labelShowLines
    }
}

extension CalendarExtension where BaseType == UILabel {

    /// mediumFont
    ///
    /// - Parameter fontSize: default 22
    /// - Returns: mediumFont
    public static func titleLabel(fontSize: CGFloat = 22.0) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.mediumFont(ofSize: fontSize)
        return label
    }

    /// regularFont
    public static func textLabel(fontSize: CGFloat = 16.0) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.regularFont(ofSize: fontSize)
        return label
    }

    /// - Parameter fontSize: default 14
    /// - Returns: regularFont
    public static func subTitleLabel(fontSize: CGFloat = 14.0) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.cd.regularFont(ofSize: fontSize)
        return label
    }
}
