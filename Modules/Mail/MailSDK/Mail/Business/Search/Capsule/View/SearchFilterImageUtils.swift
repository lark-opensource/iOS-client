//
//  SearchFilterImageUtils.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/16.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

public final class MailSearchFilterImageUtils {
    public static func generateAvatarImage(withNameString title: String, length: Int = 1, bgColor: UIColor = .ud.primaryContentDefault) -> UIImage? {
        guard length > 0, !title.isEmpty else { return nil }
        var avatarString: String = ""
        if title.count > length {
            avatarString = title.substring(to: length)
        } else {
            avatarString = title
        }
        var attribute = [NSAttributedString.Key: Any]()
        attribute[NSAttributedString.Key.foregroundColor] = UIColor.ud.primaryOnPrimaryFill
        attribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 20)
        let nameString = NSAttributedString(string: avatarString, attributes: attribute)
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
}
