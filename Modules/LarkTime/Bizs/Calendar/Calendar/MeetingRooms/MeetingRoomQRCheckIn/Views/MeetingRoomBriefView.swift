//
//  MeetingRoomBriefView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/7.
//

import UniverseDesignIcon
import UIKit
import LarkZoomable

final class MeetingRoomBriefView: UIView, ViewDataConvertible {
    var viewData: (Rust.MeetingRoom, Rust.Building)? {
        didSet {
            guard let viewData = viewData else { return }
            if viewData.0.displayType == .hierarchical,
               viewData.0.resourceNameWithLevelInfo.count == 2 {
                nameLabel.text = viewData.0.resourceNameWithLevelInfo[0]
                positionLabel.text = viewData.0.resourceNameWithLevelInfo[1]
            } else {
                nameLabel.text = "\(viewData.0.floorName)-\(viewData.0.name)"
                positionLabel.text = viewData.1.name
            }
        }
    }

    private(set) lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heading3.bold()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private(set) lazy var positionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body2
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var detailIndicatorView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return imageView
    }()

    private lazy var sepLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        view.alpha = 0.3
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        addSubview(nameLabel)
        addSubview(positionLabel)
        addSubview(detailIndicatorView)
        addSubview(sepLineView)

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.top.equalTo(snp.topMargin)
        }

        positionLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.trailing.equalTo(nameLabel.snp.trailing)
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.bottom.equalTo(snp.bottomMargin)
        }

        detailIndicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(snp.centerYWithinMargins)
            make.leading.equalTo(nameLabel.snp.trailing).offset(10)
            make.trailing.equalTo(snp.trailingMargin)
            make.width.height.equalTo(16)
        }

        sepLineView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin).offset(-4)
            make.centerX.equalTo(snp.centerXWithinMargins)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
