//
//  UserSettingDependencyImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/3/31.
//

import Foundation
import ByteViewSetting
import LarkSetting
import LarkReleaseConfig
import LarkAccountInterface
import ByteViewCommon
import ByteViewNetwork
import LarkEnv
import LarkTTNetInitializor
import LarkUIKit
import LarkLocalizations
import LarkContainer
import LarkAppResources
import LarkStorage
#if MessengerMod
import LarkSDKInterface
import RxSwift
import RustPB
#endif
#if canImport(LarkVersion)
import LarkVersion
#endif

final class UserSettingDependencyImpl: UserSettingDependency {
    private let logger = Logger.getLogger("Setting")
    let userResolver: UserResolver
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.account = try userResolver.resolve(assert: AccountInfo.self)
        self.httpClient = try userResolver.resolve(assert: HttpClient.self)
        self.universalUserSettingCache = UniversalSettingCache(storage: LocalStorageImpl(space: .user(id: account.userId)),
                                                               userResolver: userResolver)
    }

    let account: ByteViewNetwork.AccountInfo
    let httpClient: HttpClient
    let universalUserSettingCache: UniversalSettingCache

    func featureGatingValue(for key: String) -> Bool {
        if let service = try? userResolver.resolve(assert: FeatureGatingService.self) {
            return service.staticFeatureGatingValue(with: .init(stringLiteral: key))
        } else {
            return false
        }
    }

    func dynamicFeatureGatingValue(for key: String) -> Bool {
        if let service = try? userResolver.resolve(assert: FeatureGatingService.self) {
            return service.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
        } else {
            return false
        }
    }

    func setting<T>(for key: SettingsV3Key, type: T.Type) throws -> T where T: Decodable {
        let key2 = key.toLarkSetting()
        assert(key.rawValue == key2.stringValue, "SettingsV3Key.toLarkSetting() incorrect!, key: \(key)")
        return try userResolver.resolve(assert: SettingService.self).setting(with: type, key: key2)
    }

    func setting(for key: SettingsV3Key) throws -> [String: Any] {
        let key2 = key.toLarkSetting()
        assert(key.rawValue == key2.stringValue, "SettingsV3Key.toLarkSetting() incorrect!, key: \(key)")
        return try userResolver.resolve(assert: SettingService.self).setting(with: key2)
    }

    func domain(for key: UserSettingDomainKey) -> [String] {
        DomainSettingManager.shared.currentSetting[key.toLarkSetting(), default: []]
    }

    var isPrivateKA: Bool {
        ReleaseConfig.isPrivateKA
    }

    var isKA: Bool {
        ReleaseConfig.isKA
    }

    var packageIsLark: Bool {
        ReleaseConfig.isLark
    }

    var appGroupId: String {
        ReleaseConfig.groupId
    }

    var broadcastExtensionId: String {
        let extensionName = "BroadcastUploadExtension"
        guard let path = Bundle.main.path(forResource: "PlugIns/\(extensionName).appex/Info", ofType: "plist"),
              let dic = NSDictionary(contentsOfFile: path) as? [String: Any],// lint:disable:this lark_storage_check
              let identifier = dic["CFBundleIdentifier"] as? String else {
            return ""
        }
        return identifier
    }

    var rtcSetting: ByteViewSetting.RtcSettingDependency {
        let kaChannel = ReleaseConfig.isKA ? ReleaseConfig.releaseChannel : "saas"
        let cert = RootCertificates.getRootCertificates()
        return RtcSettingDependency(appId: ReleaseConfig.appId, kaChannel: kaChannel, serverCertificate: cert)
    }

    var storage: LocalStorage {
        LocalStorageImpl(space: .user(id: account.userId))
    }

    var globalStorage: LocalStorage {
        LocalStorageImpl(space: .global)
    }

    private var hasCallKitFeature: Bool {
        #if CallKitMod && !targetEnvironment(simulator)
        if Util.isiOSAppOnMacSystem {
            return false
        }
        if ReleaseConfig.releaseChannel == "Oversea" || featureGatingValue(for: "byteview.callkit.ios") {
            return true
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    var showsCallKitSetting: Bool {
        hasCallKitFeature
    }

    var isCallKitEnabled: Bool {
        hasCallKitFeature && (universalBoolValue(for: .useSysCallKey) ?? true)
    }

    var callKitLogo: UIImage {
        AppResources.callkit_logo
    }

    var includesCallsInRecents: Bool {
        universalBoolValue(for: .includeInRecentKey) ?? false
    }

    var shouldUpdateLark: Bool {
        #if canImport(LarkVersion)
        do {
            return try userResolver.resolve(assert: LarkVersion.VersionUpdateService.self).shouldUpdate
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    var mobileCodes: [ByteViewNetwork.MobileCode] {
        let provider = MobileCodeProvider(mobileCodeLocale: LanguageManager.currentLanguage, topCountryList: [], blackCountryList: [])
        return provider.getMobileCodes().map { .init(key: $0.key, name: $0.name, code: $0.code, index: $0.index) }
    }

    var logPath: String {
        let relativePath: String
        switch EnvManager.env.type {
        case .release, .preRelease:
            relativePath = "log/xlog"
        case .staging:
            relativePath = "staging/log/xlog"
        @unknown default:
            relativePath = "log/xlog"
        }
        let logPath = AbsPath.rustSdk + relativePath
        return logPath.absoluteString
    }

    var voipExpiredRecord: VoIPExpiredIgnoreRecord? {
        let key = UserSettingVoIPKey.voipExpiredIgnoreKey.rawValue
        let store = KVStores.udkv(space: .global, domain: Domain.biz.byteView, mode: .normal)
        return store.value(forKey: key)
    }

    func updateVoipExpiredRecord(_ record: VoIPExpiredIgnoreRecord?) {
        let key = UserSettingVoIPKey.voipExpiredIgnoreKey.rawValue
        let store = KVStores.udkv(space: .global, domain: Domain.biz.byteView, mode: .normal)
        if let record {
            store.set(record, forKey: key)
        } else {
            store.removeValue(forKey: key)
        }
    }

    var deviceNtpTimeRecord: DeviceNtpTimeRecord? {
        let key = UserSettingVoIPKey.deviceNtpTimeKey.rawValue
        let store = KVStores.udkv(space: .global, domain: Domain.biz.byteView, mode: .normal)
        return store.value(forKey: key)
    }

    func updateDeviceNtpTimeRecord(_ record: DeviceNtpTimeRecord?) {
        let key = UserSettingVoIPKey.deviceNtpTimeKey.rawValue
        let store = KVStores.udkv(space: .global, domain: Domain.biz.byteView, mode: .normal)
        if let record {
            store.set(record, forKey: key)
        } else {
            store.removeValue(forKey: key)
        }
    }

    private func universalBoolValue(for key: UniversalSettingKey) -> Bool? {
        return self.universalUserSettingCache.boolForKey(key.rawValue)
    }

    private func setUniversalBoolValue(_ value: Bool, for key: UniversalSettingKey) {
        self.universalUserSettingCache.set(key: key.rawValue, value: value)
    }

    #if MessengerMod
    private let disposeBag = DisposeBag()
    private var userGeneralSettings: UserGeneralSettings? {
        do {
            return try userResolver.resolve(assert: UserGeneralSettings.self)
        } catch {
            Logger.dependency.error("resolve UserGeneralSettings failed, \(error)")
            return nil
        }
    }

    var translateLanguageSetting: ByteViewSetting.TranslateLanguageSetting {
        (userGeneralSettings?.translateLanguageSetting ?? LarkSDKInterface.TranslateLanguageSetting()).vcType
    }

    func updateTranslateLanguage(isAutoTranslationOn: Bool?, targetLanguage: String?, rule: TranslateDisplayRule?) {
        guard let service = self.userGeneralSettings else { return }
        if let isOn = isAutoTranslationOn {
            var scope = service.translateLanguageSetting.translateScope
            scope = isOn ? (scope | Im_V1_TranslateScopeMask.videoConference.rawValue) : (scope & (~Im_V1_TranslateScopeMask.videoConference.rawValue))
            service.updateAutoTranslateScope(scope: scope).subscribe().disposed(by: disposeBag)
        }
        if let targetLanguage = targetLanguage {
            service.updateTranslateLanguageSetting(language: targetLanguage).subscribe().disposed(by: disposeBag)
        }
        if let rule = rule {
            var conf = Im_V1_LanguagesConfiguration()
            conf.rule = rule.pbType
            service.updateLanguagesConfiguration(globalConf: conf, languagesConf: nil).subscribe().disposed(by: disposeBag)
        }
    }

    func observeTranslateLanguageSetting(onChanged: @escaping (ByteViewSetting.TranslateLanguageSetting) -> Void) {
        userGeneralSettings?.translateLanguageSettingDriver.asObservable().map { $0.vcType }.subscribe(onNext: onChanged).disposed(by: disposeBag)
    }

    /// 通知是否显示详情
    var shouldShowDetails: Bool {
        userGeneralSettings?.showMessageDetail ?? false
    }

    /// 通知是否显示详情-管理员
    var adminCloseShowDetail: Bool {
        userGeneralSettings?.adminCloseShowDetail ?? false
    }

    /// 会中通话中是否暂停通知
    var shouldShowMessage: Bool {
        if let settings = userGeneralSettings {
            return !settings.messageNotificationsOffDuringCalls
        } else {
            return false
        }
    }
    #else
    private lazy var demoStorage = KVStores.udkv(space: .user(id: userResolver.userID), domain: Domain.biz.byteView.child("Demo"), mode: .normal)
    private var translateLanguageObservers: [(ByteViewSetting.TranslateLanguageSetting) -> Void] = []
    var translateLanguageSetting: ByteViewSetting.TranslateLanguageSetting {
        let availableLanguages: [ByteViewSetting.TranslateLanguage] = [
            ByteViewSetting.TranslateLanguage(key: "en", name: "English"),
            ByteViewSetting.TranslateLanguage(key: "zh", name: "简体中文"),
            ByteViewSetting.TranslateLanguage(key: "ja", name: "日本語"),
            ByteViewSetting.TranslateLanguage(key: "th", name: "ไทย")
        ]
        return ByteViewSetting.TranslateLanguageSetting(
            targetLanguage: demoStorage.string(forKey: "demo_target_language") ?? "en",
            isAutoTranslationOn: demoStorage.bool(forKey: "demo_is_vc_auto_translation_on"),
            availableLanguages: availableLanguages,
            globalConf: .init(rule: demoStorage.string(forKey: "demo_translation_display_rule") == "onlyTranslation" ? .onlyTranslation : .withOriginal)
        )
    }

    func updateTranslateLanguage(isAutoTranslationOn: Bool?, targetLanguage: String?, rule: TranslateDisplayRule?) {
        var setting = translateLanguageSetting
        if let isOn = isAutoTranslationOn {
            setting.isAutoTranslationOn = isOn
            demoStorage.set(isOn, forKey: "demo_is_vc_auto_translation_on")
        }
        if let targetLanguage = targetLanguage {
            setting.targetLanguage = targetLanguage
            demoStorage.set(targetLanguage, forKey: "demo_target_language")
        }
        if let rule = rule {
            setting.globalConf.rule = rule
            demoStorage.set(rule == .onlyTranslation ? "onlyTranslation" : "withOriginal", forKey: "demo_target_language")
        }
        translateLanguageObservers.forEach {
            $0(setting)
        }
    }

    func observeTranslateLanguageSetting(onChanged: @escaping (ByteViewSetting.TranslateLanguageSetting) -> Void) {
        translateLanguageObservers.append(onChanged)
    }

    var shouldShowDetails: Bool {
        true
    }

    var shouldShowMessage: Bool {
        false
    }
    #endif
}

private extension UserSettingDomainKey {
    func toLarkSetting() -> DomainKey {
        switch self {
        case .passport:
            return .passport
        case .rtcFrontier:
            return .rtcFrontier
        case .rtcDecision:
            return .rtcDecision
        case .rtcDefaultips:
            return .rtcDefaultips
        case .mpApplink:
            return .mpApplink
        default:
            return DomainKey(stringLiteral: self.rawValue)
        }
    }
}

private enum UniversalSettingKey: String {
    case useSysCallKey = "BYTEVIEW_USE_SYS_CALL"
    case includeInRecentKey = "BYTEVIEW_USE_SYS_RECENT"
    case useINStartCallIntentKey = "BYTEVIEW_USE_START_CALL_INTENT"
}

private enum UserSettingVoIPKey: String {
    case voipExpiredIgnoreKey = "vc_ios_voip_expired_ignore_record"
    case deviceNtpTimeKey = "vc_ios_device_ntp_time_record"
}

#if MessengerMod
private extension LarkSDKInterface.TranslateLanguageSetting {
    var vcType: ByteViewSetting.TranslateLanguageSetting {
        .init(targetLanguage: targetLanguage,
              isAutoTranslationOn: isScopeOpen(scope: translateScope, scopeType: .videoConference),
              availableLanguages: languageKeys.compactMap({ key in
            if let name = supportedLanguages[key] {
                return ByteViewSetting.TranslateLanguage(key: key, name: name)
            } else {
                return nil
            }
        }), globalConf: .init(rule: globalConf.rule.vcType))
    }
}

private extension Basic_V1_DisplayRule {
    var vcType: TranslateDisplayRule {
        switch self {
        case .noTranslation:
            return .noTranslation
        case .onlyTranslation:
            return .onlyTranslation
        case .withOriginal:
            return .withOriginal
        default:
            return .unknown
        }
    }
}

private extension TranslateDisplayRule {
    var pbType: Basic_V1_DisplayRule {
        switch self {
        case .noTranslation:
            return .noTranslation
        case .onlyTranslation:
            return .onlyTranslation
        case .withOriginal:
            return .withOriginal
        default:
            return .unknownRule
        }
    }
}
#endif

private extension SettingsV3Key {
    // nolint: cyclo_complexity
    func toLarkSetting() -> UserSettingKey {
        switch self {
        case .vc_feedback_issue_type_config: return .make(userKeyLiteral: "vc_feedback_issue_type_config")
        case .vc_active_speaker_config_v2: return .make(userKeyLiteral: "vc_active_speaker_config_v2")
        case .vc_mute_prompt_config: return .make(userKeyLiteral: "vc_mute_prompt_config")
        case .vc_retry_interval: return .make(userKeyLiteral: "vc_retry_interval")
        case .vc_howling_warn: return .make(userKeyLiteral: "vc_howling_warn")
        case .vc_countdown_config: return .make(userKeyLiteral: "vc_countdown_config")
        case .vc_ios_participants_config: return .make(userKeyLiteral: "vc_ios_participants_config")
        case .vc_suggestion_setting: return .make(userKeyLiteral: "vc_suggestion_setting")
        case .vc_keyboard_mute: return .make(userKeyLiteral: "vc_keyboard_mute")
        case .vc_mic_volume_levels: return .make(userKeyLiteral: "vc_mic_volume_levels")
        case .vc_animation_config: return .make(userKeyLiteral: "vc_animation_config")
        case .vc_video_sort_config: return .make(userKeyLiteral: "vc_video_sort_config")
        case .vc_billing_link_config: return .make(userKeyLiteral: "vc_billing_link_config")
        case .vc_whiteboard_config: return .make(userKeyLiteral: "vc_whiteboard_config")
        case .vc_send_share_screen_config: return .make(userKeyLiteral: "vc_send_share_screen_config")
        case .vc_feature_performance_config: return .make(userKeyLiteral: "vc_feature_performance_config")
        case .vc_virtual_background_images: return .make(userKeyLiteral: "vc_virtual_background_images")
        case .vc_enterprise_control_link: return .make(userKeyLiteral: "vc_enterprise_control_link")
        case .vc_platform_config: return .make(userKeyLiteral: "vc_platform_config")
        case .vc_audioshare_config: return .make(userKeyLiteral: "vc_audioshare_config")
        case .vc_network_tips_config: return .make(userKeyLiteral: "vc_network_tips_config")
        case .vc_show_mic_camera_mute_toast_config: return .make(userKeyLiteral: "vc_show_mic_camera_mute_toast_config")
        case .vc_multi_resolution_config: return .make(userKeyLiteral: "vc_multi_resolution_config")
        case .camera_capture_encode_linkage_config: return .make(userKeyLiteral: "camera_capture_encode_linkage_config")
        case .vc_ios_render_config: return .make(userKeyLiteral: "vc_ios_render_config")
        case .client_dynamic_link: return .make(userKeyLiteral: "client_dynamic_link")
        case .vc_phone_call_config: return .make(userKeyLiteral: "vc_phone_call_config")
        case .vc_voice_mode_config: return .make(userKeyLiteral: "vc_voice_mode_config")
        case .sdk_bandwidth_throttle_config: return .make(userKeyLiteral: "sdk_bandwidth_throttle_config")
        case .vc_auto_hide_toolbar_config: return .make(userKeyLiteral: "vc_auto_hide_toolbar_config")
        case .custom_exception_config: return .make(userKeyLiteral: "custom_exception_config")
        case .vc_in_meet_perf_sample_config: return .make(userKeyLiteral: "vc_in_meet_perf_sample_config")
        case .vc_hide_non_video_config: return .make(userKeyLiteral: "vc_hide_non_video_config")
        case .vc_rtc_app_config: return .make(userKeyLiteral: "vc_rtc_app_config")
        case .vc_rtc_billing_heartbeat_interval: return .make(userKeyLiteral: "vc_rtc_billing_heartbeat_interval")
        case .vc_upload_share_status: return .make(userKeyLiteral: "vc_upload_share_status")
        case .vc_landscape_button_config: return .make(userKeyLiteral: "vc_landscape_button_config")
        case .vc_sla_timeout_config: return .make(userKeyLiteral: "vc_sla_timeout_config")
        case .vc_tool_config: return .make(userKeyLiteral: "vc_tool_config")
        case .vc_media_service_toast: return .make(userKeyLiteral: "vc_media_service_toast")
        case .notes_template_category_id_config: return .make(userKeyLiteral: "notes_template_category_id_config")
        case .notes_ai_config: return .make(userKeyLiteral: "notes_ai_config")
        case .vc_meeting_notes_config: return .make(userKeyLiteral: "vc_meeting_notes_config")
        case .vc_mute_audio_unit: return .make(userKeyLiteral: "vc_mute_audio_unit")
        case .nfd_scan_config: return .make(userKeyLiteral: "nfd_scan_config")
        case .myai_onboarding_config: return .make(userKeyLiteral: "myai_onboarding_config")
        case .my_ai_brand_name: return .make(userKeyLiteral: "my_ai_brand_name")
        case .vc_float_reaction_config: return .make(userKeyLiteral: "vc_float_reaction_config")
        case .lark_ios_universal_downgrade_config: return .make(userKeyLiteral: "lark_ios_universal_downgrade_config")
        case .vc_ios_ignore_expired_voip_config: return .make(userKeyLiteral: "vc_ios_ignore_expired_voip_config")
        case .fine_scheduling: return .make(userKeyLiteral: "fine_scheduling")
        case .vc_miniwindow_share: return .make(userKeyLiteral: "vc_miniwindow_share")
        case .vc_magic_share_config: return .make(userKeyLiteral: "vc_magic_share_config")
        }
    }
}

final class UniversalSettingCache {
    struct Key: LocalStorageKey {
        var rawValue: String
        var domain: LocalStorageDomain {
            .child("UniversalUserSetting")
        }
    }
#if MessengerMod
    let userUniversalSettingService: UserUniversalSettingService?
    let disposeBag = DisposeBag()
    static let cachedKeys: Set<String> = [
        UniversalSettingKey.useSysCallKey.rawValue,
        UniversalSettingKey.includeInRecentKey.rawValue
    ]
#endif

    let storage: LocalStorage
    init(storage: LocalStorage, userResolver: UserResolver) {
        self.storage = storage
#if MessengerMod
        self.userUniversalSettingService =
        {
            do {
                return try userResolver.resolve(assert: UserUniversalSettingService.self)
            } catch {
                Logger.dependency.error("resolve UserUniversalSettingService failed, \(error)")
                return nil
            }
        }()
        for k in Self.cachedKeys {
            self.observeKey(k)
        }
#endif
    }

#if MessengerMod
    private func observeKey(_ key: String) {
        self.userUniversalSettingService?.getBoolUniversalUserObservableSetting(key: key)
            .flatMap({ val -> Observable<Bool> in
                if let v = val {
                    return .just(v)
                } else {
                    return .empty()
                }
            })
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] val in
                self?.onValueChanged(key: key, value: val)
            })
            .disposed(by: disposeBag)
    }
    private func onValueChanged(key: String, value: Bool) {
        if let v: Bool = storage.value(for: Key(rawValue: key)),
           value == v {
            return
        }
        Logger.dependency.info("\(key) => \(value)")
        storage.set(value, for: Key(rawValue: key))
    }
#endif

    func boolForKey(_ key: String) -> Bool? {
        #if MessengerMod
        if let v = userUniversalSettingService?.getBoolUniversalUserSetting(key: key) {
            return v
        } else if Self.cachedKeys.contains(key),
            let v: Bool = storage.value(for: Key(rawValue: key)) {
            Logger.dependency.warn("missing \(key), used cached: \(v)")
            return v
        } else {
            Logger.dependency.warn("missing \(key)")
            return nil
        }
        #else
        return storage.value(for: Key(rawValue: key))
        #endif

    }
    func set(key: String, value: Bool) {
        #if MessengerMod
        userUniversalSettingService?.setUniversalUserConfig(values: [key: .boolValue(value)])
            .subscribe()
            .disposed(by: disposeBag)
        #else
        storage.set(value, for: Key(rawValue: key))
        #endif
    }
}
