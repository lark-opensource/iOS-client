//
//  TagType.swift
//  TangramService
//
//  Created by 袁平 on 2021/7/12.
//

import UIKit
import Foundation
import UniverseDesignColor

public enum TagType {
    case normal
    case link

    public var textColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.udtokenTagNeutralTextNormal
        case .link:
            return UIColor.ud.udtokenTagTextSBlue
        }
    }

    public var backgroundColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.udtokenTagNeutralBgNormal
        case .link:
            return UIColor.ud.udtokenTagBgBlue
        }
    }
}

final class PaddingUILabel: UILabel {
    static let defaultPadding = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)

    var padding = UIEdgeInsets.zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: padding.left + size.width + padding.right,
                      height: padding.top + size.height + padding.bottom)
    }

    static func sizeToFit(text: String, font: UIFont, padding: UIEdgeInsets = PaddingUILabel.defaultPadding) -> CGSize {
        let size = NSString(string: text).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
                                                       options: .usesLineFragmentOrigin,
                                                       attributes: [.font: font],
                                                       context: nil).size
        return CGSize(width: size.width + padding.left + padding.right, height: size.height + padding.top + padding.bottom)
    }
}
