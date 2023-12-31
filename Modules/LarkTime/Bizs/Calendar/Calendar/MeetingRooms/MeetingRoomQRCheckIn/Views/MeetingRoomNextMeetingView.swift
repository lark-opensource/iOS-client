//
//  MeetingRoomNextMeetingView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/9.
//

import UniverseDesignIcon
import UIKit
import LarkZoomable
import LarkTimeFormatUtils
import CalendarFoundation

final class MeetingRoomNextMeetingView: UIView, ViewDataConvertible {

    var viewData: (MeetingRoomCheckInResponseModel.InstanceWithInfo, MeetingRoomCheckInResponseModel.Strategy, Rust.MeetingRoom)? {
        didSet {
            guard let viewData = viewData else {
                assertionFailure()
                return
            }

            titleLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_NextMeeting

            let (instance, info) = viewData.0

            let start = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
            let end = Date(timeIntervalSince1970: TimeInterval(instance.endTime))

            var option = TimeFormatUtils.defaultOptions
            option.timePrecisionType = .minute
            timeLabel.text = TimeFormatUtils.formatDateTimeRange(startFrom: start, endAt: end, with: option)

            let avatar = MeetingRoomUserInfoView.ViewData(creator: instance.creator)
            userInfoView.viewData = avatar

            var checkInStrategyInMinutes = Int(viewData.1.durationBeforeCheckIn) / 60
            tipsLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_CheckInDescription(number: checkInStrategyInMinutes)

            switch info.status {
            case .alreadyCheckIn:
                fakeCheckInLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_CheckedInTip
                tipsIcon.isHidden = true
                tipsLabel.isHidden = true
            case .userNotAuthorized:
                fakeCheckInLabel.isHidden = true
                tipsIcon.isHidden = true
                tipsLabel.isHidden = true
            case .notCheckIn:
                fakeCheckInLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_WaitForCheckInButton
                tipsIcon.isHidden = false
                tipsLabel.isHidden = false
            @unknown default:
                assertionFailure()
                fakeCheckInLabel.isHidden = true
                tipsIcon.isHidden = true
                tipsLabel.isHidden = true
                break
            }

            invalidLabel.isHidden = true
            if instance.category == .resourceRequisition,
               let resourceRequisition = viewData.2.schemaExtraData.cd.resourceRequisition {
                invalidLabel.isHidden = false
                fakeCheckInLabel.isHidden = true
                tipsIcon.isHidden = true
                tipsLabel.isHidden = true
                userInfoView.isHidden = true
                let start = TimeFormatUtils.formatDateTime(from: Date(timeIntervalSince1970: TimeInterval(instance.startTime)), with: .init(timePrecisionType: .minute))
                let end = TimeFormatUtils.formatDateTime(from: Date(timeIntervalSince1970: TimeInterval(instance.endTime)), with: .init(timePrecisionType: .minute))
                invalidLabel.text = BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactiveCantReserve(StartTime: start, EndTime: end)
                titleLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_NextPeriodNotAvailableCopy
            }
            if instance.category == .resourceStrategy,
               let resourceStrategy = viewData.2.schemaExtraData.cd.resourceStrategy {
                invalidLabel.isHidden = false
                fakeCheckInLabel.isHidden = true
                tipsIcon.isHidden = true
                tipsLabel.isHidden = true
                userInfoView.isHidden = true

                let timeIntervalRanges = CalendarMeetingRoom.availableTimeIntervalRanges(
                    by: Date(),
                    TimeInterval(resourceStrategy.dailyStartTime),
                    TimeInterval(resourceStrategy.dailyEndTime),
                    .current,
                    TimeZone(identifier: resourceStrategy.timezone) ?? .current,
                    false
                )
                let comma = BundleI18n.Calendar.Calendar_Common_Comma
                let timeString = timeIntervalRanges.map { range in
                    return CalendarTimeFormatter.formatOneDayTimeRange(
                        startFrom: range.startDate,
                        endAt: range.endDate,
                        with: TimeFormatUtils.defaultOptions
                    )
                }
                .joined(separator: comma)
                invalidLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_MeetingRoomReservationPeriod(AvailableTimePeriod: timeString)
                titleLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_NextPeriodNotAvailableCopy
            }
        }
    }

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_MeetingRoom_NextMeeting
        label.font = UIFont.body0
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        return label
    }()

    private lazy var sepLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        view.alpha = 0.1
        return view
    }()

    private(set) lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heading3
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var invalidLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heading3
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var userInfoView: MeetingRoomUserInfoView = {
        let avatar = MeetingRoomUserInfoView()
        return avatar
    }()

    private lazy var fakeCheckInLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_MeetingRoom_WaitForCheckInButton
        label.font = UIFont.body0
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.6)
        label.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        return label
    }()

    private lazy var tipsIcon: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.infoOutlined).renderColor(with: .n3).withRenderingMode(.alwaysTemplate))
        imageView.tintColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        return imageView
    }()

    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body1(.fixed)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        addSubview(titleLabel)
        addSubview(sepLineView)
        addSubview(timeLabel)
        addSubview(invalidLabel)
        addSubview(userInfoView)
        addSubview(fakeCheckInLabel)
        addSubview(tipsIcon)
        addSubview(tipsLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.top.equalTo(snp.top).offset(10)
            make.height.equalTo(20)
        }

        sepLineView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.centerX.equalTo(snp.centerXWithinMargins)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.height.equalTo(1)
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.centerX.equalTo(snp.centerXWithinMargins)
            make.top.equalTo(sepLineView.snp.bottom).offset(10)
        }

        invalidLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(timeLabel)
            make.top.equalTo(timeLabel.snp.bottom).offset(10)
        }

        userInfoView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.trailing.equalTo(snp.trailingMargin)
            make.top.equalTo(timeLabel.snp.bottom).offset(12)
        }

        fakeCheckInLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.top.equalTo(userInfoView.snp.bottom).offset(32)
            make.size.equalTo(CGSize(width: 142, height: 40))
        }

        tipsIcon.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.top.equalTo(fakeCheckInLabel.snp.bottom).offset(8)
            make.size.equalTo(CGSize(width: 15, height: 15))
        }

        tipsLabel.snp.makeConstraints { make in
            make.leading.equalTo(tipsIcon.snp.trailing).offset(5)
            make.trailing.equalTo(snp.trailingMargin)
            make.centerY.equalTo(tipsIcon)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
