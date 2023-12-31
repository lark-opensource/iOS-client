//
//  ShareContentSettingsViewModel.swift
//  ByteView
//
//  Created by Prontera on 2020/2/13.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ReplayKit
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI
import ByteViewSetting

struct ShareContentEnabledConfig {
    let isShareScreenEnabled: Bool
    let isWhiteboardEnable: Bool
    let isMagicShareEnabled: Bool
    let isNewFileEnabled: Bool
    let isUltrasonicEnabled: Bool
}

enum ShareContentControlToastType {
    case canShareContent
    case canReplaceShareContent
}

final class ShareContentSettingsViewModel: ShareContentSettingsVMProtocol, MeetingSettingListener, InMeetShareDataListener {
    static let logger = Logger.ui

    var httpClient: HttpClient {
        meeting.httpClient
    }

    var hasShowUltrawaveTip: Bool {
        get {
            meeting.service.storage.bool(forKey: .ultrawaveTip)
        }
        set {
            meeting.service.storage.set(newValue, forKey: .ultrawaveTip)
        }
    }

    let meeting: InMeetMeeting
    let disposeBag = DisposeBag()
    var accountInfo: AccountInfo { meeting.accountInfo }
    var hasBottomViewRelay = BehaviorRelay<Bool>(value: false)
    private let mySharingScreenRelay: BehaviorRelay<Bool>
    private let mySharingWhiteboardRelay: BehaviorRelay<Bool>
    var scenario: ShareContentScenario {
        .inMeet
    }
    private let shouldReloadWhiteboardItemRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var shouldReloadWhiteboardItemObservable: Observable<Bool> {
        shouldReloadWhiteboardItemRelay.asObservable()
    }

    weak var hostVC: UIViewController?
    // 共享内容权限相关
    let canShareContentRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let canReplaceShareContentRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let handleShareContentControlForbiddenPublisher = PublishSubject<ShareContentControlToastType>()
    private lazy var whiteboardConfig = meeting.setting.whiteboardConfig

    var ccmDependency: CCMDependency { meeting.service.ccm }
    var setting: MeetingSettingManager { meeting.setting }

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.mySharingScreenRelay = .init(value: meeting.shareData.isMySharingScreen)
        self.mySharingWhiteboardRelay = .init(value: meeting.shareData.isSelfSharingWhiteboard)
        self.canShareContentRelay.accept(meeting.setting.canShareContent)
        self.canReplaceShareContentRelay.accept(meeting.setting.canReplaceShareContent)
        bindShareContentControl()
        meeting.shareData.addListener(self)
        meeting.setting.addListener(self, for: [.canShareContent, .canReplaceShareContent])
    }

    var isSharingContent: Bool { return meeting.shareData.isSharingContent }
    var isSelfSharingContent: Bool { return meeting.shareData.isSelfSharingContent }

    var canShareContent: Bool {
        canShareContentRelay.value
    }

    var canReplaceShareContent: Bool {
        canReplaceShareContentRelay.value
    }

    var shareContentEnabledConfig: ShareContentEnabledConfig {
        let canShowWhiteboardItem = (!meeting.shareData.isSharingWhiteboard || meeting.shareData.isSelfSharingContent)
        return ShareContentEnabledConfig(
            isShareScreenEnabled: !Util.isiOSAppOnMacSystem,
            isWhiteboardEnable: meeting.setting.isShareWhiteboardEnabled && canShowWhiteboardItem && !meeting.setting.isCrossWithKa,
            isMagicShareEnabled: meeting.setting.isShareCcmEnabled,
            isNewFileEnabled: meeting.setting.isNewCcmEnabled,
            isUltrasonicEnabled: false)
    }

    var shareScreenTitle: Driver<String> {
        return mySharingScreenRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> String in
                if open {
                    return I18n.View_VM_StopSharing
                } else {
                    return Display.pad ? I18n.View_VM_ShareScreenButton : I18n.View_MV_SharePhoneScreen_GreenButton
                }
            })
    }

    var shareScreenTitleColor: Driver<UIColor> {
        return mySharingScreenRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> UIColor in
                if open {
                    return UIColor.ud.colorfulRed
                } else {
                    return UIColor.ud.textTitle
                }
            })
    }

    var shareScreenIcon: Driver<UIImage?> {
        return mySharingScreenRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> UIImage? in
                if open {
                    return UDIcon.getIconByKey(.stopRecordFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0))
                } else {
                    return UDIcon.getIconByKey(.shareScreenFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0))
                }
            })
    }

    var shareScreenIconBackgroundColor: Driver<UIColor> {
        return mySharingScreenRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> UIColor in
                if open {
                    return .ud.functionDangerContentDefault
                } else {
                    return .ud.colorfulGreen
                }
            })
    }

    var whiteboardTitle: RxCocoa.Driver<String> {
        return mySharingWhiteboardRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> String in
                return open ? I18n.View_MV_StopShareWhiteboard : I18n.View_VM_ShareWhiteboard
            })
    }

    var whiteboardTitleColor: RxCocoa.Driver<UIColor> {
        return mySharingWhiteboardRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> UIColor in
                return open ? .ud.functionDangerContentDefault : .ud.textTitle
            })
    }

    var whiteboardIcon: RxCocoa.Driver<UIImage?> {
        return mySharingWhiteboardRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> UIImage? in
                return open ? UDIcon.getIconByKey(.stopRecordFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0)) : UDIcon.getIconByKey(.vcWhiteboardOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0))
            })
    }

    var whiteboardIconBackgroundColor: RxCocoa.Driver<UIColor> {
        return mySharingWhiteboardRelay
            .asDriver(onErrorJustReturn: false)
            .map({ open -> UIColor in
                return open ? .ud.functionDangerContentDefault : .ud.primaryContentDefault
            })
    }

    func didTapShareWhiteboard() {
        self.dismiss {
            var whiteboardId: Int64?
            if let wbId = self.meeting.shareData.shareContentScene.whiteboardData?.whiteboardID {
                whiteboardId = wbId
            }
            let meetingMeta = MeetingMeta(meetingID: self.meeting.meetingId)
            if self.mySharingWhiteboardRelay.value {
                MagicShareTracksV2.trackQuitWhiteboard(rank: 0, isLocal: false)
                let request = OperateWhiteboardRequest(action: .stopWhiteboard, meetingMeta: meetingMeta, whiteboardSetting: nil, whiteboardId: whiteboardId)
                HttpClient(userId: self.meeting.userId).getResponse(request) { r in
                    switch r {
                    case .success:
                        Self.logger.info("operateWhiteboard stopWhiteboard success")
                    case .failure(let error):
                        Self.logger.info("operateWhiteboard stopWhiteboard error: \(error)")
                    }
                }
                if self.meeting.subType == .screenShare {
                    self.meeting.leave()
                }
            } else {
                let canvasSize = CGSize(width: CGFloat(self.whiteboardConfig.canvasSize.width), height: CGFloat(self.whiteboardConfig.canvasSize.height))
                let wbSetting: WhiteboardSettings = WhiteboardSettings(shareMode: .presentation, canvasSize: canvasSize)
                MagicShareTracksV2.trackStartWhiteboard(rank: 0, isLocal: true)
                let request = OperateWhiteboardRequest(action: .startWhiteboard, meetingMeta: meetingMeta, whiteboardSetting: wbSetting, whiteboardId: whiteboardId)
                HttpClient(userId: self.meeting.userId).getResponse(request) { r in
                    switch r {
                    case .success:
                        Self.logger.info("operateWhiteboard startWhiteboard success")
                    case .failure(let error):
                        Self.logger.info("operateWhiteboard startWhiteboard error: \(error)")
                    }
                }
            }
        }
    }

    private lazy var pickerView: UIView? = {
        if InMeetSelfShareScreenViewModel.isPickerViewAvailable, #available(iOS 12.0, *) {
            _ = ReplayKitFixer.fixOnce
            let pickerView = ShareScreenSncWrapper.createRPSystemBroadcastPickerView(for: .shareScreen)
            if #available(iOS 12.2, *) {
                pickerView?.preferredExtension = meeting.setting.broadcastExtensionId
            }
            pickerView?.showsMicrophoneButton = false
            return pickerView
        } else {
            return nil
        }
    }()

    private func pickerViewDidTouch() {
        VCTracker.post(name: .vc_meeting_sharescreen_click, params: [.click: "picker_view"])
        guard let pickerView = pickerView, ShareScreenSncWrapper.getCheckResult(by: .shareScreen) else {
            Toast.showOnVCScene(I18n.View_G_FailShareForNow)
            return
        }

        for subview in pickerView.subviews {
            if let button = subview as? UIButton {
                button.sendActions(for: .allEvents)
            }
        }
    }

    func bindShareContentControl() {
        handleShareContentControlForbiddenPublisher
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type: ShareContentControlToastType) in
                switch type {
                case .canShareContent:
                    ShareContentSettingsViewModel.logger.debug("Share content is denied due to lack of permission.")
                    Toast.show(I18n.View_M_NoPermissionToShare)
                    self?.dismiss()
                case .canReplaceShareContent:
                    ShareContentSettingsViewModel.logger.debug("Replace share content is denied due to lack of permission")
                    Toast.show(I18n.View_M_ShareAfterCurrentSessionEnds)
                    self?.dismiss()
                }
            })
            .disposed(by: disposeBag)
    }

    func generateSearchViewModel(isSearch: Bool) -> SearchShareDocumentsVMProtocol {
        return SearchShareDocumentsViewModel(
            meeting: meeting,
            canShareContentRelay: canShareContentRelay,
            canReplaceShareContentRelay: canReplaceShareContentRelay,
            handleShareContentControlForbiddenPublisher: handleShareContentControlForbiddenPublisher,
            isSearch: isSearch)
    }

    func generateCreateAndShareViewModel() -> NewShareSettingsVMProtocol {
        return NewShareSettingsViewModel(
            meeting: meeting,
            canShareContentRelay: canShareContentRelay,
            canReplaceShareContentRelay: canReplaceShareContentRelay,
            handleShareContentControlForbiddenPublisher: handleShareContentControlForbiddenPublisher)
    }

    func showShareScreenAlert() {
        guard !meeting.shareData.isMySharingScreen else {
            MagicShareTracks.trackShareContent(action: .stopSharingScreenCellClick)
            let engine = meeting.rtc.engine
            self.dismiss { [weak engine] in
                Self.logger.info("stopShareScreen reason: shareScreenEnd")
                engine?.sendScreenCaptureExtensionMessage(I18n.View_M_ScreenSharingStopped)
            }
            return
        }
        MagicShareTracks.trackShareContent(action: .shareScreenClicked)
        MagicShareTracksV2.trackShareScreen(rank: 0, isLocal: false)    // Rank = 0 移动端无法选择窗口
        if InMeetSelfShareScreenViewModel.isPickerViewAvailable {
            self.dismiss { // 此处捕获self，防止非主线程调用时，closure内容不执行
                self.pickerViewDidTouch()
            }
        } else {
            let message = I18n.View_VM_ShareDeviceScreenDescription(Util.appName)
            self.dismiss {
                ByteViewDialog.Builder()
                    .title(I18n.View_VM_ShareDeviceScreen)
                    .message(message)
                    .rightTitle(I18n.View_G_OkButton)
                    .rightHandler(nil)
                    .show()
            }
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .canShareContent {
            canShareContentRelay.accept(isOn)
        } else if key == .canReplaceShareContent {
            canReplaceShareContentRelay.accept(isOn)
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            if let vc = self?.hostVC?.presentingViewController {
                vc.dismiss(animated: true, completion: completion)
            } else {
                completion?()
            }
        }
    }

    var showTip: Bool {
        let showTipThreshold = meeting.setting.largeMeetingShareNoticeThreshold
        return self.meeting.participant.currentRoom.count >= showTipThreshold
    }

    func checkShowChangeAlert(isWhiteBoard: Bool) -> Bool {
        if isWhiteBoard && meeting.shareData.isSharingContent && !meeting.shareData.isSharingWhiteboard {
            return true
        } else if !isWhiteBoard && meeting.shareData.isOthersSharingContent {
            return true
        } else {
            return false
        }
    }

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if newScene.isWhiteboard || oldScene.isWhiteboard {
            mySharingWhiteboardRelay.accept(meeting.shareData.isSelfSharingWhiteboard)
            shouldReloadWhiteboardItemRelay.accept(true)
        }
        if newScene.isSelfSharingScreen != mySharingScreenRelay.value {
            mySharingScreenRelay.accept(newScene.isSelfSharingScreen)
        }
    }

}
