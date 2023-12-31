//
//  InMeetFollowManager.swift
//  ByteView
//
//  Created by kiri on 2021/4/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI
import ByteViewCommon
import ByteViewRtcBridge

/// 会中一直存在的vm，而非仅在FullScreen状态存在
final class InMeetFollowManager: InMeetMeetingProvider {
    private let logger = Logger.vcFollow
    let meeting: InMeetMeeting
    private(set) var lastEvent: InMeetFollowEvent?
    /// 是否可以显示“已跟随到xxx的位置”
    var canShowPositionSyncedToast: Bool = false
    @RwAtomic
    private(set) var localDocuments: [MagicShareDocument] = []
    private(set) var status: InMeetFollowViewModelStatus = .none
    var magicShareDocument: MagicShareDocument? { meeting.shareData.shareContentScene.magicShareDocument }
    private var lastShareId = ""
    private var docsAlert: [String: WeakRef<ByteViewDialog>] = [:]
    @RwAtomic
    var currentRuntime: MagicShareRuntime?
    let magicShareRuntimeFactory: FollowDocumentFactory
    let trackManager = MagicShareTracksManager()
    /// 已经关闭过的文档权限变更 tips
    @RwAtomic var externalPermChangeClosedTips = Set<String>()

    /// 打开下一篇MS时调用clearLocation方法
    var clearLocationOnNextDocument: Bool = false

    /// 是否开启了字幕
    var isTranslationOn: Bool = false

    /// 是否正在刷新流程中
    var isReloading: Bool = false

    /// 妙享开启后，如遇妙享结束（非切换文档），额外上报一次CLOSE状态；由于会议结束导致妙享结束则无需上报
    var isExtraCPUUsageUpdateNeeded: Bool = false

    // MARK: - 投屏转妙享提示

    @RwAtomic
    /// 投屏转妙享是否显示“共享人已切换内容”提示
    var shouldShowPresenterChangedContentHint: Bool = false

    /// 记录最新的共享屏幕数据
    var latestScreenSharedData: ScreenSharedData?

    // MARK: - 妙享降级

    @RwAtomic
    /// 是否处于高负载
    private var isSystemLoadMarked: Bool = false
    @RwAtomic
    /// 动态负载记分
    private var dynamicScore: CGFloat = 0
    @RwAtomic
    /// 持续高负载次数
    private var dynamicOverloadCount: Int = 0
    @RwAtomic
    /// 持续低负载次数
    private var dynamicUnderuseCount: Int = 0
    @RwAtomic
    /// 发热等级
    private var thermalState: ProcessInfo.ThermalState = .nominal
    @RwAtomic
    /// 打开文档/纪要的时间戳记录
    private var openDocRecord: [Date] = []

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.magicShareRuntimeFactory = meeting.service.ccm.createFollowDocumentFactory()
        if let doc = meeting.shareData.shareContentScene.magicShareDocument {
            handleNewDocument(doc, lastDocument: nil)
        }
        meeting.shareData.addListener(self)
        meeting.addMyselfListener(self)
        NoticeService.shared.addListener(self)
        meeting.rtc.engine.addListener(self)
        meeting.service.perfMonitor.addListener(self)
        meeting.notesData.addListener(self)
        isTranslationOn = meeting.myself.settings.isTranslationOn ?? false
        startThermalDetection()
    }

    deinit {
        docsAlert.values.forEach {
            $0.ref?.dismiss()
        }
        docsAlert.removeAll()
    }

    private let listeners = Listeners<InMeetFollowListener>()
    func addListener(_ listener: InMeetFollowListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            if !localDocuments.isEmpty {
                listener.didUpdateLocalDocuments(localDocuments, oldValue: [])
            }
            if let event = lastEvent {
                listener.didReceiveFollowEvent(event)
            }
            if status != .none {
                listener.didUpdateFollowStatus(status, oldValue: .none)
            }
        }
    }

    func removeListener(_ listener: InMeetFollowListener) {
        listeners.removeListener(listener)
    }

    private func updateStatus(_ status: InMeetFollowViewModelStatus) {
        Util.runInMainThread {
            let oldValue = self.status
            self.status = status
            self.handleStatusToast(status, oldValue: oldValue)
            self.listeners.forEach { $0.didUpdateFollowStatus(status, oldValue: oldValue) }

            switch status {
            case .sharing:
                self.logger.info("Start sharing content: isLocal: true; type: ms")
            case .free:
                self.canShowPositionSyncedToast = true
                self.logger.info("Start sharing content: isLocal: false; type: ms")
            case .following:
                self.showPositionSyncedToastIfNeeded()
                self.logger.info("Start sharing content: isLocal: false; type: ms")
            case .shareScreenToFollow:
                self.logger.info("Start share screen to follow")
            case .none:
                self.logger.info("Stop sharing content: type: ms")
            }
        }
    }

    private func handleStatusToast(_ status: InMeetFollowViewModelStatus, oldValue: InMeetFollowViewModelStatus) {
        logger.info("follow status changed from: \(oldValue) to: \(status)")
        switch (oldValue, status) {
        case (.free(let oldDocument, _), .sharing(let newDocument)),
            (.following(let oldDocument, _), .sharing(let newDocument)):
            if newDocument.shareID == oldDocument.shareID {
                Toast.showOnVCScene(BundleI18n.ByteView.View_VM_YouAreNowSharing)
            }
        case (.none, .following(let document, _)),
             (.none, .free(let document, _)),
             (.sharing, .following(let document, _)),
             (.sharing, .free(let document, _)):
            Toast.showOnVCScene(I18n.View_VM_NameIsSharingContent(document.userName))
        case (.following, .following(let newDocument, true)),
             (.following, .free(let newDocument, true)),
             (.free, .following(let newDocument, true)):
            Toast.showOnVCScene(I18n.View_VM_NameIsSharingContent(newDocument.userName))
        case (.free, .free(let newDocument, true)):
            if newDocument.initSource == .initDirectly {
                Toast.showOnVCScene(I18n.View_VM_NameIsSharingContent(newDocument.userName))
            }
        case (.following, .following(let newDocument, false)):
            Toast.showOnVCScene(I18n.View_VM_NameIsSharingContent(newDocument.userName))
        case (.free, .free(let newDocument, false)):
            Toast.showOnVCScene(I18n.View_VM_NameIsSharingContent(newDocument.userName))
        case (.following, .free(_, false)):
            Toast.showOnVCScene(I18n.View_VM_CanViewBySelf)
        default:
            break
        }
    }

    func followPresenter(_ document: MagicShareDocument) {
        replaceWithDocument(document, status: .following, createSource: .toPresenter)
        updateStatus(.following(document: document, newShare: false))
    }

    func freeToBrowse(_ document: MagicShareDocument) {
        updateStatusWithDocument(document, status: .free, createSource: .becomePresenter)
        updateStatus(.free(document: document, newShare: false))
        MagicShareTracks.trackChangeToFree(document: document, deviceId: self.meeting.account.deviceId)
    }

    func pushDocument(_ document: MagicShareDocument,
                      status: MagicShareDocumentStatus,
                      createSource: MagicShareRuntimeCreateSource,
                      clearStoredLocation: Bool = false) {
        logger.info("magic share local runtime push, clear: \(clearStoredLocation)")
        let oldValue = localDocuments
        localDocuments.append(document)
        sendEvent(.push,
                  document: document,
                  status: status,
                  createSource: createSource,
                  oldDocuments: oldValue,
                  clearStoredPos: clearStoredLocation)
    }

    func popToDocument(_ document: MagicShareDocument,
                       status: MagicShareDocumentStatus,
                       createSource: MagicShareRuntimeCreateSource,
                       clearStoredLocation: Bool = false) {
        logger.info("magic share local runtime pop, clear: \(clearStoredLocation)")
        let oldValue = localDocuments
        if let index = localDocuments.lastIndex(where: { $0.hasEqualContentTo(document) }) {
            localDocuments = Array(localDocuments.prefix(index + 1))
        } else {
            localDocuments = [document]
        }
        sendEvent(.popTo,
                  document: document,
                  status: status,
                  createSource: createSource,
                  oldDocuments: oldValue,
                  clearStoredPos: clearStoredLocation)
    }

    func replaceWithDocument(_ document: MagicShareDocument,
                             status: MagicShareDocumentStatus,
                             createSource: MagicShareRuntimeCreateSource,
                             clearStoredLocation: Bool = false) {
        logger.info("magic share local runtime replace, clear: \(clearStoredLocation)")
        let oldValue = localDocuments
        localDocuments = [document]
        sendEvent(.replace,
                  document: document,
                  status: status,
                  createSource: createSource,
                  oldDocuments: oldValue,
                  clearStoredPos: clearStoredLocation)
    }

    func reloadWithDocument(_ document: MagicShareDocument,
                            status: MagicShareDocumentStatus,
                            createSource: MagicShareRuntimeCreateSource,
                            clearStoredLocation: Bool = false) {
        logger.info("magic share local runtime reload, clear: \(clearStoredLocation)")
        let oldValue = localDocuments
        localDocuments.removeLast()
        localDocuments.append(document)
        sendEvent(.reload,
                  document: document,
                  status: status,
                  createSource: createSource,
                  oldDocuments: oldValue,
                  clearStoredPos: clearStoredLocation)
    }

    func updateStatusWithDocument(_ document: MagicShareDocument,
                                  status: MagicShareDocumentStatus,
                                  createSource: MagicShareRuntimeCreateSource,
                                  clearStoredLocation: Bool = false) {
        logger.info("magic share local runtime updateStatus, clear: \(clearStoredLocation)")
        let oldValue = localDocuments
        sendEvent(.updateStatus,
                  document: document,
                  status: status,
                  createSource: createSource,
                  oldDocuments: oldValue,
                  clearStoredPos: clearStoredLocation)
    }

    func removeLatestDocumentOnUpdating(with documentUrl: String) {
        logger.info("magic share local runtime remove second last document, url.hash: \(documentUrl.hash)")
        guard localDocuments.count > 1, let lastDocument = localDocuments.last else {
            logger.warn("no second last document, skip remove operation.")
            return
        }
        guard !lastDocument.urlString.vc.removeParams().isEmpty,
              lastDocument.urlString.vc.removeParams() == documentUrl.vc.removeParams() else {
            logger.warn("second last document.url not equal to removing target, skip remove operation.")
            return
        }
        localDocuments.removeLast()
    }

    @discardableResult
    func changeDocumentTitle(_ document: MagicShareDocument, title: String) -> Bool {
        let oldValue = localDocuments
        var isChanged = false
        for (i, localDoc) in localDocuments.enumerated() {
            if localDoc.hasEqualContentTo(document) {
                isChanged = true
                localDocuments[i].docTitle = title
            }
        }
        if isChanged {
            listeners.forEach { $0.didUpdateLocalDocuments(localDocuments, oldValue: oldValue) }
        }
        return isChanged
    }

    private func sendEvent(_ action: InMeetFollowEvent.Action, document: MagicShareDocument, status: MagicShareDocumentStatus,
                           createSource: MagicShareRuntimeCreateSource, oldDocuments: [MagicShareDocument], clearStoredPos: Bool = false) {
        let event = InMeetFollowEvent(action: action, document: document, status: status, createSource: createSource, clearStoredPos: clearStoredPos)
        listeners.forEach { $0.didUpdateLocalDocuments(localDocuments, oldValue: oldDocuments) }
        listeners.forEach { $0.didReceiveFollowEvent(event) }
        self.lastEvent = event
    }

    /// 重建并替换当前Runtime，以达到刷新的目的
    func reload(with viewModel: InMeetFollowViewModel) {
        if let oldRuntime = currentRuntime {
            self.isReloading = true
            reloadWithDocument(oldRuntime.documentInfo,
                               status: oldRuntime.currentDocumentStatus,
                               createSource: .reload)
        } else {
            self.logger.warn("current runtime is invalid, reload failed")
        }
    }
}

extension InMeetFollowManager: InMeetShareDataListener {

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if [.othersSharingScreen, .magicShare, .shareScreenToFollow, .none].contains(newScene.shareSceneType)
            || [.othersSharingScreen, .magicShare, .shareScreenToFollow, .none].contains(oldScene.shareSceneType) {
            let newDocument = newScene.magicShareDocument
            let oldDocument = oldScene.magicShareDocument
            let newScreenSharedData = newScene.shareScreenData
            let oldScreenSharedData = oldScene.shareScreenData
            checkShouldShowPresenterChangedContentHintOnRemoteChange(
                newDocument: newDocument,
                newScreenSharedData: newScreenSharedData,
                oldScreenSharedData: oldScreenSharedData)
            guard newDocument != oldDocument else { return }
            if var doc = newDocument {
                // 本地记录的文档标题是准确的，否则转移共享人/抢占共享人后，标题会取用后端未更新的数据
                doc.updateTitleWithLocalDocuments(localDocuments)
                handleNewDocument(doc, lastDocument: oldDocument)
                // 如果发起新MS时处于小窗或后台，上报MS发起埋点
                let shareID = doc.shareID ?? ""
                let isPresenter = doc.user.deviceId == meeting.account.deviceId
                if self.router.isFloating {
                    MagicShareTracks.trackMagicShareInitError(.isFloating, isPresenter: isPresenter, shareID: shareID)
                }
                Util.runInMainThread {
                    if UIApplication.shared.applicationState != .active {
                        MagicShareTracks.trackMagicShareInitError(.isBackground, isPresenter: isPresenter, shareID: shareID)
                    }
                }
            } else {
                handleUnfollow(lastDocument: oldDocument)
            }
            dismissAlertIfNeeded(newDocument)
            if newDocument != oldDocument, oldDocument != nil {
                reportMagicShareInfo(with: oldDocument)
            }
        }
    }

    private func handleNewDocument(_ document: MagicShareDocument, lastDocument: MagicShareDocument?) {
        let documentLogInfo = """
                magicShareDocumentObservable
                document url.hash = \(document.urlString.hash),
                type = \(document.shareType)
                """
        logger.info(documentLogInfo)
        TrackContext.shared.updateContext(for: meeting.sessionId) { context in
            context.shareId = document.shareID ?? "none"
            context.actionUniqueID = document.actionUniqueID ?? "none"
        }
        let defaultFollow = document.options?.defaultFollow ?? true
        let newShare = lastShareId != document.shareID
        lastShareId = document.shareID ?? ""
        let newStatus: InMeetFollowViewModelStatus
        let isPresenter = meeting.account == document.user
        let isSSToMS = document.isSSToMS
        MagicShareTracks.trackReceiveNewShare(shareType: document.shareType,
                                              shareSubType: document.shareSubType,
                                              isPresenter: isPresenter ? 1 : 0,
                                              shareId: document.shareID)
        if isPresenter {
            newStatus = .sharing(document: document)
        } else if isSSToMS {
            newStatus = .shareScreenToFollow
        } else {
            switch self.status {
            case .following:
                newStatus = .following(document: document, newShare: newShare)
            case .free:
                switch document.initSource {
                case .initDirectly:
                    if newShare {
                        newStatus = defaultFollow ?
                            .following(document: document, newShare: newShare) :
                            .free(document: document, newShare: newShare)
                    } else {
                        newStatus = .free(document: document, newShare: newShare)
                    }
                default:
                    newStatus = .free(document: document, newShare: newShare)
                }
            case .sharing, .none, .shareScreenToFollow:
                newStatus = defaultFollow ?
                    .following(document: document, newShare: newShare) :
                    .free(document: document, newShare: newShare)
            }
        }
        startNewDocument(document,
                         newStatus: newStatus,
                         lastDocument: lastDocument)
        logger.debug("open new document, will append open doc record")
        appendOpenDocRecord()
    }

    private func startNewDocument(_ document: MagicShareDocument,
                                  newStatus: InMeetFollowViewModelStatus,
                                  lastDocument: MagicShareDocument?) {
        if lastDocument == nil {
            logger.debug("magic share factory start meeting")
            magicShareRuntimeFactory.startMeeting()
        }
        logger.info("follow status = \(newStatus)")
        if case .none = self.status {
            let documentStatus: MagicShareDocumentStatus
            switch newStatus {
            case .sharing:
                documentStatus = .sharing
            case .following:
                documentStatus = .following
            case .shareScreenToFollow:
                documentStatus = .sstomsFollowing
            default:
                documentStatus = .free
            }
            logger.info("follow page first replace")
            self.replaceWithDocument(document, status: documentStatus, createSource: .newShare, clearStoredLocation: true)
            updateStatus(newStatus)
            return
        }
        let lastUser: ByteviewUser? = self.localDocuments.last?.user
        let isSelfReSharing: Bool = lastUser == nil ? false : lastUser == meeting.account
        let createSource: MagicShareRuntimeCreateSource = isSelfReSharing ? (document.initSource == .initReactivated ? .popBack : .reShare) : .becomePresenter
        switch newStatus {
        case .sharing:
            switch document.initSource {
            case .initDirectly:
                logger.info("follow page initDirectly reload")
                self.replaceWithDocument(document, status: .sharing, createSource: createSource, clearStoredLocation: true)
            case .initFromLink:
                if lastDocument?.identifier == document.identifier {
                    logger.info("follow page initFromLink push")
                    self.pushDocument(document, status: .sharing, createSource: createSource)
                } else {
                    logger.info("follow page initFromLink replace")
                    self.replaceWithDocument(document, status: .sharing, createSource: createSource, clearStoredLocation: true)
                }
            case .initReactivated:
                if lastDocument?.identifier == document.identifier {
                    logger.info("follow page initReactivated pop")
                    self.popToDocument(document, status: .sharing, createSource: createSource)
                } else {
                    logger.info("follow page initReactivated replace")
                    self.replaceWithDocument(document, status: .sharing, createSource: createSource)
                }
            default:
                break
            }
        case .following:
            logger.info("follow page following replace")
            self.replaceWithDocument(document, status: .following, createSource: createSource, clearStoredLocation: true)
        case .free:
            switch document.initSource {
            case .initFromLink, .initReactivated:
                if let localDocument = self.localDocuments.last, localDocument.hasEqualContentTo(document) {
                    // 同一篇文档，以远端为准，刷新当前文档的Groot通道，埋点上报“相同页面不重新加载”
                    self.updateStatusWithDocument(document, status: .free, createSource: createSource)
                    self.currentRuntime?.trackOnMagicShareInitFinished(dueTo: .samePage, forceUpdateWith: document.shareID)
                } else {
                    // 非同一篇文档，本地无变化，埋点上报“非跟随状态不重新加载”
                    self.currentRuntime?.trackOnMagicShareInitFinished(dueTo: .unfollow, forceUpdateWith: document.shareID)
                }
            default:
                break
            }
        case .shareScreenToFollow:
            self.replaceWithDocument(document, status: .sstomsFollowing, createSource: createSource, clearStoredLocation: true)
        case .none:
            break
        }
        updateStatus(newStatus)
    }

    private func handleUnfollow(lastDocument: MagicShareDocument?) {
        logger.info("magic share data is nil, then navigatorEventRelay accept none")
        TrackContext.shared.updateContext(for: meeting.sessionId) { context in
            context.shareId = "none"
            context.actionUniqueID = "none"
        }
        currentRuntime?.setClearStoredLocation()
        if lastDocument != nil {
            // 多次调用stopMeeting会有问题
            logger.debug("magic share factory stop meeting")
            magicShareRuntimeFactory.stopMeeting()
        }
        // 妙享结束时主动dismiss掉文档中present的页面，避免打开图片/视频时结束妙享导致内存泄漏
        if let currentRuntime = self.currentRuntime {
            Util.runInMainThread {
                // 仅处理文档中present的页面，避免误dismiss掉参会人等页面
                if let presentedVC = currentRuntime.documentVC.presentedViewController,
                   presentedVC.presentingViewController == currentRuntime.documentVC.navigationController {
                    presentedVC.dismiss(animated: false)
                }
            }
        }
        let oldValue = localDocuments
        localDocuments = []
        currentRuntime = nil
        // 状态流转回none
        logger.info("follow status = \(InMeetFollowViewModelStatus.none)")
        listeners.forEach { $0.didUpdateLocalDocuments(localDocuments, oldValue: oldValue) }
        self.lastEvent = nil
        updateStatus(.none)
    }

    private func reportMagicShareInfo(with document: MagicShareDocument?) {
        guard let doc = document, doc.user == meeting.account else { return }
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        /// eventType: 4 (EndShare)
        httpClient.follow.postMagicShareInfo(eventType: 4, meetingId: meeting.meetingId, objToken: doc.token, timestamp: timestamp, shareId: doc.shareID, info: nil)
    }
}

extension InMeetFollowManager: MyselfListener {

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let myNewInterpreterStatus = myself.settings.interpreterSetting?.confirmStatus == .confirmed
        let myOldInterpreterStatus = oldValue?.settings.interpreterSetting?.confirmStatus == .confirmed
        if oldValue == nil || (myNewInterpreterStatus != myOldInterpreterStatus) {
            listeners.forEach { $0.didUpdateMyselfInterpreterStatus(myNewInterpreterStatus) }
        }
    }
}

extension InMeetFollowManager: MeetingNoticeListener {
    func didReceiveDocPermissionPopup(_ popupInfo: PopupNoticeInfo) {
        showDocPermissionAlert(popupInfo)
    }

    private func dismissAlertIfNeeded(_ document: MagicShareDocument?) {
        if let alertShareId = document?.shareID, docsAlert.keys.contains(alertShareId) {} else {
            // 共享关闭及共享人变化了则弹框消失
            docsAlert.values.forEach {
                $0.ref?.dismiss()
            }
            docsAlert.removeAll()
        }
    }

    private func showDocPermissionAlert(_ popupInfo: PopupNoticeInfo) {

        ByteViewDialog.Builder()
            .id(.permissionOfDocs)
            .colorTheme(.tendencyConfirm)
            .title(popupInfo.title)
            .message(popupInfo.messageContent)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                let request = ReplyFollowNoticeRequest(meetingId: self.meeting.meetingId,
                                                       breakoutRoomId: self.meeting.data.breakoutRoomId,
                                                       messageId: popupInfo.messageID, action: .reject)
                self.httpClient.send(request)
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                let request = ReplyFollowNoticeRequest(meetingId: self.meeting.meetingId,
                                                       breakoutRoomId: self.meeting.data.breakoutRoomId,
                                                       messageId: popupInfo.messageID, action: .agree)
                self.httpClient.send(request)
            })
            .show { [weak self] alert in
                if let self = self, let popupShareID = popupInfo.extra["share_id"] {
                    self.docsAlert[popupShareID] = WeakRef(alert)
                } else {
                    alert.dismiss()
                }
            }
    }
}

extension InMeetFollowManager: MagicShareDocumentChangeDelegate {

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, didDocumentChange userOperation: MagicShareOperation) {
        switch userOperation {
        case .onTitleChange(let title):
            Logger.vcFollow.debug("userOperation applied, document title did change to: \(title.hash)")
            self.changeDocumentTitle(magicShareRuntime.documentInfo, title: title)
        default:
            Logger.vcFollow.debug("userOperation skipped")
        }
    }
}

extension InMeetFollowManager {

    func showPositionSyncedToastIfNeeded() {
        if canShowPositionSyncedToast, let document = magicShareDocument {
            Toast.showOnVCScene(BundleI18n.ByteView.View_VM_PositionSyncedNameBraces(document.userName))
            canShowPositionSyncedToast = false
        }
    }

}

extension InMeetFollowManager: RtcListener {

    func reportSysStats(_ stats: RtcSysStats) {
        // 仅当妙享不为空，或需要额外上报一次CLOSE时，才进入内部逻辑
        guard setting.isMagicShareCpuUpdateEnabled, self.isExtraCPUUsageUpdateNeeded == true || !self.localDocuments.isEmpty else {
            return
        }
        let cpuAppUsage = stats.cpuAppUsage
        let cpuTotalUsage = stats.cpuTotalUsage
        let cpuCoreCount = stats.cpuCoreCount
        let isCharging = UIDevice.current.isBatteryMonitoringEnabled ? UIDevice.current.batteryState != .unplugged : false
        let magicShareStatus = self.magicShareStatus
        let usage = SetAppCpuManagerStatusRequest.iOSCpuUsage(appCpuUsage: Int32(cpuAppUsage * 100), systemCpuUsage: Int32(cpuTotalUsage * 100))
        let request = SetAppCpuManagerStatusRequest(iosCpuUsage: usage, logicCoreCount: cpuCoreCount, isCharging: isCharging, magicShareStatus: magicShareStatus)
        httpClient.send(request) { result in
            if case let .failure(errorMsg) = result {
                Logger.vcFollow.warn("update cpu usage failed, errorCode: \(errorMsg.toErrorCode())")
            }
        }
        // 直到上报过CLOSE，才置否开关
        if magicShareStatus != .close {
            self.isExtraCPUUsageUpdateNeeded = true
        } else {
            self.isExtraCPUUsageUpdateNeeded = false
        }
    }

    private var magicShareStatus: SetAppCpuManagerStatusRequest.MagicShareStatus {
        let isMagicShareOn = !self.localDocuments.isEmpty
        let isFloating = self.router.isFloating
        let didRenderFinish = self.currentRuntime?.didRenderFinish ?? false
        switch (isMagicShareOn, isFloating, didRenderFinish) {
        case (false, _, _):
            return .close
        case (true, true, _):
            return .smallWindows
        case (true, false, true):
            return .frontStandBy
        case (true, false, false):
            return .frontStartup
        }
    }

}

// MARK: - 投屏转妙享“共享人已更换内容”提示

extension InMeetFollowManager {

    /// 当远端数据改变时，比较是否与本地相同，并更新提示的显示状态
    /// - Parameters:
    ///   - newDocument: 新妙享数据
    ///   - newScreenSharedData: 新共享屏幕数据
    ///   - oldScreenSharedData: 旧共享屏幕数据
    private func checkShouldShowPresenterChangedContentHintOnRemoteChange(
        newDocument: MagicShareDocument?,
        newScreenSharedData: ScreenSharedData?,
        oldScreenSharedData: ScreenSharedData?
    ) {
        Logger.shareScreenToFollow.info("remote change, may update presenterChangedContentHint, newDocument: \(newDocument), newSSData: \(newScreenSharedData), oldSSData: \(oldScreenSharedData)")
        // 记录最近一次的共享屏幕数据
        self.latestScreenSharedData = newScreenSharedData
        // 如果新妙享数据为空，或不是投屏转妙享，则恢复更新提示的显示状态
        if newDocument?.isSSToMS != true {
            Logger.shareScreenToFollow.info("did recover hintValue: false")
            shouldShowPresenterChangedContentHint = false
        }
        // 判断是否是投屏转妙享，远端是否有共享屏幕数据变化，否则直接退出判断
        guard let newMSData = newDocument,
              newMSData.isSSToMS == true,
              let newSSData = newScreenSharedData else {
            Logger.shareScreenToFollow.info("skip remote change, due to: Invalid Data")
            return
        }
        // 如果是小窗返回大窗/首次入会，根据FollowManager的记录做数据补偿
        guard let oldSSData = oldScreenSharedData else {
            Logger.shareScreenToFollow.info("apply local change, hintValue: \(shouldShowPresenterChangedContentHint)")
            listeners.forEach { $0.didUpdateShowPresenterChangedContentHint(shouldShowPresenterChangedContentHint) }
            return
        }
        // 判断远端是否改变
        var isRemoteChanged: Bool = false
        if let newCCMInfo = newSSData.ccmInfo, let oldCCMInfo = oldSSData.ccmInfo { // 变化前后都是CCM文档的Tab，则判断是否发生文档变化
            isRemoteChanged = (newCCMInfo != oldCCMInfo)
        } else { // 变化前后有非CCM文档的Tab参与，直接认定为有改变
            isRemoteChanged = true
        }
        guard isRemoteChanged else {
            // 远端没有改变，则中止后续操作
            Logger.shareScreenToFollow.info("skip remote change, due to: Unchanged")
            return
        }
        // 判断是否有新CCMInfo
        guard let newCCMInfo = newSSData.ccmInfo else {
            // 没有新CCMInfo，直接更新为true
            Logger.shareScreenToFollow.info("apply remote change, hintValue: true, due to: web tab")
            updateShouldShowPresenterChangedContentHint(to: true)
            return
        }
        // 比较和本地是否相同
        if let localDocument = localDocuments.last { // 优先比较本地现有数据，因为可能有本地跳转
            let shouldShow = !localDocument.hasEqualContentToCCMInfo(newCCMInfo)
            Logger.shareScreenToFollow.info("apply remote change, hintValue: \(shouldShow), due to: Local File Data = Remote CCMInfo")
            updateShouldShowPresenterChangedContentHint(to: shouldShow)
        } else { // 没有本地数据，则比较推送过来的数据
            let shouldShow = !newMSData.hasEqualContentToCCMInfo(newCCMInfo)
            Logger.shareScreenToFollow.info("apply remote change, hintValue: \(shouldShow), due to: Local MS Data = Remote CCMInfo")
            updateShouldShowPresenterChangedContentHint(to: shouldShow)
        }
    }

    /// 记录“共享人已切换内容”的显示状态，并发出通知
    /// - Parameter newStatus: 是否显示提示内容
    private func updateShouldShowPresenterChangedContentHint(to showHint: Bool) {
        Logger.shareScreenToFollow.info("did update show hintValue to: \(showHint)")
        shouldShowPresenterChangedContentHint = showHint
        listeners.forEach { $0.didUpdateShowPresenterChangedContentHint(showHint) }
    }

    /// 当本地数据改变时，比较是否与远端相同，如为同一文档，更新提示的显示状态
    /// - Parameter newDocument: 新妙享数据
    func checkShouldShowPresenterChangedContentHintOnLocalChange(to newDocument: MagicShareDocument) {
        Logger.shareScreenToFollow.info("local change, may update presenterChangedContentHint, document: \(newDocument)")
        // 如果当前显示了提示，且有新投屏转妙享文档，判断是否需要移除提示
        guard shouldShowPresenterChangedContentHint,
              let lastCCMInfo = latestScreenSharedData?.ccmInfo,
              newDocument.isSSToMS else {
            Logger.shareScreenToFollow.info("skip local change, hintValue: \(shouldShowPresenterChangedContentHint)")
            return
        }
        // 如果本地和远端相等，则同步
        if newDocument.hasEqualContentToCCMInfo(lastCCMInfo) {
            Logger.shareScreenToFollow.info("apply local change, dismiss presenterChangedContentHint")
            updateShouldShowPresenterChangedContentHint(to: false)
        }
    }

}

// MARK: - v7.9妙享降级
// 妙享降级方案 https://bytedance.larkoffice.com/wiki/VO9CwvV2TiaAlrklDkickjTpnMb

enum MagicShareDowngradeReason: String {
    case systemLoad
    case thermal
    case openDoc
    case dynamic
}

extension InMeetFollowManager: PerfMonitorDelegate {

    // systemLoad + dynamic + thermal + openDoc
    func updatePerfInfo(for downgradeReason: MagicShareDowngradeReason) {
        guard isMagicShareDowngradeEnabled else { return }
        let systemLoadScore: CGFloat = isSystemLoadMarked ? degradeSystemLoad : 0
        let dynamicScore: CGFloat = dynamicScore
        let thermalScore: CGFloat = calcThermalScore()
        let openDocScore = calcOpenDocScore()
        let level = min(systemLoadScore + dynamicScore + thermalScore + openDocScore, 4.0)
        let performanceInfo = MeetingObserver.MagicSharePerformanceInfo(level: level,
                                                                        systemLoadScore: systemLoadScore,
                                                                        dynamicScore: dynamicScore,
                                                                        thermalScore: thermalScore,
                                                                        openDocScore: openDocScore)
        logger.debug("will post ms performance info, level: \(level), systemLoadScore: \(systemLoadScore), dynamicScore: \(dynamicScore), thermalScore: \(thermalScore), openDocScore: \(openDocScore)")
        if isMagicShareDowngradeConfigEnabled { // 仅线上开关打开时才真正更新通知给CCM
            meeting.service.postMeetingChanges { $0.magicSharePerformanceInfo = performanceInfo }
        }
        MagicShareTracksV2.trackDowngradeInfoChange(token: magicShareDocument?.token ?? "",
                                                    level: level,
                                                    systemLoadScore: systemLoadScore,
                                                    dynamicScore: dynamicScore,
                                                    thermalScore: thermalScore,
                                                    openDocScore: openDocScore,
                                                    degradeReason: downgradeReason.rawValue)
    }

    // MARK: - PerfMonitorDelegate
    // SystemCPU 在一段时间内连续处于高负载的时候，会触发 reportOverload 事件
    // MagicShare 场景下会根据这个事件，通知降级。当事件发生时，设置值为system_load
    // 数据来自线上 Settings 配置，目前暂定值为 1，表示降级等级 +1
    func reportPerformanceOverload() {
        guard isMagicShareDowngradeEnabled else { return }
        logger.debug("receive system over load")
        isSystemLoadMarked = true
        updateDynamicScore(with: true)
    }

    func reportPerformanceUnderuse() {
        guard isMagicShareDowngradeEnabled else { return }
        logger.debug("receive system under use")
        isSystemLoadMarked = false
        updateDynamicScore(with: false)
    }

    // MARK: - Dynamic
    private func updateDynamicScore(with isOverload: Bool) {
        guard isMagicShareDowngradeEnabled else { return }
        if isOverload {
            if dynamicOverloadCount < degradeDynamicHighCount - 1 {
                dynamicOverloadCount += 1
                dynamicUnderuseCount = 0
            } else {
                dynamicOverloadCount = 0
                dynamicScore += degradeDynamicStep
                if dynamicScore > degradeDynamicMax {
                    dynamicScore = degradeDynamicMax
                }
            }
        } else {
            if dynamicUnderuseCount < degradeDynamicLowCount - 1 {
                dynamicUnderuseCount += 1
                dynamicOverloadCount = 0
            } else {
                dynamicUnderuseCount = 0
                dynamicScore -= degradeDynamicStep
                if dynamicScore < 0 {
                    dynamicScore = 0
                }
            }
        }
        updatePerfInfo(for: .dynamic)
    }

    // MARK: - ThermalState
    private func startThermalDetection() {
        guard isMagicShareDowngradeEnabled else { return }
        logger.debug("start thermal detection")
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            let currentThermalState = ProcessInfo.processInfo.thermalState
            self.thermalState = currentThermalState
            self.updatePerfInfo(for: .thermal)
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeThermalState),
                                               name: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil)
    }

    @objc
    private func didChangeThermalState() {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            let thermalState = ProcessInfo.processInfo.thermalState
            logger.debug("thermal detection did change to: \(thermalState)")
            self.thermalState = thermalState
            self.updatePerfInfo(for: .thermal)
        }
    }

    private func calcThermalScore() -> CGFloat {
        let currentThermalState = self.thermalState
        switch currentThermalState {
        case .fair: return degradeThermalFair
        case .serious: return degradeThermalSerious
        case .critical: return degradeThermalCritical
        default: return 0
        }
    }

    // MARK: - OpenDoc
    private func appendOpenDocRecord() {
        guard isMagicShareDowngradeEnabled else { return }
        openDocRecord.append(Date())
        updatePerfInfo(for: .openDoc)
        DispatchQueue.main.asyncAfter(deadline: .now() + degradeOpenDocInterval) { [weak self] in
            guard let self = self else { return }
            self.updatePerfInfo(for: .openDoc)
        }
    }

    private func calcOpenDocScore() -> CGFloat {
        let openDocRecord = self.openDocRecord
        let currentDate = Date()
        var score: CGFloat = 0
        openDocRecord.forEach { date in
            if currentDate.timeIntervalSince(date) <= degradeOpenDocInterval {
                score += degradeOpenDocStep
            }
        }
        return score
    }
}

extension InMeetFollowManager: InMeetNotesDataListener {
    func didChangeNotesOn(_ isOn: Bool) {
        guard isMagicShareDowngradeEnabled else { return }
        if isOn {
            logger.debug("notes is on, will append open doc record")
            appendOpenDocRecord()
        }
    }
}
