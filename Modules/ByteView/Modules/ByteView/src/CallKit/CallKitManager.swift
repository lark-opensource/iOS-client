//
//  CallKitManager.swift
//  ByteView
//
//  Created by kiri on 2023/6/14.
//

import Foundation
import CallKit
import RxSwift
import RxRelay
import LarkLocalizations
import LarkMedia
import ByteViewCommon
import ByteViewTracker

final class CallKitManager: NSObject {

    struct ProviderConfig {
        let ringtone: String?
        let forceIgnoreRecents: Bool

        init(ringtone: String? = nil, forceIgnoreRecents: Bool = false) {
            self.ringtone = ringtone
            self.forceIgnoreRecents = forceIgnoreRecents
        }
    }

    static let shared = CallKitManager()

    @RwAtomic private var _provider: CXProvider?
    @RwAtomic private var controller: CXCallController?
    private var factory: (() throws -> MeetingDependency)?

    private var calls: [UUID: CallKitCall] = [:]
    private var muteActionTriggeredInApp: Set<UUID> = []
    // 避免重复响铃
    private var filteredIncomingCalls: Set<VideoChatIdentifier> = []
    // 接听忙线响铃触发的挂断
    private var busyEndCallUUIDs: Set<UUID> = []
    private var disposeBag = DisposeBag()
    @RwAtomic private(set) var userId: String = ""
    @RwAtomic private var processingIncomingCallRequests: Set<UUID> = []

    private var provider: CXProvider? {
        CallKitQueue.assertCallKitQueue()
        if _provider == nil {
            _provider = CXProvider(configuration: .configuration(from: nil))
            _provider?.setDelegate(self, queue: CallKitQueue.queue)
        }
        return _provider
    }

    private override init() {
        super.init()
        CallKitQueue.queue.async {
            self.controller = CXCallController(queue: CallKitQueue.queue)
        }
    }

    func setup(userId: String, factory: @escaping () throws -> MeetingDependency) {
        _ = AppInfo.shared
        CallKitQueue.queue.async {
            if self.userId == userId { return }
            self.resetIfNeeded()
            self.userId = userId
            Logger.callKit.info("setup CallKitManager by factory, user: \(userId)")
            self.setupPushReceiver(factory: factory)
        }
    }

    func setupIfNeeded(dependency: MeetingDependency) {
        _ = AppInfo.shared
        CallKitQueue.queue.async {
            let userId = dependency.account.userId
            if self.userId == userId { return }
            self.resetIfNeeded()
            self.userId = userId
            Logger.callKit.info("setup CallKitManager by dependency, user: \(userId)")
            self.setupPushReceiver(factory: { dependency })
        }
    }

    func destroy() {
        CallKitQueue.queue.async {
            Logger.callKit.info("destroy CallKitManager and unregistryPushKit for user: \(self.userId)")
            // CallKitManager 应该成对的 registry/unregistry PushKit，
            // 否则容易导致无法响应到 VoIP 推送
            PushKitService.shared.unregistryPushKit()
            PushKitService.shared.removeHandler(self)
            self.resetIfNeeded()
        }
    }

    private typealias IconDataProvider = (() -> Data?)
    func updateConfiguration(service: MeetingBasicService, providerConfig: ProviderConfig) {
        let setting = service.setting
        let includesInRecents = !providerConfig.forceIgnoreRecents && setting.includesCallsInRecents
        let ringtone: String
        if let ringtone_ = providerConfig.ringtone, !ringtone_.isEmpty {
            ringtone = ringtone_
        } else {
            ringtone = setting.customRingtone
        }
        let dataProvider = { setting.callKitIconData }
        updateConfigurationIfNeeded(iconProvider: dataProvider,
                                    ringtone: ringtone,
                                    includesInRecents: includesInRecents)
    }

    func updateConfiguration(dependency: MeetingDependency, providerConfig: ProviderConfig) {
        let setting = dependency.setting
        let includesInRecents = !providerConfig.forceIgnoreRecents && setting.includesCallsInRecents
        let ringtone: String
        if let ringtone_ = providerConfig.ringtone, !ringtone_.isEmpty {
            ringtone = ringtone_
        } else {
            ringtone = setting.customRingtone
        }
        let dataProvider = { setting.callKitIconData }
        updateConfigurationIfNeeded(iconProvider: dataProvider,
                                    ringtone: ringtone,
                                    includesInRecents: includesInRecents)
    }

    private func updateConfigurationIfNeeded(iconProvider: IconDataProvider, ringtone: String, includesInRecents: Bool) {
        guard let provider = self.provider else { return }

        let imageData = provider.configuration.iconTemplateImageData
        let updateIcon: Bool
        var iconData: Data?
        // 仅 CallKit icon 为空时才更新 icon data
        if imageData == nil {
            updateIcon = true
            iconData = iconProvider()
        } else {
            updateIcon = false
        }
        let updateRingtone = provider.configuration.ringtoneSound != ringtone
        let updateRecents = provider.configuration.includesCallsInRecents != includesInRecents

        guard updateIcon || updateRingtone || updateRecents else { return }
        let config = provider.configuration
        if updateIcon {
            config.iconTemplateImageData = iconData
        }
        if updateRingtone {
            config.ringtoneSound = ringtone
        }
        if updateRecents {
            config.includesCallsInRecents = includesInRecents
        }
        provider.configuration = config
    }

    private func resetIfNeeded() {
        if self.userId.isEmpty { return }
        Logger.callKit.info("reset callkit, oldUser = \(self.userId)")
        self.disposeBag = DisposeBag()
        self._provider?.invalidate()
        self._provider = nil
        self.factory = nil
        self.userId = ""
    }

    deinit {
        _provider?.invalidate()
        _provider = nil
    }
}

// MARK: CallKitCall
extension CallKitManager {
    func lookupCall(uuid: UUID) -> CallKitCall? {
        CallKitQueue.assertCallKitQueue()
        return calls[uuid]
    }

    private func addCall(_ call: CallKitCall) {
        CallKitQueue.assertCallKitQueue()
        calls[call.uuid] = call
        call.delegate?.didStartCall(call)
    }

    private func removeCall(_ call: CallKitCall) {
        CallKitQueue.assertCallKitQueue()
        if calls.removeValue(forKey: call.uuid) != nil {
            call.delegate?.didRemoveCall(call)
        }
    }

    func hasIncomingCall(except call: CallKitCall) -> Bool {
        calls.contains { $0.value.uuid != call.uuid && !$0.value.isOutgoing }
    }

    func isFilteredIncomingCall(meetingId: String, interactiveId: String) -> Bool {
        if !meetingId.isEmpty, !interactiveId.isEmpty, self.filteredIncomingCalls.contains(VideoChatIdentifier(id: meetingId, interactiveId: interactiveId)) {
            return true
        } else {
            return false
        }
    }
}

// MARK: Call Actions
extension CallKitManager {
    func ignoreVoipPush(_ pushInfo: VoIPPushInfo, reason: CallkitIgnoredReason, completion: (() -> Void)? = nil) {
        guard let provider = self.provider else {
            completion?()
            return
        }
        // reportNewIncomingCall 方法不要直接被外部调用，必须要走
        let uuid = UUID()
        Logger.callKit.info("ignoreVoipPush by start and end: \(pushInfo.uuid), call uuid: \(uuid)")
        self.processingIncomingCallRequests.remove(pushInfo.requestId)
        provider.reportNewIncomingCall(with: uuid, update: .from(pushInfo: pushInfo, ignoredReason: reason)) { error in
            if let error = error {
                Logger.callKit.error("Failed reportNewIncomingCall when ignoreVoipPush, \(error)")
            } else {
                provider.reportCall(with: uuid, endedAt: nil, reason: .remoteEnded)
            }
            self.trackIgnoredVoipPush(pushInfo, reason: reason)
            completion?()
        }
        CallKitQueue.assertCallKitQueue()
        CallKitQueue.queue.setSpecific(key: PushKitService.hasOutstandingVoIPPushKey, value: false)
    }

    /// 强制丢弃过期的 VoIPPushInfo
    /// - Parameter pushInfo: VoIPPushInfo
    /// - Parameter dependency: MeetingDependency
    ///
    /// - Returns: true: 丢弃；false：不丢弃，正常走后续流程
    func dropVoIPPushIfNeeded(_ pushInfo: VoIPPushInfo, dependency: MeetingDependency) -> Bool {
        let expiredConfig = dependency.setting.voipExpiredConfig
        let apnsExpiration = pushInfo.apnsExpiration
        let appState = AppInfo.shared.applicationState
        Logger.callKit.info("dropVoIPPush: \(pushInfo.uuid), expired=\(apnsExpiration), expiredConfig=\(expiredConfig), appState=\(appState)")
        // 以下条件均满足时执行强制丢弃：
        // 1、配置有效
        // 2、飞书在后台
        // 3、当前设备未修改本地时间，可推算近似 NTP 时间
        guard expiredConfig.isValid, appState == .background else {
            return false
        }
        // 推送时间与当前时间间隔检查，因为 ntp 时间是异步，无法保障快速的获取，
        // 所以用本地上次 ntp 偏移量计算的 ntp 时间做判断
        let ntpRecord = dependency.setting.deviceNtpTimeRecord
        let deviceNtpDate = ntpRecord?.deviceNtpDate()
        Logger.callKit.info("dropVoIPPush: \(pushInfo.uuid), ntpRecord=\(ntpRecord), deviceNtpDate=\(deviceNtpDate)")
        guard let deviceNtpDate else {
            return false
        }
        let now = deviceNtpDate.timeIntervalSince1970
        let pushDate = apnsExpiration.timeIntervalSince1970
        let delta = now - pushDate
        Logger.callKit.info("dropVoIPPush: \(pushInfo.uuid), delta=\(delta)")
        if delta < expiredConfig.expiredInterval {
            return false
        }
        // 周期内忽略次数检查
        var needDrop = false
        var records = [TimeInterval]()
        if let ignoreRecord = dependency.setting.voipExpiredRecord {
            records.append(contentsOf: ignoreRecord.records)
        }

        if records.isEmpty {
            needDrop = true
        } else {
            // 一个忽略周期
            let ignorePeriod = TimeInterval(expiredConfig.ignorePeriod * 24 * 60 * 60)
            let validInterval = now - ignorePeriod
            records.removeAll(where: { $0 < validInterval })
            needDrop = records.count < expiredConfig.ignoreCount
        }

        if needDrop {
            // 设置 slardar 自定义内容，便于排查是否是主动忽略导致的 crash
            dependency.heimdallr.setCustomContextValue("1", forKey: "vc_drop_expired_voip")
            dependency.heimdallr.setCustomFilterValue("1", forKey: "vc_drop_expired_voip")
            records.append(now)
            dependency.setting.voipExpiredRecord = VoIPExpiredIgnoreRecord(records: records)
            self.processingIncomingCallRequests.remove(pushInfo.requestId)
            CallKitQueue.assertCallKitQueue()
            CallKitQueue.queue.setSpecific(key: PushKitService.forceDropExpiredVoIPPushKey, value: true)
            #if !(DEBUG || INHOUSE || ALPHA)
            // beta 版直接让其 crash
            CallKitQueue.queue.setSpecific(key: PushKitService.hasOutstandingVoIPPushKey, value: false)
            #endif
            trackIgnoredVoipPush(pushInfo, reason: .forceDropExpired)
        }

        Logger.callKit.info("dropVoIPPush: \(pushInfo.uuid), needDrop=\(needDrop), ignored records=\(records)")
        return needDrop
    }

    func reportNewIncomingCall(_ call: CallKitCall, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let provider = self.provider, let params = call.incomingCallParams else {
            completion(.failure(VCError.unknown))
            return
        }
        self.addCall(call)
        call.log("\(#function) start, includesCallsInRecents: \(provider.configuration.includesCallsInRecents)")
        self.processingIncomingCallRequests.remove(params.requestId)
        provider.reportNewIncomingCall(with: call.uuid, update: params.callUpdate) { error in
            // 被屏蔽的、勿扰模式、已存在的记录到已上报里，下次直接忽略
            // iOS 15 上专注模式开启且飞书不在白名单（iOS 14 上勿扰模式+始终静音），在前台也会被系统拦截，
            // 优化成前台 callkit 被拦截后放行降级到 app 内置的响铃页
            // https://bytedance.feishu.cn/docx/doxcnhdJns0RdEjCoM1gjQCxQ5f
            if let error = error {
                call.loge("\(#function) Failed: \(error)")
                if let callkitErr = error as? CXErrorCodeIncomingCallError {
                    let identifier = VideoChatIdentifier(id: params.meetingId, interactiveId: params.interactiveId)
                    switch callkitErr.code {
                    case .filteredByBlockList, .filteredByDoNotDisturb, .callUUIDAlreadyExists:
                        self.filteredIncomingCalls.insert(identifier)
                        call.log("filteredIncomingCall \(identifier), errorCode: \(callkitErr.code)")
                    default:
                        call.log("don`t filteredIncomingCall \(identifier), errorCode: \(callkitErr.code)")
                    }
                    self.trackFailedIncomingCall(params, isDisturb: callkitErr.code == .filteredByDoNotDisturb)
                } else {
                    self.trackFailedIncomingCall(params, isDisturb: false)
                }
                _ = call.reportEnded()
                self.removeCall(call)
                completion(.failure(error))
            } else {
                call.log("\(#function) succeed")
                completion(.success(Void()))
            }
        }
        CallKitQueue.assertCallKitQueue()
        CallKitQueue.queue.setSpecific(key: PushKitService.hasOutstandingVoIPPushKey, value: false)
    }

    func requestStartCall<T>(_ call: CallKitCall, completion: @escaping (Result<T, Error>) -> Void) {
        guard let controller = self.controller, case let .dialing(transaction) = call.status else {
            call.log("requestStartCall cancelled")
            completion(.failure(VCError.unknown))
            return
        }

        call.log("requestStartCall start")
        self.addCall(call)
        let cxAction = CXStartCallAction(call: call.uuid, handle: CXHandle(type: .generic, value: ""))
        controller.requestTransaction(with: cxAction) { error in
            if let error = error {
                call.loge("requestStartCall failed, error = \(error)")
                transaction.fail(error: error)
            }
        }
    }

    func reportOutgoingCall(_ call: CallKitCall) {
        call.log("reportOutgoingCall")
        self.provider?.reportOutgoingCall(with: call.uuid, connectedAt: Date())
    }

    func reportCallEnded(_ call: CallKitCall, reason: CallEndedReason) {
        call.log("reportCallEnded, reason: \(reason)")
        // TODO(callkit): transform event to callkit end reason
        if call.reportEnded() {
            self.provider?.reportCall(with: call.uuid, endedAt: Date(), reason: reason.cxReason)
        }
        self.removeCall(call)
    }

    func updateCall(_ call: CallKitCall, info: VideoChatInfo, topic: String) {
        self.provider?.reportCall(with: call.uuid, updated: .from(userId: call.userId, info: info, topic: topic))
    }

    func updateCall(_ call: CallKitCall, lobbyInfo: LobbyInfo) {
        self.provider?.reportCall(with: call.uuid, updated: .from(userId: call.userId, lobbyInfo: lobbyInfo, inviterId: call.incomingCallParams?.inviterId))
    }

    func muteCallMicrophone(_ call: CallKitCall, muted: Bool, from: String = #function) {
        call.log("muteCallMicrophone, muted: \(muted), from: \(from)")
        let muteAction = CXSetMutedCallAction(call: call.uuid, muted: muted)
        if call.isMuted == muted {
            call.log("muteCallMicrophone, action: \(muteAction), not changed, skip SetMutedCallAction")
            // iOS 16 AudioSession 拉起比较慢，用户早于 AudioSession 激活点击 unmute，会被过滤掉
            //return
        }

        // MuteAction 需要等 AudioSession 激活后再提交执行，
        // 否则在特定机型上有概率出现 AudioSession 激活后，系统自动执行 unmute 操作
        // 产生隐私风险
        self.waitAudioSessionActivated { [weak self] result in
            CallKitQueue.queue.async {
                guard let self = self, result.isSuccess else { return }
                self.muteActionTriggeredInApp.insert(muteAction.uuid)
                self.controller?.requestTransaction(with: muteAction) { error in
                    if let error = error {
                        call.loge("muteCallMicrophone failed, \(error)")
                    }
                }
            }
        }
    }

    func waitAudioSessionActivated(completion: @escaping (Result<Void, Error>) -> Void) {
        Logger.callKit.info("waiting AudioSession activated, current status \(Self.audioSessionActivated.value)")
        Observable<Bool>.merge(
            Self.audioSessionActivated.filter({ $0 }).asObservable(),
            Observable.just(true).delay(.seconds(3), scheduler: MainScheduler.instance).do(onNext: { _ in
                Logger.callKit.error("waiting AudioSession activated timeout!")
            })
        )
        .take(1)
        .subscribe(onNext: { _ in
            completion(.success(Void()))
        }, onError: { error in
            completion(.failure(error))
        }).disposed(by: disposeBag)
    }

    func releaseHold(_ call: CallKitCall) {
        let action = CXSetHeldCallAction(call: call.uuid, onHold: false)
        self.controller?.requestTransaction(with: [action], completion: { error in
            if let error = error {
                call.loge("releaseHold failed: \(error)")
            }
        })
    }

    func checkPendingTransactions() -> Bool {
        guard let provider = self.provider else { return false }
        return provider.pendingTransactions.count > 0
    }
}

// MARK: CXProviderDelegate
extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        Logger.callKit.info(#function)
    }

    /// Called when the provider has been fully created and is ready to send actions and receive updates
    func providerDidBegin(_ provider: CXProvider) {
        Logger.callKit.info(#function)
    }

    /// Called whenever a new transaction should be executed. Return whether or not the transaction was handled:
    ///
    /// - NO: the transaction was not handled indicating that the perform*CallAction methods should be called sequentially for each action in the transaction
    /// - YES: the transaction was handled and the perform*CallAction methods should not be called sequentially
    ///
    /// If the method is not implemented, NO is assumed.
    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        Logger.callKit.info("\(#function) \(transaction.actions)")
        if transaction.actions.count == 2,
           transaction.actions[0].isKind(of: CXEndCallAction.self) && transaction.actions[1].isKind(of: CXAnswerCallAction.self)
            || transaction.actions[1].isKind(of: CXEndCallAction.self) && transaction.actions[0].isKind(of: CXAnswerCallAction.self) {
            let endActionIdx = transaction.actions[0].isKind(of: CXEndCallAction.self) ? 0 : 1
            if let endAction = transaction.actions[endActionIdx] as? CXEndCallAction,
               let acceptAction = transaction.actions[1 - endActionIdx] as? CXAnswerCallAction {
                self.busyEndCallUUIDs.insert(endAction.callUUID)
                Logger.callKit.info("end call: \(endAction.callUUID), by accept call: \(acceptAction.callUUID)")
            }
        }
        return false
    }

    // If provider:executeTransaction:error: returned NO, each perform*CallAction method is called sequentially for each action in the transaction
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Logger.callKit.info("\(#function) \(action)")
        guard let call = lookupCall(uuid: action.callUUID) else {
            Logger.callKit.error("\(#function) failed, can't find call \(action)")
            action.fail()
            return
        }
        call.performStartCall(action: action)
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = lookupCall(uuid: action.callUUID) else {
            Logger.callKit.error("\(#function) failed, can't find call \(action)")
            action.fail()
            return
        }
        call.log("\(#function), action: \(action)")
        if !call.performAnswerCall(action: action) {
            removeCall(call)
        }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let isAcceptOther = self.busyEndCallUUIDs.remove(action.callUUID) != nil
        guard let controller = self.controller, let call = lookupCall(uuid: action.callUUID) else {
            Logger.callKit.error("\(#function) failed, can't find call \(action), fulfill end action")
            action.fulfill(withDateEnded: Date())
            return
        }
        call.log("\(#function), isAcceptOther: \(isAcceptOther), action: \(action)")
        var deferRequest = false
        // 判断是否安装了多个 LARK 并且 同时收到 CallKit 响铃
        if case .ringing = call.status, controller.callObserver.calls.contains(where: {
            !$0.hasConnected && !$0.hasEnded && !$0.isOutgoing && !$0.isOnHold && self.lookupCall(uuid: $0.uuid) == nil
        }) {
            call.log("defer backend request")
            deferRequest = true
        }
        if !call.performEnd(action: action, deferRequest: deferRequest, isAcceptOther: isAcceptOther) {
            _ = call.reportEnded()
            self.removeCall(call)
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = self.lookupCall(uuid: action.callUUID) else {
            Logger.callKit.error("\(#function) failed, can't find call \(action)")
            action.fail()
            return
        }
        call.log("\(#function), action: \(action)")
        call.performHoldCall(action: action)
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = self.lookupCall(uuid: action.callUUID) else {
            Logger.callKit.error("\(#function) failed, can't find call \(action)")
            action.fail()
            return
        }
        call.log("\(#function), action: \(action)")
        let isTriggerdInApp = self.muteActionTriggeredInApp.remove(action.uuid) != nil
        call.performMuteCall(action: action, isTriggeredInApp: isTriggerdInApp)
    }

    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        Logger.callKit.info("\(#function), action: \(action)")
        action.fail()
    }

    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        Logger.callKit.info("\(#function), action: \(action)")
        action.fail()
    }

    /// Called when an action was not performed in time and has been inherently failed.
    /// Depending on the action, this timeout may also force the call to end.
    /// An action that has already timed out should not be fulfilled or failed by the provider delegate
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        Logger.callKit.error("\(#function), action: \(action)")
    }

    static let audioSessionActivated = BehaviorRelay(value: false)
    /// Called when the provider's audio session activation state changes.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        Logger.callKit.info("providerDidActivateAudioSession category:\(audioSession.category), mode:\(audioSession.mode), currentRoute:\(audioSession.currentRoute) ")
        // iOS 15 系统上，callkit 会有 mute bug，https://bytedance.feishu.cn/docx/doxcn6ZKsUNaIzPIshZ3rMl1F1d
        // 需要切换一下 mute 状态兼容下
        if #available(iOS 17, *) {
            // iOS 17 已经修复该问题
        } else if #available(iOS 15, *), let controller = self.controller {
            // 当前有 callkit 已经接听且麦克风是 unmute 的才重新激活
            if let call = self.calls.first(where: { $0.value.status == .connected })?.value, !call.isMuted {
                let action1 = CXSetMutedCallAction(call: call.uuid, muted: true)
                let action2 = CXSetMutedCallAction(call: call.uuid, muted: false)
                self.muteActionTriggeredInApp.insert(action1.uuid)
                self.muteActionTriggeredInApp.insert(action2.uuid)
                controller.requestTransaction(with: [action1, action2], completion: { error in
                    if let error = error {
                        Logger.callKit.error("restore callkit audio failed: \(error)")
                    }
                })
            }
        }
        Self.audioSessionActivated.accept(true)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        Logger.callKit.info("providerDidDeactivateAudioSession")
        Self.audioSessionActivated.accept(false)
        // fix: 预览页停留几秒扬声器会闪变听筒再闪变回扬声器
        // https://meego.feishu.cn/?issueId=3297514&project=larksuite
        LarkAudioSession.shared.enableSpeakerIfNeeded(LarkAudioSession.shared.isSpeakerOn)
    }
}

// MARK: Track
private extension CallKitManager {
    func trackIgnoredVoipPush(_ pushInfo: VoIPPushInfo, reason: CallkitIgnoredReason) {
        // 忽略的也需要上报收到推送埋点
        let receivedTracker = CallKitReceivedTracker(pushInfo: pushInfo, logger: Logger.callKit)
        _ = receivedTracker.trackReceivedPushViaNTP(ntpDate: nil)
        /// voip 被忽略埋点
        let callType: String
        switch pushInfo.meetingType {
        case .call:
            callType = "call"
        case .meet:
            callType = "meeting"
        default:
            callType = "none"
        }
        let params: TrackParams = [
            "action_name": "receive_ignore",
            "is_voip": 1,
            "is_new_feat": 0,
            "call_type": callType,
            "interactive_id": pushInfo.interactiveID,
            "conference_id": pushInfo.conferenceID,
            "ignore_type": reason.rawValue,
            "is_callkit": true
        ]
        VCTracker.post(name: .vc_meeting_callee_status, params: params)
    }

    func trackFailedIncomingCall(_ params: CallKitCall.IncomingCallParams, isDisturb: Bool) {
        /// voip 被忽略埋点
        let callType: String
        switch params.meetingType {
        case .call:
            callType = "call"
        case .meet:
            callType = "meeting"
        default:
            callType = "none"
        }
        let reason: CallkitIgnoredReason = isDisturb ? .disturbMode : .others
        let params: TrackParams = [
            "action_name": "receive_ignore",
            "is_voip": params.isVoipPush ? 1 : 0,
            "is_new_feat": 0,
            "call_type": callType,
            "interactive_id": params.interactiveId,
            "conference_id": params.meetingId,
            "ignore_type": reason.rawValue,
            "is_callkit": true
        ]
        VCTracker.post(name: .vc_meeting_callee_status, params: params)
    }
}

// MARK: CXProviderConfiguration
private extension CXProviderConfiguration {
    static func configuration(from: CXProviderConfiguration?) -> CXProviderConfiguration {
        let cfg: CXProviderConfiguration
        if #available(iOS 14.0, *) {
            cfg = CXProviderConfiguration()
        } else {
            cfg = CXProviderConfiguration(localizedName: LanguageManager.bundleDisplayName)
        }
        cfg.supportsVideo = true
        cfg.maximumCallGroups = 1
        cfg.maximumCallsPerCallGroup = 1
        cfg.supportedHandleTypes = [.generic]
        if let oldValue = from {
            cfg.includesCallsInRecents = oldValue.includesCallsInRecents
            cfg.ringtoneSound = oldValue.ringtoneSound
            cfg.iconTemplateImageData = oldValue.iconTemplateImageData
        }
        return cfg
    }
}

// MARK: Others
private extension CallEndedReason {
    var cxReason: CXCallEndedReason {
        switch self {
        case .failed:
            return .failed
        case .remoteEnded:
            return .remoteEnded
        case .answeredElsewhere:
            return .answeredElsewhere
        case .declinedElsewhere:
            return .declinedElsewhere
        case .unanswered:
            return .unanswered
        }
    }
}

// MARK: PushKitService
import ByteViewMeeting
import ByteViewNetwork
import ByteViewSetting
import PushKit
import SuiteCodable

extension CallKitManager: PushKitServiceHandler {

    func handlePayload(_ raw: PKPushPayload) {
        let logger = Logger.callKit
        guard raw.type == .voIP, let payload = raw.dictionaryPayload as? [String: Any] else {
            logger.info("PushKitPayload is not voIP type, ignored")
            return
        }
        // nolint-next-line: magic number
        guard let pushInfo = try? DictionaryDecoder().decode(VoIPPushInfo.self, from: payload), pushInfo.pushType == 102 else {
            logger.error("Failed decoding VoIPPushInfo, \(payload)")
            VCTracker.post(name: .vc_biz_error, params: ["error": "invalid_voip_push", "msg": "invalid voip push \(payload)"],
                           platforms: [.slardar])
            DevTracker.post(.warning(.pushkit_invalid_push).category(.callkit).params(["payload": "\(payload)"]))
            self.ignoreVoipPush(.empty, reason: .others)
            return
        }

        let startTime = CACurrentMediaTime()
        let requestId = pushInfo.requestId
        self.processingIncomingCallRequests.insert(requestId)
        logger.info("did receive pushkit, pushInfo: \(pushInfo.uuid), requestId = \(requestId)")
        do {
            if let factory {
                self.handlePushInfo(pushInfo, dependency: try factory())
            }
        } catch {
            logger.error("resolve dependency failed: \(error)")
        }
        if self.processingIncomingCallRequests.contains(requestId) {
            assertionFailure("reportNewIncomingCall missing!")
            logger.error("reportNewIncomingCall missing, abnormal branch matched")
            self.ignoreVoipPush(pushInfo, reason: .others)
        }
        logger.info("handle pushInfo finished: \(pushInfo.uuid), duration = \(Util.formatTime(CACurrentMediaTime() - startTime))")
    }

    func handleToken(_ token: PushKitToken) {
        guard token.type == .voIP else { return }
        Logger.callKit.debug("PushKit voip token: \(token.token.suffix(6))")
    }
}

private extension CallKitManager {
    func setupPushReceiver(factory: @escaping () throws -> MeetingDependency) {
        self.factory = factory
        PushKitService.shared.addHandler(self, priority: .high)
        PushKitService.shared.registryPushKit([.voIP], queue: CallKitQueue.queue)
    }

    func handlePushInfo(_ pushInfo: VoIPPushInfo, dependency: MeetingDependency) {
        if dropVoIPPushIfNeeded(pushInfo, dependency: dependency) {
            return
        }
        let providerConfig = ProviderConfig(ringtone: pushInfo.ringtone)
        updateConfiguration(dependency: dependency, providerConfig: providerConfig)
        let result: Result<MeetingSession, StartMeetingError>
        if self.userId.isEmpty || self.userId != pushInfo.userID {
            result = .failure(.invalidUser)
        } else {
            result = MeetingManager.shared.startMeeting(.voipPush(pushInfo), dependency: dependency, from: nil)
        }
        switch result {
        case .success(let session):
            // PushKit需要同步调用reportNewIncomingCall
            if let component = session.callKit {
                component.reportNewIncomingCall(pushInfo: pushInfo)
            } else {
                assertionFailure("ignoreVoipPush with CallKitMeetingComponent not found: \(pushInfo.uuid)")
                ignoreVoipPush(pushInfo, reason: .others)
                // 之前fallback为.success(.succed), session没有leave，继续执行。by MockCallCoordinator
            }
            Logger.callKit.info("Complete voip task, callkit consumed, session is \(session)")
        case .failure(let error):
            Logger.callKit.warn("ignored by error: \(error)")
            switch error {
            case .alreadyExists:
                self.ignoreVoipPush(pushInfo, reason: .existed)
            case .invalidUser:
                let userId = pushInfo.userID
                let meetingId = pushInfo.conferenceID
                // 收到其它用户的 VoIP Push, 直接忽略，同时将 topic 脱敏，防止下游滥用
                var desensitizedInfo = pushInfo
                desensitizedInfo.topic = ""
                Logger.meeting.error("joinWithVoipPush failed: Receive other user's \(userId) push")
                DevTracker.post(.warning(.pushkit_other_user_push).category(.callkit)
                    .params(["other_user_id": userId, "other_meeting_id": meetingId]))
                Logger.callKit.info("ignoreVoipPush without session: \(pushInfo.uuid)")
                self.ignoreVoipPush(desensitizedInfo, reason: .otherUser)
            default:
                Logger.callKit.error("ignoreVoipPush with asserted branch: \(pushInfo.uuid)")
                self.ignoreVoipPush(pushInfo, reason: .others)
            }
        }
    }
}
