//
//  LocalShareContentViewModel.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/5/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ReplayKit
import LarkMedia
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting
import ByteViewTracker
import ByteViewUI
import ByteViewSetting

typealias StartSharing = ((LocalShareType) -> Void)

enum LocalShareType: CustomStringConvertible {
    case newShare(VcDocType)
    case shareDoc(String)
    case shareScreen
    case whiteboard

    var description: String {
        switch self {
        case .newShare:
            return "newShare"
        case .shareDoc:
            return "shareDoc"
        case .shareScreen:
            return "shareScreen"
        case .whiteboard:
            return "whiteboard"
        }
    }

    var isShareScreen: Bool {
        if case .shareScreen = self {
            return true
        } else {
            return false
        }
    }
}

class LocalShareContentViewModel: ShareContentSettingsVMProtocol {

    let logger = Logger.localShare

    static let logger = Logger.ui

    let disposeBag = DisposeBag()

    var scenario: ShareContentScenario {
        .local
    }

    var isRecvingUltrawave: Bool {
        UltrawaveManager.shared.isRecvingUltrawave
    }
    var isRecvUltrawaveSuccess: Bool = false
    var isInRequestStatus: Bool = false
    private var isStartNewMeeting: Bool = false
    private var isDoubleCheckManualInput: Bool = false

    weak var shareContentVC: ShareContentViewController?
    weak var shareCodeVC: ShareContentCodeViewController?
    weak var searchVC: SearchShareDocumentsViewController?
    weak var doubleCheckAlert: ByteViewDialog?

    // !isAlreadyInBoxMeeting
    lazy var canSharingDocsRelay = BehaviorRelay<Bool>(value: MeetingManager.shared.currentSession?.setting?.isBoxSharing != true)

    lazy var isLoadingRelay = BehaviorRelay<Bool>(value: false)

    private let source: MeetingEntrySource
    private var shareType: LocalShareType?
    private var shareCode: ShareContentEntryCodeType?
    var tenantId: Int64? { Int64(accountInfo.tenantId) }

    var accountInfo: AccountInfo { service.accountInfo }
    var httpClient: HttpClient { service.httpClient }
    var setting: MeetingSettingManager { service.setting }

    var hasShowUltrawaveTip: Bool {
        get {
            service.storage.bool(forKey: .ultrawaveTip)
        }
        set {
            service.storage.set(newValue, forKey: .ultrawaveTip)
        }
    }
    private lazy var whiteboardConfig: WhiteboardConfig = setting.whiteboardConfig
    var ccmDependency: CCMDependency { service.ccm }
    private let service: MeetingBasicService
    private let session: MeetingSession

    init?(source: MeetingEntrySource, session: MeetingSession) {
        guard let service = session.service else { return nil }
        self.source = source
        self.session = session
        self.service = service

        if ultrawaveAllowedCache {
            startRecvUltrawave()
        }
        session.addListener(self)
    }

    deinit {
        if !isStartNewMeeting {
            session.leave()
        }
        stopRecvUltrawave()
    }

    var shareContentEnabledConfig: ShareContentEnabledConfig {
        return ShareContentEnabledConfig(
            isShareScreenEnabled: !Util.isiOSAppOnMacSystem,
            isWhiteboardEnable: true,
            isMagicShareEnabled: true,
            isNewFileEnabled: true,
            isUltrasonicEnabled: self.canUseUltrawave)
    }

    var shareScreenTitle: Driver<String> {
        return .just(Display.pad ? I18n.View_VM_ShareScreenButton : I18n.View_MV_SharePhoneScreen_GreenButton)
    }

    var shareScreenTitleColor: Driver<UIColor> {
        return .just(UIColor.ud.textTitle)
    }

    var shareScreenIcon: Driver<UIImage?> {
        return .just(UDIcon.getIconByKey(.shareScreenFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0)))
    }

    var shareScreenIconBackgroundColor: Driver<UIColor> {
        return .just(.ud.colorfulGreen)
    }

    var whiteboardTitle: RxCocoa.Driver<String> {
        return .just(I18n.View_VM_ShareWhiteboard)
    }

    var whiteboardTitleColor: RxCocoa.Driver<UIColor> {
        return .just(UIColor.ud.textTitle)
    }

    var whiteboardIcon: RxCocoa.Driver<UIImage?> {
        return .just(UDIcon.getIconByKey(.vcWhiteboardOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16.0, height: 16.0)))
    }

    var whiteboardIconBackgroundColor: RxCocoa.Driver<UIColor> {
        return .just(.ud.primaryContentDefault)
    }

    func generateSearchViewModel(isSearch: Bool) -> SearchShareDocumentsVMProtocol {
        return LocalSearchShareDocumentsViewModel(accountInfo: accountInfo,
                                                  httpClient: httpClient,
                                                  startSharing: prepareForSharing,
                                                  showLoadingObservable: isLoadingObservable,
                                                  isSearch: isSearch)
    }

    func generateCreateAndShareViewModel() -> NewShareSettingsVMProtocol {
        return LocalNewShareViewModel(setting: setting, startSharing: prepareForSharing, showLoadingObservable: isLoadingObservable)
    }

    func showShareScreenAlert() {
        MagicShareTracksV2.trackShareScreen(rank: 0, isLocal: true)
        prepareForSharing(shareType: .shareScreen)
    }

    func didTapShareWhiteboard() {
        MagicShareTracksV2.trackStartWhiteboard(rank: 0, isLocal: true)
        prepareForSharing(shareType: .whiteboard)
    }

    var canSharingDocs: Bool {
        return canSharingDocsRelay.value
    }

    var canSharingDocsObservable: Observable<Bool> {
        return canSharingDocsRelay.asObservable().distinctUntilChanged()
    }

    var isLoadingObservable: Observable<Bool> {
        return isLoadingRelay.asObservable().distinctUntilChanged()
    }

    func dismissShareContentVC(completion: (() -> Void)? = nil) {
        if let vc = shareContentVC {
            if let currentSession = MeetingManager.shared.currentSession, session.sessionId != currentSession.sessionId {
                session.leave()
            }
            stopRecvUltrawave()
            vc.presentingViewController?.dismiss(animated: true, completion: completion)
            self.shareContentVC = nil
        }
    }

    func dismissShareCodeVC(completion: (() -> Void)? = nil) {
        if let vc = shareCodeVC {
            vc.hasHandledClose = true
            vc.presentingViewController?.dismiss(animated: true, completion: completion)
            self.shareCodeVC = nil
        }
    }

    func dismissDocumentVC() {
        if let nav = shareContentVC?.navigationController {
            searchVC?.navigationController?.dismiss(animated: true, completion: nil)
            let c0 = nav.viewControllers.count
            let vcs = nav.viewControllers.filter { $0 !== searchVC }
            if !vcs.isEmpty, vcs.count != c0 {
                nav.setViewControllers(vcs, animated: true)
            }
        }
        searchVC = nil
    }

    func toast(_ text: String) {
        Toast.show(text, type: .warning)
    }
}

/// Ultrawave
extension LocalShareContentViewModel {
    var ultrawaveAllowedCache: Bool {
        setting.isUltrawaveEnabled
    }

    private func startRecvUltrawave() {
        // 当前没有投屏码 && 当前不在共享会议中 ==> 开启接收超声波
        guard shareCode == nil, isNotInMeeting else { return }
        if setting.isUltrawaveEnabled {
            UltrawaveManager.shared.startRecv(config: setting.nfdScanConfig, usageType: .shareScreen) { [weak self] result in
                switch result {
                case .success(let key):
                    self?.shareCode = .shareCode(code: key)
                    self?.didRecvUltrawave()
                case .failure:
                    self?.failRecvUltrawave()
                default:
                    return
                }
            }
        } else {
            failRecvUltrawave()
        }
    }

    private func stopRecvUltrawave() {
        UltrawaveManager.shared.stopRecv()
    }

    private func didRecvUltrawave() {
        isRecvUltrawaveSuccess = true
        // 如果loading，直接开始共享
        if isLoadingRelay.value && shareType != nil && shareCode != nil {
            startSharing()
        }
    }

    private func failRecvUltrawave() {
        // 如果loading，直接报错，进shareCodeVC
        if isLoadingRelay.value {
            toast(I18n.View_G_ShareScreen_UnableAutoConnectEnterCodeID_Toast)
            goToShareCodeVC()
            isLoadingRelay.accept(false)
        }
    }

    private var isNotInMeeting: Bool {
        MeetingManager.shared.currentSession?.state != .onTheCall
    }

    var canUseUltrawave: Bool {
        isNotInMeeting && setting.isUltrawaveEnabled
    }
}

/// start sharing
extension LocalShareContentViewModel {
    var shareCodeCommitAction: ShareContentCodeCommitAction {
        return { [weak self] (code, completion) in
            if let self = self {
                self.startSharing(shareCode: code, completion: completion)
            } else {
                completion(.success(nil))
            }
        }
    }

    func prepareForSharing(shareType: LocalShareType) {
        guard !isInRequestStatus else {
            return
        }
        isInRequestStatus = true
        self.shareType = shareType
        if let session = MeetingManager.shared.currentSession, session.isAlreadyInSharingScreen {
            // 已经在共享会议中，则回到会中、直接重新共享
            session.service?.router.setWindowFloating(false) { [weak self] _ in
                // 调用会中共享
                self?.startSharingInCurrentMeeting()
                self?.dismissShareContentVC()
            }
        } else {
            // 发起新的共享
            if self.shareCode != nil && (ultrawaveAllowedCache || !canSharingDocs) {
                // 当前有共享码 && (开关打开 || 投屏目标是盒子)，直接开始共享
                startSharing()
            } else if isRecvingUltrawave {
                // 超声波仍在识别中，展示loading
                isLoadingRelay.accept(true)
            } else {
                // 关闭超声波or识别失败，进入ShareCodeVC
                goToShareCodeVC()
                // 若开关开启、无麦克风权限，需要toast提示
                if ultrawaveAllowedCache && !Privacy.audioAuthorized {
                    toast(I18n.View_G_ShareScreen_UnableAutoConnectEnterCodeID_Toast)
                }
            }
        }
    }

    private func startSharing(shareCode: ShareContentEntryCodeType? = nil, completion: ((Result<ShareScreenToRoomResponse?, Error>) -> Void)? = nil) {
        guard let shareType = self.shareType, let code = (shareCode ?? self.shareCode) else {
            completion?(.success(nil))
            return
        }
        joinSharingMeeting(shareType: shareType, entryCode: code, isFromUltrawave: shareCode == nil, completion: completion)
    }

    private func joinSharingMeeting(shareType: LocalShareType, entryCode: ShareContentEntryCodeType,
                                    isFromUltrawave: Bool,
                                    completion: ((Result<ShareScreenToRoomResponse?, Error>) -> Void)? = nil) {
        logger.info("start sharing, type: \(shareType), entryCode: \(entryCode)")
        let wrapper: (Result<ShareScreenToRoomResponse?, Error>) -> Void = { [weak self] result in
            Util.runInMainThread {
                self?.handleJoinSharingResult(entryCode: entryCode, result: result)
                completion?(result)
            }
        }

        if MeetingManager.shared.hasActiveMeeting {
            handleActiveMeetingOnJoin(shareType: shareType, entryCode: entryCode) { [weak self] result in
                switch result {
                case .success:
                    self?.fetchUrlAndJoin(shareType: shareType, entryCode: entryCode, isFromUltrawave: isFromUltrawave, completion: wrapper)
                case .failure(let error):
                    wrapper(.failure(error))
                }
            }
        } else {
            fetchUrlAndJoin(shareType: shareType, entryCode: entryCode, isFromUltrawave: isFromUltrawave, completion: wrapper)
        }
    }

    private func handleJoinSharingResult(entryCode: ShareContentEntryCodeType, result: Result<ShareScreenToRoomResponse?, Error>) {
        let currentSession = MeetingManager.shared.currentSession
        let router = currentSession?.service?.router
        isInRequestStatus = false
        switch result {
        case .success(let resp):
            isStartNewMeeting = resp != nil
            router?.setWindowFloating(false)
            shareCodeVC?.hasHandledClose = true
            dismissShareContentVC()
        case .failure(let e):
            self.isLoadingRelay.accept(false)
            let error = e.toVCError()
            switch error {
            case .magicShareBoxUnsupported:
                // 投屏码对应的设备是盒子，不支持ms
                self.toast(I18n.View_MV_NoShareDoc)
                self.shareCode = entryCode
                self.isRecvUltrawaveSuccess = false
                self.canSharingDocsRelay.accept(false)
                self.dismissShareCodeVC { [weak self] in
                    self?.dismissDocumentVC()
                }
                self.logger.error("magicShareBoxUnsupported in shareVC")
            case .noCastWhiteboard:
                self.toast(I18n.View_G_NoCastWhiteboard)
                self.logger.error("whiteboard is not support in box")
            case .localShareToCurrentMeeting, .shareScreenInThisMeeting:
                self.logger.error("show in current meeting")
                // 与目标room在同一个会议中，不能再次发起本地投屏
                router?.setWindowFloating(false)
                // 直接调用会中共享
                self.startSharingInCurrentMeeting()
                self.dismissShareContentVC()
            case .shareScreenInWiredShare:
                self.toast(I18n.View_G_AlreadySharingViaHDMI)
            case .invalidShareCode, .shareScreenNoRooms:
                if self.shareCodeVC == nil {
                    self.goToShareCodeVC()
                }
            default:
                break
            }
        }
    }

    private func startSharingInCurrentMeeting() {
        if let sharer = MeetingManager.shared.currentSession?.inMeetLocalContentSharer, let shareType = self.shareType {
            sharer.startSharingInCurrentMeeting(shareType: shareType)
        }
    }

    private func fetchUrlAndJoin(shareType: LocalShareType, entryCode: ShareContentEntryCodeType,
                                 isFromUltrawave: Bool,
                                 completion: ((Result<ShareScreenToRoomResponse?, Error>) -> Void)?) {
        switch shareType {
        case .newShare(let docType):
            // newShare需要先手动创建docs
            httpClient.getResponse(CreateDocRequest(docType: docType)) { [weak self] result in
                switch result {
                case .success(let resp):
                    self?.startMeeting(shareType: shareType, entryCode: entryCode, url: resp.url, isFromUltrawave: isFromUltrawave, completion: completion)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        case .shareDoc(let url):
            startMeeting(shareType: shareType, entryCode: entryCode, url: url, isFromUltrawave: isFromUltrawave, completion: completion)
        case .shareScreen:
            startMeeting(shareType: shareType, entryCode: entryCode, url: nil, isFromUltrawave: isFromUltrawave, completion: completion)
        case .whiteboard:
            startMeeting(shareType: shareType, entryCode: entryCode, url: nil, isFromUltrawave: isFromUltrawave, completion: completion)
        }
    }

    private func startMeeting(shareType: LocalShareType, entryCode: ShareContentEntryCodeType, url: String?,
                              isFromUltrawave: Bool,
                              completion: ((Result<ShareScreenToRoomResponse?, Error>) -> Void)?) {
        let confirmSetting: ShareScreenToRoomRequest.ConfirmSetting?
        switch entryCode {
        case .meetingNumber: confirmSetting = nil
        case .shareCode:
            switch setting.shareScreenConfirm {
            case .none: confirmSetting = .neverNeed
            case .crossTenantOnly: confirmSetting = .onlyCrossTanent
            case .always: confirmSetting = .always
            }
        }
        var whiteboardSetting: WhiteboardSettings?
        if case .whiteboard = shareType {
            let canvasSize = CGSize(width: CGFloat(whiteboardConfig.canvasSize.width), height: CGFloat(whiteboardConfig.canvasSize.height))
            whiteboardSetting = WhiteboardSettings(shareMode: .presentation, canvasSize: canvasSize)
        }
        let source = self.source
        let params = ShareToRoomParams(source: source, shareType: shareType, entryCode: entryCode, url: url, confirmSetting: confirmSetting, whiteboardSetting: whiteboardSetting)
        let isFromDoubleCheck = self.isDoubleCheckManualInput
        self.isDoubleCheckManualInput = false
        session.joinSharingToRoom(params, isFromDoubleCheck: isFromDoubleCheck) { [weak self] result in
            Util.runInMainThread {
                if case .success(let resp) = result, let confirm = resp?.confirmationInfo, confirm.needConfirm {
                    self?.showDoubleCheckAlert(roomInfo: confirm.roomInfo, isFromUltrawave: isFromUltrawave) { res in
                        self?.isInRequestStatus = false
                        switch res {
                        case .confirmed:
                            let newParams = ShareToRoomParams(source: source, shareType: shareType, entryCode: entryCode, url: url, confirmSetting: .confirmed, whiteboardSetting: whiteboardSetting)
                            self?.session.joinSharingToRoom(newParams, isFromDoubleCheck: true, completion: completion)
                        case .cancelled: completion?(.success(nil))
                        case .manualInput:
                            self?.isDoubleCheckManualInput = true
                        }
                    }
                } else {
                    completion?(result)
                }
            }
        }
    }

    private func handleActiveMeetingOnJoin(shareType: LocalShareType, entryCode: ShareContentEntryCodeType,
                                           completion: ((Result<Bool, Error>) -> Void)?) {
        if case .shareCode(let code) = entryCode {
            getShareCodeInfo(code: code, completion: completion)
        } else if case .meetingNumber(let number) = entryCode {
            precheckInMeetingConflict(entryCode: entryCode, meetingNumber: number) { [weak self] result in
                switch result {
                case .success:
                    // 正常情况下不该走到这里
                    completion?(.success(true))
                case .failure(.shareScreenInOtherMeeting):
                    self?.showInMeetingAlert(completion: completion)
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
    }

    private func getShareCodeInfo(code: String, completion: ((Result<Bool, Error>) -> Void)?) {
        httpClient.getResponse(GetShareCodeInfoRequest(shareCode: code)) { [weak self] result in
            switch result {
            case .success(let resp):
                if resp.user?.type == .room {
                    self?.httpClient.getResponse(PullMeetingByShareCodeRequest(shareCode: code)) { [weak self] r2 in
                        switch r2 {
                        case .success(let resp2):
                            let info = resp2.info
                            self?.logger.info("PullMeetingByShareCode response \(info.id) \(info.subtype)")
                            if info.subtype == .wiredScreenShare {
                                completion?(.failure(VCError.shareScreenInWiredShare))
                            } else {
                                self?.meetingDetection(meetingId: info.id, completion: completion)
                            }
                        case .failure(let error):
                            self?.logger.info("PullMeetingByShareCode failure \(error)")
                            completion?(.failure(error))
                        }
                    }
                } else if resp.user?.type == .shareboxUser {
                    self?.showInMeetingAlert(completion: completion)
                } else {
                    completion?(.success(true))
                }
            case .failure(let error):
                self?.logger.info("GetShareCodeInfo failure \(error)")
                completion?(.failure(error))
            }
        }
    }

    private func precheckInMeetingConflict(entryCode: ShareContentEntryCodeType, meetingNumber: String,
                                           completion: @escaping (Result<VideoChatInfo, VCError>) -> Void) {
        let meetingId = MeetingManager.shared.currentSession?.meetingId
        let request = ShareScreenToRoomRequest(shareCode: "", meetingNo: meetingNumber, meetingId: meetingId, url: nil, confirmSetting: nil, whiteboardSettings: nil)
        httpClient.getResponse(request) { r in
            switch r {
            case .success(let res):
                completion(.success(res.info))
            case .failure(let error):
                completion(.failure(error.toVCError()))
            }
        }
    }

    private func meetingDetection(meetingId: String, completion: ((Result<Bool, Error>) -> Void)?) {
        if let currentMeetingId = MeetingManager.shared.currentSession?.meetingId, !meetingId.isEmpty {
            logger.info("meetingDetection rooms in meet: \(meetingId), currentMeetingId: \(currentMeetingId)")
            if currentMeetingId == meetingId {
                // 如果是已经在同一个会中也需要再走一次shareScreenToRoom接口使其绑定rooms，因此不能直接返回在当前会议共享的错误
                completion?(.success(true))
            } else {
                showInMeetingAlert(completion: completion)
            }
        }
        // 用户在等候室直接投会议室，需要弹窗结束当前会议
        else if let currentMeetingState = MeetingManager.shared.currentSession?.state, (currentMeetingState == .lobby || currentMeetingState == .prelobby) {
                showInMeetingAlert(completion: completion)
        } else {
            completion?(.success(true))
        }
    }

    private func showInMeetingAlert(completion: ((Result<Bool, Error>) -> Void)?) {
        ByteViewDialog.Builder()
            .colorTheme(.followSystem)
            .inVcScene(false)
            .title(I18n.View_MV_StartSharing)
            .message(I18n.View_MV_CurrentCallWillEnd)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                completion?(.failure(VCError.localShareCancelled))
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ _ in
                MeetingManager.shared.currentSession?.leaveAndWaitServerResponse { _ in
                    completion?(.success(true))
                }
            })
            .show()
    }

    private func goToShareCodeVC() {
        self.isInRequestStatus = false
        Util.runInMainThread { [weak self] in
            guard let self = self, let from = self.shareContentVC else { return }
            let vm = ShareContentCodeViewModel(commitAction: self.shareCodeCommitAction, source: self.source)
            let vc = ShareContentCodeViewController(viewModel: vm)
            let regularConfig = DynamicModalConfig(presentationStyle: .formSheet, needNavigation: true)
            let compactConfig = DynamicModalConfig(presentationStyle: .fullScreen, needNavigation: true)
            from.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig)
            self.shareCodeVC = vc
        }
    }

    private enum ConfirmResult {
        case confirmed
        case cancelled
        case manualInput
    }

    private func fetchExternalLabel(for roomID: String, completion: @escaping (String) -> Void) {
        let defaultExternalLabel = I18n.View_G_ExternalLabel
        guard setting.isRelationTagEnabled else {
            completion(defaultExternalLabel)
            return
        }
        let user = VCRelationTag.User(type: .room, id: roomID)
        httpClient.participantRelationTagService.relationTagsByUsers([user]) { [weak self] tags in
            guard self != nil, let relationTag = tags.first, relationTag.userID == roomID,
                  let relationText = relationTag.relationText else {
                completion(defaultExternalLabel)
                return
            }
            completion(relationText)
        }
    }

    private func showDoubleCheckAlert(roomInfo: ShareScreenToRoomResponse.ConfirmationInfo.RoomInfo,
                                      isFromUltrawave: Bool,
                                      completion: @escaping (ConfirmResult) -> Void) {
        if roomInfo.tanentID != self.tenantId {
            // 如果是外部租户，需要展示外部标签，标签支持租户自定义配置，因此先去拉该租户的外部标签
            fetchExternalLabel(for: String(roomInfo.roomID)) { [weak self] externalLabel in
                self?._showDoubleCheckAlert(roomInfo: roomInfo, externalLabel: externalLabel, isFromUltrawave: isFromUltrawave, completion: completion)
            }
        } else {
            // 否则直接弹框，externalLabel 不会被用到
            _showDoubleCheckAlert(roomInfo: roomInfo, externalLabel: "", isFromUltrawave: isFromUltrawave, completion: completion)
        }
    }

    private func _showDoubleCheckAlert(roomInfo: ShareScreenToRoomResponse.ConfirmationInfo.RoomInfo,
                                       externalLabel: String,
                                       isFromUltrawave: Bool,
                                       completion: @escaping (ConfirmResult) -> Void) {
        let isExternal = roomInfo.tanentID != self.tenantId
        let code: String
        let shareType: String
        let shareMethod = shareCode == nil ? "ultrasonic" : "share_code"
        let duringMeeting = MeetingManager.shared.hasActiveMeeting
        if let shareCode = shareCode {
            switch shareCode {
            case .shareCode(code: let c): code = c
            case .meetingNumber(number: let num): code = num
            }
        } else {
            code = ""
        }
        if let type = self.shareType {
            switch type {
            case .shareScreen: shareType = "screen"
            default: shareType = "follow"
            }
        } else {
            shareType = ""
        }

        let view = UltrawaveDoubleCheckView(roomName: roomInfo.fullName, isExternal: isExternal, externalString: externalLabel, showManualInput: isFromUltrawave) { [weak self] in
            // 跳转到投屏码
            self?.gotoShareCodeForDoubleCheck()
            completion(.manualInput)
        }
        let cancelHandler: ((ByteViewDialog) -> Void)? = { [weak self] _ in
            // 退出投屏
            LocalShareTracks.trackDoubleCheckClick(click: "cancel",
                                                   shareCode: code,
                                                   isExternal: isExternal,
                                                   roomTenantID: roomInfo.tanentID,
                                                   shareMethod: shareMethod,
                                                   shareType: shareType,
                                                   duringMeeting: duringMeeting)
            self?.dismissShareContentVC()
            completion(.cancelled)
        }
        let confirmHandler: ((ByteViewDialog) -> Void)? = { [weak self] _ in
            // 开始投屏
            LocalShareTracks.trackDoubleCheckClick(click: "confirm",
                                                   shareCode: code,
                                                   isExternal: isExternal,
                                                   roomTenantID: roomInfo.tanentID,
                                                   shareMethod: shareMethod,
                                                   shareType: shareType,
                                                   duringMeeting: duringMeeting)
            self?.doubleCheckAlert = nil
            completion(.confirmed)
        }
        LocalShareTracks.trackDoubleCheckAppear(isExternal: isExternal,
                                                shareMethod: shareMethod,
                                                shareType: shareType,
                                                duringMeeting: duringMeeting)
        let title = isExternal ? I18n.View_G_ConfirmCastingToExternal_Pop : I18n.View_G_ConfirmCastingToThis_Pop
        ByteViewDialog.Builder()
            .title(title)
            .id(.localShareDoubleCheck)
            .contentView(view)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler(cancelHandler)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler(confirmHandler)
            .show { [weak self] alert in
                self?.doubleCheckAlert = alert
            }
    }

    private func gotoShareCodeForDoubleCheck() {
        Util.runInMainThread { [weak self] in
            self?.doubleCheckAlert?.dismiss()
            self?.doubleCheckAlert = nil
            self?.goToShareCodeVC()
            self?.isLoadingRelay.accept(false)
        }
    }
}

extension LocalShareContentViewModel: MeetingSessionListener {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        if state == .end {
            Util.runInMainThread {
                self.dismissShareContentVC()
                self.dismissShareCodeVC()
                self.doubleCheckAlert?.dismiss()
                self.doubleCheckAlert = nil
            }
        }
    }
}

final class InMeetLocalContentSharer: InMeetShareDataListener {
    private weak var session: MeetingSession?
    private weak var data: InMeetShareDataManager?
    private var service: MeetingBasicService? { session?.state == .onTheCall ? session?.service : nil }
    init(session: MeetingSession, data: InMeetShareDataManager) {
        self.session = session
        self.data = data
    }

    func shareScreenToRoom() -> Bool {
        if let service = self.service, service.setting.isBoxSharing {
            // 若当前已经在盒子会议中，直接在当前会中开始共享
            service.router.setWindowFloating(false)
            // 已经在共享屏幕，则无需再次唤起pickerView
            shareScreenInCurrentMeeting()
            return true
        }
        return false
    }

    // 在当前的共享会议中重新共享
    func startSharingInCurrentMeeting(shareType: LocalShareType) {
        Logger.ui.info("start sharing in current meeting, type: \(shareType)")
        switch shareType {
        case .newShare(let type):
            shareNewDocsInCurrentMeeting(type)
        case .shareDoc(let url):
            shareDocsInCurrentMeeting(url)
        case .shareScreen:
            shareScreenInCurrentMeeting()
        case .whiteboard:
            shareWhiteboardInCurrentMeeting()
        }
    }

    private func shareWhiteboardInCurrentMeeting() {
        guard let service = self.service, let data = self.data else { return }
        let meetingMeta: MeetingMeta = MeetingMeta(meetingID: service.meetingId)
        let whiteboardConfig = service.setting.whiteboardConfig
        let canvasSize = CGSize(width: CGFloat(whiteboardConfig.canvasSize.width), height: CGFloat(whiteboardConfig.canvasSize.height))
        let whiteboardId = data.shareContentScene.whiteboardData?.whiteboardID
        let request = OperateWhiteboardRequest(action: .startWhiteboard, meetingMeta: meetingMeta, whiteboardSetting: WhiteboardSettings(shareMode: .presentation, canvasSize: canvasSize), whiteboardId: whiteboardId)
        service.httpClient.getResponse(request) {
            switch $0 {
            case .success:
                Logger.ui.info("operateWhiteboard startWhiteboard success")
            case .failure(let error):
                Logger.ui.info("operateWhiteboard startWhiteboard error: \(error)")
            }
        }
    }

    private func shareScreenInCurrentMeeting() {
        guard InMeetSelfShareScreenViewModel.isPickerViewAvailable, let service = self.service, let data = self.data else {
            return
        }
        // 已经在共享屏幕，则无需再次唤起pickerView
        if #available(iOS 12.0, *), data.shareContentScene.shareScreenData?.participant != service.account {
            _ = ReplayKitFixer.fixOnce
            guard let pickerView = ShareScreenSncWrapper.createRPSystemBroadcastPickerView(for: .takeOverSameRoom) else {
                return
            }
            if #available(iOS 12.2, *) {
                pickerView.preferredExtension = service.setting.broadcastExtensionId
            }
            pickerView.showsMicrophoneButton = false
            for subview in pickerView.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .allEvents)
                }
            }
        }
    }

    private func shareDocsInCurrentMeeting(_ target: String) {

        guard let service = self.service else { return }
        // 不能重复共享
        if let document = self.data?.shareContentScene.magicShareData, document.urlString.vc.removeParams() == target { return }
        service.httpClient.follow.startShareDocument(target, meetingId: service.meetingId, lifeTime: .ephemeral, initSource: .initDirectly, authorityMask: nil, breakoutRoomId: service.breakoutRoomId)
    }

    private func shareNewDocsInCurrentMeeting(_ type: VcDocType) {
        guard let service = self.service else { return }
        service.httpClient.follow.createAndShareDocs(type, meetingId: service.meetingId, isExternalMeeting: service.setting.isExternalMeeting, breakoutRoomId: service.breakoutRoomId, tenantTag: service.accountInfo.tenantTag)
    }
}

extension MeetingSession {
    var inMeetLocalContentSharer: InMeetLocalContentSharer? {
        get { attr(.inMeetLocalContentSharer) }
        set { setAttr(newValue, for: .inMeetLocalContentSharer) }
    }

    fileprivate var isAlreadyInSharingScreen: Bool {
        state == .onTheCall && service?.setting.meetingSubType == .screenShare
    }
}

private extension MeetingAttributeKey {
    static let inMeetLocalContentSharer: MeetingAttributeKey = "vc.inMeetLocalContentSharer"
}

private extension MeetingSession {
    func joinSharingToRoom(_ params: ShareToRoomParams, isFromDoubleCheck: Bool, completion: ((Result<ShareScreenToRoomResponse?, Error>) -> Void)?) {
        slaTracker.startEnterOnthecall()
        let logTag = self.description
        let startTime = CACurrentMediaTime()
        var shareCode: String = ""
        var meetingNo: String = ""
        switch params.entryCode {
        case .shareCode(let code):
            shareCode = code
        case .meetingNumber(let number):
            meetingNo = number
        }
        isShareScreen = params.shareType.isShareScreen
        let meetingId = MeetingManager.shared.currentSession?.meetingId
        let wrapper = { [weak self] (result: Result<ShareScreenToRoomResponse, Error>) in
            guard let self = self else {
                Logger.meeting.warn("\(logTag) joinSharingToRoom failed: MeetingSession is nil")
                completion?(result.map { _ in nil })
                return
            }

            switch result {
            case .success(let res):
                let duration = Int((CACurrentMediaTime() - startTime) * 1000)
                self.log("joinSharingToRoom success: duration = \(duration)ms")
                VCTracker.post(name: .vc_client_signal_info, params: [.action_name: "recive_meeting_info", "duration": duration.description])
                if case .shareScreen = params.shareType {
                    self.autoShareScreen = true
                }
                // 如果需要二次弹窗，则不做处理，交由弹窗处理
                if res.confirmationInfo.needConfirm {
                    self.slaTracker.resetOnthecall()
                } else {
                    self.handleJoinedResponse(res.info, type: .shareScreenToRoom)
                }
                completion?(.success(res))
            case .failure(let error):
                self.loge("joinSharingToRoom failed: error = \(error)")
                self.slaTracker.endEnterOnthecall(success: self.slaTracker.isSuccess(error: error.toVCError()))
                completion?(.failure(error))
            }
        }
        // 有会议的时候，不走callkit
        // 二次确认直接走请求逻辑
        if MeetingManager.shared.hasActiveMeeting || isFromDoubleCheck {
            slaTracker.resetOnthecall()
            shareScreenToRoom(code: shareCode, meetingNo: meetingNo, url: params.url, meetingId: meetingId, confirmSetting: params.confirmSetting, whiteboardSetting: params.whiteboardSetting, completion: wrapper)
        } else {
            callCoordinator.requestStartCall(action: {
                self.shareScreenToRoom(code: shareCode, meetingNo: meetingNo, url: params.url, meetingId: meetingId, confirmSetting: params.confirmSetting, whiteboardSetting: params.whiteboardSetting, completion: $0)
            }, completion: wrapper)
        }
    }

    func shareScreenToRoom(code: String, meetingNo: String, url: String?, meetingId: String?,
                           confirmSetting: ShareScreenToRoomRequest.ConfirmSetting?,
                           whiteboardSetting: WhiteboardSettings?,
                           completion: ((Result<ShareScreenToRoomResponse, Error>) -> Void)?) {
        VCTracker.post(name: .vc_client_signal_info, params: [.action_name: "req_create"], platforms: [.plane])
        let request = ShareScreenToRoomRequest(shareCode: code, meetingNo: meetingNo, meetingId: meetingId, url: url, confirmSetting: confirmSetting, whiteboardSettings: whiteboardSetting)
        httpClient.getResponse(request, completion: completion)
    }
}
