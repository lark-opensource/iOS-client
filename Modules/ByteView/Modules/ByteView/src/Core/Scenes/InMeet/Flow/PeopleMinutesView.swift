//
//  PeopleMinutesView.swift
//  ByteView
//
//  Created by Shuai Zipei on 2023/3/22.
//

import UIKit
import Foundation
import UniverseDesignIcon

class PeopleMinutesView: BaseInMeetStatusView {
    struct Layout {
        static let IconSize: CGFloat = 12.0
        static let IconRightOffset: CGFloat = 2.0
        static let IconSizeWithoutText: CGFloat = 12.0
    }

    private let peopleMinutesIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.getIconByKey(.voice2textFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: Layout.IconSize, height: Layout.IconSize))
        return icon
    }()

    private let peopleMinutesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.textColor = UIColor.ud.textTitle
        label.text = I18n.View_MV_WrittenRecord
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(peopleMinutesIcon)
        addSubview(peopleMinutesLabel)
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout() {
        if shouldHiddenForOmit {
            peopleMinutesLabel.isHidden = true
            peopleMinutesIcon.image = UDIcon.getIconByKey(.voice2textFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: Layout.IconSizeWithoutText, height: Layout.IconSizeWithoutText))
            peopleMinutesIcon.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            peopleMinutesLabel.isHidden = false
            peopleMinutesIcon.image = UDIcon.getIconByKey(.voice2textFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: Layout.IconSize, height: Layout.IconSize))
            peopleMinutesIcon.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview()
            }

            peopleMinutesLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.height.equalTo(13.0)
                maker.left.equalTo(peopleMinutesIcon.snp.right).offset(Layout.IconRightOffset)
                maker.right.equalToSuperview()
            }
        }
    }

    func setLabel(_ text: String) {
        peopleMinutesLabel.text = text
    }

    func setIcon(_ icon: UIImage?) {
        guard let image = icon else { return }
        peopleMinutesIcon.image = image
    }
}
