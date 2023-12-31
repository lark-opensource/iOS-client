//
//  ZoomDefaultSettingViewModel+DataDealer.swift
//  Calendar
//
//  Created by pluto on 2022/11/16.
//

import Foundation

extension ZoomDefaultSettingViewModel {
    func selectAutoMeetingNo() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.autogenMeetingNoPassword.meetingNo.optionButton.editable == false && !zoomSetting.isAutoMeetingNoSelected {
            toastDefaultLockedMsg()
            return
        }

        zoomSetting.autogenMeetingNoPassword.meetingNo.optionButton.selected = true
        zoomSetting.personalMeetingNoPassword.meetingNo.optionButton.selected = false
        if let bfh = originalZoomSettings?.joinBeforeHost {
            zoomSetting.joinBeforeHost = bfh
        }
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
        securityOptionsCheck()
        resetPassCodetStatus()
    }

    func selectSoloMeetingNo() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.personalMeetingNoPassword.meetingNo.optionButton.editable == false && !zoomSetting.isPersonMeetingNoSelected {
            switch zoomSetting.personalMeetingNoPassword.meetingNo.lockedType {
            case .lockedByAdmin:
                toastDefaultLockedMsg()
            case .closed:
                rxToast.accept(.tips(I18n.Calendar_Zoom_PersonalClosed))
            @unknown default:
                break
            }
            return
        }

        zoomSetting.autogenMeetingNoPassword.meetingNo.optionButton.selected = false
        zoomSetting.personalMeetingNoPassword.meetingNo.optionButton.selected = true
        zoomSetting.joinBeforeHost.jbhType = .anytime

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
        securityOptionsCheck()
        resetPassCodetStatus()
    }

    func updatePassCodeStatus(passCodeInfo: Server.ZoomSetting.Password) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        var tmpComparablePassword: Server.ZoomSetting.Password?
        if zoomSetting.isAutoMeetingNoSelected {
            zoomSetting.autogenMeetingNoPassword.passwordInfo = passCodeInfo
            tmpComparablePassword = comparableZoomSettings?.autogenMeetingNoPassword.passwordInfo
        } else {
            zoomSetting.personalMeetingNoPassword.passwordInfo = passCodeInfo
            tmpComparablePassword = comparableZoomSettings?.personalMeetingNoPassword.passwordInfo
        }

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
        securityOptionsCheck()

        if let tmpPassCodeInfo = tmpComparablePassword, !(tmpPassCodeInfo == passCodeInfo) {
            resetPassCodetStatus()
        }
    }

    func clickWaitingRoom(isOn: Bool) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.waitingRoom.selected = isOn

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
        securityOptionsCheck()
    }

    func updateVerifyInfo(authenticationInfo: Server.ZoomMeetingSettings.Authentication) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.authentication = authenticationInfo

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
        securityOptionsCheck()
    }

    func clickHostTick(isOn: Bool) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.host.selected = isOn
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickParticipantTick(isOn: Bool) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.participant.selected = isOn
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickPhoneTick() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.audio.editable == false && zoomSetting.audio.audioType != .telephone {
            toastDefaultLockedMsg()
            return
        }

        zoomSetting.audio.audioType = .telephone
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickComputerTick() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.audio.editable == false && zoomSetting.audio.audioType != .voip {
            toastDefaultLockedMsg()
            return
        }

        zoomSetting.audio.audioType = .voip
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickPhoneComputerTick() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.audio.editable == false && zoomSetting.audio.audioType != .both {
            toastDefaultLockedMsg()
            return
        }

        zoomSetting.audio.audioType = .both
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickAllowAnyTimeEnter(isOn: Bool) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.joinBeforeHost.optionButton.selected = isOn
        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func updateTimeLimit(info: Server.ZoomMeetingSettings.BeforeHost) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.joinBeforeHost = info

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickAllowEnterRoomMute(isOn: Bool) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.mute.selected = isOn

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickAutoRecord(isOn: Bool) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.autoRecording.autoRecordButton.selected = isOn

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func clickAutoRecordToLocal() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.autoRecording.autoRecordButton.editable == false && zoomSetting.autoRecording.autoRecordType != .local {
            toastDefaultLockedMsg()
            return
        }

        zoomSetting.autoRecording.autoRecordType = .local

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func ClickAutoRecordInCloud() {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        if zoomSetting.autoRecording.autoRecordButton.editable == false && zoomSetting.autoRecording.autoRecordType != .cloud {
            toastDefaultLockedMsg()
            return
        }

        zoomSetting.autoRecording.autoRecordType = .cloud

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))
    }

    func updateAlternativeHost(info: [String]) {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return
        }

        zoomSetting.alternativeHosts = info

        rxViewData.accept(ViewData(zoomSetting: zoomSetting))

        if !(comparableZoomSettings?.alternativeHosts == info) {
            updateErrorTipsStatus(type: .alternativeHostsIllegal)
            self.hasInputError = false
        }
    }

    private func toastDefaultLockedMsg() {
        rxToast.accept(.tips(I18n.Calendar_Zoom_LockedByAdmin))
    }

    func checkLimitTimeCellLocked() -> Bool {
        guard var zoomSetting = rxViewData.value?.zoomSetting else {
            return true
        }

        if zoomSetting.joinBeforeHost.optionButton.editable == false {
            toastDefaultLockedMsg()
            return true
        }

        return false
    }

    private func updateErrorTipsStatus(type: Server.UpdateZoomSettingsResponse.State) {
        self.delegate?.updateErrorTipsStatus(type: type)
    }

    private func resetPassCodetStatus() {
        updateErrorTipsStatus(type: .passwordIllegal)
        passCodeErrroTips = []
        self.hasInputError = false
    }
}

extension Server.ZoomSetting {

    var isAutoMeetingNoSelected: Bool {
        return self.autogenMeetingNoPassword.meetingNo.optionButton.selected
    }

    var isPersonMeetingNoSelected: Bool {
        return self.personalMeetingNoPassword.meetingNo.optionButton.selected
    }

    var isMeetingNoLocked: Bool {
        return !(self.autogenMeetingNoPassword.meetingNo.optionButton.editable && self.personalMeetingNoPassword.meetingNo.optionButton.editable)
    }

    var autoMeetingNo: String {
        return "\(self.autogenMeetingNoPassword.meetingNo.meetingNo)".formatZoomMeetingNumber()
    }

    var soloMeetingNo: String {
        return "\(self.personalMeetingNoPassword.meetingNo.meetingNo)".formatZoomMeetingNumber()
    }

    var isPassCodeOptionOpen: Bool {
        return isAutoMeetingNoSelected ? self.autogenMeetingNoPassword.passwordInfo.optionButton.selected : self.personalMeetingNoPassword.passwordInfo.optionButton.selected
    }

    var isAuthenticationOptionOpen: Bool {
        return self.authentication.optionButton.selected
    }

    var isWaitingRoomOptionOpen: Bool {
        return self.waitingRoom.selected
    }

    var isAllowAnyTimeJoin: Bool {
        return self.joinBeforeHost.jbhType == .anytime
    }

    var isAutoDisplaySelected: Bool {
        return self.autoRecording.autoRecordButton.selected
    }

    var isLocalRecordSelected: Bool {
        return self.autoRecording.autoRecordType == .local
    }

    var isClouldRecordSelected: Bool {
        return self.autoRecording.autoRecordType == .cloud
    }
}
