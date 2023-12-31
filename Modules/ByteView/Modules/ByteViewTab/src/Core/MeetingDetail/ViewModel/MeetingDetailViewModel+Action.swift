//
//  MeetingDetailViewModel+Action.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/25.
//

import Foundation
import ByteViewNetwork
import LarkLocalizations
import ByteViewTracker
import ByteViewCommon
import ByteViewSetting

extension MeetingDetailViewModel {

    func handleMeetingChatHistoryTapped() {
        guard let meetingID = meetingID else { return }
        httpClient.send(CreateVCTabMeetingImRecordDocRequest(meetingId: meetingID)) { [weak self] r in
            guard let self = self else { return }
            if case let .failure(error) = r {
                Self.logger.warn("create Tab meeting chatHistory request failed, error: \(error)")
                let failedInfo = TabDetailChatHistoryV2(meetingID: meetingID, version: 0, owner: ByteviewUser(id: "", type: .larkUser), status: .failed, title: "", url: "", type: .doc)
                self.chatHistory.send(data: failedInfo)
            }
        }
    }

    func handleMeetingStatisticsTapped() {
        guard let meetingID = meetingID else { return }
        let is12HourStyle = !DateUtil.is24HourTime
        let request = CreateTabMeetingStatisticsRequest(meetingId: meetingID, isTwelveHourTime: is12HourStyle, locale: LanguageManager.currentLanguage.identifier)
        httpClient.send(request) { [weak self] r in
            if case let .failure(error) = r {
                Self.logger.warn("create Tab meeting statistics request failed, error: \(error)")
                var failedInfo = TabStatisticsInfo()
                failedInfo.status = .failed
                failedInfo.isBitable = self?.statisticsInfo.value?.isBitable ?? false
                /// 点击“生成会议统计”的请求fail后，认为等同于服务端推了一个failed的VCTabStatisticsInfo，toast提示并重置按钮状态
                self?.statisticsInfo.send(data: failedInfo)
            }
        }
    }

    func handleVoteStatisticsInfoTapped() {
        guard let meetingID = meetingID else { return }
        let is12HourStyle = !DateUtil.is24HourTime
        let request = ExportVoteStatisticsRequest(meetingID: meetingID, isTwelveHourTime: is12HourStyle, locale: LanguageManager.currentLanguage.identifier)
        httpClient.send(request) { [weak self] r in
            if case let .failure(error) = r {
                Self.logger.warn("create Tab vote statistics request failed, error: \(error)")
                var failedInfo = TabVoteStatisticsInfo()
                failedInfo.status = .failed
                self?.voteStatisticsInfo.send(data: failedInfo)
            }
        }
    }

    func handleAvatarTapped(userID: String) {
        guard let meetingBaseInfo = meetingBaseInfo else { return }
        httpClient.participantService.participantInfo(pid: meetingBaseInfo.sponsorUser, meetingId: meetingID) { [weak self] sponsorInfo in
            self?.gotoUserProfile(userID: userID, sponsorName: sponsorInfo.name, sponsorID: sponsorInfo.id)
        }
    }

    func handleParticipantsTapped(view: ParticipantsPreviewView) {
        gotoParticipantView(from: view, animated: true)
    }

    private func gotoParticipantView(from view: ParticipantsPreviewView, animated: Bool) {
        guard let meetingBaseInfo = meetingBaseInfo else { return }
        httpClient.participantService.participantInfo(pid: meetingBaseInfo.sponsorUser, meetingId: meetingID) { [weak self] info in
            guard let self = self, let participantAbbrInfos = self.participantAbbrInfos.value, !participantAbbrInfos.isEmpty else { return }

            if participantAbbrInfos.count == 1, let participantAbbrInfo = participantAbbrInfos.first {
                VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "vc_meeting_username", .from_source: "meeting_detail"])
                let user = participantAbbrInfo.user
                if user.type == .larkUser ||
                    (user.type == .pstnUser && participantAbbrInfo.bindType == .lark) {
                    let userId = participantAbbrInfo.participantId.larkUserId ?? user.id
                    self.gotoUserProfile(userID: userId, sponsorName: info.name, sponsorID: info.id)
                }
            } else {
                self.gotoParticipantList(sponsor: info, view: view, animated: animated)
            }
        }
    }

    private func gotoParticipantList(sponsor: ParticipantUserInfo, view: ParticipantsPreviewView, animated: Bool) {
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "tab_meeting_detail_userlist"])

        guard let from = findViewController(with: view), let participantAbbrInfos = participantAbbrInfos.value else { return }

        httpClient.participantService.participantInfo(pids: participantAbbrInfos, meetingId: meetingID) { [weak self] aps in
            guard let self = self else { return }
            self.participantsPopover.didSelectCellCallback = { [weak self] participant, _ in
                if let commonInfo = self?.commonInfo.value {
                    MeetTabTracks.trackMeetTabDetailOperation(.clickUserGroupIcon,
                                                              isOngoing: commonInfo.meetingStatus == .meetingOnTheCall,
                                                              isCall: commonInfo.meetingType == .call)
                }

                guard !participant.isLarkGuest else { return }
                if participant.participantType == .larkUser ||
                    (participant.participantType == .pstnUser && participant.bindType == .lark) {
                    let userId = participant.participantType == .larkUser ? participant.userId : participant.bindId
                    self?.gotoUserProfile(userID: userId,
                                          sponsorName: sponsor.name,
                                          sponsorID: sponsor.id,
                                          from: self?.participantsPopover.participantVC)
                }
            }
            self.participantsPopover.showParticipantsList(
                participants: self.convert(
                    participantAbbrInfos: participantAbbrInfos,
                    aps: aps,
                    sponsorID: sponsor.id),
                isInterview: self.meetingBaseInfo?.meetingInfo.meetingSource == .vcFromInterview,
                isWebinar: self.isWebinarMeeting,
                from: from,
                animated: animated)
        }
    }

    private func convert(participantAbbrInfos: [ParticipantAbbrInfo], aps: [ParticipantUserInfo], sponsorID: String) -> [PreviewParticipant] {
        let ids = participantAbbrInfos.map { $0.id }
        let duplicatedParticipantIds = Set(ids.reduce(into: [String: Int]()) { $0[$1] = ($0[$1] ?? 0) + 1 }
                                            .filter { $0.1 > 1 }.map { $0.key })

        var alreadyHasSponsor = false
        let users = Array(zip(participantAbbrInfos, aps))

        var previewParticipants: [PreviewParticipant] = []
        users.forEach { (participant: ParticipantAbbrInfo, ap: ParticipantUserInfo) in

            let showDevice = duplicatedParticipantIds.contains(participant.id) &&
                (participant.deviceType == .mobile || participant.deviceType == .web)

            let isSponsor: Bool
            if alreadyHasSponsor || participant.id != sponsorID {
                isSponsor = false
            } else {
                isSponsor = true
                alreadyHasSponsor = true
            }
            let item = PreviewParticipant(userId: participant.id,
                                          userName: ap.name,
                                          avatarInfo: ap.avatarInfo,
                                          participantType: participant.user.type,
                                          isLarkGuest: participant.isLarkGuest,
                                          isSponsor: isSponsor,
                                          deviceType: participant.deviceType,
                                          showDevice: showDevice,
                                          tenantId: ap.tenantId,
                                          tenantTag: nil,
                                          bindId: participant.bindID,
                                          bindType: participant.bindType,
                                          showCallme: participant.usedCallMe)
            previewParticipants.append(item)
        }
        return previewParticipants
    }

    private func findViewController(with view: UIView) -> UIViewController? {
        var fromVC: UIViewController?
        var parentResponder: UIResponder? = view
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                fromVC = viewController
                break
            }
        }
        return fromVC
    }

    func resetParticipantsPopover(view: ParticipantsPreviewView) {
        if participantsPopover.resetParticipantsPopover() {
            // 派发到下一渲染队列，确保 participants 页 dismiss 完成，否则 popover 指定的 sourceView 和 sourceRect 计算时会有问题
            DispatchQueue.main.async { [weak self] in
                self?.gotoParticipantView(from: view, animated: false)
            }
        }
    }

    private func gotoUserProfile(userID: String, sponsorName: String, sponsorID: String, from: UIViewController? = nil) {
        guard let meetingID = meetingID,
              let meetingBaseInfo = self.meetingBaseInfo,
              let host = from ?? self.hostViewController else { return }
        router?.gotoUserProfile(userId: userID,
                                meetingTopic: meetingBaseInfo.meetingInfo.meetingTopic,
                                sponsorName: sponsorName,
                                sponsorId: sponsorID,
                                meetingId: meetingID,
                                from: host)
    }

    func joinMeeting(meetingId: String, topic: String, from: UIViewController) {
        router?.joinMeetingById(meetingId, topic: topic, subtype: self.commonInfo.value?.meetingSubType, from: from)
    }

    func startCall(userId: String, isVoiceCall: Bool, from: UIViewController) {
        router?.startCall(userId: userId, isVoiceCall: isVoiceCall, from: from)
    }

    func shareMeeting(topic: String, meetingTime: String, isInterview: Bool, on view: UIView) {
        guard let meetingURL = meetingURL, let meetingNumber = meetingNumber, let accessInfos = accessInfos else { return }
        let request = MeetingCopyInfoRequest(type: .tab(accessInfos), topic: topic, meetingURL: meetingURL, isWebinar: isWebinarMeeting, isInterview: isInterview, meetingTime: meetingTime, meetingNumber: meetingNumber, isE2EeMeeting: false)
        self.tabViewModel.setting.fetchCopyInfo(request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    if let vm = self?.tabViewModel,
                       vm.setPasteboardText(resp.copyContent, token: .tabPageMeetingContent, shouldImmunity: true) {
                        Toast.showSuccess(I18n.View_M_JoiningInfoCopied, on: view)
                    }
                default:
                    break
                }
            }
        }
    }

    func gotoChatViewController(userID: String, isGroup: Bool, shouldSwitchFeedTab: Bool) {
        guard let host = self.hostViewController else { return }
        router?.gotoChat(chatID: userID, isGroup: isGroup, switchFeedTab: shouldSwitchFeedTab, from: host)
    }
}
