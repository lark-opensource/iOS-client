//
//  ZoomDefaultSettingController+ListViewAction.swift
//  Calendar
//
//  Created by pluto on 2022/11/16.
//

import Foundation
import EENavigator

extension ZoomDefaultSettingController: ZoomSettingListViewDelegate {

    func didSelectAutoMeetingNo() {
        viewModel.selectAutoMeetingNo()
    }

    func didSelectSoloMeetingNo() {
        viewModel.selectSoloMeetingNo()
    }

    func didClickPassCodeCell() {
        let info = viewModel.getZoomPassCodeInfo()
        let vc = ZoomPasswordViewController(passCodeInfo: info, errorTitles: viewModel.passCodeErrroTips)
        vc.onSavePassCode = { [weak self] passCodeInfo in
            guard let self = self else { return }
            self.viewModel.updatePassCodeStatus(passCodeInfo: passCodeInfo)
        }
        self.userResolver.navigator.push(vc, from: self)
    }

    func didClickWaitingRoom(isOn: Bool) {
        viewModel.clickWaitingRoom(isOn: isOn)
    }

    func didClickVerifyCell() {
        let info = viewModel.getAuthenticationInfo()
        let vc = ZoomIdentityAuthenticationViewController(authenticationInfo: info)
        vc.onSaveAuthenticationCallBack = { [weak self] authenticationInfo in
            guard let self = self else { return }
            self.viewModel.updateVerifyInfo(authenticationInfo: authenticationInfo)
        }
        self.userResolver.navigator.push(vc, from: self)
    }

    func didClickTimeLimitCell() {
        if viewModel.checkLimitTimeCellLocked() { return }
        let info = viewModel.getLimitTimeInfo()
        let vc = ZoomLimitTimePickerViewController(info: info)
        vc.onSaveCallBack = { [weak self] info in
            guard let self = self else { return }

            self.viewModel.updateTimeLimit(info: info)
        }

        self.userResolver.navigator.push(vc, from: self)
    }

    func didClickHostTick(isOn: Bool) {
        viewModel.clickHostTick(isOn: isOn)
    }

    func didClickParticipantTick(isOn: Bool) {
        viewModel.clickParticipantTick(isOn: isOn)
    }

    func didClickPhoneTick() {
        viewModel.clickPhoneTick()
    }

    func didClickComputerTick() {
        viewModel.clickComputerTick()
    }

    func didClickPhoneComputerTick() {
        viewModel.clickPhoneComputerTick()
    }

    func didClickAllowAnyTimeEnter(isOn: Bool) {
        viewModel.clickAllowAnyTimeEnter(isOn: isOn)
    }

    func didClickAllowEnterRoomMute(isOn: Bool) {
        viewModel.clickAllowEnterRoomMute(isOn: isOn)
    }

    func didClickAutoRecord(isOn: Bool) {
        viewModel.clickAutoRecord(isOn: isOn)
    }

    func didClickAutoRecordToLocal() {
        viewModel.clickAutoRecordToLocal()
    }

    func didClickAutoRecordInCloud() {
        viewModel.ClickAutoRecordInCloud()
    }

    func didClickAlternativeHostCell() {
        let info = viewModel.getAlternativeHosts()
        let vm = ZoomAlternativeHostViewModel(info: info)
        let vc = ZoomAlternativeHostViewController(viewModel: vm)
        vc.onSaveCallBack = {[weak self] info in
            guard let self = self else { return }
            self.viewModel.updateAlternativeHost(info: info)
        }
        self.userResolver.navigator.push(vc, from: self)
    }
}
