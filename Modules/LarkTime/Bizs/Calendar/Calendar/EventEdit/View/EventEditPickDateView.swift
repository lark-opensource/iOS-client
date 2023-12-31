//
//  EventEditPickDateView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/18.
//

import UniverseDesignIcon
import UIKit
import SnapKit

protocol EventEditPickDateViewData {
    var startDate: Date { get }
    var endDate: Date { get }
    var isAllDay: Bool { get }
    var is12HourStyle: Bool { get }
    var timeZone: TimeZone { get }
    // 编辑页是否展示时区信息
    var isShowTimezone: Bool { get }
    var isClickable: Bool { get }
    // 开始时间样式开关
    var startDateShowAIStyle: Bool { get }
    // 截止时间AI样式开关
    var endDateShowAIStyle: Bool { get }
}

final class EventEditPickDateView: UIView, ViewDataConvertible {

    var startClickHandler: (() -> Void)?
    var endClickHandler: (() -> Void)?

    var viewData: EventEditPickDateViewData? {
        didSet {
            if let startDate = viewData?.startDate, let endDate = viewData?.endDate {
                innerDateRangeView.dateRange = (startDate, endDate)
            } else {
                innerDateRangeView.dateRange = nil
            }
            innerDateRangeView.isAllDay = viewData?.isAllDay ?? false
            innerDateRangeView.is12HourStyle = viewData?.is12HourStyle ?? false
            innerDateRangeView.timeZone = viewData?.timeZone ?? TimeZone.current
            // timeZoneLabel.text = viewData?.timeZone.name
            let isClickable = viewData?.isClickable ?? false
            let textColor = isClickable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            innerDateRangeView.startComponents.titleLabel.textColor = textColor
            innerDateRangeView.startComponents.firstSubtitleLabel.textColor = textColor
            innerDateRangeView.startComponents.secondSubtitleLabel.textColor = textColor
            innerDateRangeView.endComponents.titleLabel.textColor = textColor
            innerDateRangeView.endComponents.firstSubtitleLabel.textColor = textColor
            innerDateRangeView.endComponents.secondSubtitleLabel.textColor = textColor
            innerDateRangeView.snp.updateConstraints {
                $0.bottom.equalToSuperview().inset(viewData?.isShowTimezone == true ? 0 : 14)
            }
            innerDateRangeView.startShouldShowAIStyle = viewData?.startDateShowAIStyle ?? false
            innerDateRangeView.endShouldShowAIStyle = viewData?.endDateShowAIStyle ?? false
            iconImageView.image = isClickable ? iconImage : iconImageDisabled
            setNeedsLayout()
        }
    }

    private var innerDateRangeView = EventEditDateRangeBaseView(frame: .zero, config: .init(labelLeftPadding: EventEditUIStyle.Layout.eventEditContentLeftMargin, leftContainerCenterXOffset: -4))
    private let startClickableZoneView = UIView()
    private let endClickableZoneView = UIView()
    private lazy var iconImage = UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n3)
    private lazy var iconImageDisabled = UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n4)
    private lazy var iconImageView = UIImageView(image: iconImage)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        bindAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.ud.bgFloat

        addSubview(innerDateRangeView)
        innerDateRangeView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().inset(viewData?.isShowTimezone == true ? 0 : 14)
            $0.top.equalTo(12)
            $0.height.equalTo(46)
        }

        iconImageView.isUserInteractionEnabled = false
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(EventEditUIStyle.Layout.cellLeftIconSize)
            $0.left.equalToSuperview().offset(16)
            $0.top.equalTo(24)
        }

        addSubview(startClickableZoneView)
        startClickableZoneView.snp.makeConstraints {
            $0.edges.equalTo(innerDateRangeView.startComponents.button)
        }

        addSubview(endClickableZoneView)
        endClickableZoneView.snp.makeConstraints {
            $0.edges.equalTo(innerDateRangeView.endComponents.button)
        }
    }

    private func bindAction() {
        let tap1Gesture = UITapGestureRecognizer()
        tap1Gesture.addTarget(self, action: #selector(handleStartClick))
        startClickableZoneView.addGestureRecognizer(tap1Gesture)

        let tap2Gesture = UITapGestureRecognizer()
        tap2Gesture.addTarget(self, action: #selector(handleEndClick))
        endClickableZoneView.addGestureRecognizer(tap2Gesture)
    }

    @objc
    private func handleStartClick() {
        startClickHandler?()
    }

    @objc
    private func handleEndClick() {
        endClickHandler?()
    }

}
