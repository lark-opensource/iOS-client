//
//  MeetingRoomArrangementDetailView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/8.
//

import UniverseDesignIcon
import UIKit
import LarkZoomable

final class MeetingRoomArrangementDetailView: UIView, ViewDataConvertible {
    var viewData: MeetingRoomCheckInResponseModel? {
        didSet {
            isHidden = (viewData == nil)
        }
    }

    var didTapped: ((MeetingRoomCheckInResponseModel) -> Void)?

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heading3
        label.text = BundleI18n.Calendar.Calendar_MeetingRoom_ViewMeetingRoomAvailabilityButton
        label.textColor = UIColor.ud.textTitle
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var detailIndicatorView: UIImageView = {
        let image = UDIcon.getIconByKeyNoLimitSize(.rightOutlined).withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = UIColor.ud.iconN2
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        backgroundColor = UIColor.ud.bgBody

        addSubview(titleLabel)
        addSubview(detailIndicatorView)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.top.equalTo(snp.topMargin)
            make.centerYWithinMargins.equalToSuperview()
        }

        detailIndicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalTo(snp.trailingMargin)
            make.width.height.equalTo(24)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func tapped() {
        if let model = viewData {
            didTapped?(model)
        }
    }
}
