//
//  MeetingRoomUnavailableView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/3/4.
//

import UIKit
import RustPB
import RxRelay

final class MeetingRoomUnavailableView: UIView, ViewDataConvertible {
    final class UserInfoListView: UIView {
        private lazy var stackView: UIStackView = {
            let view = UIStackView()
            view.axis = .vertical
            view.distribution = .equalSpacing
            view.alignment = .fill
            view.spacing = 0
            return view
        }()

        private lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.showsVerticalScrollIndicator = false
            view.contentInset.bottom = 12.5
            return view
        }()

        let userTappedRelay = PublishRelay<String>()

        var users: [MeetingRoomUserInfoView.ViewData] = [] {
            didSet {
                stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                let userInfoViews = users
                    .map { data -> MeetingRoomUserInfoView in
                        let userinfoView = MeetingRoomUserInfoView()
                        userinfoView.viewData = data
                        userinfoView.snp.makeConstraints { $0.height.equalTo(56) }
                        userinfoView.userTappedRelay.bind(to: userTappedRelay)
                        return userinfoView
                    }
                userInfoViews.dropFirst().forEach {
                    let sepline = UIView()
                    sepline.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.1)
                    $0.addSubview(sepline)
                    sepline.snp.makeConstraints { make in
                        make.leading.trailing.top.equalToSuperview()
                        make.height.equalTo(1)
                    }
                }
                userInfoViews
                    .forEach { stackView.addArrangedSubview($0) }
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(scrollView)
            scrollView.addSubview(stackView)

            scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            stackView.snp.makeConstraints { make in
                make.edges.equalTo(scrollView.contentLayoutGuide.snp.edges)
                make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class UserInfoBottomView: UIView {
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = BundleI18n.Calendar.Calendar_Detail_Contacts
            label.font = UIFont.body0
            label.textColor = UIColor.ud.primaryOnPrimaryFill
            return label
        }()

        private lazy var sepline: UIView = {
            let sep = UIView()
            sep.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.1)
            return sep
        }()

        lazy var userInfoView: UserInfoListView = {
            let view = UserInfoListView()
            return view
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            preservesSuperviewLayoutMargins = true

            backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.1)

            addSubview(titleLabel)
            addSubview(sepline)
            addSubview(userInfoView)

            titleLabel.snp.makeConstraints { make in
                make.leading.equalTo(snp.leadingMargin)
                make.top.equalToSuperview().offset(10)
                make.height.equalTo(20)
            }

            sepline.snp.makeConstraints { make in
                make.leading.equalTo(snp.leadingMargin).offset(-4)
                make.centerX.equalTo(snp.centerXWithinMargins)
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
                make.height.equalTo(1)
            }

            userInfoView.snp.makeConstraints { make in
                make.leading.equalTo(snp.leadingMargin)
                make.centerX.equalTo(snp.centerXWithinMargins)
                make.top.equalTo(sepline.snp.bottom)
                make.bottom.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    var viewData: MeetingRoomOrderViewModel.InactiveStatusCalculator.InactiveStatus? {
        didSet {
            guard let status = viewData, status != .none else {
                assertionFailure()
                return
            }
            switch status {
            case .qrCodeNotEnable:
                stateLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_FunctionTurnOff
                descriptionLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_ContactAdmin
                unavailablePeriodLabel.isHidden = true
                unavailableReasonLabel.isHidden = true
                bottomView.isHidden = true
            case .meetingRoomDisabled:
                stateLabel.text = BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserve
                descriptionLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_InactiveMeetingRoom
                unavailablePeriodLabel.isHidden = true
                unavailableReasonLabel.isHidden = true
                bottomView.isHidden = true
            case .duringStrategy(range: let range, availableRange: let availableRange):
                stateLabel.text = BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserve
                descriptionLabel.text = range
                unavailablePeriodLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_MeetingRoomReservationPeriod(AvailableTimePeriod: availableRange)
                unavailablePeriodLabel.isHidden = false
                unavailableReasonLabel.isHidden = true
                bottomView.isHidden = true
            case let .duringRequisition(reason: reason, range: range, chatters: chatters):
                stateLabel.text = BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserve
                descriptionLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_InactiveMeetingRoom
                unavailableReasonLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_InactiveReason(InactiveReason: reason)
                unavailablePeriodLabel.text = range
                unavailableReasonLabel.isHidden = reason.isEmpty
                unavailablePeriodLabel.isHidden = false
                if chatters.isEmpty {
                    bottomView.isHidden = true
                } else {
                    bottomView.isHidden = false
                    let model = chatters.map { MeetingRoomUserInfoView.ViewData(creator: $0) }
                    bottomView.userInfoView.users = model
                }
            case .userStrategy:
                stateLabel.text = BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserve
                descriptionLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_NoPermissionToReserveRoom
                unavailablePeriodLabel.isHidden = true
                unavailableReasonLabel.isHidden = true
                bottomView.isHidden = true
            case .none:
                assertionFailure()
                return
            }
        }
    }

    private lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.title
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body0
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        label.numberOfLines = 0
        return label
    }()

    private lazy var unavailablePeriodLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body0
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        label.numberOfLines = 0
        return label
    }()

    private lazy var unavailableReasonLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body0
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        label.numberOfLines = 0
        return label
    }()

    lazy var bottomView: UserInfoBottomView = {
        let view = UserInfoBottomView()
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        let stackView = UIStackView(arrangedSubviews: [stateLabel, descriptionLabel, unavailablePeriodLabel, unavailableReasonLabel])
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.trailing.equalTo(snp.trailingMargin)
            make.top.equalTo(snp.topMargin)
        }

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.setCustomSpacing(20, after: descriptionLabel)

        addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom).offset(40)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
