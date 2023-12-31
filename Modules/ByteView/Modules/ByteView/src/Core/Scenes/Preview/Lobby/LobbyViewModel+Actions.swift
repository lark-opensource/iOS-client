//
//  LobbyViewModel+Actions.swift
//  ByteView
//
//  Created by Prontera on 2020/6/29.
//

import Foundation
import Action
import AVFoundation
import ByteViewTracker
import ByteViewNetwork
import ByteViewMeeting
import ByteViewSetting

extension LobbyViewModel {

    func handleMicrophone() {
        guard !(setting.isMicSpeakerDisabled && audioMode == .internet) else {
            return
        }
        if joinTogetherRoomRelay.value != nil {
            // V5.22+，连上会议室音频后，无交互反馈 by UX
            return
        }
        Privacy.requestMicrophoneAccessAlert { [weak self] in
            guard let self = self, case .success = $0 else { return }
            let toMute = !self.isMicrophoneMuted.value
            LobbyTracks.trackMicStatusOfLobby(muted: toMute, source: self.lobbySource)
            self.muteMicrophone(toMute)
            // 这个方法会被多个场景调用，因此麦克风和下面摄像头的操作埋点都埋在调用处
            Toast.showOnVCScene(toMute ? I18n.View_VM_MicOff : I18n.View_VM_MicOn)
        }
    }

    func handleCamera() {
        let isCameraMuted = !self.isCameraMuted
        if self.isCameraMuted, !CameraSncWrapper.getCheckResult(by: lobbySource == .inLobby ? .lobby : .preLobby) {
            Toast.show(I18n.View_VM_CameraNotWorking)
            return
        }

        LobbyTracks.trackCameraStatusOfLobby(muted: isCameraMuted)

        if lobbySource == .inLobby,
           !isCameraMuted,
           let effectManger = session.effectManger,
           !(!isCamOriginMuted && effectManger.virtualBgService.hasShowedNotAllowToast),
           !effectManger.virtualBgService.allowVirtualBgInfo.allow, // 不允许虚拟背景
           effectManger.virtualBgService.hasUsedBgInAllow == true, // 之前用过虚拟背景
           !effectManger.virtualBgService.hasShowedNotAllowAlert // 之前没显示过下面的vc
        {
            Util.runInMainThread { [weak self] in
                guard let self = self else { return }
                let vc = NoVirtualBgPreviewViewController(service: self.service, effectManger: effectManger)
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                vc.openCameraBlock = { [weak self] in
                    self?.realHandleCamera(isCameraMuted)
                }
                self.router.present(vc)
            }
            return
        }
        realHandleCamera(isCameraMuted)
    }

    private func realHandleCamera(_ isCameraMuted: Bool) {
        Privacy.requestCameraAccessAlert { [weak self] in
            guard let self = self, $0.isSuccess else { return }
            LobbyTracks.trackCameraStatusOfLobby(muted: isCameraMuted)
            var request = UpdateLobbyParticipantRequest(meetingId: self.session.meetingId)
            request.isCameraMuted = isCameraMuted
            self.httpClient.send(request)
            self.isCameraMuted = isCameraMuted
        }
    }

    func joinMeeting() {
        if !ReachabilityUtil.isConnected {
            Toast.show(I18n.View_G_NoConnection)
            session.loge("lobby join in meeting with error: \(VCError.badNetwork)")
            return
        }

        let meetSetting = self.meetSetting
        let logTag = self.session.description
        let isMoveToLobby = session.lobbyInfo?.lobbyParticipant?.joinReason == .hostMove
        let audioMode: ParticipantSettings.AudioMode = isMoveToLobby ? .internet : (session.joinMeetingParams?.audioMode ?? .internet)
        let joinSource = JoinMeetingRequest.JoinSource(sourceType: session.lobbyInfo?.isJoinPreLobby == true ? .preLobby : .lobby)
        let meetingParams = JoinMeetingParams(joinType: .meetingId(session.meetingId, joinSource),
                                              meetSetting: meetSetting, audioMode: audioMode,
                                              targetToJoinTogether: joinTogetherRoomRelay.value, isE2EeMeeting: session.isE2EeMeeting)
        session.joinMeetingParams = meetingParams
        httpClient.meeting.joinMeeting(params: meetingParams) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let (info, vcerror)):
                if let info = info {
                    self.joinFromLobby(info, setting: meetSetting)
                } else if let error = vcerror {
                    self.session.handleJoinMeetingBizError(error)
                    if error == .meetingHasFinished {
                        // 会前等候室的用户，入会时恰好会议结束，关闭等候室
                        self.session.leave(.meetingHasFinished)
                    }
                }
            case .failure(let error):
                Logger.meeting.error("\(logTag) lobby join meeting by meeting id error", error: error.toVCError())
            }
        }
    }

    /// 等候室准入走joinMeeting，故有此方法
    func joinFromLobby(_ info: VideoChatAttachedInfo, setting: MicCameraSetting) {
        session.localSetting = setting
        session.sendToMachine(attachedInfo: info)
    }

    func hangUp() {
        LobbyTracks.trackHangupOfLobby(source: lobbySource)
        session.leave()
    }

    private var meetSetting: MicCameraSetting {
        return MicCameraSetting(isMicrophoneEnabled: !isMicrophoneMuted.value, isCameraEnabled: !isCameraMuted)
    }
}
