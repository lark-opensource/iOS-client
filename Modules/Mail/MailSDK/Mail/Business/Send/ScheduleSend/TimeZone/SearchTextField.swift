//
//  TimeZoneSearchBar.swift
//  Calendar
//
//  Created by 张威 on 2020/1/19.
//

import UniverseDesignIcon
import UIKit
import LarkUIKit
import RxCocoa
import RxSwift

class SearchTextField: BaseTextField {

    static let desiredHeight: CGFloat = 34

    static let iconSize = CGSize(width: 16, height: 16)

    private let iconImageView: UIImageView

    override init(frame: CGRect) {
        iconImageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.searchOutlined).renderColor(with: .n3))
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBodyOverlay
        font = UIFont.systemFont(ofSize: 14)
        tintColor = UIColor.ud.primaryContentDefault
        textColor = UIColor.ud.textTitle
        layer.masksToBounds = true
        layer.cornerRadius = 4
        borderStyle = .none
        clearButtonMode = .always
        exitOnReturn = true

        let leftView = UIView()
        leftView.addSubview(iconImageView)
        leftViewMode = .always
        self.leftView = leftView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.frame = CGRect(
            origin: CGPoint(x: 8, y: (bounds.height - Self.iconSize.height) / 2),
            size: Self.iconSize
        )
        leftView?.frame = CGRect(x: 0, y: 0, width: iconImageView.frame.maxX + 7, height: bounds.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.desiredHeight)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.desiredHeight)
    }
}
