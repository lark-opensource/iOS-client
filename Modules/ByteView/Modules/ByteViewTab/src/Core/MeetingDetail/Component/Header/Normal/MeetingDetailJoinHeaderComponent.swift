//
//  MeetingDetailJoinHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/23.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewCommon

class MeetingDetailJoinHeaderComponent: MeetingDetailHeaderComponent {

    var meetingJoinable = false

    lazy var actionStackView: UIStackView = {
        let actionStackView = UIStackView()
        actionStackView.axis = .horizontal
        actionStackView.spacing = 12
        actionStackView.alignment = .center
        actionStackView.distribution = .fill
        actionStackView.layer.masksToBounds = false
        return actionStackView
    }()

    // 加入会议（已加入）按钮，在某些状态下不显示
    lazy var joinButton: UIButton = {
        let joinButton = UIButton()
        joinButton.layer.masksToBounds = true
        joinButton.layer.cornerRadius = 6
        joinButton.layer.borderWidth = 1
        joinButton.titleLabel?.numberOfLines = 1
        joinButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        joinButton.adjustsImageWhenHighlighted = false
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        joinButton.addInteraction(type: .lift)
        joinButton.addTarget(self, action: #selector(didTapJoinButton), for: .touchUpInside)
        return joinButton
    }()

    lazy var inviteButton: UIButton = {
        let inviteButton = UIButton()
        inviteButton.titleLabel?.numberOfLines = 1
        inviteButton.layer.masksToBounds = true
        inviteButton.layer.cornerRadius = 6
        inviteButton.layer.borderWidth = 1
        inviteButton.adjustsImageWhenHighlighted = false
        inviteButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        inviteButton.addInteraction(type: .lift)
        let title = NSAttributedString(string: I18n.View_MV_CopyInviteDetails, config: .body, alignment: .center, lineBreakMode: .byTruncatingTail, textColor: .ud.textTitle)
        inviteButton.setAttributedTitle(title, for: .normal)
        inviteButton.layer.ud.setBorderColor(.ud.lineBorderComponent)
        inviteButton.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        inviteButton.setBackgroundColor(.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        inviteButton.addTarget(self, action: #selector(didTapInviteButton), for: .touchUpInside)
        return inviteButton
    }()

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.joinStatus.addObserver(self)
    }

    override func setupViews() {
        super.setupViews()

        addSubview(actionStackView)
        actionStackView.addArrangedSubview(joinButton)
        actionStackView.insertArrangedSubview(inviteButton, belowArrangedSubview: joinButton)

        actionStackView.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        inviteButton.snp.remakeConstraints {
            $0.width.greaterThanOrEqualTo(76.0)
            $0.height.equalTo(36.0)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    func updateJoinButton(joinStatus: MeetingJoinInfo.JoinStatus, rehearsalStatus: WebinarRehearsalStatusType) {
        var title = joinStatus.buttonTitle
        if rehearsalStatus == .on {
            switch joinStatus {
            case .joinable:
                title = I18n.View_G_JoinRehearsal_Button
            case .joined:
                title = I18n.View_G_Rehearsing
            default:
                break
            }
        }
        joinButton.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        joinButton.setBackgroundColor(.ud.G200.dynamicColor, for: .highlighted)
        joinButton.setBackgroundColor(.clear, for: .disabled)
        joinButton.setAttributedTitle(.init(string: title, config: .body, alignment: .center, textColor: .ud.G600), for: .normal)
        joinButton.setAttributedTitle(.init(string: title, config: .body, alignment: .center, textColor: .ud.textDisabled), for: .disabled)
        joinButton.layer.ud.setBorderColor(.ud.G600)
        joinButton.snp.remakeConstraints {
            $0.width.greaterThanOrEqualTo(80.0)
            $0.height.equalTo(36.0)
        }
    }

    override var shouldShow: Bool {
        guard let viewModel = viewModel,
              let commonInfo = viewModel.commonInfo.value else {
            return false
        }
        let hideWhenMeetingEnd: Bool = commonInfo.meetingType == .meet && viewModel.isMeetingEnd
        let hideWhenPadPhoneCall: Bool = viewModel.isPhoneCall && Display.pad
        let shouldHide = hideWhenMeetingEnd || hideWhenPadPhoneCall
        return !shouldHide
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel,
              let commonInfo = viewModel.commonInfo.value,
              let joinStatus = viewModel.joinStatus.value else { return }

        updateJoinButton(joinStatus: joinStatus, rehearsalStatus: commonInfo.rehearsalStatus)

        joinButton.isHidden = commonInfo.meetingStatus == .meetingEnd

        // 加入会议的条件：1. 已加入的会议, 2. 已进入等候室的会议
        meetingJoinable = [.joined, .waiting, .joinable].contains(joinStatus)

        inviteButton.isHidden = commonInfo.meetingStatus != .meetingOnTheCall
    }

    @objc func didTapJoinButton() {
        guard let viewModel = viewModel,
              let meetingID = viewModel.meetingID,
              let from = viewModel.hostViewController,
              let model = viewModel.commonInfo.value,
              let joinStatus = viewModel.joinStatus.value else { return }
        if let eventName = joinStatus.eventName {
            VCTracker.post(name: eventName, params: [.action_name: joinStatus.actionName,
                                                     .from_source: "meeting_detail"])
        }
        guard meetingJoinable else { return }
        let isCurrentMeeting: Bool = viewModel.meetingID == viewModel.tabViewModel.currentMeeting?.id
        if !isCurrentMeeting, [.joined, .waiting].contains(joinStatus), model.isLocked, let view = self.window {
            Toast.show(I18n.View_MV_MeetingLocked_Toast, on: view)
            return
        }
        MeetTabTracks.trackClickJoinMeeting()
        switch joinStatus {
        case .joined:
            MeetTabTracks.trackMeetTabDetailOperation(.clickJoined, isOngoing: model.meetingStatus == .meetingOnTheCall, isCall: model.meetingType == .call)
        case .waiting:
            MeetTabTracks.trackMeetTabDetailOperation(.clickWaiting, isOngoing: model.meetingStatus == .meetingOnTheCall, isCall: model.meetingType == .call)
        default:
            break
        }
        let topic = model.meetingTopic.isEmpty ? I18n.View_G_ServerNoTitle : model.meetingTopic
        viewModel.joinMeeting(meetingId: meetingID, topic: topic, from: from)
    }

    @objc func didTapInviteButton() {
        guard let viewModel = viewModel,
              let model = viewModel.commonInfo.value,
              let view = viewModel.hostViewController?.view else { return }
        MeetTabTracks.trackMeetTabDetailOperation(.clickCopyInviteLink, isOngoing: model.meetingStatus == .meetingOnTheCall, isCall: model.meetingType == .call)
        if model.canCopyMeetingInfo {
            viewModel.shareMeeting(topic: model.meetingTopic,
                                   meetingTime: viewModel.viewContext.meetingTime ?? "",
                                   isInterview: model.meetingSource == .vcFromInterview,
                                   on: view)
        } else {
            Toast.show(I18n.View_MV_MeetingLocked_Toast, on: view)
        }
    }
}

extension MeetingDetailJoinHeaderComponent: MeetingDetailJoinStatusObserver {
    func didReceive(data: MeetingJoinInfo.JoinStatus) {
        updateViews()
    }
}

extension MeetingJoinInfo.JoinStatus {
    var buttonTitle: String {
        switch self {
        case .joinable, .end: return I18n.View_MV_JoinRightNow
        case .joined: return I18n.View_MV_JoinedAlready
        case .waiting: return I18n.View_MV_WaitingRightNow
        case .unknown: return ""
        }
    }

    var eventName: TrackEventName? {
        switch self {
        case .joinable: return .vc_meeting_lark_entry
        case .joined, .waiting: return .vc_meeting_lark_detail
        case .unknown, .end: return nil
        }
    }

    var actionName: String {
        switch self {
        case .joinable: return "tab_meeting_detail_join"
        case .joined: return "tab_meeting_detail_joined"
        case .waiting: return "tab_meeting_detail_waiting"
        case .unknown, .end: return ""
        }
    }
}
