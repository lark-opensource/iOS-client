//
//  PickerUtils.swift
//  LarkSearchCore
//
//  Created by Patrick on 2021/12/22.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

public final class SearchImageUtils {
    // nolint: duplicated_code 生成图片的逻辑不同
    public static func generateAvatarImage(withNameString string: String, bgColor: UIColor = .ud.primaryContentDefault) -> UIImage? {
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.ud.primaryOnPrimaryFill
        attribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 20)
        let nameString = NSAttributedString(string: string, attributes: attribute)
        let stringSize = nameString.boundingRect(with: CGSize(width: 100.0, height: 100.0),
                                                 options: .usesLineFragmentOrigin,
                                                 context: nil)
        let padding: CGFloat = 8.0    // 10.0
        let width = max(stringSize.width, stringSize.height) + padding * 2
        let size = CGSize(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                cornerRadius: size.width / 2.0)
        bgColor.setFill()
        path.fill()
        nameString.draw(at: CGPoint(x: (size.width - stringSize.width) / 2.0,
                                    y: (size.height - stringSize.height) / 2.0))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    // enable-lint: duplicated_code

    public static func generateAvatarImage(withTitle title: String, length: Int = 1, bgColor: UIColor = .ud.primaryContentDefault) -> UIImage? {
        guard length > 0 else { return nil }
        var avatarString: String = ""
        if title.count > length {
            avatarString = title.substring(to: length)
        } else {
            avatarString = title
        }
        return generateAvatarImage(withNameString: avatarString, bgColor: bgColor)
    }

}
