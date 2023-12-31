//
//  DateFilterNaviBar.swift
//  LarkSearch
//
//  Created by SuPeng on 4/19/19.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignFont

public protocol DateFilterNaviBarDelegate: AnyObject {
    func naviBarDidClickCloseButton(_ naviBar: DateFilterNaviBar)
    func naviBarDidClickFinishButton(_ naviBar: DateFilterNaviBar)
}

public final class DateFilterNaviBar: UIView {
    public weak var delegate: DateFilterNaviBarDelegate?

    public let closeButton = UIButton()
    private let titleLabel = UILabel()
    private let finishButton = UIButton()

    public init(style: DateFilerItemViewStyle) {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgFloat
        clipsToBounds = true
        layer.cornerRadius = 12
        let corner: UIRectCorner = [.topLeft, .topRight]
        layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)

        closeButton.setImage(LarkUIKit.Resources.navigation_close_light.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = UIColor.ud.iconN1
        closeButton.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        closeButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(closeButton)

        titleLabel.font = UDFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(titleLabel)

        finishButton.setTitle(BundleI18n.LarkSearchFilter.Lark_Legacy_Finished, for: .normal)
        finishButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonDidClick), for: .touchUpInside)
        finishButton.titleLabel?.font = UDFont.systemFont(ofSize: 16)
        finishButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(finishButton)

        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }

        finishButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualTo(closeButton.snp.right)
            make.right.lessThanOrEqualTo(finishButton.snp.left)
        }

        lu.addBottomBorder()

        set(style: style)
    }

    public func set(style: DateFilerItemViewStyle) {
        switch style {
        case .left:
            titleLabel.text = BundleI18n.LarkSearchFilter.Lark_Search_SelectStartTime
        case .right:
            titleLabel.text = BundleI18n.LarkSearchFilter.Lark_Search_SelectEndTime
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func closeButtonDidClick() {
        delegate?.naviBarDidClickCloseButton(self)
    }

    @objc
    private func finishButtonDidClick() {
        delegate?.naviBarDidClickFinishButton(self)
    }
}
