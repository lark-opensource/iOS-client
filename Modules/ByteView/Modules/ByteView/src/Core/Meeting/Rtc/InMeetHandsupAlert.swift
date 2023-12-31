//
//  InMeetHandsupAlert.swift
//  ByteView
//
//  Created by kiri on 2022/10/18.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

final class InMeetHandsupAlert {
    private weak var handsUpAlert: ByteViewDialog?
    private var isDismissed = false
    private var onDismiss: (() -> Void)?
    private let setting: MeetingSettingManager
    private let handsupType: HandsUpType
    init(service: MeetingBasicService, handsupType: HandsUpType) {
        self.setting = service.setting
        self.handsupType = handsupType
        setting.addListener(self, for: [.hasHostAuthority])
        setting.addComplexListener(self, for: [handsupType == .camera ? .cameraHandsStatus : .micHandsStatus])
        if handsupType == .mic {
            service.push.inMeetingChange.addObserver(self)
        }
    }

    func show(handsStatus: ParticipantHandsStatus, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        let isMicrophone = handsupType == .mic
        var title: String = ""
        var rightTitle: String = ""
        var id: ByteViewDialogIdentifier
        switch handsStatus {
        case .putUp:
            title = isMicrophone ? I18n.View_M_RaiseHandToSpeak : I18n.View_M_RequestHostToTurnOnCam
            rightTitle = isMicrophone ? I18n.View_M_RaiseHand : I18n.View_G_RequestButton
            id = isMicrophone ? .micHandsUp : .cameraHandsUp
        case .putDown:
            title = isMicrophone ? I18n.View_M_LowerHandQuestion : I18n.View_G_RequestedSureWithdrawPop
            rightTitle = isMicrophone ? I18n.View_M_LowerHand : I18n.View_G_WithdrawRequestButton
            id = isMicrophone ? .micHandsDown : .cameraHandsDown
        default:
            return
        }

        let isAudience = self.setting.rtcMode == .audience
        ByteViewDialog.Builder()
            .id(id)
            .colorTheme(handsStatus == .putDown ? .handsUpConfirm : .defaultTheme)
            .needAutoDismiss(true)
            .title(title)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ [weak self] _ in
                guard let self = self, isMicrophone else { return }
                HandsUpTracks.trackConfirmHandsUp(false,
                                                  isHandsUp: handsStatus == .putUp,
                                                  isMicrophone: isMicrophone,
                                                  isAudience: isAudience,
                                                  isOpenBreakoutRoom: self.setting.isOpenBreakoutRoom,
                                                  isInBreakoutRoom: self.setting.isInBreakoutRoom)
            })
            .rightTitle(rightTitle)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                if isMicrophone {
                    self.setting.updateParticipantSettings {
                        $0.earlyPush = false
                        $0.participantSettings.micHandsStatus = handsStatus
                    }
                    HandsUpTracks.trackConfirmHandsUp(true,
                                                      isHandsUp: handsStatus == .putUp,
                                                      isMicrophone: isMicrophone,
                                                      isAudience: isAudience,
                                                      isOpenBreakoutRoom: self.setting.isOpenBreakoutRoom,
                                                      isInBreakoutRoom: self.setting.isInBreakoutRoom)
                    if handsStatus == .putDown {
                        UserActionTracks.trackHandsDownMicAction()
                    }
                } else {
                    self.setting.updateParticipantSettings {
                        $0.earlyPush = false
                        $0.participantSettings.cameraHandsStatus = handsStatus
                    }
                }
            })
            .show { [weak self] alert in
                if let self = self {
                    self.handsUpAlert = alert
                } else {
                    alert.dismiss()
                }
            }
    }

    func dismiss() {
        Util.runInMainThread { [weak self] in
            guard let self = self, !self.isDismissed else { return }
            self.isDismissed = true
            self.handsUpAlert?.dismiss()
            self.handsUpAlert = nil
            self.onDismiss?()
        }
    }
}

extension InMeetHandsupAlert: MeetingSettingListener, MeetingComplexSettingListener, InMeetingChangedInfoPushObserver {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        guard let old = oldValue?.settings else { return }
        if handsupType == .mic && myself.settings.handsStatus == .unknown && old.handsStatus != .unknown {
            dismiss()
        } else if handsupType == .camera && myself.settings.cameraHandsStatus == .unknown && old.cameraHandsStatus != .unknown {
            dismiss()
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasHostAuthority, isOn {
            dismiss()
        }
    }

    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        guard let status = value as? ParticipantHandsStatus, let old = oldValue as? ParticipantHandsStatus else { return }
        if status == .unknown && old != .unknown {
            dismiss()
        }
    }

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.type == .settingsChanged, let settingsChangedData = data.settingsChangedData,
           settingsChangedData.meetingSettings.allowPartiUnmute {
            Logger.audio.info("allowPartiUnmute change to true by settingChangedData")
            dismiss()
        }
    }
}
