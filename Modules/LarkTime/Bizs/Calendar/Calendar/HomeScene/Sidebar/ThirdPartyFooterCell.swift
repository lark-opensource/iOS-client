//
//  ThirdPartyFooterCell.swift
//  Calendar
//
//  Created by huoyunjie on 2021/8/17.
//

import UniverseDesignIcon
import Foundation
import UIKit

struct SidebarFooterViewData {
    var isHidden: Bool = true// 是否展示底部设置
    var accountValid: Bool = true// 账户是否有效
    var accountExpiring: Bool = false// 账户是否过期
}

final class ThirdPartyFooterCell: UIView {

    var tapCallback: (() -> Void)?

    var accountValid: Bool {
        didSet {
            warningLabel.isHidden = accountValid
            warningIcon.isHidden = accountValid
        }
    }

    var accountExpiring: Bool {
        didSet {
            if accountValid {
                warningLabel.text = accountExpiring ? BundleI18n.Calendar.Calendar_Ex_AccountExpireSoon : BundleI18n.Calendar.Calendar_Sync_SyncExpiredShort
                warningLabel.isHidden = !accountExpiring
                warningIcon.isHidden = !accountExpiring
            }
        }
    }

    override init(frame: CGRect) {
        self.accountValid = true
        self.accountExpiring = false
        super.init(frame: frame)
        layoutUI()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.width.lessThanOrEqualTo(170)
        }

        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(accessArrow)
        accessArrow.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.right.equalTo(-16)
        }

        addSubview(warningLabel)
        warningLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(accessArrow)
            make.trailing.equalTo(accessArrow.snp.leading).offset(-4)
        }

        addSubview(warningIcon)
        warningIcon.snp.makeConstraints { (make) in
            make.centerY.equalTo(warningLabel)
            make.trailing.equalTo(warningLabel.snp.leading).offset(-4)
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
        }

        warningIcon.setContentCompressionResistancePriority(.required, for: .horizontal)

        addBottomBorder(inset: .zero, lineHeight: 0.5)
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.text = BundleI18n.Calendar.Calendar_GoogleCal_AccountManagement
        return label
    }()

    private let accessArrow: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))
        return imageView
    }()

    private let warningLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.text = BundleI18n.Calendar.Calendar_Sync_SyncExpiredShort
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.numberOfLines = 1
        return label
    }()

    private let warningIcon: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.warningOutlined).scaleInfoSize().ud.withTintColor(UIColor.ud.colorfulRed))
        return imageView
    }()

    @objc
    private func tap() {
        self.tapCallback?()
    }
}
