//
//  MeetingLiveView.swift
//  ByteView
//
//  Created by chentao on 2020/4/22.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import UIKit

class MeetingLiveView: BaseInMeetStatusView {

    struct Layout {
        static let IconSize: CGFloat = 12.0
        static let IconRightOffset: CGFloat = 2.0
        static let IconSizeWithoutText: CGFloat = 12.0
    }

    private let liveIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.getIconByKey(.livestreamFilled, iconColor: UIColor.ud.functionDangerFillDefault, size: CGSize(width: Layout.IconSize, height: Layout.IconSize))
        return icon
    }()

    private var liveNumLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(liveIcon)
        addSubview(liveNumLabel)
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout() {
        if shouldHiddenForOmit {
            liveNumLabel.isHiddenInStackView = true
            liveIcon.image = UDIcon.getIconByKey(.livestreamFilled, iconColor: UIColor.ud.functionDangerFillDefault, size: CGSize(width: Layout.IconSizeWithoutText, height: Layout.IconSizeWithoutText))
            liveIcon.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            liveNumLabel.isHiddenInStackView = false
            liveIcon.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview()
            }

            liveNumLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.height.equalTo(13.0)
                maker.left.equalTo(liveIcon.snp.right).offset(Layout.IconRightOffset)
                maker.right.equalToSuperview()
            }
        }
    }

    func setLabel(_ text: String) {
        liveNumLabel.text = text
    }
    func setIcon(_ icon: UIImage?) {
        guard let image = icon else { return }
        liveIcon.image = image
    }
}

class FloatingLiveView: UIView {

    let liveLabel: UILabel = {
        var label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        label.text = I18n.View_MV_Live_StatusTopBar
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    override var intrinsicContentSize: CGSize {
        let labelWidth = liveLabel.intrinsicContentSize.width
        let width = labelWidth + 8.0
        let height = 16.0
        return CGSize(width: width, height: height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.colorfulRed
        layer.cornerRadius = 6.0
        layer.masksToBounds = true

        addSubview(liveLabel)
        liveLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.right.equalToSuperview().inset(4.0)
        }
    }
}
