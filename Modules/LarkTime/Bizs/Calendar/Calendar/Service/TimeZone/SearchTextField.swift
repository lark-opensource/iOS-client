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
import UniverseDesignColor

final class SearchTextField: BaseTextField {
    private var clearBtnBackgroundImage: UIImage?

    static let desiredHeight: CGFloat = 34

    static let iconSize = CGSize(width: 16, height: 16)

    private let iconImageView: UIImageView

    override init(frame: CGRect) {
        iconImageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.searchOutlined).renderColor(with: .n3))
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgFiller
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
        leftView?.frame = CGRect(x: 0, y: 0, width: iconImageView.frame.maxX + 4, height: bounds.height)
        
        // 设置clear按钮
        for view in subviews {
            if view is UIButton {
                guard let button = view as? UIButton else { continue }
                if let image = button.image(for: .highlighted) {
                    if self.clearBtnBackgroundImage == nil {
                        clearBtnBackgroundImage = image.ud.withTintColor(UIColor.ud.N500, renderingMode: .alwaysOriginal)
                    }
                    button.frame.size = CGSize(width: 16, height: 16)
                    button.setImage(self.clearBtnBackgroundImage, for: .normal)
                    button.setImage(self.clearBtnBackgroundImage, for: .highlighted)
                }
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.desiredHeight)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.desiredHeight)
    }
}
