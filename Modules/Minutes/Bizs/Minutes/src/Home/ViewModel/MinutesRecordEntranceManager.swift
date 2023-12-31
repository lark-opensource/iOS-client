//
//  MinutesRecordEntranceManager.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/9.
//

import Foundation
import CoreTelephony
import UniverseDesignToast
import UniverseDesignDialog
import AVFoundation
import RoundedHUD
import MinutesFoundation
import MinutesNetwork
import EENavigator
import LarkUIKit
import LarkFeatureGating
import LarkAlertController
import LarkAppConfig
import RichLabel
import LarkMedia
import LarkContainer
import LarkAccountInterface
import LarkSetting
import LarkSensitivityControl

// tab情况下homevc不释放，存在多个manager的场景
var lastCreateRequestTime: CFAbsoluteTime?

class MinutesRecordEntranceManager: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedProvider var passportUserService: PassportUserService?
    @ScopedProvider var featureGatingService: FeatureGatingService?

    var userId: String {
        return passportUserService?.user.userID ?? ""
    }

    var minutesRecordingEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .byteviewMMIOSRecording) == true
    }

    let tracker = BusinessTracker()

    var entrances = [RecordEntrance]()
    var currentEntrance: RecordEntrance?
    var recordView: MinutesHomeAudioRecordCircleView? {
        return currentEntrance?.recordView
    }
    var isRecordShow = false
    var canAddItemToList = true

    private var isInDemo: Bool {
        if let plistInfo = Bundle.main.infoDictionary, let displayName = plistInfo["CFBundleName"] as? String, displayName == "Minutes_Example" {
            return true
        } else {
            return false
        }
    }

    private var privacyDialog: UDDialog?

    init(resolver: UserResolver) {
        MinutesLogger.record.info("minutes record entrance manager init")
        self.userResolver = resolver
        MinutesAudioRecorder.shared.shouldFetchLanguage = true
        addObserver()
    }

    deinit {
        MinutesLogger.record.info("minutes record entrance manager deinit")
        NotificationCenter.default.removeObserver(self)
    }

    private func addObserver() {
        MinutesLogger.record.info("minutes record entrance manager addObserver")
        MinutesAudioRecorder.shared.listeners.addListener(self)
        MinutesAudioDataUploadCenter.shared.initUploaderCheck(userId: userId)
        MinutesAudioDataUploadCenter.shared.listeners.addListener(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveMinutesAudioRecordingVCDismissNotification(_:)),
                                               name: Notification.minutesAudioRecordingVCDismiss,
                                               object: nil)
    }

    func appendEntrance(withController controller: MinutesHomePageViewController) {
        let rv = MinutesHomeAudioRecordCircleView()
        rv.onClickCircleButton = { [weak self] in
            self?.recordButtonAction()
        }
        rv.isHidden = true
        let entrance = RecordEntrance()
        entrance.viewController = controller
        entrance.recordView = rv
        entrances.append(entrance)
        currentEntrance = entrance
    }

    func popLast() {
        entrances.popLast()
        currentEntrance = entrances.last
    }

    private func showSpaceNotEnoughAlert(warningText: String) {

        let alertController: LarkAlertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Minutes.MMWeb_M_Record_InsufficientStorage_PopupTitle, color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        alertController.setContent(text: warningText, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: nil)
        alertController.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_M_Record_InsufficientStorageRecordAnyway_PopupButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.preAudioRecord()
        })
        currentEntrance?.viewController?.present(alertController, animated: true)
    }

    private func recordButtonAction() {
        guard let view = currentEntrance?.viewController?.view else { return }
        tracker.tracker(name: .listClick, params: ["click": "start_recording", "target": "vc_minutes_recording_view"])

        let isOnPhoneCall = Device.IsOnPhoneCall()
        let isInPodcast = MinutesPodcast.shared.isInPodcast

        if isOnPhoneCall {
            MinutesLogger.record.info("current isOnPhoneCall")
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CanNotRecordInCall, on: view)
            return
        }

        // 播客模式下开启录音
        if isInPodcast {
            MinutesLogger.record.info("current isInPodcast")
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CanNotRecordInPodcastMode, on: view)
            return
        }

        var spaceWarning: String?
        if let remainSpace = MinutesDeviceHelper.deviceRemainingFreeSpaceInBytes() {
            let remainSpaceThreshold = 120 * 1024 * 1024
            if remainSpace >= remainSpaceThreshold {
                spaceWarning = nil
            } else {
                spaceWarning = BundleI18n.Minutes.MMWeb_M_Record_InsufficientStorage_PopupText
            }
        }
        if let spaceWarning = spaceWarning {
            self.showSpaceNotEnoughAlert(warningText: spaceWarning)
        } else {
            self.preAudioRecord()
        }
    }

    private func preAudioRecord() {
        if MinutesAudioRecorder.shared.status == .idle {
            let permission = AVAudioSession.sharedInstance().recordPermission
            if permission == .undetermined {
                do {
                    try AudioRecordEntry.requestRecordPermission(forToken: Token(withIdentifier: DeviceToken.microphoneAccess.rawValue), session: AVAudioSession.sharedInstance()) { [weak self] allowed in
                        guard let wSelf = self else { return }
                        DispatchQueue.main.async {
                            if allowed {
                                wSelf.checkMinutesAudioPrivacy()
                            } else {
                                wSelf.showMicrophonePrivacyAlert()
                            }
                        }
                    }
                } catch {
                    if let controller = currentEntrance?.viewController {
                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: controller.view, delay: 2.0)
                    }
                    MinutesLogger.record.info("request microphone access encounter exception: \(error)")
                }
            } else if permission == .denied {
                self.showMicrophonePrivacyAlert()
            } else {
                self.checkMinutesAudioPrivacy()
            }
        }
    }

    private func checkMinutesAudioPrivacy() {
        guard let controller = currentEntrance?.viewController, let recordView = currentEntrance?.recordView else { return }
        RoundedHUD.showLoading(with: nil, on: controller.view, disableUserInteraction: false)

        Minutes.getAudioRecordUserGuide(catchError: true) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    RoundedHUD.removeHUD(on: controller.view)
                    switch result {
                    case .success(let result):
                        if result.guided {
                            self.createAudioRecord()
                        } else {
                            let privacyURL: String = PrivacyConfig.dynamicPrivacyURL ?? PrivacyConfig.privacyURL
                            self.showAddUserGuideAlert(linkUrl: privacyURL) { link in
                                guard let url = URL(string: link) else {
                                    return
                                }
                                self.privacyDialog?.dismiss(animated: true, completion: {
                                    self.privacyDialog = nil
                                    self.userResolver.navigator.push(url, from: controller)
                                })
                            }
                        }
                    case .failure(let error):
                        MinutesLogger.record.warn("get audioRecordUserGuide for audio record error:\(error)")
                    }
                }
        }
    }

    private func addMinutesAudioPrivacy() {
        Minutes.addAudioRecordUserGuide(catchError: true) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let minutes):
                    break
                case .failure(let error):
                    MinutesLogger.record.warn("get audioRecordUserGuide for audio record error:\(error)")
                }
        }
    }

    private func showAddUserGuideAlert(linkUrl: String, openLink: ((String) -> Void)?) {
        guard let controller = currentEntrance?.viewController else { return }
        let label = LKLabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = .clear

        let alertText = BundleI18n.Minutes.MMWeb_G_MinutesPrivacyStatement_Description
        let linkText = LinkTextParser.parsedLinkText(from: alertText)
        let linkFont = UIFont.systemFont(ofSize: 16)

        for (index, component) in linkText.components.enumerated() {
            var link = LKTextLink(range: component.range,
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.primaryContentDefault,
                                               .font: linkFont])
            link.linkTapBlock = { (_, link: LKTextLink) in
                openLink?(linkUrl)
            }
            label.addLKTextLink(link: link)
        }

        let attributedString = NSAttributedString(string: linkText.result,
                                                  attributes: [.font: linkFont,
                                                               .foregroundColor: UIColor.ud.textTitle])
        label.attributedText = attributedString

        let layout = LKTextLayoutEngineImpl()
        layout.attributedText = attributedString
        let margin: CGFloat = 40
        layout.preferMaxWidth = UDDialog.Layout.dialogWidth - margin
        layout.layout(size: CGSize(width: UDDialog.Layout.dialogWidth - margin, height: CGFloat.greatestFiniteMagnitude))
        let height = layout.textSize.height

        let title = BundleI18n.Minutes.MMWeb_G_MinutesPrivacyStatement_Title

        var config = UDDialogUIConfig()
        config.style = .normal
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: title)
        dialog.setContent(view: label)

        let content = UIView()
        content.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(height)
        }

        dialog.setContent(view: content)

        dialog.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: {[weak self] in
            guard let self = self else { return }
            self.privacyDialog = nil
        })
        dialog.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_G_StartRecording_Button, dismissCompletion: {[weak self] in
            guard let self = self else { return }
            self.privacyDialog = nil
            self.createAudioRecord()
        })

        self.privacyDialog = dialog
        self.addMinutesAudioPrivacy()
        controller.present(dialog, animated: true)
    }
    
    private func createAudioRecord(isForced: Bool = false) {
        guard let controller = currentEntrance?.viewController, let recordView = currentEntrance?.recordView else {
            return
        }
        recordView.circleButton.isUserInteractionEnabled = true
        
        MinutesRecorderReciableTracker.shared.startEnterRecorder()
        
        guard MinutesAudioRecorder.shared.perpare() else {
            MinutesLogger.record.warn("MinutesAudioRecorder perpare failed. show toast.")
            recordView.circleButton.isUserInteractionEnabled = true
            createAudioRecordfailed(error: .unknown)
            return
        }
        
        MinutesAudioRecorder.shared.tryOpenAudio(isForced: isForced)
    }
    
    private func requestCreateMinutesForAudioRecord(isForced: Bool) {
        MinutesLogger.record.info("start request create minutes, thread: \(Thread.current), self: \(self), lastCreateRequestTime: \(lastCreateRequestTime)")

        // 需要throttle，防止短时间执行请求导致异常
        // https://bytedance.feishu.cn/docx/TpHzdA0dxosulExddEEcMZr0ndb
        if let lastTime = lastCreateRequestTime {
            let currentTime = CFAbsoluteTimeGetCurrent()
            MinutesLogger.record.info("request create minutes currentTime: \(currentTime), lastTime: \(lastTime), minus: \(currentTime - lastTime)")
            let threshold = 0.5
            if currentTime - lastTime < threshold { // 0.5s内连续请求
                MinutesLogger.record.warn("continuous requests in a short period of time, return")
                return
            } else {
                lastCreateRequestTime = currentTime
                MinutesLogger.record.info("request create minutes update lastCreateRequestTime: \(lastCreateRequestTime)")
            }
        } else {
            lastCreateRequestTime = CFAbsoluteTimeGetCurrent()
            MinutesLogger.record.info("request create minutes set lastCreateRequestTime: \(lastCreateRequestTime)")
        }
        
        guard let controller = currentEntrance?.viewController, let recordView = currentEntrance?.recordView else {
            return
        }
        
        RoundedHUD.showLoading(with: nil, on: controller.view, disableUserInteraction: false)

        Minutes.createMinutesForAudioRecord(catchError: false, isForced: isForced, topic: BundleI18n.Minutes.MMWeb_G_UntitledRecording) { [weak self] result in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                recordView.circleButton.isUserInteractionEnabled = true
                RoundedHUD.removeHUD(on: controller.view)
                switch result {
                case .success(let minutes):
                    MinutesRecorderReciableTracker.shared.finishNetworkReqeust()

                    let currenrUserSession = strongSelf.passportUserService?.user.sessionKey
                    MinutesAudioRecorder.shared.start(minutes, container: strongSelf.userResolver.navigator.mainSceneWindow, session: currenrUserSession)
                    MinutesRecorderReciableTracker.shared.finishDataProcess()
                    let body = MinutesAudioRecordingBody(minutes: minutes, source: .createIcon)
                        strongSelf.userResolver.navigator.present(body: body, from: controller, prepare: {$0.modalPresentationStyle = .fullScreen})
                    strongSelf.trackerStartRecording()
                    strongSelf.canAddItemToList = true

                    strongSelf.tracker.tracker(name: .minutesRecordingClickDev, params: [ "is_error": 0])

                case .failure(let error):
                    MinutesRecorderReciableTracker.shared.cancelEnterRecorder()
                    if let error = MinutesCommonErrorToastManger.message(forKey: MinutesAPIPath.create), error.code == noKeyCode {
                        UDToast.showFailure(with: BundleI18n.Minutes.MMWeb_NoKeyNoRecord_Toast, on: controller.view, delay: 2)
                    } else if let err = error as? StorageSpaceError {
                        let isAdmin = err.isAdmin
                        strongSelf.showStorageSpaceNotEnoughAlertController(isAdmin: isAdmin, notice: err.errorDescription, billUrl: err.billUrl)
                    } else if let err = error as? ResponseError, err == .inRecording {
                        strongSelf.showExistAudioRecordingAlertController()
                    } else {
                        UDToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: controller.view, delay: 2)
                        MinutesReciableTracker.shared.error(scene: .MinutesRecorder,
                                                            event: .minutes_create_audio_record_error,
                                                            error: error,
                                                            extra: nil)

                    }
                    MinutesAudioRecorder.shared.cleanup()
                    MinutesLogger.record.warn("create minutes for audio record error:\(error)")
                    
                    var params: [String: Any] = ["is_error": 1]
                    params["server_error_code"] = "\(error.minutes.code)"
                    strongSelf.tracker.tracker(name: .minutesRecordingClickDev, params: params)
                }
            }
        }
    }
    
    private func createAudioRecordfailed(error: LarkMedia.MediaMutexError) {
        //创建失败埋点
        MinutesRecorderReciableTracker.shared.cancelEnterRecorder()
        MinutesReciableTracker.shared.error(scene: .MinutesRecorder,
                                            event: .minutes_create_audio_record_error,
                                            errorType: .Other,
                                            error: NSError(domain: "start recorder error", code: 0, userInfo: nil),
                                            extra: nil)
        //清理
        MinutesAudioRecorder.shared.cleanup()
        guard let controller = currentEntrance?.viewController, let recordView = currentEntrance?.recordView else {
            return
        }
        
        if case let MediaMutexError.occupiedByOther(context) = error {
            if let msg = context.1 {
                UDToast.showFailure(with: msg, on: controller.view, delay: 2)
            }
        } else {
            UDToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: controller.view, delay: 2)
        }
    }

    private func resumeAudioRecordfailed(error: LarkMedia.MediaMutexError) {
       
    }
    
    private func setRecordViewIsHidden(_ isHidden: Bool) {
        entrances.forEach { entrance in
            entrance.recordView?.isHidden = isHidden
        }
    }

    private func audioRecorderDidUploaded(_ uploadedToken: String) {
        DispatchQueue.main.async {
            for entrance in self.entrances {
                if let viewModel = entrance.viewController?.viewModel, (viewModel.spaceType == .home || viewModel.spaceType == .my) {
                    if let someMinutes = MinutesAudioRecorder.shared.minutes, uploadedToken == someMinutes.objectToken {
                        viewModel.updateRecordingListItem(with: someMinutes, canAddNewItem: self.canAddItemToList, isRecordingStop: true)
                        viewModel.startToFetchBatchStatus()
                        MinutesAudioRecorder.shared.stop()
                    } else {
                        viewModel.startToFetchBatchStatus()
                    }
                }
            }
            self.canAddItemToList = false
        }
    }

    func showRecordViewIfNeeded() {
        if isRecordShow {
            checkAudioRecordCircleView()
        }
    }

    func showRecordView() {
        if MinutesAudioRecorder.shared.status == .idle, recordView?.isHidden == true {
            checkAudioRecordCircleView()
        }
    }
    
    func checkAudioRecordCircleView() {
//        if isInDemo {
//            setRecordViewIsHidden(Display.pad || MinutesAudioRecorder.shared.status != .idle)
//        } else {
//            let isHidden = (Display.pad || MinutesAudioRecorder.shared.status != .idle || !minutesRecordingEnabled)
//            setRecordViewIsHidden(isHidden)
//        }
//        isRecordShow = true

        if isInDemo {
            setRecordViewIsHidden(MinutesAudioRecorder.shared.status != .idle)
        } else {
            let isHidden = (MinutesAudioRecorder.shared.status != .idle || !minutesRecordingEnabled)
            setRecordViewIsHidden(isHidden)
        }
        isRecordShow = true
    }

    @objc
    private func receiveMinutesAudioRecordingVCDismissNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let someMinutes = MinutesAudioRecorder.shared.minutes else { return }
            for entrance in self.entrances {
                if let viewModel = entrance.viewController?.viewModel, (viewModel.spaceType == .home || viewModel.spaceType == .my) {
                    if let isStop = notification.userInfo?[Notification.Key.minutesAudioRecordIsStop] as? Bool, isStop {
                        viewModel.updateRecordingListItem(with: someMinutes, canAddNewItem: self.canAddItemToList, isRecordingStop: true)
                        viewModel.startToFetchBatchStatus()
                    } else {
                        viewModel.updateRecordingListItem(with: someMinutes, canAddNewItem: self.canAddItemToList)
                    }
                }
            }
            self.canAddItemToList = false
        }
    }

    private func showMicrophonePrivacyAlert() {
        guard let controller = currentEntrance?.viewController else { return }
        let message: String = BundleI18n.Minutes.MMWeb_G_AccessToMicDenied + "，" + BundleI18n.Minutes.MMWeb_G_AllowAccessToMicIOS
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_Cancel, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_OpenSettings, style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }))
        controller.present(alertController, animated: true, completion: nil)
    }

    func getDomainApplinkString() -> String {
        let domain = ConfigurationManager.shared.settings
        guard var applink = domain[InitSettingKey.mpApplink] else {
            return "applink.feishu.cn"
        }

        return applink[0]
    }

    private func showStorageSpaceNotEnoughAlertController(isAdmin: Bool, notice: String?, billUrl: String?) {
        guard let controller = currentEntrance?.viewController else { return }

        if isAdmin {
            let alertController: LarkAlertController = LarkAlertController()
            alertController.setContent(text: notice ?? BundleI18n.Minutes.MMWeb_G_InsufficientStorageUpgrade_Toast, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
            alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_InsufficientStorageGotIt_Button, dismissCompletion: { [weak self] in
                self?.tracker.tracker(name: .popupClick, params: ["click": "confirm", "popup_name": "over_capacity", "page_type": "recording"])
            })
            alertController.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_G_InsufficientStorage_Upgrade_Button, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.tracker.tracker(name: .popupClick, params: ["click": "upgrade_package", "popup_name": "over_capacity", "page_type": "recording"])

                let host = self.getDomainApplinkString()
                var linkUrl = "https://" + host + "/client/web_url/open?url=https%3A%2F%2Fwww.feishu.cn%2Focic%3Fsource%3D1%26channel_id%3D33%26feature_key%3Dfeishu_minutes_function_storage&mode=window&height=700&width=1200"
                if self.passportUserService?.userTenantBrand == .lark {
                    linkUrl = "https://" + host + "/TJoVSTt"
                }
                MinutesLogger.record.info("bill url is \(billUrl), defaultLinkUrl is: \(linkUrl)")
                if let navVC = controller.navigationController, let url = URL(string: billUrl ?? linkUrl) {
                    alertController.dismiss(animated: false) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.userResolver.navigator.push(url, from: navVC)
                        }
                    }
                }
            })
            controller.present(alertController, animated: true, completion: nil)
            self.tracker.tracker(name: .popupView, params: ["popup_name": "over_capacity_administrator", "page_type": "recording"])
        } else {
            let alertController: LarkAlertController = LarkAlertController()
            alertController.setContent(text: notice ?? BundleI18n.Minutes.MMWeb_G_InsufficientStorageContactAdministrator_Toast, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
            alertController.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_G_InsufficientStorageGotIt_Button, dismissCompletion: { [weak self] in
                self?.tracker.tracker(name: .popupClick, params: ["click": "confirm", "popup_name": "over_capacity", "page_type": "recording"])
            })
            controller.present(alertController, animated: true, completion: nil)
            self.tracker.tracker(name: .popupView, params: ["popup_name": "over_capacity_user", "page_type": "recording"])
        }
    }

    private func showExistAudioRecordingAlertController() {
        guard let controller = currentEntrance?.viewController else { return }

        let alertController: LarkAlertController = LarkAlertController()
        alertController.setContent(text: BundleI18n.Minutes.MMWeb_G_StartNewRecordingQuestion, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: nil)
        alertController.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_G_StartNewRecording, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.createAudioRecord(isForced: true)
        })
        controller.present(alertController, animated: true, completion: nil)
    }

    private func trackerStartRecording() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.startRecording)
        tracker.tracker(name: .listPage, params: trackParams)
    }
}

extension MinutesRecordEntranceManager: MinutesAudioDataUploadListener {
    func audioDataUploadChanged(status: MinutesAudioDataUploadCenterWorkLoad) {
        
    }
    func audioDataUploadComplete(data: String) {
        audioRecorderDidUploaded(data)
    }
}

extension MinutesRecordEntranceManager {

    class RecordEntrance {
        weak var viewController: MinutesHomePageViewController?
        var recordView: MinutesHomeAudioRecordCircleView?
    }
}

extension MinutesRecordEntranceManager: MinutesAudioRecorderListener {
    func audioRecorderDidChangeStatus(status: MinutesAudioRecorderStatus) {
        self.checkAudioRecordCircleView()

        if status == .idle {
            AudioSuspendable.removeRecordSuspendable()
        }
    }
    
    func audioRecorderOpenRecordingSucceed(isForced: Bool) {
        MinutesLogger.record.info("audio recorder open recording succeed")

        MinutesRecorderReciableTracker.shared.finishPreProcess()
        self.requestCreateMinutesForAudioRecord(isForced: isForced)
    }
    
    func audioRecorderTryMideaLockfailed(error: LarkMedia.MediaMutexError, isResume: Bool) {
        guard let controller = currentEntrance?.viewController, let recordView = currentEntrance?.recordView else {
            return
        }
        recordView.circleButton.isUserInteractionEnabled = true
        if !isResume {
            self.createAudioRecordfailed(error: error)
        }
    }
    
    func audioRecorderTimeUpdate(time: TimeInterval) {
        
    }
}

