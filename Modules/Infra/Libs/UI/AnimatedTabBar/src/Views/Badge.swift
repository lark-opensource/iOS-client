//
//  Badge.swift
//  AnimatedTabBar
//
//  Created by liuwanlin on 2018/9/21.
//

import Foundation
import UIKit
import SnapKit

extension Badge {
    enum Layout {
        static let defaultSize: CGSize = CGSize(width: 16.0, height: 16.0)
        static let defaultSmallSize: CGSize = CGSize(width: 12.0, height: 12.0)
    }
    enum Style {
        static let defaultFont: UIFont = .systemFont(ofSize: 12.0, weight: .medium)
        static let defaultColor: UIColor = UIColor.ud.colorfulRed
    }
}

final class Badge: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        text = ""
        font = Style.defaultFont
        layer.backgroundColor = Style.defaultColor.cgColor
        textColor = .white
        textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += 10.0
        return contentSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2
    }
}
