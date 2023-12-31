//
//  MeetingDetailCallHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import SnapKit
import UniverseDesignIcon
import ByteViewCommon

class MeetingDetailCallHeaderComponent: MeetingDetailHeaderComponent {

    var callButtonsBottom: Constraint?

    lazy var actionStackView: UIStackView = {
        let actionStackView = UIStackView()
        actionStackView.axis = .horizontal
        actionStackView.spacing = Util.rootTraitCollection?.horizontalSizeClass == .regular ? 20 : 12
        actionStackView.alignment = .center
        actionStackView.distribution = .fillEqually
        actionStackView.layer.masksToBounds = false
        return actionStackView
    }()

    lazy var messageButton: CallActionButton = {
        let messageButton = addActionButton(text: I18n.View_MV_Message_HistoryRecord_BlackButton, with: .chatFilled, to: actionStackView)
        messageButton.button.addTarget(self, action: #selector(didTapMessageButton), for: .touchUpInside)
        return messageButton
    }()

    lazy var callButton: CallActionButton = {
        let callButton = addActionButton(text: I18n.View_MV_Voice_HistoryRecord_BlackButton, with: .callFilled, to: actionStackView)
        callButton.button.addTarget(self, action: #selector(didTapCallButton), for: .touchUpInside)
        return callButton
    }()

    lazy var videoButton: CallActionButton = {
        let videoButton = addActionButton(text: I18n.View_MV_Video_HistoryRecord_BlackButton, with: .videoFilled, to: actionStackView)
        videoButton.button.addTarget(self, action: #selector(didTapVideoButton), for: .touchUpInside)
        return videoButton
    }()

    override func setupViews() {
        super.setupViews()

        addSubview(actionStackView)
        actionStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.actionStackView.isHidden == false else { return }
            let width = (self.actionStackView.bounds.width - self.actionStackView.spacing * CGFloat(self.actionStackView.arrangedSubviews.count - 1)) / 3
            self.actionStackView.arrangedSubviews.forEach { view in
                guard let view = view as? CallActionButton else { return }
                view.rightConstraint?.deactivate()
                view.widthConstraint?.update(offset: width)
                view.widthConstraint?.activate()
            }
        }
    }

    override func updateLayout() {
        super.updateLayout()
        // nolint-next-line: magic number
        actionStackView.spacing = traitCollection.isRegular ? 20 : 12

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.actionStackView.isHidden == false else { return }
            let width = (self.actionStackView.bounds.width - self.actionStackView.spacing * CGFloat(self.actionStackView.arrangedSubviews.count - 1)) / 3
            self.actionStackView.arrangedSubviews.forEach { view in
                guard let view = view as? CallActionButton else { return }
                view.rightConstraint?.deactivate()
                view.widthConstraint?.update(offset: width)
                view.widthConstraint?.activate()
            }
        }
    }

    private func addActionButton(text: String, with icon: UDIconType, to view: UIStackView) -> CallActionButton {
        let actionButton = CallActionButton(frame: .zero)
        actionButton.button.setImage(UDIcon.getIconByKey(icon, iconColor: .ud.N700.dynamicColor, size: CGSize(width: 22, height: 22)), for: .normal)
        actionButton.button.setImage(UDIcon.getIconByKey(icon, iconColor: .ud.N700.dynamicColor, size: CGSize(width: 22, height: 22)), for: .disabled)
        actionButton.button.setTitle(text, for: .normal)

        view.addArrangedSubview(actionButton)
        actionButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(60)
            if callButtonsBottom == nil {
                callButtonsBottom = make.bottom.lessThanOrEqualToSuperview().constraint
            }
        }
        return actionButton
    }

    override var shouldShow: Bool {
        guard let viewModel = viewModel,
              let commonInfo = viewModel.commonInfo.value else {
            return false
        }
        let showWhenCallEnd = viewModel.isMeetingEnd && commonInfo.meetingType == .call
        let showWhenPhoneCallEnd = viewModel.tabListItem?.phoneType == .outsideEnterprisePhone && Display.phone
        let hideActionView = (commonInfo.meetingType == .meet && viewModel.isMeetingEnd) || (viewModel.isPhoneCall && Display.pad)
        return (showWhenCallEnd || showWhenPhoneCallEnd) && !hideActionView
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = viewModel,
              let commonInfo = viewModel.commonInfo.value,
              let historyInfo = viewModel.historyInfo else { return }

        let callBtnText: String
        if viewModel.isPhoneCall {
            switch historyInfo.historyInfoType {
            case .enterprisePhone:
                callBtnText = I18n.View_MV_OfficePhonePaid
            case .recruitment:
                callBtnText = I18n.View_G_RecruitmentCall_Hover
            default:
                callBtnText = I18n.View_VM_CallButton
            }
        } else {
            callBtnText = I18n.View_MV_Voice_HistoryRecord_BlackButton
        }

        // 执行顺序会改变按钮顺序
        messageButton.isHidden = viewModel.isPhoneCall
        callButton.button.setTitle(callBtnText, for: .normal)
        videoButton.isHidden = viewModel.isPhoneCall

        let meetingType = commonInfo.meetingType
        let meetingEnd = commonInfo.meetingStatus == .meetingEnd
        let hideCallTypeButtons = !((meetingEnd && meetingType == .call) || viewModel.tabListItem?.phoneType == .outsideEnterprisePhone)
        if hideCallTypeButtons {
            callButtonsBottom?.deactivate()
        } else {
            callButtonsBottom?.activate()
        }
    }

    @objc func didTapMessageButton() {
        guard let viewModel = viewModel, let historyInfo = viewModel.historyInfo else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "tab_meeting_detail_chat",
                                                               .from_source: "meeting_detail"])
        MeetTabTracks.trackClickChat()
        viewModel.gotoChatViewController(userID: historyInfo.interacterUserID, isGroup: false, shouldSwitchFeedTab: !(self.traitCollection.horizontalSizeClass == .compact))
    }

    @objc func didTapCallButton() {
        guard let viewModel = viewModel,
              let meetingID = viewModel.meetingID,
              let tabListItem = viewModel.tabListItem,
              let historyInfo = viewModel.historyInfo,
              let from = viewModel.hostViewController else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "tab_meeting_detail_call", .from_source: "meeting_detail"])
        MeetTabTracks.trackClickVoiceCall()
        switch tabListItem.phoneType {
        case .insideEnterprisePhone, .outsideEnterprisePhone:
            let phoneType: TabPhoneCallBody.PhoneType
            switch tabListItem.enterpriseType {
            case .enterprise:
                phoneType = .enterprisePhone
            case .recruit:
                phoneType = .recruitmentPhone
            }
            self.showCallingActionSheet(phoneNumber: tabListItem.phoneNumber, phoneType: phoneType)
        case .ipPhone:
            if tabListItem.historyAbbrInfo.interacterUserType == .larkUser {
                self.showCallingActionSheet(with: historyInfo, meetingID: meetingID)
            } else {
                viewModel.router?.startPhoneCall(body: TabPhoneCallBody(phoneNumber: tabListItem.ipPhoneNumber, phoneType: .ipPhone), from: from)
            }
        default:
            if tabListItem.historyAbbrInfo.interacterUserType == .pstnUser {
                // 办公电话兜底逻辑，ongoing时进入详情页phoneType为vc
                self.showCallingActionSheet(phoneNumber: tabListItem.phoneNumber, phoneType: .ipPhone)
            } else {
                self.showCallingActionSheet(with: historyInfo, meetingID: meetingID)
            }
        }
    }

    @objc func didTapVideoButton() {
        guard let viewModel = viewModel,
              let from = viewModel.hostViewController,
              let historyInfo = viewModel.historyInfo else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "tab_meeting_detail_video",
                                                                             .from_source: "meeting_detail"])
        MeetTabTracks.trackClickVideoCall()
        viewModel.startCall(userId: historyInfo.interacterUserID, isVoiceCall: false, from: from)
    }

    private func showCallingActionSheet(with info: HistoryInfo, meetingID: String) {
        guard let viewModel = viewModel, let from = viewModel.hostViewController else { return }
        let id = ParticipantId(id: info.interacterUserID, type: info.interacterUserType)
        viewModel.httpClient.participantService.participantInfo(pid: id, meetingId: meetingID) { [weak viewModel] user in
            Util.runInMainThread {
                guard case let .remote(key: avatarKey, _) = user.avatarInfo, let viewModel = viewModel else { return }
                let tenentId = viewModel.tabListItem?.sameTenantID ?? user.tenantId
                viewModel.router?.showCallsActonSheet(userID: user.id,
                                                      name: user.name,
                                                      avatarKey: avatarKey,
                                                      isCrossTenant: viewModel.account.tenantId != tenentId,
                                                      from: from)
            }
        }
    }

    private func showCallingActionSheet(phoneNumber: String?, phoneType: TabPhoneCallBody.PhoneType) {
        guard let from = viewModel?.hostViewController, let phoneNumber = phoneNumber else { return }
        viewModel?.router?.showEnterpriseCallActionSheet(body: TabPhoneCallBody(phoneNumber: phoneNumber, phoneType: phoneType), from: from)
    }
}
