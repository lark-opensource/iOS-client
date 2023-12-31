//
//  MeetingDetailRedirectHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

class MeetingDetailRedirectHeaderComponent: MeetingDetailHeaderComponent {

    lazy var redirectView = UIView()

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.appLinkInfo.addObserver(self)
    }

    override func setupViews() {
        super.setupViews()

        addSubview(redirectView)
        redirectView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(24)
        }

        let redirectImg = UDIcon.getIconByKey(.detailsOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
        let redirectIcon = UIImageView(image: redirectImg)
        redirectView.addSubview(redirectIcon)
        redirectIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }

        let redirectButton = VisualButton()
        redirectButton.setAttributedTitle(.init(string: I18n.View_G_ViewEventDetails, config: .bodyAssist), for: .normal)
        redirectButton.titleLabel?.textColor = UIColor.ud.primaryContentDefault
        redirectButton.setBackgroundColor(.ud.udtokenBtnTextBgPriFocus, for: .highlighted)
        redirectButton.layer.cornerRadius = 6.0
        redirectButton.clipsToBounds = true
        redirectButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        redirectButton.extendEdge = UIEdgeInsets(top: -6, left: -28, bottom: -6, right: -4)
        redirectView.addSubview(redirectButton)
        redirectButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(redirectIcon.snp.right).offset(8.0)
        }
        redirectButton.addTarget(self, action: #selector(didTapRedirectButton), for: .touchUpInside)
    }

    override var shouldShow: Bool {
        guard let viewModel = viewModel,
              let commonInfo = viewModel.commonInfo.value,
              let appLinkInfo = viewModel.appLinkInfo.value,
              !viewModel.isCall else { return false }
        return commonInfo.meetingSource == .vcFromCalendar && appLinkInfo.type == .calendar
    }

    @objc func didTapRedirectButton() {
        guard let from = viewModel?.hostViewController,
              let commonInfo = viewModel?.commonInfo.value,
              let linkInfo = viewModel?.appLinkInfo.value,
              linkInfo.type == .calendar,
              let calendarLinkInfo = linkInfo.paramCalendar else {
            Logger.ui.info("User tapped \"go to calendar\" but applinkInfo is invalid: applinkInfo = \(String(describing: viewModel?.appLinkInfo))")
            return
        }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "view_in_calendar"])
        MeetTabTracks.trackMeetTabDetailOperation(.clickCalendarDetail, isOngoing: commonInfo.meetingStatus == .meetingOnTheCall, isCall: commonInfo.meetingType == .call)

        viewModel?.router?.gotoCalendarEvent(calendarID: calendarLinkInfo.calendarID,
                                    key: calendarLinkInfo.key,
                                    originalTime: Int(calendarLinkInfo.originalTime),
                                    startTime: Int(calendarLinkInfo.startTime),
                                    from: from)
    }
}

extension MeetingDetailRedirectHeaderComponent: MeetingDetailAppLinkInfoObserver {
    func didReceive(data: MeetingSourceAppLinkInfo) {
        updateViews()
    }
}
