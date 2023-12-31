//
//  MeetingSettingManager.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/27.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork

public protocol MeetingSettingListener: AnyObject {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool)
}

public protocol MeetingComplexSettingListener: AnyObject {
    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?)
}

public final class MeetingSettingManager {
    public let sessionId: String

    let account: ByteviewUser
    let service: UserSettingManager
    let fg: MeetingFeatureGating
    let settingsV3: MeetingSettingsV3
    let logger: Logger
    var userId: String { account.id }

    @RwAtomic public private(set) var meetingId: String = ""
    @RwAtomic public private(set) var meetingType: MeetingType = .unknown
    @RwAtomic private(set) var meetingURL: String = ""
    @RwAtomic private(set) var videoChatInfo: VideoChatInfo = .init()
    @RwAtomic private(set) var myself: Participant?
    @RwAtomic private(set) var videoChatSettings: VideoChatSettings = .init()
    @RwAtomic private var lobbyInfo: LobbyInfo?

    // snapshot of settings
    @RwAtomic private(set) var suiteQuota: GetSuiteQuotaResponse
    @RwAtomic private(set) var adminSettings: GetAdminSettingsResponse
    @RwAtomic private(set) var sponsorAdminSettings: GetAdminSettingsResponse
    @RwAtomic private(set) var _pstnMobileCodes: GetAdminSettingsResponse.PstnMobileCodes?
    @RwAtomic private(set) var viewUserSetting: ViewUserSetting
    @RwAtomic private(set) var viewDeviceSetting: ViewDeviceSetting
    @RwAtomic private(set) var adminOrgSettings: GetAdminOrgSettingsResponse
    @RwAtomic private(set) var adminPermissionInfo: GetAdminPermissionInfoResponse
    @RwAtomic private(set) var rtcFeatureGating: GetRtcFeatureGatingResponse?
    @RwAtomic private(set) var adminMediaServerSettings: GetAdminMediaServerSettingsResponse?
    @RwAtomic private(set) var callmePhone: GetCallmePhoneResponse?
    @RwAtomic private(set) var appConfig: GetAppConfigResponse
    @RwAtomic private(set) var videoChatConfig: PullVideoChatConfigResponse
    @RwAtomic public private(set) var subtitlePhraseStatus: GetSubtitleSettingResponse.PhraseTranslationStatus = .unknown

    @RwAtomic private var boolSettings: [MeetingSettingKey: Bool] = [:]
    @RwAtomic private var complexSettings: [MeetingComplexSettingKey: Any] = [:]

    /// 是否在OnTheCall状态（可重复进入）
    @RwAtomic private(set) var isOnTheCall: Bool = false
    /// 是否已手动释放（离开OnTheCall时标记，可重复释放）
    @RwAtomic private var isReleased: Bool = false

    @RwAtomic private(set) var controlOptions: MeetingSettingControl = []
    @RwAtomic private(set) var extraData = MeetingSettingExtraData()

    /// private listener's handler
    private let receiver = ChangesReceiver()
    private let listeners = HashListeners<MeetingSettingKey, MeetingSettingListener>()
    private let complexListeners = HashListeners<MeetingComplexSettingKey, MeetingComplexSettingListener>()
    private let internalListeners = Listeners<MeetingInternalSettingListener>()

    var isHost: Bool { myself?.isHost == true }
    var participantSettings: ParticipantSettings {
        if let myself = self.myself {
            return myself.settings
        } else if let lobby = self.lobbyInfo {
            if lobby.isJoinLobby, let p = lobby.lobbyParticipant {
                return p.participantSettings
            } else if lobby.isJoinPreLobby, let p = lobby.preLobbyParticipant {
                return p.participantSettings
            }
        }
        return .default
    }
    var featureConfig: FeatureConfig { videoChatSettings.featureConfig ?? .default }
    var manageCapabilities: VideoChatSettings.ManageCapabilities { videoChatSettings.manageCapabilities }

    /// for settings ui
    private(set) lazy var requestCache = MeetingSettingRequestCache(httpClient: service.httpClient)
    @RwAtomic private var finishedWaitItems: Set<MeetingSettingWaitableItem> = []
    @RwAtomic private var waitingObservers: [MeetingSettingWaitObserver] = []

    public init(sessionId: String, service: UserSettingManager) {
        self.account = service.account.user
        self.sessionId = sessionId
        self.logger = Logger.setting.withContext(sessionId).withTag("[Setting(\(sessionId))]")
        self.service = service
        self.fg = MeetingFeatureGating(service, logger: logger)
        self.settingsV3 = MeetingSettingsV3(service, logger: logger)

        self.adminSettings = service.adminSettings
        self.sponsorAdminSettings = service.adminSettings
        self.suiteQuota = service.suiteQuota()
        self.viewUserSetting = service.viewUserSetting
        self.viewDeviceSetting = service.viewDeviceSetting
        self.adminOrgSettings = service.adminOrgSettings
        self.videoChatConfig = service.videoChatConfig
        self.appConfig = service.appConfig
        self.adminPermissionInfo = service.adminPermissionInfo
        self.rtcFeatureGating = service.rtcFeatureGating
        self.adminMediaServerSettings = service.adminMediaServerSettings
        self.callmePhone = service.callmePhone

        self.receiver.owner = self
        service.addListener(receiver, for: [
            .viewUserSetting, .viewDeviceSetting,
            .micSpeakerDisabled, .displayFPS, .displayCodec, .meetingHDVideo, .pip,
            .useCellularImproveAudioQuality, .autoHideToolStatusBar, .ultrawave, .needAdjustAnnotate,
            .translateLanguageSetting
        ])
        DebugSettings.addListener(receiver, for: [.pip])
        self.logger.info("init MeetingSettingManager")
    }

    public func prefetch() {
        refreshCallMePhoneIfNeeded()
        service.refreshAdminOrgSettings(force: true) { [weak self] in
            self?.updateSettings($0, \.adminOrgSettings, .adminOrgSettings)
            self?.onWaitItemFinished(.adminOrgSettings)
        }
        service.refreshRtcFeatureGating(force: true) { [weak self] in
            self?.updateSettings($0, \.rtcFeatureGating)
            self?.onWaitItemFinished(.rtcFeatureGating)
        }
        service.refreshAppConfig(force: true) { [weak self] in
            self?.updateSettings($0, \.appConfig, .videoChatConfig)
            self?.onWaitItemFinished(.appConfig)
        }
        service.refreshVideoChatConfig(force: true) { [weak self] in
            self?.updateSettings($0, \.videoChatConfig)
            self?.onWaitItemFinished(.videoChatConfig)
        }
        service.refreshAdminMediaServerSettings(force: true) { [weak self] in
            self?.updateSettings($0, \.adminMediaServerSettings)
            self?.onWaitItemFinished(.adminMediaServerSettings)
        }
        service.refreshSuiteQuota(force: true) { [weak self] in
            self?.updateSettings($0, \.suiteQuota, .suiteQuota)
            self?.onWaitItemFinished(.suiteQuota)
        }
        service.refreshViewUserSetting(force: true) { [weak self] _ in
            self?.onWaitItemFinished(.viewUserSetting)
        }
        service.refreshAdminSettings(force: true) { [weak self] in
            self?.updateSettings($0, \.adminSettings, .adminSettings)
            self?.onWaitItemFinished(.adminSettings)
        }
        service.refreshAdminPermissionInfo(force: true) { [weak self] in
            self?.updateSettings($0, \.adminPermissionInfo)
            self?.onWaitItemFinished(.adminPermissionInfo)
        }
        self.logger.info("prefetch")
    }

    deinit {
        self.logger.info("deinit MeetingSettingManager")
    }

    public func updatePrestartContext(_ context: MeetingSettingPrestartContext) {
        if isOnTheCall { return }
        switch context {
        case .videoChatInfo(let info):
            self.meetingId = info.id
            self.meetingType = info.type
            self.videoChatInfo = info
            self.videoChatSettings = info.settings
            self.lobbyInfo = nil
            if let myself = info.participants.first(where: { $0.user == self.account }) {
                self.myself = myself
            }
            self.sponsorAdminSettings = service.adminSettings(for: info.tenantId)
            self.suiteQuota = service.suiteQuota(meetingId: info.id)
            var reasons = self.updateFeatureControlOptions().toChangeReasons()
            reasons.append(contentsOf: [.videoChatSettings, .participantSettings, .meetingType, .suiteQuota, .sponsorAdminSettings])
            batchUpdateSettings(reasons: reasons)
            refreshSuiteQuota()
        case .meetingType(let meetingType):
            self.meetingType = meetingType
            batchUpdateSettings(reasons: [.meetingType])
        case .lobbyInfo(let lobbyInfo):
            self.meetingId = lobbyInfo.meetingId
            self.meetingType = .meet
            self.lobbyInfo = lobbyInfo
            batchUpdateSettings(reasons: [.meetingType, .participantSettings])
            refreshSuiteQuota()
        }
    }

    @RwAtomic var isPushObservered = false
    public func startOnTheCall() {
        self.logger.info("start MeetingSettingManager, isOnTheCall = \(isOnTheCall), isPushObservered = \(isPushObservered)")
        /// 存在onthecall -> x -> onthecall的场景，比如moveToLobby，需要处理重入。
        if self.isOnTheCall { return }
        self.isOnTheCall = true
        self.isReleased = false

        // callme FG打开并且没获取到电话的时候再拉一次
        refreshCallMePhoneIfNeeded()
        refreshSubtitleSetting()
        service.refreshAdminSettings(force: true, tenantId: videoChatInfo.tenantId, meetingId: meetingId) { [weak self] in
            self?.updateSettings($0, \.sponsorAdminSettings, .sponsorAdminSettings)
            self?.onWaitItemFinished(.sponsorAdminSettings)
        }
        self.trackViewUserSetting()

        if self.isPushObservered { return }
        self.isPushObservered = true
        Push.fullParticipants.inUser(userId).addObserver(self, willHandle: { [weak self] in
            self?.willHandleFullParticipants($0)
        }, didHandle: { [weak self] _ in
            self?.flushPushedChanges()
        }, handler: { _ in })
        Push.participantChange.inUser(userId).addObserver(self, willHandle: { [weak self] in
            self?.willHandleParticipantChange($0)
        }, didHandle: { [weak self] _ in
            self?.flushPushedChanges()
        }, handler: { _ in })
        Push.videoChatCombinedInfo.inUser(userId).addObserver(self, willHandle: { [weak self] in
            self?.willHandleCombinedInfo($0)
        }, didHandle: { [weak self] _ in
            self?.flushPushedChanges()
        }, handler: { _ in })
        Push.vcManageNotify.inUser(userId).addObserver(self) { [weak self] in self?.handleManageNotify($0) }
    }

    public func release() {
        self.logger.info("release MeetingSettingManager, isOnTheCall = \(isOnTheCall), isReleased = \(isReleased)")
        if isReleased { return }
        self.isReleased = true
        self.isOnTheCall = false
    }

    public func addListener(_ listener: MeetingSettingListener, for key: MeetingSettingKey) {
        addListener(listener, for: [key])
    }

    public func addListener(_ listener: MeetingSettingListener, for keys: Set<MeetingSettingKey>) {
        self.listeners.addListener(listener, for: keys)
    }

    public func removeListener(_ listener: MeetingSettingListener) {
        self.listeners.removeListener(listener)
    }

    public func addComplexListener(_ listener: MeetingComplexSettingListener, for key: MeetingComplexSettingKey) {
        addComplexListener(listener, for: [key])
    }

    public func addComplexListener(_ listener: MeetingComplexSettingListener, for keys: Set<MeetingComplexSettingKey>) {
        self.complexListeners.addListener(listener, for: keys)
    }

    public func removeComplexListener(_ listener: MeetingComplexSettingListener) {
        self.complexListeners.removeListener(listener)
    }

    func addInternalListener(_ listener: MeetingInternalSettingListener) {
        self.internalListeners.addListener(listener)
    }

    func removeInternalListener(_ listener: MeetingInternalSettingListener) {
        self.internalListeners.removeListener(listener)
    }

    // mobileCodes太耗时，且只有少数场景使用，改成懒加载
    var pstnMobileCodes: GetAdminSettingsResponse.PstnMobileCodes {
        if let codes = _pstnMobileCodes {
            return codes
        } else {
            let codes = sponsorAdminSettings.toPstnMobileCodes(service.mobileCodes)
            _pstnMobileCodes = codes
            return codes
        }
    }

    public func wait(for item: MeetingSettingWaitableItem, completion: @escaping () -> Void) {
        if self.finishedWaitItems.contains(item) {
            completion()
        } else {
            self.waitingObservers.append(MeetingSettingWaitObserver(item: item, callback: completion))
        }
    }

    private static let firstFetchWaitItems: Set<MeetingSettingWaitableItem> = [
        .callMePhone, .adminOrgSettings, .rtcFeatureGating, .appConfig, .videoChatConfig, .adminMediaServerSettings,
        .suiteQuota, .viewUserSetting, .adminSettings, .adminPermissionInfo
    ]
    private static let onTheCallFetchWaitItems: Set<MeetingSettingWaitableItem> = firstFetchWaitItems.union([
        .subtitleSettings, .meetingSuiteQuota, .sponsorAdminSettings
    ])
    private func onWaitItemFinished(_ item: MeetingSettingWaitableItem) {
        guard self.finishedWaitItems.insert(item).inserted else { return }
        self.invokeWaitObserver(for: item)
        if Self.firstFetchWaitItems.contains(item), !self.finishedWaitItems.contains(.firstFetch) {
            if self.finishedWaitItems.isSuperset(of: Self.firstFetchWaitItems) {
                self.finishedWaitItems.insert(.firstFetch)
                self.invokeWaitObserver(for: .firstFetch)
            }
        }
        if Self.onTheCallFetchWaitItems.contains(item), !self.finishedWaitItems.contains(.onTheCallFetch) {
            if self.finishedWaitItems.isSuperset(of: Self.onTheCallFetchWaitItems) {
                self.finishedWaitItems.insert(.onTheCallFetch)
                self.invokeWaitObserver(for: .onTheCallFetch)
            }
        }
    }

    private func invokeWaitObserver(for item: MeetingSettingWaitableItem) {
        self.logger.info("onWaitItemFinished: \(item)")
        var obs: [MeetingSettingWaitObserver] = []
        self.waitingObservers.removeAll { observer in
            if observer.item == item {
                obs.append(observer)
                return true
            } else {
                return false
            }
        }
        obs.forEach {
            $0.callback()
        }
    }

    private func invokeListeners(for changes: [MeetingSettingKey: Bool]) {
        changes.forEach { (key, value) in
            listeners.invokeListeners(for: key) {
                $0.didChangeMeetingSetting(self, key: key, isOn: value)
            }
        }
    }

    private func invokeComplexListeners(for changes: [MeetingComplexSettingKey: (Any, Any?)]) {
        changes.forEach { (key, value) in
            complexListeners.invokeListeners(for: key) {
                $0.didChangeComplexSetting(self, key: key, value: value.0, oldValue: value.1)
            }
        }
    }

    public func refreshSubtitleSetting() {
        service.httpClient.getResponse(GetSubtitleSettingRequest()) { [weak self] result in
            if let self = self, case .success(let resp) = result {
                self.subtitlePhraseStatus = resp.status
                self.batchUpdateComplexSettings(keys: [.subtitlePhraseStatus])
                self.onWaitItemFinished(.subtitleSettings)
            }
        }
    }

    func updateSubtitlePhraseStatus(isOn: Bool) {
        service.httpClient.getResponse(SetSubtitleSettingRequest(on: isOn)) { [weak self] result in
            if let self = self, case .success(let resp) = result, resp.success {
                self.subtitlePhraseStatus = isOn ? .on : .off
                self.batchUpdateComplexSettings(keys: [.subtitlePhraseStatus])
            }
        }
    }

    func refreshSuiteQuota() {
        service.refreshSuiteQuota(force: true, meetingId: meetingId) { [weak self] in
            self?.updateSettings($0, \.suiteQuota, .suiteQuota) { value, oldValue in
                if let self = self {
                    self.internalListeners.forEach { $0.didChangeSuiteQuota(self, value: value, oldValue: oldValue) }
                }
            }
            self?.onWaitItemFinished(.meetingSuiteQuota)
        }
    }

    private func refreshCallMePhoneIfNeeded() {
        if fg.isCallMeEnabled {
            service.refreshCallmePhone(force: false) { [weak self] in
                self?.updateSettings($0, \.callmePhone)
                self?.onWaitItemFinished(.callMePhone)
            }
        } else {
            self.onWaitItemFinished(.callMePhone)
        }
    }

    private func updateSettings<T>(_ resp: Result<T, Error>, _ keyPath: ReferenceWritableKeyPath<MeetingSettingManager, T?>) {
        if case .success(let success) = resp {
            self[keyPath: keyPath] = success
        }
    }

    private func updateSettings<T>(_ resp: Result<T, Error>, _ keyPath: ReferenceWritableKeyPath<MeetingSettingManager, T>) {
        if case .success(let success) = resp {
            self[keyPath: keyPath] = success
        }
    }

    private func updateSettings<T: Equatable>(_ resp: Result<T, Error>, _ keyPath: ReferenceWritableKeyPath<MeetingSettingManager, T>, _ reason: MeetingSettingChangeReason, onUpdate: ((T, T) -> Void)? = nil) {
        if case .success(let value) = resp {
            let oldValue = self[keyPath: keyPath]
            if oldValue != value {
                self[keyPath: keyPath] = value
                batchUpdateSettings(reasons: [reason])
                onUpdate?(value, oldValue)
            }
        }
    }

    private func updateViewUserSetting(_ setting: ViewUserSetting) {
        self.viewUserSetting = setting
        self.batchUpdateSettings(reasons: [.viewUserSetting])
    }

    private func updateViewDeviceSetting(_ setting: ViewDeviceSetting) {
        self.viewDeviceSetting = setting
        self.batchUpdateSettings(reasons: [.viewDeviceSetting])
    }

    private func updateFeatureControlOptions() -> MeetingSettingControl {
        var options: MeetingSettingControl = []
        if let meetingRole = myself?.meetingRole, videoChatSettings.isOwnerJoinedMeeting && featureConfig.hostControlEnable {
            switch meetingRole {
            case .host:
                options.insert(.host)
                options.insert(.cohost)
            case .coHost:
                options.insert(.cohost)
            default:
                break
            }
        }
        if let breakoutRoomId = myself?.breakoutRoomId, videoChatSettings.isOpenBreakoutRoom,
           !breakoutRoomId.isEmpty && breakoutRoomId != "1" {
            // 服务端打包数据时将主会场的id都设为1，但不保证不遗漏，可能出现主会场id为空的情况，端上需要兜底
            options.insert(.breakoutRoom)
        }
        if videoChatSettings.subType == .webinar, myself?.meetingRole == .webinarAttendee {
            options.insert(.webinarAttendee)
        }
        let changedOptions = self.controlOptions.symmetricDifference(options)
        if changedOptions.isEmpty {
            return []
        } else {
            self.controlOptions = options
            return changedOptions
        }
    }

    // used in push queue
    private var flushPushAction: ((MeetingSettingManager) -> Void)?
    private func willHandleCombinedInfo(_ info: VideoChatCombinedInfo) {
        guard !isReleased, info.inMeetingInfo.id == self.meetingId else { return }
        let inMeetingInfo = info.inMeetingInfo
        self.meetingURL = inMeetingInfo.meetingURL
        var changes: [MeetingSettingChangeReason] = []
        if inMeetingInfo.vcType != self.meetingType {
            self.meetingType = inMeetingInfo.vcType
            changes.append(.meetingType)
        }
        let oldVideoChatSettings = self.videoChatSettings
        let videoChatSettings = inMeetingInfo.meetingSettings
        if self.videoChatSettings != videoChatSettings {
            self.videoChatSettings = videoChatSettings
            changes.append(.videoChatSettings)
            changes.append(.featureConfig)
        }
        let changedOptions = updateFeatureControlOptions()
        changes.append(contentsOf: changedOptions.toChangeReasons())
        let extraData = self.extraData.updated(by: inMeetingInfo, account: self.account)
        if extraData != self.extraData {
            self.extraData = extraData
            changes.append(.extraData)
        }
        logger.info("willHandleCombinedInfo, changes = \(changes)")
        self.flushPushAction = { [weak self] setting in
            self?.logger.info("didHandleCombinedInfo, changes = \(changes)")
            setting.batchUpdateSettings(reasons: changes)
            if changes.contains(.videoChatSettings) {
                setting.internalListeners.forEach {
                    $0.didChangeVideoChatSettings(setting, value: videoChatSettings, oldValue: oldVideoChatSettings)
                }
            }
            self?.onWaitItemFinished(.firstCombinedInfo)
        }
    }

    private func willHandleFullParticipants(_ info: InMeetingUpdateMessage) {
        if !isReleased, info.meetingID == self.meetingId, let myself = info.participants.first(where: { $0.user == self.account }) {
            self.willHandleMyself(myself)
        }
    }

    private func willHandleParticipantChange(_ info: MeetingParticipantChange) {
        if !isReleased, info.meetingID == self.meetingId, let myself = info.upsertParticipants.first(where: { $0.user == self.account }) {
            self.willHandleMyself(myself)
        }
    }

    private func willHandleMyself(_ myself: Participant) {
        if self.myself == myself { return }
        let oldValue = self.myself
        self.myself = myself
        var changes: [MeetingSettingChangeReason] = [.participantSettings]
        let changedOptions = updateFeatureControlOptions()
        changes.append(contentsOf: changedOptions.toChangeReasons())
        logger.info("willHandleMyself, changes = \(changes)")
        self.flushPushAction = { [weak self] setting in
            self?.logger.info("didHandleMyself, changes = \(changes)")
            setting.batchUpdateSettings(reasons: changes)
            setting.internalListeners.forEach {
                $0.didChangeMyself(setting, value: myself, oldValue: oldValue)
            }
        }
    }

    private func flushPushedChanges() {
        self.flushPushAction?(self)
        self.flushPushAction = nil
    }

    private func handleManageNotify(_ info: VCManageNotify) {
        if !isReleased, info.meetingID == self.meetingId, info.notificationType == .largeMeetingTriggered {
            // largeMeetingTriggered 会触发"大方会管提示人数"降阈，session维度，离会再入会无需保留之前的降阈机制 (by design)
            // 降阈前使用`largeMeetingSecurityNoticeThreshold`，降阈后使用`largeMeetingSuggestThreshold`判断人数阈值
            if !extraData.isLargeMeetingTriggered {
                self.updateExtraData { $0.isLargeMeetingTriggered = true }
                self.internalListeners.forEach {
                    $0.didChangeSuggestThreshold(self, value: Int(self.suggestManageThreshold))
                }
            }
        }
    }
}

extension MeetingSettingManager {
    @discardableResult
    func updateExtraData(_ updator: (inout MeetingSettingExtraData) -> Void) -> Bool {
        let oldValue = self.extraData
        updator(&self.extraData)
        if oldValue != self.extraData {
            batchUpdateSettings(reasons: [.extraData], shouldNotifyListener: true)
            return true
        } else {
            return false
        }
    }

    private func updateBool(for key: MeetingSettingKey) -> (isChanged: Bool, value: Bool) {
        let value = self[keyPath: key.keyPath]
        let oldValue = self.boolSettings.updateValue(value, forKey: key)
        if oldValue != value {
            if oldValue == nil {
                self.logger.info("initMeetingSetting: \(key) -> \(value)")
            } else {
                self.logger.info("didChangeMeetingSetting: \(key) -> \(value)")
            }
            return (true, value)
        } else {
            return (false, value)
        }
    }

    private func updateComplex<T: Equatable>(_ value: T, for key: MeetingComplexSettingKey) -> (isChanged: Bool, value: T, oldValue: T?) {
        let oldValue = self.complexSettings.updateValue(value, forKey: key) as? T
        if oldValue != value {
            if oldValue == nil {
                self.logger.info("initMeetingComplexSetting: \(key) -> \(value)")
            } else {
                self.logger.info("didChangeMeetingComplexSetting: \(key) -> \(value)")
            }
            return (true, value, oldValue)
        } else {
            return (false, value, oldValue)
        }
    }

    private func updateComplex(for key: MeetingComplexSettingKey) -> (isChanged: Bool, value: Any, oldValue: Any?) {
        switch key {
        case .countdownSetting:
            return updateComplex(counddownSetting, for: .countdownSetting)
        case .billingSetting:
            return updateComplex(billingSetting, for: .billingSetting)
        case .translateLanguageSetting:
            return updateComplex(translateLanguageSetting, for: .translateLanguageSetting)
        case .handsUpEmojiKey:
            return updateComplex(handsUpEmojiKey, for: .handsUpEmojiKey)
        case .subtitlePhraseStatus:
            return updateComplex(subtitlePhraseStatus, for: .subtitlePhraseStatus)
        case .cameraHandsStatus:
            return updateComplex(cameraHandsStatus, for: .cameraHandsStatus)
        case .micHandsStatus:
            return updateComplex(micHandsStatus, for: .micHandsStatus)
        case .virtualBackground:
            return updateComplex(virtualBackground, for: .virtualBackground)
        case .advancedBeauty:
            return updateComplex(advancedBeauty, for: .advancedBeauty)
        }
    }

    @discardableResult
    private func batchUpdateSettings(keys: Set<MeetingSettingKey>, shouldNotifyListener: Bool = true) -> [MeetingSettingKey: Bool] {
        self.logger.info("batchUpdateSettings for keys: \(keys)")
        var changes: [MeetingSettingKey: Bool] = [:]
        keys.forEach { key in
            let result = updateBool(for: key)
            if result.isChanged {
                changes[key] = result.value
            }
        }
        if shouldNotifyListener {
            invokeListeners(for: changes)
        }
        return changes
    }

    @discardableResult
    private func batchUpdateComplexSettings(keys: Set<MeetingComplexSettingKey>, shouldNotifyListener: Bool = true) -> [MeetingComplexSettingKey: (Any, Any?)] {
        self.logger.info("batchUpdateComplexSettings for keys: \(keys)")
        var changes: [MeetingComplexSettingKey: (Any, Any?)] = [:]
        keys.forEach { key in
            let result = updateComplex(for: key)
            if result.isChanged {
                changes[key] = (result.value, result.oldValue)
            }
        }
        if shouldNotifyListener {
            invokeComplexListeners(for: changes)
        }
        return changes
    }

    private func batchUpdateSettings(reasons: [MeetingSettingChangeReason], shouldNotifyListener: Bool = true) {
        if reasons.isEmpty { return }
        self.logger.info("batchUpdateSettings for reasons: \(reasons)")
        let checkingKeys = reasons.reduce(into: Set<MeetingSettingKey>(), { $0.formUnion($1.affectKeys) })
        let changes = batchUpdateSettings(keys: checkingKeys, shouldNotifyListener: false)
        let checkingComplexKeys = reasons.reduce(into: Set<MeetingComplexSettingKey>(), { $0.formUnion($1.affectComplexKeys) })
        let complexChanges = batchUpdateComplexSettings(keys: checkingComplexKeys, shouldNotifyListener: false)
        if shouldNotifyListener {
            invokeListeners(for: changes)
            invokeComplexListeners(for: complexChanges)
        }
    }
}

public extension MeetingSettingManager {
    func updateDeviceNtpTimeRecord(_ record: DeviceNtpTimeRecord?) {
        self.logger.info("dropVoIPPush: save ntpRecord=\(String(describing: record)), deviceNtpDate=\(String(describing: record?.deviceNtpDate()))")
        service.deviceNtpTimeRecord = record
    }
}

private extension MeetingSettingManager {

    /// 视频会议设置项
    func trackViewUserSetting() {
        let setting = self.viewUserSetting
        let larkMonitorEnable = self.larkDowngradeConfig.enableDowngrade && self.featurePerformanceConfig.isLarkDowngrade
        VCTracker.post(name: .vc_meeting_onthecall_status, params: [
            .action_name: "person_setting_status",
            "start_remind": setting.meetingGeneral.calendarMeetingStartNotify,
            "normal_remind": setting.meetingGeneral.playEnterExitChimes,
            "see_myself_active_speaker": setting.meetingGeneral.enableSelfAsActiveSpeaker,
            "join_interpretation": setting.meetingAdvanced.interpretation.canOpenInterpretation,
            "auto_meeting_record": setting.meetingAdvanced.recording.groupMeetingAutoRecord,
            "auto_call_record": setting.meetingAdvanced.recording.singleMeetingAutoRecord,
            "join_subtitle": setting.meetingAdvanced.subtitle.turnOnSubtitleWhenJoin,
            "enable_voiceprint_recognition": setting.audio.enableVoiceprintRecognition,
            "degrade_monitor_type": larkMonitorEnable ? "main_platform" : "vc"])
    }
}

private extension MeetingSettingManager {
    final class ChangesReceiver: UserSettingListener, DebugSettingListener {
        weak var owner: MeetingSettingManager?
        func didChangeUserSetting(_ settings: UserSettingManager, _ change: UserSettingChange) {
            switch change {
            case .viewUserSetting(let data):
                owner?.updateViewUserSetting(data.value)
            case .viewDeviceSetting(let data):
                owner?.updateViewDeviceSetting(data.value)
            default:
                let changeType = change.type
                if let key = changeType.toFeatureKey() {
                    owner?.batchUpdateSettings(keys: [key])
                }
                if let key = changeType.toComplexKey() {
                    owner?.batchUpdateComplexSettings(keys: [key])
                }
            }
        }

        func didChangeDebugSetting(for key: DebugSettingKey) {
            owner?.batchUpdateSettings(reasons: [.debug])
        }
    }
}

private extension ParticipantSettings {
    static let `default` = ParticipantSettings()
}

private extension FeatureConfig {
    static let `default` = FeatureConfig()
}

private extension UserSettingChangeType {
    func toFeatureKey() -> MeetingSettingKey? {
        switch self {
        case .micSpeakerDisabled:
            return .isMicSpeakerDisabled
        case .displayFPS:
            return .displayFPS
        case .displayCodec:
            return .displayCodec
        case .meetingHDVideo:
            return .isHDModeEnabled
        case .pip:
            return .isPiPEnabled
        case .useCellularImproveAudioQuality:
            return .useCellularImproveAudioQuality
        case .autoHideToolStatusBar:
            return .autoHideToolStatusBar
        case .ultrawave:
            return .isUltrawaveEnabled
        case .needAdjustAnnotate:
            return .needAdjustAnnotate
        default:
            return nil
        }
    }

    func toComplexKey() -> MeetingComplexSettingKey? {
        switch self {
        case .translateLanguageSetting:
            return .translateLanguageSetting
        default:
            return nil
        }
    }
}

private extension MeetingSettingExtraData {
    func updated(by inMeetingInfo: VideoChatInMeetingInfo, account: ByteviewUser) -> MeetingSettingExtraData {
        var extra = self
        extra.hasVote = !inMeetingInfo.voteList.isEmpty
        if let followInfo = inMeetingInfo.followInfo, !followInfo.url.isEmpty {
            extra.isSharingDocument = true
        } else {
            extra.isSharingDocument = false
        }
        if let shareScreen = inMeetingInfo.shareScreen, shareScreen.isSharing {
            extra.isSharingScreen = true
        } else {
            extra.isSharingScreen = false
        }
        extra.isSharingWhiteboard = inMeetingInfo.whiteboardInfo?.whiteboardIsSharing == true
        return extra
    }
}

private struct MeetingSettingWaitObserver {
    let item: MeetingSettingWaitableItem
    let callback: () -> Void
}
