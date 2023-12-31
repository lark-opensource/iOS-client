//
//  MeetingRoomStateView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/8.
//

import UIKit
import RustPB
import LarkZoomable
import LarkTimeFormatUtils
import RxRelay

final class MeetingRoomStateView: UIView, ViewDataConvertible {
    private var reserveInfo: (fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String, creatorID: String, nextMeetingStartTime: Date?)?

    enum ViewData {
        case free(until: Date?, reservable: Bool, meetingRoom: (fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String, creatorID: String)?)
        case inUse(startTime: Date, endTime: Date, user: Calendar_V1_EventCreator)
        // 当前时间已经晚于会议开始时间，但还没有签到
        case waitingForCheckIn(startTime: Date, endTime: Date, user: Calendar_V1_EventCreator)
        // 当前时间早于会议开始时间，但晚于可签到开始时间
        case waitingForBegin(startTime: Date, endTime: Date, user: Calendar_V1_EventCreator)
    }

    var viewData: ViewData? {
        didSet {
            guard let viewData = viewData else {
                assertionFailure()
                return
            }

            var option = TimeFormatUtils.defaultOptions
            option.timePrecisionType = .minute

            switch viewData {
            case let .free(endDate, reservable, meetingRoom):
                stateLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_AvailableLable
                if let endDate = endDate {
                    timeLabel.text = "\(BundleI18n.Calendar.Calendar_Common_Now)-" + TimeFormatUtils.formatDateTime(from: endDate, with: option)
                } else {
                    // 空闲到第二天晚上
                    let tomorrowEnd = Date().tomorrow.dayEnd()
                    timeLabel.text = "\(BundleI18n.Calendar.Calendar_Common_Now)-" + TimeFormatUtils.formatDateTime(from: tomorrowEnd, with: option)
                }
                reserveButton.isHidden = !reservable
                userInfoView.isHidden = true
                self.reserveInfo = meetingRoom.map { ($0.fromResource, $0.buildingName, $0.tenantId, $0.creatorID, endDate) }
            case let .inUse(startTime, endTime, user):
                stateLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_InUseLable
                timeLabel.text = TimeFormatUtils.formatTimeRange(startFrom: startTime, endAt: endTime, with: option)
                reserveButton.isHidden = true
                userInfoView.isHidden = false
                userInfoView.viewData = .init(creator: user)
            case let .waitingForCheckIn(startTime, endTime, user):
                stateLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_StartedLable
                timeLabel.text = TimeFormatUtils.formatTimeRange(startFrom: startTime, endAt: endTime, with: option)
                reserveButton.isHidden = true
                userInfoView.isHidden = false
                userInfoView.viewData = .init(creator: user)
            case let .waitingForBegin(startTime, endTime, user):
                stateLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_StartingLable
                timeLabel.text = TimeFormatUtils.formatTimeRange(startFrom: startTime, endAt: endTime, with: option)
                reserveButton.isHidden = true
                userInfoView.isHidden = false
                userInfoView.viewData = .init(creator: user)
            }

        }
    }

    private(set) lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.title
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        return label
    }()

    private(set) lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.heading3
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var userInfoView: MeetingRoomUserInfoView = {
        let view = MeetingRoomUserInfoView()
        return view
    }()

    private lazy var reserveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.Calendar.Calendar_MeetingRoom_ReserveButton, for: .normal)
        button.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        button.titleLabel?.font = UIFont.heading3
        button.setTitleColor(UIColor.ud.staticBlack, for: .normal)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()

    var reserveButtonClickedRelay = PublishRelay<(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String, creatorID: String, nextMeetingStartTime: Date?)>()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        let stackView = UIStackView(arrangedSubviews: [stateLabel, timeLabel, reserveButton, userInfoView])
        addSubview(stackView)
        reserveButton.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(88)
            make.height.equalTo(40)
        }
        reserveButton.addTarget(self, action: #selector(reserveButtonTapped), for: .touchUpInside)

        stackView.snp.makeConstraints { make in
            make.edges.equalTo(snp.margins)
        }

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.setCustomSpacing(32, after: timeLabel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func reserveButtonTapped() {
        if let reserveInfo = reserveInfo {
            reserveButtonClickedRelay.accept(reserveInfo)
        }
    }
}
