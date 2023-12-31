//
//  LockedView.swift
//  ByteView
//
//  Created by wulv on 2022/3/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignIcon

class LockedView: BaseInMeetStatusView {

    struct Layout {
        static let IconSize: CGFloat = 12.0
        static let IconRightOffset: CGFloat = 2.0
        static let IconSizeWithoutText: CGFloat = 12.0
    }

    private let lockedIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.getIconByKey(.lockFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: Layout.IconSize, height: Layout.IconSize))
        return icon
    }()

    private let lockedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.textColor = UIColor.ud.textTitle
        label.text = I18n.View_MV_Locked_Sign
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(lockedIcon)
        addSubview(lockedLabel)
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout() {
        if shouldHiddenForOmit {
            lockedLabel.isHidden = true
            lockedIcon.image = UDIcon.getIconByKey(.lockFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: Layout.IconSizeWithoutText, height: Layout.IconSizeWithoutText))
            lockedIcon.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            lockedLabel.isHidden = false
            lockedIcon.image = UDIcon.getIconByKey(.lockFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: Layout.IconSize, height: Layout.IconSize))
            lockedIcon.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview()
            }

            lockedLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.height.equalTo(13.0)
                maker.left.equalTo(lockedIcon.snp.right).offset(Layout.IconRightOffset)
                maker.right.equalToSuperview()
            }
        }
    }
    func setLabel(_ text: String) {
        lockedLabel.text = text
    }

    func setIcon(_ icon: UIImage?) {
        guard let image = icon else { return }
        lockedIcon.image = image
    }
}
