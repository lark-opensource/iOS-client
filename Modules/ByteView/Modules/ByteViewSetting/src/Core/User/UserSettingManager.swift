//
//  UserSettingManager.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/27.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

public protocol UserSettingListener: AnyObject {
    func didChangeUserSetting(_ settings: UserSettingManager, _ change: UserSettingChange)
}

public final class UserSettingManager {
    @RwAtomic private var cache: UserSettings
    private let dependency: UserSettingDependency
    private let listeners = HashListeners<UserSettingChangeType, UserSettingListener>()
    private(set) lazy var centerStage = CenterStageCapability(storage: cache.diskCache)
    public var userId: String { account.userId }
    let account: AccountInfo
    let httpClient: HttpClient
    public init(dependency: UserSettingDependency) {
        self.account = dependency.account
        self.dependency = dependency
        self.cache = UserSettings(dependency: dependency)
        self.httpClient = dependency.httpClient

        Push.viewUserSetting.inUser(userId).addObserver(self) { [weak self] in
            self?.didReceiveViewUserSetting($0)
        }

        dependency.observeTranslateLanguageSetting { [weak self] in
            self?.didUpdateTranslateLanguageSetting($0)
        }

        DispatchQueue.global().asyncAfter(deadline: .now()) { [weak self] in
            self?.cache.mergeOldLocalStorage(dependency: dependency)
            // prefetch
            // 企业电话设置IM入口也会用，没有合适的刷新时机，启动时强刷一次
            self?.refreshEnterpriseConfig(force: true)
            self?.refreshViewUserSetting(force: false)
            self?.refreshAdminSettings(force: false)
        }
    }

    public func addListener(_ listener: UserSettingListener, for changeType: UserSettingChangeType) {
        addListener(listener, for: [changeType])
    }

    public func addListener(_ listener: UserSettingListener, for changeTypes: Set<UserSettingChangeType>) {
        self.listeners.addListener(listener, for: changeTypes)
    }

    public func removeListener(_ listener: UserSettingListener) {
        self.listeners.removeListener(listener)
    }

    private func invokeListeners(_ changes: [UserSettingChange]) {
        changes.forEach { change in
            let changeType = change.type
            Logger.setting.info("didChangeUserSetting: \(changeType)")
            self.listeners.invokeListeners(for: changeType) { $0.didChangeUserSetting(self, change) }
        }
    }

    private lazy var defaultViewUserSetting: ViewUserSetting = {
        var settings = ViewUserSetting()
        // lark和飞书有不同的默认配置策略，飞书默认关闭，lark默认开启。
        settings.meetingAdvanced.recording.recordCompliancePopup.optionalValue = dependency.packageIsLark
        settings.meetingAdvanced.recording.recordComplianceVoicePrompt.optionalValue = dependency.packageIsLark
        return settings
    }()

    private func refreshSetting<R: NetworkRequestWithResponse>(
        _ req: @autoclosure () -> R, cache: @autoclosure () -> R.Response?, force: Bool,
        completion: ((Result<R.Response, Error>) -> Void)?,
        updator: @escaping (inout UserSettings, R, R.Response) -> [UserSettingChange]
    ) {
        if !force, let obj = cache() {
            completion?(.success(obj))
            return
        }
        let request = req()
        httpClient.getResponse(request, options: .retry(3, owner: self)) { [weak self] result in
            let handler: () -> Void = {
                if let self = self, case .success(let resp) = result {
                    self.invokeListeners(updator(&self.cache, request, resp))
                }
                completion?(result)
            }
            if #available(iOS 13.0, *) {
                handler()
            } else {
                /// 减少低版本iOS多线程使用范型的问题，_swift_initClassMetadataImpl，https://t.wtturl.cn/UoAXrse/
                Queue.push.async(execute: handler)
            }
        }
    }

    private func bool(forKey key: UserSettingStorageKey, defaultValue: Bool = false) -> Bool {
        cache.diskCache.bool(forKey: key, defaultValue: defaultValue)
    }

    private func updateLocalSetting(_ value: Bool, forKey key: UserSettingStorageKey) {
        if cache.updateLocalSetting(value, forKey: key), let change = key.toUserSettingChange() {
            invokeListeners([change])
        }
    }
}

extension UserSettingManager {
    var rtcDependency: RtcSettingDependency { dependency.rtcSetting }
    var isPrivateKA: Bool { dependency.isPrivateKA }
    var deviceId: String { account.deviceId }
    var tenantId: String { account.tenantId }
    var packageIsLark: Bool { dependency.packageIsLark }
    public var isFeishuBrand: Bool { account.isFeishuBrand }
    public var isCallKitEnabled: Bool { dependency.isCallKitEnabled }
    /// 是否显示CallKit设置
    public var showsCallKitSetting: Bool { dependency.showsCallKitSetting }
    public var includesCallsInRecents: Bool { dependency.includesCallsInRecents }

    var appGroupId: String { dependency.appGroupId }
    var broadcastExtensionId: String { dependency.broadcastExtensionId }
    var mobileCodes: [MobileCode] { dependency.mobileCodes }
    var userName: String { account.userName }
    var logPath: String { dependency.logPath }

    /// voip 过期推送忽略设备维度记录
    public var voipExpiredRecord: VoIPExpiredIgnoreRecord? {
        get {
            dependency.voipExpiredRecord
        }
        set {
            dependency.updateVoipExpiredRecord(newValue)
        }
    }

    /// 设备使用 ntp 时间记录
    public var deviceNtpTimeRecord: DeviceNtpTimeRecord? {
        get {
            dependency.deviceNtpTimeRecord
        }
        set {
            dependency.updateDeviceNtpTimeRecord(newValue)
        }
    }

    /// 小B用户不显示外部标签
    var canShowExternal: Bool {
        if let tenantTag = self.account.tenantTag, tenantTag != .standard {
            return false // 小B用户不显示外部标签
        } else {
            return true
        }
    }

    func fg(_ key: String, logger: Logger = .setting) -> Bool {
        let value = dependency.featureGatingValue(for: key)
        logger.info("get fg \(key) success: \(value)")
        return value
    }

    func dynamicFeatureGatingValue(_ key: String, logger: Logger = .setting) -> Bool {
        let value = dependency.dynamicFeatureGatingValue(for: key)
        logger.info("get dynamic fg \(key) success: \(value)")
        return value
    }

    /// LarkSetting解析时已经设置了`convertFromSnakeCase`，CodingKeys里不要再把驼峰名称转成下划线了，否则会报错`DecodingError.keyNotFound`
    func settings<T: Decodable>(for key: SettingsV3Key, type: T.Type, logger: Logger = .setting) -> T? {
        let tag = "\(T.self)(\(key))"
        do {
            let value = try dependency.setting(for: key, type: type)
            logger.info("get settings \(tag) success: \(value)")
            return value
        } catch DecodingError.dataCorrupted(let context) {
            logger.error("get settings \(tag) failed, error = dataCorrupted, context = \(context)")
        } catch DecodingError.keyNotFound(let key0, let context) {
            logger.error("get settings \(tag) failed, error = keyNotFound, key = \(key0), context = \(context)")
        } catch DecodingError.valueNotFound(let value, let context) {
            logger.error("get settings \(tag) failed, error = valueNotFound, value = \(value), context = \(context)")
        } catch DecodingError.typeMismatch(let type0, let context) {
            logger.error("get settings \(tag) failed, error = typeMismatch, type = \(type0), context = \(context)")
        } catch {
            logger.error("get settings \(tag) failed, error = \(error)")
        }
        return nil
    }

    func settings<T: Decodable>(for key: SettingsV3Key, defaultValue: T, logger: Logger = .setting) -> T {
        if let value = settings(for: key, type: T.self) {
            return value
        }
        logger.info("get settings \(T.self)(\(key)) failed, use defaultValue")
        return defaultValue
    }

    func settings(for key: SettingsV3Key, logger: Logger = .setting) -> [String: Any] {
        do {
            let value = try dependency.setting(for: key)
            logger.info("get settings \(key) success: value.count = \(value.count)")
            return value
        } catch {
            logger.error("get settings \(key) failed, error = \(error)")
            return [:]
        }
    }

    public func domain(for key: UserSettingDomainKey) -> [String] {
        dependency.domain(for: key)
    }
}

extension UserSettingManager {

    private func didReceiveViewUserSetting(_ resp: PullViewUserSettingResponse) {
        self.invokeListeners(cache.updateViewUserSettings(user: resp.userSetting, device: resp.deviceSetting))
    }

    private func didUpdateTranslateLanguageSetting(_ setting: TranslateLanguageSetting) {
        self.invokeListeners(cache.updateTranslateLanguageSetting(setting))
    }

    func refreshViewUserSetting(force: Bool, completion: ((Result<PullViewUserSettingResponse, Error>) -> Void)? = nil) {
        refreshSetting(PullViewUserSettingRequest(), cache: cache.viewUserSettingResponse, force: force, completion: completion) {
            $0.updateViewUserSettings(user: $2.userSetting, device: $2.deviceSetting)
        }
    }

    func refreshAdminSettings(force: Bool, completion: ((Result<GetAdminSettingsResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetAdminSettingsRequest(tenantID: nil), cache: cache.adminSettings, force: force, completion: completion) {
            $0.updateAdminSettings($2, for: $1)
        }
    }

    func refreshAdminSettings(force: Bool, tenantId: String, meetingId: String? = nil, uniqueId: String? = nil,
                              completion: ((Result<GetAdminSettingsResponse, Error>) -> Void)? = nil) {
        guard !tenantId.isEmpty, let id = Int64(tenantId) else {
            completion?(.failure(NetworkError.noElements))
            return
        }
        let request = GetAdminSettingsRequest(tenantID: id, meetingID: meetingId, uniqueID: uniqueId)
        refreshSetting(request, cache: cache.tenantAdminSettings[tenantId], force: force, completion: completion) {
            $0.updateAdminSettings($2, for: $1)
        }
    }

    public func refreshEnterpriseConfig(force: Bool, completion: ((Result<GetEnterprisePhoneConfigResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetEnterprisePhoneConfigRequest(), cache: cache.enterprisePhoneConfig, force: force, completion: completion) {
            $0.updateLocalSetting($2, forKey: .enterprisePhoneConfig)
            return []
        }
    }

    func refreshAdminOrgSettings(force: Bool, completion: ((Result<GetAdminOrgSettingsResponse, Error>) -> Void)? = nil) {
        let request = GetAdminOrgSettingsRequest(userId: userId, tenantID: tenantId, settingKeys: ["allow_user_change_pstn_audio_type"])
        refreshSetting(request, cache: cache.adminOrgSettings, force: force, completion: completion) {
            $0.updateLocalSetting($2, forKey: .adminOrgSettings)
            return []
        }
    }

    func updateTranslateLanguage(isAutoTranslationOn: Bool? = nil, targetLanguage: String? = nil, rule: TranslateDisplayRule? = nil) {
        dependency.updateTranslateLanguage(isAutoTranslationOn: isAutoTranslationOn, targetLanguage: targetLanguage, rule: rule)
    }

    func updateViewUserSetting(_ action: (inout PatchViewUserSettingRequest) -> Void,
                               completion: ((Result<PatchViewUserSettingResponse, Error>) -> Void)? = nil) {
        var request = PatchViewUserSettingRequest()
        action(&request)
        refreshSetting(request, cache: nil, force: true, completion: completion) {
            $0.updateViewUserSettings(user: $2.userSetting, device: $2.deviceSetting)
        }
    }

    public func refreshSuiteQuota(force: Bool, meetingId: String? = nil, completion: ((Result<GetSuiteQuotaResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetSuiteQuotaRequest(meetingID: meetingId), cache: self.suiteQuota(meetingId: meetingId), force: force, completion: completion) {
            $0.updateSuiteQuota($2, for: $1)
        }
    }

    func refreshVideoChatConfig(force: Bool, completion: ((Result<PullVideoChatConfigResponse, Error>) -> Void)? = nil) {
        refreshSetting(PullVideoChatConfigRequest(), cache: cache.videoChatConfig, force: force, completion: completion) {
            $0.videoChatConfig = $2
            return []
        }
    }

    private struct UpdateSubtitleLanguageError: Error {}
    func updateSubtitleLanguage(_ subtitleLanguage: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = UpdateSubtitleLanguageRequest(subtitleLanguage: .init(language: subtitleLanguage))
        httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(let resp):
                if resp.status == .success {
                    self?.refreshSubtitleLanguage(force: true)
                    completion?(.success(Void()))
                } else {
                    completion?(.failure(UpdateSubtitleLanguageError()))
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func refreshSubtitleLanguage(force: Bool, completion: ((Result<GetSubtitleLanguageResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetSubtitleLanguageRequest(), cache: cache.subtitleLanguage, force: force, completion: completion) {
            $2.status == .success ? $0.updateSubtitleLanguage($2) : []
        }
    }

    func refreshCallmePhone(force: Bool, completion: ((Result<GetCallmePhoneResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetCallmePhoneRequest(), cache: cache.callmePhone, force: force, completion: completion) {
            $0.callmePhone = $2
            return []
        }
    }

    func refreshAppConfig(force: Bool, completion: ((Result<GetAppConfigResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetAppConfigRequest(), cache: cache.appConfig, force: force, completion: completion) {
            $0.updateAppConfig($2)
        }
    }

    func refreshAdminMediaServerSettings(force: Bool, completion: ((Result<GetAdminMediaServerSettingsResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetAdminMediaServerSettingsRequest(), cache: cache.adminMediaServerSettings, force: force, completion: completion) {
            $0.updateLocalSetting($2, forKey: .adminMediaServer)
            return []
        }
    }

    func refreshRtcFeatureGating(force: Bool, completion: ((Result<GetRtcFeatureGatingResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetRtcFeatureGatingRequest(), cache: cache.rtcFeatureGating, force: force, completion: completion) {
            $0.updateLocalSetting($2, forKey: .rtcFeatureGating)
            return []
        }
    }

    func refreshAdminPermissionInfo(force: Bool, completion: ((Result<GetAdminPermissionInfoResponse, Error>) -> Void)? = nil) {
        refreshSetting(GetAdminPermissionInfoRequest(), cache: cache.adminPermissionInfo, force: force, completion: completion) {
            $0.adminPermissionInfo = $2
            return []
        }
    }

    func refreshVoiceprintStatus(completion: ((Result<VoicePrintPullStatusResponse, Error>) -> Void)? = nil) {
        let request = VoicePrintPullStatusRequest(userId: userId, tenantId: tenantId)
        refreshSetting(request, cache: nil, force: true, completion: completion) {
            $0.updateMyVoiceprintStatus($2.voiceprintStatusInfo.voiceprintStatus)
        }
    }

    func clearVoiceprint(completion: ((Result<VoicePrintClearResponse, Error>) -> Void)? = nil) {
        let request = VoicePrintClearRequest(userId: userId, tenantId: tenantId)
        refreshSetting(request, cache: nil, force: true, completion: completion) {
            $0.updateMyVoiceprintStatus($2.voiceprintStatusInfo.voiceprintStatus)
        }
    }
}

extension UserSettingManager {
    var adminSettings: GetAdminSettingsResponse {
        if let setting = cache.adminSettings {
            return setting
        } else {
            return .default
        }
    }

    var viewUserSetting: ViewUserSetting {
        if let setting = cache.userSetting {
            return setting
        } else {
            return defaultViewUserSetting
        }
    }

    var viewDeviceSetting: ViewDeviceSetting {
        if let setting = cache.deviceSetting {
            return setting
        } else {
            return .default
        }
    }

    public var enterprisePhoneConfig: GetEnterprisePhoneConfigResponse {
        if let obj = cache.enterprisePhoneConfig {
            return obj
        } else {
            return .default
        }
    }

    func suiteQuota(meetingId: String? = nil) -> GetSuiteQuotaResponse {
        if let meetingId = meetingId, !meetingId.isEmpty, let setting = cache.meetingSuiteQuotas[meetingId] {
            return setting
        } else if let setting = cache.suiteQuota {
            return setting
        } else {
            return .default
        }
    }

    func adminSettings(for tenantId: String) -> GetAdminSettingsResponse {
        if tenantId.isEmpty { return adminSettings }
        if let setting = cache.tenantAdminSettings[tenantId] {
            return setting
        } else if self.tenantId == tenantId, let setting = cache.adminSettings {
            return setting
        } else {
            return .default
        }
    }

    var adminOrgSettings: GetAdminOrgSettingsResponse {
        if let setting = cache.adminOrgSettings {
            return setting
        } else {
            return .default
        }
    }

    var videoChatConfig: PullVideoChatConfigResponse {
        if let setting = cache.videoChatConfig {
            return setting
        } else {
            return .default
        }
    }

    var adminPermissionInfo: GetAdminPermissionInfoResponse {
        if let setting = cache.adminPermissionInfo {
            return setting
        } else {
            return .default
        }
    }

    var myVoiceprintStatus: VoiceprintStatus {
        cache.myVoiceprintStatus
    }

    var translateLanguageSetting: TranslateLanguageSetting {
        cache.translateLanguageSetting
    }

    var subtitleLanguage: GetSubtitleLanguageResponse? {
        cache.subtitleLanguage
    }

    var adminMediaServerSettings: GetAdminMediaServerSettingsResponse? {
        cache.adminMediaServerSettings
    }

    var rtcFeatureGating: GetRtcFeatureGatingResponse? {
        cache.rtcFeatureGating
    }

    var callmePhone: GetCallmePhoneResponse? {
        cache.callmePhone
    }

    var appConfig: GetAppConfigResponse {
        if let config = cache.appConfig {
            return config
        } else {
            return .default
        }
    }

    public var customRingtone: String {
        cache.customRingtone
    }
}

extension UserSettingManager {
    /// 通知是否显示详情
    public var shouldShowDetails: Bool {
        dependency.shouldShowDetails
    }

    /// 会中通话中是否暂停通知
    var shouldShowMessage: Bool {
        dependency.shouldShowMessage
    }

    var shouldUpdateLark: Bool {
        dependency.shouldUpdateLark
    }

    var isMicSpeakerDisabled: Bool {
        get { bool(forKey: .micSpeakerDisabled) }
        set { updateLocalSetting(newValue, forKey: .micSpeakerDisabled) }
    }

    var isKeyboardMuteEnabled: Bool {
        get { bool(forKey: .keyboardMute, defaultValue: true) }
        set { updateLocalSetting(newValue, forKey: .keyboardMute) }
    }

    var displayFPS: Bool {
        get { bool(forKey: .displayFPS) }
        set { updateLocalSetting(newValue, forKey: .displayFPS) }
    }

    var displayCodec: Bool {
        get { bool(forKey: .displayCodec) }
        set { updateLocalSetting(newValue, forKey: .displayCodec) }
    }

    var isHDModeEnabled: Bool {
        get { bool(forKey: .meetingHDVideo) }
        set { updateLocalSetting(newValue, forKey: .meetingHDVideo) }
    }

    var autoHideToolStatusBar: Bool {
        get { bool(forKey: .autoHideToolStatusBar) }
        set { updateLocalSetting(newValue, forKey: .autoHideToolStatusBar) }
    }

    var useCellularImproveAudioQuality: Bool {
        get { bool(forKey: .improveAudioQuality, defaultValue: true) }
        set { updateLocalSetting(newValue, forKey: .improveAudioQuality) }
    }

    var isUltrawaveEnabled: Bool {
        get { bool(forKey: .ultrawave, defaultValue: true) }
        set { updateLocalSetting(newValue, forKey: .ultrawave) }
    }

    var needAdjustAnnotate: Bool {
        get { bool(forKey: .needAdjustAnnotate, defaultValue: true) }
        set { updateLocalSetting(newValue, forKey: .needAdjustAnnotate)}
    }

    public var lastOnTheCallMeetingId: String? {
        get { cache.diskCache.value(forKey: .lastlyMeetingId) }
        set { cache.diskCache.setValue(newValue, forKey: .lastlyMeetingId) }
    }

    var micCameraSetting: MicCameraSetting {
        get { MicCameraSetting(rawValue: cache.diskCache.int(forKey: .micCameraSetting, defaultValue: 0)) }
        set { cache.diskCache.setValue(newValue.rawValue, forKey: .micCameraSetting) }
    }

    public var lastCalledPhoneNumber: String? {
        get { cache.diskCache.value(forKey: .lastCalledPhoneNumber, type: Data.self).flatMap({ String(data: $0, encoding: .utf8) }) }
        set { cache.diskCache.setValue(newValue?.data(using: .utf8), forKey: .lastCalledPhoneNumber) }
    }

    var reactionDisplayMode: ReactionDisplayMode {
        get {
            cache.diskCache.value(forKey: .reactionDisplayMode, type: Int.self).flatMap { ReactionDisplayMode(rawValue: $0) } ?? .floating
        } set {
            cache.diskCache.set(newValue.rawValue, forKey: .reactionDisplayMode)
            invokeListeners([.reactionDisplayMode])
        }
    }

    var userjoinAudioOutputSetting: JoinAudioOutputSettingType {
        let type = cache.diskCache.int(forKey: .preferAudioOutputSetting, defaultValue: 0)
        return JoinAudioOutputSettingType(rawValue: type) ?? .last
    }

    func saveUserjoinAudioOutputSetting(_ output: Int) {
        self.invokeListeners(cache.updateJoinAudioOutputSetting(output))
    }

    func lastMeetAudioOutput() -> Int {
        cache.diskCache.int(forKey: .meetingAudioDevice)
    }

    func saveLastMeetAudioOutput(_ output: Int) {
        cache.diskCache.set(output, forKey: .meetingAudioDevice)
    }

    func lastCallAudioOutput(isVoiceCall: Bool) -> Int {
        cache.diskCache.int(forKey: isVoiceCall ? .voiceAudioDevice : .videoAudioDevice)
    }

    func saveLastCallAudioOutput(_ output: Int, isVoiceCall: Bool) {
        cache.diskCache.set(output, forKey: isVoiceCall ? .voiceAudioDevice : .videoAudioDevice)
    }

    public var callKitIconData: Data? {
        var pngData: Data?
        let path = cache.diskCache.getIsoPath(root: .document, relativePath: "videoconference/icon_data.png")
        if path.fileExists() {
            pngData = try? path.readData(options: .mappedIfSafe)
        }
        if pngData == nil {
            pngData = dependency.callKitLogo.pngData()
            if let data = pngData {
                try? path.writeData(data, options: [.atomic, .noFileProtection])
            }
        }
        return pngData
    }

    var replaceJoinedDevice: Bool {
        get { bool(forKey: .replaceJoinedDevice, defaultValue: true) }
        set { updateLocalSetting(newValue, forKey: .replaceJoinedDevice) }
    }

    var isPIPPreferred: Bool {
        get { bool(forKey: .pip, defaultValue: true) }
        set { updateLocalSetting(newValue, forKey: .pip) }
    }

    /// VoIP 过期推送忽略配置
    public var voipExpiredConfig: VoIPExpiredIgnoreConfig {
        let config: VoIPExpiredIgnoreConfig = settings(for: .vc_ios_ignore_expired_voip_config, defaultValue: .default)
        return config
    }
}

private extension GetAdminSettingsResponse {
    static let `default` = GetAdminSettingsResponse()
}

private extension GetSuiteQuotaResponse {
    static let `default` = GetSuiteQuotaResponse()
}

private extension ViewDeviceSetting {
    static let `default`: ViewDeviceSetting = {
        var settings = ViewDeviceSetting()
        settings.video.mirror = true
        return settings
    }()
}

private extension GetEnterprisePhoneConfigResponse {
    static let `default` = GetEnterprisePhoneConfigResponse()
}

private extension GetAdminOrgSettingsResponse {
    static let `default` = GetAdminOrgSettingsResponse(allowUserChangePstnAudioType: false)
}

private extension PullVideoChatConfigResponse {
    // disable-lint: magic number
    static let `default` = PullVideoChatConfigResponse(enableUpgradePlanNotice: [:],
                                                       meetingSupportInterpretationLanguage: [],
                                                       subtitleLanguages: [],
                                                       spokenLanguages: [],
                                                       inMeetingCountdownPermissionThreshold: 50,
                                                       largeMeetingSuggestThreshold: 40,
                                                       largeMeetingShareNoticeThreshold: 80,
                                                       largeMeetingSecurityNoticeThreshold: 70)
    // enable-lint: magic number
}

private extension GetAppConfigResponse {
    static let `default` = GetAppConfigResponse(videochatParticipantLimit: 6)
}

private extension GetAdminPermissionInfoResponse {
    static let `default` = GetAdminPermissionInfoResponse(isSuperAdministrator: false)
}

private extension MicCameraSetting {
    /// 兼容老版本
    init(rawValue: Int) {
        if (rawValue & 0x01) > 0 {
            self.isMicrophoneEnabled = true
        }
        if (rawValue & 0x04) > 0 {
            self.isCameraEnabled = true
        }
    }

    /// 兼容老版本
    var rawValue: Int {
        var i = 0
        if isMicrophoneEnabled {
            i |= 0x01
        }
        if isCameraEnabled {
            i |= 0x04
        }
        return i
    }
}

private extension UserSettingStorageKey {
    func toUserSettingChange() -> UserSettingChange? {
        switch self {
        case .improveAudioQuality:
            return .useCellularImproveAudioQuality
        case .autoHideToolStatusBar:
            return .autoHideToolStatusBar
        case .ultrawave:
            return .ultrawave
        case .micSpeakerDisabled:
            return .micSpeakerDisabled
        case .displayFPS:
            return .displayFPS
        case .displayCodec:
            return .displayCodec
        case .meetingHDVideo:
            return .meetingHDVideo
        case .needAdjustAnnotate:
            return .needAdjustAnnotate
        case .pip:
            return .pip
        default:
            return nil
        }
    }
}
