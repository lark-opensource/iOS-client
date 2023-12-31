//
//  CameraContainer.swift
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/21.
//

import Foundation
import LarkFoundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignActionPanel
import UniverseDesignDialog
import LarkContainer
import LarkAccountInterface
import LarkLocalizations
import LKCommonsLogging
import LKCommonsTracker
import LarkAppLog
import UIKit
import EENavigator
import LarkMedia
import LarkMonitor
import LarkSensitivityControl
import CoreMotion

// swiftlint:disable all

// MARK: Color

public final class LVDCameraClor: NSObject {
    @objc
    public static func iconColor() -> UIColor {
        return UIColor.ud.primaryContentDefault
    }
}

// MARK: i18n

public final class LVDCameraI18N: NSObject {

    @objc
    public static func resourceBundle() -> Bundle {
        return BundleConfig.LarkVideoDirectorBundle
    }

    @objc
    public static func getLocalizedString(key: NSString, defaultStr: NSString? = nil) -> NSString {
        switch key {
        case "record_mode_shot":
            return BundleI18n.LarkVideoDirector.Lark_IM_PhotoTaking as NSString
        case "creation_shoot_split":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoTaking as NSString
        case "reverse":
            return BundleI18n.LarkVideoDirector.Lark_IM_FlipCamera as NSString
        case "filter":
            return BundleI18n.LarkVideoDirector.Lark_IM_FilterButton as NSString
        case "flash":
            return BundleI18n.LarkVideoDirector.Lark_IM_FlashButton as NSString
        case "discard_last_clip_popup_body":
            return BundleI18n.LarkVideoDirector.Lark_IM_DiscardVideoAlert as NSString
        case "discard_last_clip_popup_keep":
            return BundleI18n.LarkVideoDirector.Lark_IM_DiscardVideoAlert_Save as NSString
        case "discard_last_clip_popup_discard":
            return BundleI18n.LarkVideoDirector.Lark_IM_DiscardVideoAlert_Discard as NSString
        case "com_mig_beauty":
            return BundleI18n.LarkVideoDirector.Lark_IM_MakeupButton as NSString
        case "beauty_default":
            return BundleI18n.LarkVideoDirector.Lark_IM_RestoreAllEffects_Alert as NSString
        case "beauty_default_discard":
            return BundleI18n.LarkVideoDirector.Lark_IM_RestoreAllEffects_Restore as NSString
        case "beauty_default_keep":
            return BundleI18n.LarkVideoDirector.Lark_IM_RestoreAllEffects_Cancel as NSString
        case "beauty_default_tips":
            return BundleI18n.LarkVideoDirector.Lark_IM_RestoreAllEffects_Button as NSString
        case "message_send":
            return BundleI18n.LarkVideoDirector.Lark_IM_SendVideo as NSString
        case "message_finish":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_Done as NSString
        case "on":
            return BundleI18n.LarkVideoDirector.Lark_IM_Makeup_On as NSString
        case "off":
            return BundleI18n.LarkVideoDirector.Lark_IM_Makeup_Off as NSString
        case "com_mig_beauty_mode_off":
            return BundleI18n.LarkVideoDirector.Lark_IM_Makeup_Off as NSString
        case "cancel":
            return BundleI18n.LarkVideoDirector.Lark_IM_CancelAndCloseWindow as NSString
        case "av_exit_recording":
            return BundleI18n.LarkVideoDirector.Lark_IM_QuitCamera as NSString
        case "av_clear_recording_segments":
            return BundleI18n.LarkVideoDirector.Lark_IM_RetakeButton as NSString
        case "video_too_short":
            return BundleI18n.LarkVideoDirector.Lark_IM_TimeTooShortRetake_Toast as NSString
        case "transCoding":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoGeneratingNow as NSString
        case "save_photo":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoSavedToPhotos as NSString
        case "filter_local_normal":
            return BundleI18n.LarkVideoDirector.Lark_IM_FilterName01 as NSString
        case "filter_local_baixi":
            return BundleI18n.LarkVideoDirector.Lark_IM_FilterName02 as NSString
        case "filter_local_rixi":
            return BundleI18n.LarkVideoDirector.Lark_IM_FilterName03 as NSString
        case "av_beauty_smooth_skin":
            return BundleI18n.LarkVideoDirector.Lark_IM_BeautifySmoothSkin_Button as NSString
        case "av_beauty_reshape":
            return BundleI18n.LarkVideoDirector.Lark_IM_BeautifySlimFace_Button as NSString
        case "com_mig_eye":
            return BundleI18n.LarkVideoDirector.Lark_IM_BeautifyBiggerEyes_Button as NSString
        case "transcode_waiting":
            return BundleI18n.LarkVideoDirector.Lark_IM_OtherVideosBeingUploadedPlsWait_Toast as NSString
        case "transcode_failed":
            return BundleI18n.LarkVideoDirector.Lark_IM_FailedToProcessVideo_Toast as NSString
        case "ck_edit_clip":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_Edit as NSString
        case "ck_text_word":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_Text as NSString
        case "ck_image_sticker":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_Sticker as NSString
        case "ck_filter":
            return BundleI18n.LarkVideoDirector.Lark_IM_FilterButton as NSString
        case "ck_beautify":
            return BundleI18n.LarkVideoDirector.Lark_IM_MakeupButton as NSString
        case "ck_sticker_emoji":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_EmojiStickers_Title as NSString
        case "ck_edit_clip":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_Edit as NSString
        case "ck_video_synthesis":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoGeneratingNow as NSString
        case "ck_ablum_success_save_export_video":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoSavedToPhotos as NSString
        case "ck_setting_duration":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_SetDuration as NSString
        case "ck_edit_delete_confirm":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_DeleteSelectedClip_PopUpTitle as NSString
        case "ck_cancel":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_DeleteSelectedClip_CancelPopUpButton as NSString
        case "ck_confirm":
            return BundleI18n.LarkVideoDirector.Lark_Legacy_LarkConfirm as NSString
        case "ck_edit":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_EditText as NSString
        case "ck_preview_trash_text":
            return BundleI18n.LarkVideoDirector.Lark_IM_VideoEdit_DragHereToDelete as NSString
        case "ck_sticker_time_adjust_tip":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_StickerDurationSelected_Tooltip("%.1fs") as NSString
        case "ck_text_time_adjust_tip":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_TextDurationSelected_Tooltip("%.1fs") as NSString
        case "ck_beauty_ensure_recover_default_effect":
            return BundleI18n.LarkVideoDirector.Lark_IM_RestoreAllEffects_Alert as NSString
        case "com_mig_limit_reached_try_trimming_the_video":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_VideoLengthLimitReached_Toast as NSString
        case "com_mig_cant_shoot_in_splitscreen_mode_to_continue_switch_to_fullscreen_mode":
            return BundleI18n.LarkVideoDirector.Lark_Legacy_iPadSplitViewCamera as NSString
        case "download_model_failed":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_NetworkErrorLoadingFailedRetry_Toast as NSString
        case "com_mig_couldnt_shoot_video_try_again_later":
            return BundleI18n.LarkVideoDirector.Lark_IM_VE_PageBlockingUnableToRecordVideo_Toast as NSString
        default:
            break
        }
        return defaultStr ?? key
    }
}

// MARK: Toast

public final class LVDCameraToast: NSObject {

    @objc
    public static func show(message: String, on: UIView) {
        let config = UDToastConfig(toastType: .info, text: message, operation: nil)
        doInMainThread {
            UDToast.showToast(with: config, on: on)
        }
    }
    @objc
    public static func showSuccess(message: String, on: UIView) {
        let config = UDToastConfig(toastType: .success, text: message, operation: nil)
        doInMainThread {
            UDToast.showToast(with: config, on: on)
        }
    }

    @objc
    public static func showFailed(message: String, on: UIView) {
        let config = UDToastConfig(toastType: .error, text: message, operation: nil)
        doInMainThread {
            UDToast.showToast(with: config, on: on)
        }
    }

    @objc
    public static func showLoading(message: String, on: UIView) {
        let config = UDToastConfig(toastType: .loading, text: message, operation: nil)
        doInMainThread {
            UDToast.showToast(with: config, on: on, delay: 100_000)
        }
    }

    @objc
    public static func dismiss(on: UIView) {
        doInMainThread {
            UDToast.removeToast(on: on)
        }
    }
}

// MARK: Config

public final class LVDCameraConfig: NSObject {

    static var session = AVCaptureSession()

    @objc
    public static func deviceID() -> String {
        let service = implicitResolver?.resolve(DeviceService.self)
        return service?.deviceId ?? ""
    }

    @objc
    public static func installID() -> String {
        let service = implicitResolver?.resolve(DeviceService.self)
        return service?.installId ?? ""
    }

    @objc
    public static func appLanguage() -> String {
        return LanguageManager.currentLanguage.localeIdentifier
    }

    @objc
    public static func appID() -> String {
        return "1252"
    }

    @objc
    public static func supportMultitaskingCameraAccess() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }
        if #available(iOS 16.0, *) {
            LVDCameraMonitor.logger.info("camera session isMultitaskingCameraAccessSupported \(self.session.isMultitaskingCameraAccessSupported) isMultitaskingCameraAccessEnabled \(self.session.isMultitaskingCameraAccessEnabled)")
            if self.session.isMultitaskingCameraAccessSupported,
               self.session.isMultitaskingCameraAccessEnabled {
                return true
            }
        }
        return false
    }
}

// MARK: Monitor

public final class LVDCameraMonitor: NSObject {

    internal static var logger = Logger.log(LVDCameraMonitor.self, category: "LVDCameraMonitor")

    private static var photoTab: Bool = true

    struct TimeCostParams {
        /// App 生命周期内是否第一次启动
        var firstStart: Bool = true
        var startupTime: CFTimeInterval?
        var uiAppearTime: CFTimeInterval?
        var startupCPU: Float?

        mutating func consume() {
            firstStart = false
            startupTime = nil
            uiAppearTime = nil
            startupCPU = nil
        }
    }
    private static var timeCostPrams = TimeCostParams()

    @objc
    public static func setTab(photo: Bool) {
        photoTab = photo
    }

    @objc
    public static func getTabisPhoto() -> Bool {
        return photoTab
    }

    @objc
    public static func customTrack(_ event: String, params: [String: Any] = [:]) {
        var newParams = params
        newParams["tab"] = photoTab ? "photo" : "video"
        if newParams["target"] == nil {
            newParams["target"] = "none"
        }
        self.track(event: event, params: newParams)
    }

    @objc
    public static func trackNLE(_ event: String, params: [String: Any] = [:]) {
        var event = event.replacingOccurrences(of: "lite_", with: "public_")
        var newParams = params
        if let target = newParams["target"] as? String {
            newParams["target"] = target.replacingOccurrences(of: "lite_", with: "public_")
        }
        self.track(event: event, params: newParams)
    }

    @objc
    public static func track(event: String, params: [String: Any]?) {
        self.logger.info("event \(event) \(params ?? [:])")
        Tracker.post(TeaEvent(event, params: params ?? [:]))
    }

    @objc
    public static func track(logData: [String: Any]) {
        LarkAppLog.shared.tracker.customEvent("log_data", params: logData)
    }

    @objc
    public static func log(info: String, message: String) {
        self.logger.info("inf0 \(info) message \(message)")
    }

    // camera_start_dev

    @objc
    public static func startCamera() {
        timeCostPrams.startupTime = CACurrentMediaTime()
        timeCostPrams.startupCPU = (try? Utils.averageCPUUsage) ?? 0
    }

    @objc
    public static func cameraDidAppear() {
        timeCostPrams.uiAppearTime = CACurrentMediaTime()
    }

    @objc
    public static func cameraDidRenderFirstFrame() {
        let firstFrameTime = CACurrentMediaTime()
        if let startupTime = timeCostPrams.startupTime,
           let uiAppearTime = timeCostPrams.uiAppearTime,
           let startupCPU = timeCostPrams.startupCPU {
            let pageTimeCost = (uiAppearTime - startupTime) * 1000
            let firstFrameTimeCost = (firstFrameTime - uiAppearTime) * 1000
            let params: [String: Any] = [
                "type": "ck",
                "is_first_open": timeCostPrams.firstStart ? 1 : 0,
                "cpu_usage": startupCPU,
                "open_page_duration": pageTimeCost,
                "open_camera_duration": firstFrameTimeCost
            ]
            let eventName = "camera_start_dev"
            Tracker.post(TeaEvent(eventName, params: params))
            logger.info("\(eventName) \(params)")
        }
        timeCostPrams.consume()
    }

    // 功耗

    @objc
    public static func startCameraPowerMonitor() {
        BDPowerLogManager.beginEvent("messenger_video_record", params: ["scene": "veCamera"])
    }

    @objc
    public static func endCameraPowerMonitor() {
        BDPowerLogManager.endEvent("messenger_video_record", params: ["scene": "veCamera"])
    }

    @objc
    public static func startPreviewPowerMonitor() {
        BDPowerLogManager.beginEvent("messenger_video_preview", params: ["scene": "veCamera"])
    }

    @objc
    public static func endPreviewPowerMonitor() {
        BDPowerLogManager.endEvent("messenger_video_preview", params: ["scene": "veCamera"])
    }
}

// MARK: AudioSession

@objc
public enum LVDCameraSessionScene: Int, RawRepresentable {
    case camera
    case videoRecord
    case editor

    var mediaMutexScene: MediaMutexScene {
        switch self {
        case .camera: return .commonCamera
        case .videoRecord: return .commonVideoRecord
        case .editor: return .imVideoPlay
        }
    }
}

public final class LVDCameraSession: NSObject {
    private static let logger = Logger.log(LVDCameraSession.self, category: "LVDCameraSession")
    private static let options: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay, .mixWithOthers, .duckOthers]
    private static let cameraScenario = AudioSessionScenario("lark.new.camera", category: .playAndRecord, mode: .default, options: options)
    private static let editorScenario = AudioSessionScenario("lark.new.videoEditor", category: .playback, mode: .default, options: options)

    private static var category: AVAudioSession.Category = .playAndRecord

    @objc
    public static var cameraScene: LVDCameraSessionScene = .camera

    @objc
    public static func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) {
        self.category = category
    }

    @objc
    public static func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) {
        self.setActive(active)
    }

    @objc
    public static func setActive(_ active: Bool) {
        self.setActive(active, category: LVDCameraSession.category, force: false)
    }

    private static func setActive(_ active: Bool, category: AVAudioSession.Category, force: Bool) {
        self.logger.info("camera session setActive \(active) \(category.rawValue) \(options) force \(force)")
        guard let audioSession = LarkMediaManager.shared.getMediaResource(for: cameraScene.mediaMutexScene)?.audioSession else {
            self.logger.info("camera session setActive failed, audioSession not found")
            return
        }
        self.logger.info("camera session current info \(String(describing: audioSession.activeScenario))")

        let scenario: AudioSessionScenario
        if category == .playAndRecord {
            scenario = LVDCameraSession.cameraScenario
        } else {
            scenario = LVDCameraSession.editorScenario
        }
        /// 这里只处理 active 的场景
        if active {
            audioSession.enter(scenario, options: .enableSpeakerIfNeeded)
        } else if force {
            audioSession.leave(scenario)
        }
    }

    @objc
    public static func deactiveIfNeeded(with category: AVAudioSession.Category) {
        self.logger.info("camera session deactiveIfNeeded \(category.rawValue)")
        self.setActive(false, category: category, force: true)
    }
}

// MARK: Alert

public final class LVDCameraAlert: NSObject {

    @objc
    public static func currentWindow() -> UIWindow {
        return UIApplication.shared.keyWindow ??
            UIApplication.shared.windows.first ??
            UIWindow()
    }

    @objc
    public static func currentWindow(from: UIViewController?) -> UIWindow {
        return from?.currentWindow() ?? self.currentWindow()
    }

    @objc
    public static func show(alert: UIAlertController, on: UIView) {
        typealias AlertHandler = @convention(block) (UIAlertAction) -> Void
        if alert.preferredStyle == .alert {
            let dialog = UDDialog()
            if let title = alert.title, !title.isEmpty {
                dialog.setTitle(text: title)
            }
            if let content = alert.message, !content.isEmpty {
                dialog.setContent(text: content)
            }
            alert.actions.reversed().forEach { action in
                var handler: AlertHandler?
                if let block = action.value(forKey: "handler") {
                    handler = unsafeBitCast(block as AnyObject, to: AlertHandler.self)
                }
                let actionHandler: () -> Void = {
                    handler?(action)
                }
                if action.title == BundleI18n.LarkVideoDirector.Lark_IM_DiscardVideoAlert_Discard {
                    dialog.addDestructiveButton(text: action.title ?? "", dismissCompletion: actionHandler)
                } else if action.style == .default {
                    dialog.addPrimaryButton(text: action.title ?? "", dismissCompletion: actionHandler)
                } else if action.style == .cancel {
                    dialog.addSecondaryButton(text: action.title ?? "", dismissCompletion: actionHandler)
                } else {
                    dialog.addDestructiveButton(text: action.title ?? "", dismissCompletion: actionHandler)
                }
            }
            doInMainThread {
                Navigator.shared.present(dialog, from: on.window ?? Navigator.shared.mainSceneWindow!)
            }
        } else {
            let config = UDActionSheetUIConfig(style: .normal)
            let actionSheet = UDActionSheet(config: config)
            actionSheet.modalPresentationStyle = .overFullScreen
            if let title = alert.title, !title.isEmpty {
                actionSheet.setTitle(title)
            }
            alert.actions.forEach { action in
                var handler: AlertHandler?
                if let block = action.value(forKey: "handler") {
                    handler = unsafeBitCast(block as AnyObject, to: AlertHandler.self)
                }
                let actionHandler: () -> Void = {
                    handler?(action)
                }
                if action.style == .default {
                    actionSheet.addDefaultItem(text: action.title ?? "", action: actionHandler)
                } else if action.style == .cancel {
                    actionSheet.setCancelItem(text: action.title ?? "", action: actionHandler)
                } else {
                    actionSheet.addDestructiveItem(text: action.title ?? "", action: actionHandler)
                }
            }
            doInMainThread {
                Navigator.shared.present(actionSheet, from: on.window ?? Navigator.shared.mainSceneWindow!)
            }
        }
    }

    @objc
    public static func show(
        title: String,
        description: String,
        leftTitle: String,
        rightTitle: String,
        leftBlock: @escaping () -> Void,
        rightBlock: @escaping () -> Void,
        controller: UIViewController
    ) {
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: description)
        dialog.addPrimaryButton(text: leftTitle, dismissCompletion: {
            leftBlock()
        })
        dialog.addPrimaryButton(text: rightTitle, dismissCompletion: {
            rightBlock()
        })
        doInMainThread {
            Navigator.shared.present(dialog, from: controller)
        }
    }
}

// MARK: Motion

public final class LVDMotionManager: NSObject {

    public static var logger = Logger.log(LVDMotionManager.self, category: "LVDMotionManager")

    @objc
    public static func startDeviceMotionUpdates(
        manager: CMMotionManager,
        queue: OperationQueue,
        handler: @escaping CMDeviceMotionHandler
    ) {
        do {
            try DeviceInfoEntry.startDeviceMotionUpdates(
                forToken: Token(withIdentifier: "LARK-PSDA-ve_camera_motion_monitor"),
                manager: manager,
                to: queue,
                withHandler: handler
            )
        } catch {
            self.logger.warn("Could not startDeviceMotionUpdates by LarkSensitivityControl API")
        }
    }
}

func doInMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
// swiftlint:enable all
