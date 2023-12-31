//
//  InMeetMiscViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewNetwork
import UniverseDesignToast

final class InMeetMiscViewModel: InMeetDataListener, InMeetingChangedInfoPushObserver, MyselfListener {
    let meeting: InMeetMeeting
    private let disposeBag = DisposeBag()
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        meeting.data.addListener(self)
        meeting.addMyselfListener(self)
        meeting.push.inMeetingChange.addObserver(self)
        setupConfigs()
    }

    /// to be deleted
    func setupConfigs() {
        MicVolumeView.micVolumeConfig = meeting.setting.micVolumeConfig
        if let config = meeting.setting.animationConfig.configs[.mic_volume] {
            MicVolumeView.animationConfig = config
        }
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        if meeting.setting.isHostControlEnabled, myself.status != .idle {
            let role = myself.meetingRole
            let oldRole = oldValue?.meetingRole ?? .participant
            switch (oldRole, role) {
            case (.participant, .coHost):
                Toast.showOnVCScene(I18n.View_M_YouBecameCoHost)
            case (.coHost, .participant):
                Toast.showOnVCScene(I18n.View_M_CoHostPermissionWithdrawn)
            default:
                break
            }
        }
        let oldStatus = oldValue?.settings.handsStatus
        let handsStatus = myself.settings.handsStatus
        if !meeting.setting.hasCohostAuthority, oldStatus != handsStatus {
            didChangeNonHostHandsStatus(handsStatus, oldValue: oldStatus, handsupType: .mic)
        }
        let oldCameraHandsStatus = oldValue?.settings.cameraHandsStatus
        let cameraHandsStatus = myself.settings.cameraHandsStatus
        if !meeting.setting.hasCohostAuthority, oldCameraHandsStatus != cameraHandsStatus {
            didChangeNonHostHandsStatus(cameraHandsStatus, oldValue: oldCameraHandsStatus, handsupType: .camera)
        }
    }

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.meetingID == meeting.meetingId, data.type == .hostTransferred, let hostTransferData = data.hostTransferData {
            // hostControlEnable 表示自己能否成为主持人/联席主持人
            // 1v1 时 featureConfig.hostControlEnable 为 false
            // 多人会议 时 featureConfig.hostControlEnable 通常为 true (面试会议且自己是候选人、游客等场景为 false)
            // 1v1 升级多人时，HostTransferData 推送 会比 FeatureConfig 更早到，
            // 导致 主持人 Toast 被过滤掉
            // 加 200ms 延迟，确保能读到正确的 FeatureConfig 数值
            Logger.phoneCall.info("enterprise direct presenter start")
            // nolint-next-line: magic number
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                guard let self = self else { return }
                if hostTransferData.host == self.meeting.account && self.meeting.setting.isHostControlEnabled {
                    Toast.show(I18n.View_M_HostMadeYouNewHost)
                    Logger.phoneCall.info("enterprise direct presenter start really")
                }
            }
        }
        // 给主持人推送因为安全事件离会的参会人信息
        if data.meetingID == meeting.meetingId, data.type == .unsafeLeaveParticipant, let participant = data.unsafeLeaveParticipant {
            let participantService = meeting.httpClient.participantService
            participantService.participantInfo(pid: participant, meetingId: meeting.meetingId) { [weak self] ap in
                Util.runInMainThread {
                    let name = ap.name
                    let config = UDToastConfig(toastType: .info, text: I18n.View_G_NameRemoved_Toast(name), operation: UDToastOperationConfig(text: I18n.View_VM_PermissionsOffNew, displayType: .horizontal), delay: 6.0)
                    if let view = self?.meeting.router.window {
                        UDToast.showToast(with: config, on: view, delay: 6.0)
                    }
                }
            }
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        let securitySetting = inMeetingInfo.meetingSettings.securitySetting
        let oldSecuritySetting = oldValue?.meetingSettings.securitySetting
        let level = securitySetting.securityLevel
        let oldLevel = oldSecuritySetting?.securityLevel
        // 主持人弹toast
        // 参会人弹 securityLevel变化的toast于等候室需求3.30去除了
        // skip(1), 仅当有变化时回调
        if oldLevel != nil, oldLevel != .unknown, level != oldLevel {
            if level == .onlyHost {
                Toast.show(I18n.View_MV_MeetingLocked_Toast)
            } else if oldLevel == .onlyHost {
                Toast.show(I18n.View_MV_MeetingUnlocked_Toast)
            } else if meeting.setting.hasCohostAuthority {
                switch level {
                case .`public`:
                    Toast.show(I18n.View_M_PermissionsSetAnyone)
                case .tenant:
                    Toast.show(I18n.View_G_UserFromOrgOnly)
                case .contactsAndGroup:
                    Toast.show(I18n.View_G_OnlySelectUserCanJoinMeeting)
                default:
                    break
                }
            }
        }
        // 入会权限变更
        if level != oldLevel || securitySetting.isOpenLobby != oldSecuritySetting?.isOpenLobby {
            Logger.meeting.info("InMeetMeetingContext permission changed: securityLevel: \(securitySetting.securityLevel); lobby: \(securitySetting.isOpenLobby)")
        }
    }

    private func didChangeNonHostHandsStatus(_ status: ParticipantHandsStatus, oldValue: ParticipantHandsStatus?, handsupType: HandsUpType) {
        // 非主持人和非联席主持人在当前强制静音设置打开，并且举过手的时候收到举手状态的变更需要toast
        // 当前强制静音设置打开或者为观众模式时, 举过手才需要弹提示
        let isMicrophone = handsupType == .mic
        if oldValue == .putUp {
            Logger.ui.debug("your \(isMicrophone ? "mic" : "camera") hands status is \(status)")
            switch status {
            case .approved:
                // 产品定义：主持人同意参会人打开摄像头不弹 toast
                if isMicrophone {
                    Toast.showOnVCScene(I18n.View_M_HostUnmutedYou)
                }
            case .reject:
                Toast.showOnVCScene(isMicrophone ? I18n.View_M_HostDeclinedRequestToSpeak : I18n.View_G_HostDenyCamOnToast)
            default:
                break
            }
        }
    }
}
