//
//  InMeetBatteryComponent.swift
//  ByteView
//
//  Created by ZhangJi on 2022/5/30.
//

import Foundation
import UniverseDesignToast
import ByteViewSetting

final class InMeetBatteryComponent: InMeetViewComponent {
    private let logger = Logger.getLogger("BatteryStatus.Component")
    let meeting: InMeetMeeting
    let batteryManager: InMeetBatteryStatusManager?

    weak var container: InMeetViewContainer?
    private let resolver: InMeetViewModelResolver
    private var isShowingToast: Bool = false

    private var voiceModeToaseDuration: Double {
        Double(meeting.setting.voiceModeConfig.thermalAdjustConfig.voiceModeToastShowDuration)
    }


    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.batteryManager = viewModel.resolver.resolve()
        self.resolver = viewModel.resolver
        self.container = container

        batteryManager?.addListener(self)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        return .battery
    }

    deinit {
        batteryManager?.removeListener(self)
    }

    private func showBatteryToast(_ toastType: BatteryToastType) {
        Util.runInMainThread { [weak self] in
            self?._showBatteryToast(toastType)
        }
    }

    private func _showBatteryToast(_ toastType: BatteryToastType) {
        if meeting.router.isFloating {
            logger.info("showBatteryToast dont show via floating: \(toastType)")
            return
        }
        if isShowingToast {
            logger.info("showBatteryToast already show: \(toastType)")
            return
        }

        switch toastType {
        case .voiceMode(let voiceModeReason):
            self.showVoiceModeToastForReaseon(voiceModeReason)
        case .ecoMode(let rate):
            self.showEcoModeToast(rate)
        }
    }

    private func showVoiceModeToastForReaseon(_ reason: VoiceModeReason) {
        logger.info("showVoiceModeToastForReaseon: \(reason)")
        var text = ""
        switch reason {
        case .performance:
            text = I18n.View_MV_RecToAudioMode_KeepAudioAndShare
        case .battery(let val):
            text = I18n.View_MV_BatterySwitch_KeepAudioAndShare(val)
        case .thermal(let state):
            switch state {
            case .serious:
                text = I18n.View_G_TempHighSwitch_KeepAudioAndShare
            case .critical:
                text = I18n.View_G_TempVeryHighWarn_KeepAudioAndShare
            default:
                break
            }
        }
        let config = UDToastConfig(toastType: .info, text: text, operation: UDToastOperationConfig(text: I18n.View_G_SwitchButtonNow, displayType: .horizontal), delay: voiceModeToaseDuration)
        if let w = meeting.router.window, !w.isFloating {
            isShowingToast = true
            BatteryStatusTracks.trackBatteryToastShow(toastType: .voiceMode(reason))
            batteryManager?.didShowBatteryToast(.voiceMode(reason))
            UDToast.showToast(with: config, on: w, delay: voiceModeToaseDuration) { [weak self] _ in
                guard let self = self else { return }
                BatteryStatusTracks.trackBatteryToastClick(toastType: .voiceMode(reason))
                self.batteryManager?.enableVoiceMode(true, reason: reason)
                self.isShowingToast = false
            } dismissCallBack: { [weak self] in
                self?.isShowingToast = false
            }
        }
    }

    private func showEcoModeToast(_ rate: Double) {
        logger.info("showEcoModeToastBatteryLevel: \(rate)")
        let config = UDToastConfig(toastType: .info, text: I18n.View_G_Setting_LowPowerModeSuggestNoLink_Toast, operation: UDToastOperationConfig(text: I18n.View_G_SwitchButtonNow, displayType: .horizontal), delay: voiceModeToaseDuration)
        if let w = meeting.router.window, !w.isFloating {
            isShowingToast = true
            BatteryStatusTracks.trackBatteryToastShow(toastType: .ecoMode(rate))
            batteryManager?.didShowBatteryToast(.ecoMode(rate))
            UDToast.showToast(with: config, on: w, delay: voiceModeToaseDuration) { [weak self] _ in
                guard let self = self else { return }
                BatteryStatusTracks.trackBatteryToastClick(toastType: .ecoMode(rate))
                self.batteryManager?.enableEcoMode(true)
                self.isShowingToast = false
            } dismissCallBack: { [weak self] in
                self?.isShowingToast = false
            }
        }
    }
}

extension InMeetBatteryComponent: InMeetBatteryStatusListener {
    func shouldShowBatteryToast(_ type: BatteryToastType) {
        self.showBatteryToast(type)
    }
}
