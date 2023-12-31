//
//  UserGeneralSettingsImpl.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/6/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkSDKInterface
import LKCommonsLogging
import LarkModel
import LarkContainer
import LarkAppConfig
import LarkAccountInterface
import LarkFeatureGating
import RunloopTools
import LarkExtensions
import RustPB
import LarkCombine
import LKCommonsTracker
import Homeric
import LarkRustClient
import LarkStorage
import LarkSetting

final class RWLock {
    private var rwLock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwLock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwLock)
    }

    func rlock() {
        pthread_rwlock_rdlock(&rwLock)
    }

    func wlock() {
        pthread_rwlock_wrlock(&rwLock)
    }

    func unlock() {
        pthread_rwlock_unlock(&rwLock)
    }
}

@propertyWrapper
struct AtomicRWGetter<T> {
    private var rwLock: RWLock!
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    var wrappedValue: T {
        rwLock.rlock()
        defer {
            rwLock.unlock()
        }
        return value
    }

    mutating func setNonatomic(_ value: T) {
        self.value = value
    }

    mutating func setLock(_ rwLock: RWLock) {
        self.rwLock = rwLock
    }
}

/// 这个类新增方法一定要注意多线程问题
final class UserGeneralSettingsImpl: UserGeneralSettings {

    private static let logger = Logger.log(UserGeneralSettingsImpl.self, category: "UserSettings")

    private let disposeBag = DisposeBag()
    /// Swift.String在携带了nativeObject或bridgeObject的时候不是线程安全的，因此要保证下面getter、setter的线程安全问题
    private let rwLock = RWLock()

    /// 字节云平台视频发送限制
    /// 线程安全不需要保证
    var sendVideoConfig = SendVideoConfig()
    //// 字节云平台创建假消息上屏
    /// 线程安全不需要保证
    var createQuasiMessageConfig = CreateQuasiMessageConfig()

    ///消息预处理配置
    var messagePreProcessConfig = MessagePreProcessConfig()
    ///获取机型分类
    var deviceClassifyConfig = DeviceClassifyConfig()
    var memberListNonDepartmentConfig = MemberListNonDepartmentConfig()
    /// 消息气泡折叠配置
    var messageBubbleFoldConfig = MessageBubbleFoldConfig()
    /// 群Tab添加引导网页链接
    var chatTabAddUGLinkConfig = ChatTabAddUGLinkConfig()

    /// 大 GIF 不自动播放配置
    var gifLoadConfig = GIFLoadConfig()

    /// 文件发送大小限制
    var fileUploadSizeLimit: BehaviorRelay<FileUploadSizeLimit> = BehaviorRelay<FileUploadSizeLimit>(value: FileUploadSizeLimit())
    /// Messenger单测黑名单机制
    var skipTestConfig: BehaviorRelay<SkipTestConfig> = BehaviorRelay<SkipTestConfig>(value: SkipTestConfig())
    /// 字节云平台配置的messenger_video_compress
    var videoCompress: BehaviorRelay<MessengerVideoCompress> = BehaviorRelay<MessengerVideoCompress>(value: MessengerVideoCompress())
    /// 字节云平台配置的video_origin_type
    var originVideoCompress: BehaviorRelay<OriginVideoCompressConfig> = BehaviorRelay<OriginVideoCompressConfig>(value: OriginVideoCompressConfig())
    /// 字节云平台配置的ve_synthesis_settings
    var videoSynthesisSetting: BehaviorRelay<VideoSynthesisSetting> = BehaviorRelay<VideoSynthesisSetting>(value: VideoSynthesisSetting())
    /// 字节云平台配置的video_pre_process
    var videoPreprocessConfig: BehaviorRelay<VideoPreprocessConfig> = BehaviorRelay<VideoPreprocessConfig>(value: VideoPreprocessConfig())
    /// 群置顶 onboarding 网页链接
    /// 包含String需要保证线程安全
    @AtomicRWGetter(ChatPinOnboardingDetailLinkConfig())
    var chatPinOnboardingDetailLinkConfig
    /// 字节云平台配置的bgtask_enable
    /// 包含String需要保证线程安全
    @AtomicRWGetter(BGTaskConfig())
    var bgTaskConfig
    /// 群接龙 url 的 path 配置
    /// 包含String需要保证线程安全
    @AtomicRWGetter(BitableGroupNoteConfig())
    var bitableGroupNoteConfig
    /// 字节云平台配置的helpdesk_common
    /// 包含String需要保证线程安全
    @AtomicRWGetter(HelpdeskCommon())
    var helpdeskCommon
    /// 字节云平台配置的GroupConfig
    /// 线程安全不需要保证
    var groupConfig: GroupConfig = GroupConfig()
    /// 字节云平台配置的desc_op
    /// 线程安全不需要保证
    var userGrowthConfig: UserGrowthConfig = UserGrowthConfig()
    /// byteCloud setting dominManagePolicy
    /// 包含数组需要保证线程安全
    @AtomicRWGetter(DominManagePolicyConfig())
    var dominManagePolicyConfig
    /// 字节云平台配置的contacts_config
    /// 包含String需要保证线程安全
    @AtomicRWGetter(ContactsConfig())
    var contactsConfig
    /// gadget engine ab test config
    /// 包含Map需要保证线程安全
    @AtomicRWGetter(GadgetEngineConfig())
    var gadgetABTestConfig
    /// op monitor config
    /// 包含Map需要保证线程安全
    @AtomicRWGetter(OPMonitorConfig())
    var opMonitorConfig

    /// 可在线解压缩的文件类型配置
    /// 包含数组需要保证线程安全
    @AtomicRWGetter(MessengerFileConfig())
    var messengerFileConfig

    /// 用户投放Source列表
    /// 包含数组需要保证线程安全
    @AtomicRWGetter(UGBannerConfig())
    var ugBannerConfig

    /// 用户投放Source列表变化监听
    var ugBannerConfigChangeVariable: BehaviorRelay<Void> = BehaviorRelay(value: ())

    /// Onboarding spotlight config
    /// 包含String需要保证线程安全
    @AtomicRWGetter(SpotlightWorkspaceConfig())
    var spotlightWorkspaceConfig

    /// 翻译设置
    var translateLanguageSetting: TranslateLanguageSetting {
        return self.translateLanguageSettingVariable.value
    }
    var translateLanguageSettingDriver: Driver<TranslateLanguageSetting> {
        return self.translateLanguageSettingVariable.asDriver()
    }
    private var translateLanguageSettingVariable =
        BehaviorRelay<TranslateLanguageSetting>(value: TranslateLanguageSetting())
    /// 网页翻译配置
    /// 线程安全
    var webTranslateConfig: SettingV3WebTranslateConfig = SettingV3WebTranslateConfig()

    // 帮助中心域名
    @AtomicRWGetter(HelpCenterBizDomainConfig())
    var helpDeskBizDomainConfig

    var pushDowngradeAppLagConfig: PushDowngradeAppLagConfig?

    var chatSecureViewEnableConfig: ChatSecureViewEnableConfig?

    /// pc登录关闭手机通知、依然接受@消息
    /// 线程安全
    var notifyConfig: NotifyConfig = NotifyConfig()
    /// 防止多次请求
    private var notifyOpenIsSetting = false
    /// 防止多次请求
    private var atNotifyOpenIsSetting = false
    /// 防止多次请求
    private var notifySpecialFocusIsSetting = false
    /// 防止多次请求
    private var notifySoundsSetting = false

    /// 通知栏是否显示详情
    var showMessageDetail: Bool = true

    var adminCloseShowDetail: Bool = false
    /// 通话和会议中是否屏蔽消息
    var messageNotificationsOffDuringCalls: Bool = false
    /// 是否在拨打电话前弹出提示
    var showPhoneAlert: Bool = true

    var is24HourTime: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: Date.lf.is24HourTime)

    private let userId: String

    private let chatterSettingAPI: ChatterSettingAPI
    private let chatterAPI: ChatterAPI
    private let urgentAPI: UrgentAPI
    private let configAPI: ConfigurationAPI
    private var timeFormatService: TimeFormatSettingService
    private var serverNTPTimeService: ServerNTPTimeService
    private let featureGatingService: FeatureGatingService

    init(
        chatterSettingAPI: ChatterSettingAPI,
        chatterAPI: ChatterAPI,
        urgentAPI: UrgentAPI,
        configAPI: ConfigurationAPI,
        pushCenter: PushNotificationCenter,
        timeFormatService: TimeFormatSettingService,
        serverNTPTimeService: ServerNTPTimeService,
        featureGatingService: FeatureGatingService,
        currentChatterID: String) {
        self.chatterAPI = chatterAPI
        self.chatterSettingAPI = chatterSettingAPI
        self.urgentAPI = urgentAPI
        self.configAPI = configAPI
        self.timeFormatService = timeFormatService
        self.serverNTPTimeService = serverNTPTimeService
        self.featureGatingService = featureGatingService
        self.userId = currentChatterID

        self._helpdeskCommon.setLock(rwLock)
        self._contactsConfig.setLock(rwLock)
        self._chatPinOnboardingDetailLinkConfig.setLock(rwLock)
        self._bgTaskConfig.setLock(rwLock)
        self._ugBannerConfig.setLock(rwLock)
        self._opMonitorConfig.setLock(rwLock)
        self._spotlightWorkspaceConfig.setLock(rwLock)
        self._dominManagePolicyConfig.setLock(rwLock)
        self._helpDeskBizDomainConfig.setLock(rwLock)
        self._gadgetABTestConfig.setLock(rwLock)
        self._messengerFileConfig.setLock(rwLock)
        self._bitableGroupNoteConfig.setLock(rwLock)

        /// 接收翻译推送通知，全部都是部分数据
        pushCenter.observable(for: PushTranslateLanguageSetting.self)
            .subscribe(onNext: { [weak self] (setting) in
                guard let `self` = self else { return }
                var translateLanguageSetting: TranslateLanguageSetting = self.translateLanguageSetting
                translateLanguageSetting.targetLanguage = setting.targetLanguage
                translateLanguageSetting.languageKeys = setting.languageKeys
                translateLanguageSetting.supportedLanguages = setting.supportedLanguages
                UserGeneralSettingsImpl.logger.info("PushTranslateLanguageSetting translateInfo: \(translateLanguageSetting.info())")
                self.translateLanguageSettingVariable.accept(translateLanguageSetting)
            }).disposed(by: self.disposeBag)
        pushCenter.observable(for: PushLanguagesConfiguration.self)
            .subscribe(onNext: { [weak self] (configuration) in
                guard let `self` = self else { return }
                var translateLanguageSetting: TranslateLanguageSetting = self.translateLanguageSetting
                translateLanguageSetting.globalConf = configuration.globalConf
                // 新翻译push也会走PushLanguagesConfiguration，但读取的是SrcLanguageConfig,不需要更新languagesConf
                if !featureGatingService.staticFeatureGatingValue(with: "translate.settings.v2.enable") {
                    translateLanguageSetting.languagesConf = configuration.languagesConf
                }
                UserGeneralSettingsImpl.logger.info("PushLanguagesConfiguration translateInfo: \(translateLanguageSetting.info())")
                self.translateLanguageSettingVariable.accept(translateLanguageSetting)
            }).disposed(by: self.disposeBag)
        pushCenter.observable(for: PushAutoTranslateSrcLanguageScope.self)
            .subscribe(onNext: { [weak self] (srcLanguagesScopeSettings) in
                guard let `self` = self else { return }
                var translateLanguageSetting: TranslateLanguageSetting = self.translateLanguageSetting
                srcLanguagesScopeSettings.srcLanguagesScope.forEach { (srcLanugage: String, scopes: Int32) in
                    if var srcConfig = translateLanguageSetting.srcLanguagesConfig[srcLanugage] {
                        srcConfig.scopes = Int32(scopes)
                        translateLanguageSetting.srcLanguagesConfig[srcLanugage] = srcConfig
                    }
                }
                UserGeneralSettingsImpl.logger.info("PushAutoTranslateSrcLanguageScope translateInfo: \(translateLanguageSetting.info())")
                self.translateLanguageSettingVariable.accept(translateLanguageSetting)
            }).disposed(by: self.disposeBag)
        pushCenter.observable(for: PushLanguagesConfigurationV2.self)
            .subscribe(onNext: { [weak self] (configuration) in
                guard let `self` = self else { return }
                var translateLanguageSetting: TranslateLanguageSetting = self.translateLanguageSetting
                translateLanguageSetting.languagesConf = configuration.languagesConf
                UserGeneralSettingsImpl.logger.info("PushLanguagesConfigurationV2 translateInfo: \(translateLanguageSetting.info())")
                self.translateLanguageSettingVariable.accept(translateLanguageSetting)
            }).disposed(by: self.disposeBag)
        pushCenter.observable(for: PushAutoTranslateScope.self)
            .subscribe(onNext: { [weak self] (scope) in
                guard let `self` = self else { return }
                var translateLanguageSetting: TranslateLanguageSetting = self.translateLanguageSetting
                translateLanguageSetting.translateScope = Int(scope.translateScope)
                /// 成功后重新从server拉取更新的翻译设置列表
                self.fetchTranslateLanguageSetting(strategy: .forceServer).subscribe().disposed(by: self.disposeBag)
                UserGeneralSettingsImpl.logger.info("PushAutoTranslateScope translateInfo: \(translateLanguageSetting.info())")
            }).disposed(by: self.disposeBag)
        pushCenter.observable(for: PushDisableAutoTranslateLanguages.self)
            .subscribe(onNext: { [weak self] (languages) in
                guard let `self` = self else { return }
                var translateLanguageSetting: TranslateLanguageSetting = self.translateLanguageSetting
                translateLanguageSetting.disAutoTranslateLanguagesConf = languages.disAutoTranslateLanguagesConf
                UserGeneralSettingsImpl.logger.info("PushDisableAutoTranslateLanguages translateinfo: \(translateLanguageSetting.info())")
                self.translateLanguageSettingVariable.accept(translateLanguageSetting)
            }).disposed(by: self.disposeBag)
        /// push监听：时间制，会中通话中免打扰，勿扰模式截止ntp时间
        pushCenter.observable(for: RustPB.Settings_V1_PushUserSetting.self)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                self.messageNotificationsOffDuringCalls = response.messageNotificationsOffDuringCalls

                let is24HourTime = response.timeFormat.timeFormat.is24HourTime
                self.timeFormatService.is24HourTime = is24HourTime
                if self.is24HourTime.value != is24HourTime {
                    self.is24HourTime.accept(is24HourTime)
                }
            }).disposed(by: self.disposeBag)
        /// 监听字节云平台配置的通知
        pushCenter.observable(for: PushGeneralConfig.self)
            .subscribe(onNext: { [weak self] (config) in
                guard let `self` = self else { return }
                self.setProperties(fieldGroups: config.fieldGroups)
            }).disposed(by: self.disposeBag)
    }

    func initializeSyncSettings() {
        self.syncRemoteSettings()
    }

    func syncRemoteSettings() {
        /// 拉取showMessageDetail&&showPhoneAlert
        self.fetchRemoteSetting(strategy: .local)
        self.fetchRemoteSetting(strategy: .forceServer)

        /// 拉取 offDuringCalls、24时间制、勿扰模式截止ntp时间
        self.getMostUserSetting()

        /// 拉取翻译设置
        /// 本地翻译设置的即时读取
        self.fetchTranslateLanguageSetting(strategy: .local).subscribe().disposed(by: self.disposeBag)
        RunloopDispatcher.shared.addTask(scope: .user) {
            self.fetchTranslateLanguageSetting(strategy: .forceServer).subscribe().disposed(by: self.disposeBag)
        }.waitCPUFree()
        /// 拉取notifyConfig
        self.fetchDeviceNotifySetting(strategy: .local)
        self.fetchDeviceNotifySetting(strategy: .forceServer)
        /// 拉取字节云平台配置
        self.fetchCloudSetting()
        /// 拉取Smart Compose 配置
        self.fetchGeneralSetting()
        /// 拉取好友隐私设置
        self.configAPI.fetchAddFriendPrivateConfig()
    }

    /// 拉取showMessageDetail&&showPhoneAlert
    private func fetchRemoteSetting(strategy: RustPB.Basic_V1_SyncDataStrategy, finish: ((Bool, Bool, Bool) -> Void)? = nil) {
        UserGeneralSettingsImpl.logger.info("openSettingLog/api/getClientStatus/req strategy: \(strategy)")
        chatterSettingAPI
            .fetchRemoteSetting(strategy: strategy)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isShowDetail, showPhoneAlert, adminCloseShowDetail) in
                UserGeneralSettingsImpl.logger.info("openSettingLog/api/getClientStatus/res: ok isShowDetail: \(isShowDetail)")
                self?.showMessageDetail = isShowDetail
                self?.showPhoneAlert = showPhoneAlert
                self?.adminCloseShowDetail = adminCloseShowDetail
                finish?(isShowDetail, showPhoneAlert, adminCloseShowDetail)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                UserGeneralSettingsImpl.logger.error("openSettingLog/api/getClientStatus/res: error", error: error)
                finish?(self.showMessageDetail, self.showPhoneAlert, self.adminCloseShowDetail)
            }).disposed(by: self.disposeBag)
    }

    /// 从服务器拉取showMessageDetail&&showPhoneAlert
    func fetchRemoteSettingFromServer(finish: ((Bool, Bool, Bool) -> Void)? = nil) {
        self.fetchRemoteSetting(strategy: .forceServer, finish: finish)
    }

    private func getMostUserSetting() {
        configAPI.getMostUserSetting()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.messageNotificationsOffDuringCalls = response.messageNotificationsOffDuringCalls

                let is24HourTime = response.timeFormat.timeFormat.is24HourTime
                self.timeFormatService.is24HourTime = is24HourTime
                if self.is24HourTime.value != is24HourTime {
                    self.is24HourTime.accept(is24HourTime)
                }
                UserGeneralSettingsImpl.logger.info("openSettingLog/api/getUserSetting/res: ok"
                                                    + " offDuringCalls: \(response.messageNotificationsOffDuringCalls)"
                                                    + ", is24HourTime: \(is24HourTime)"
                                                    + ", doNotDisturbEndTime: \(response.doNotDisturbEndTime)")
            }, onError: { error in
                UserGeneralSettingsImpl.logger.error("openSettingLog/api/getUserSetting/res: error", error: error)
            }).disposed(by: self.disposeBag)
    }

    func updateRemoteSetting(isShowDetail: Bool, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        chatterSettingAPI
            .updateRemoteSetting(showNotifyDetail: isShowDetail)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.showMessageDetail = isShowDetail
                success()
            }, onError: { (error) in
                failure(error)
            })
            .disposed(by: disposeBag)
    }

    func updateRemoteSetting(showPhoneAlert: Bool, success: (() -> Void)? = nil, failure: ((Error) -> Void)? = nil) {
        chatterSettingAPI
            .updateRemoteSetting(showPhoneAlert: showPhoneAlert)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.showPhoneAlert = showPhoneAlert
                success?()
            }, onError: { (error) in
                failure?(error)
            })
            .disposed(by: self.disposeBag)
    }

    func openNotificationSetting() {
        let url = URL(string: UIApplication.openSettingsURLString) ?? .init(fileURLWithPath: "")
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // 关闭手机通知
    func updateNotificaitonStatus(notifyDisable: Bool) {
        updateNotificaitonStatus(notifyDisable: notifyDisable, retry: 1)
    }

    func updateNotificaitonStatus(notifyDisable: Bool, retry: Int) {
        if self.notifyOpenIsSetting { return }
        self.notifyOpenIsSetting = true

        self.chatterSettingAPI
            .updateNotificationStatus(notifyDisable: notifyDisable)
            .retry(retry)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.notifyOpenIsSetting = false
                self.notifyConfig.notifyDisable = notifyDisable
                UserGeneralSettingsImpl.logger.info("[notifyDisable] update notification status succeed")
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                //值不变，但仍要发射一个信号
                self.notifyOpenIsSetting = false
                self.notifyConfig.notifyDisable = self.notifyConfig.notifyDisable
                UserGeneralSettingsImpl.logger.error("[notifyDisable] update notification status failed", error: error)
            })
            .disposed(by: disposeBag)
    }

    func updateNotificationStatus(notifyDisable: Bool) -> Observable<Bool> {
        return updateNotificationStatus(notifyDisable: notifyDisable, retry: 1)
    }

    func updateNotificationStatus(notifyDisable: Bool, retry: Int) -> Observable<Bool> {
        if self.notifyOpenIsSetting { return Observable.just(false) }
        self.notifyOpenIsSetting = true

        return self.chatterSettingAPI
            .updateNotificationStatus(notifyDisable: notifyDisable)
            .retry(retry)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.notifyOpenIsSetting = false
                self.notifyConfig.notifyDisable = notifyDisable
                UserGeneralSettingsImpl.logger.info("[notifyDisable] update notification status succeed")
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                //值不变，但仍要发射一个信号
                self.notifyOpenIsSetting = false
                self.notifyConfig.notifyDisable = self.notifyConfig.notifyDisable
                UserGeneralSettingsImpl.logger.error("[notifyDisable] update notification status failed", error: error)
            })
    }

    // at我的消息仍通知
    func updateNotificaitonStatus(notifyAtEnabled: Bool) {
        updateNotificaitonStatus(notifyAtEnabled: notifyAtEnabled, retry: 1)
    }

    func updateNotificaitonStatus(notifyAtEnabled: Bool, retry: Int) {
        if self.atNotifyOpenIsSetting { return }
        self.atNotifyOpenIsSetting = true

        self.chatterSettingAPI
            .updateNotificationStatus(notifyAtEnabled: notifyAtEnabled)
            .retry(retry)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.atNotifyOpenIsSetting = false
                self.notifyConfig.atNotifyOpen = notifyAtEnabled
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                //值不变，但仍要发射一个信号
                self.atNotifyOpenIsSetting = false
                self.notifyConfig.atNotifyOpen = self.notifyConfig.atNotifyOpen
                UserGeneralSettingsImpl.logger.error("[notifyAtEnabled] update notification status failed", error: error)
        }).disposed(by: disposeBag)
    }

    func updateNotificationStatus(notifyAtEnabled: Bool) -> Observable<Bool> {
        return updateNotificationStatus(notifyAtEnabled: notifyAtEnabled, retry: 1)
    }

    func updateNotificationStatus(notifyAtEnabled: Bool, retry: Int) -> Observable<Bool> {
        if self.atNotifyOpenIsSetting { return Observable.just(false) }
        self.atNotifyOpenIsSetting = true

        return self.chatterSettingAPI
            .updateNotificationStatus(notifyAtEnabled: notifyAtEnabled)
            .retry(retry)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.atNotifyOpenIsSetting = false
                self.notifyConfig.atNotifyOpen = notifyAtEnabled
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                //值不变，但仍要发射一个信号
                self.atNotifyOpenIsSetting = false
                self.notifyConfig.atNotifyOpen = self.notifyConfig.atNotifyOpen
                UserGeneralSettingsImpl.logger.error("[notifyAtEnabled] update notification status failed", error: error)
            })
    }

    // 星标联系人仍通知
    func updateNotificationStatus(notifySpecialFocus: Bool) -> Observable<Bool> {
        return updateNotificationStatus(notifySpecialFocus: notifySpecialFocus, retry: 1)
    }

    func updateNotificationStatus(notifySpecialFocus: Bool, retry: Int) -> Observable<Bool> {
        if self.notifySpecialFocusIsSetting { return Observable.just(false) }
        self.notifySpecialFocusIsSetting = true

        return self.chatterSettingAPI
            .updateNotificationStatus(notifySpecialFocus: notifySpecialFocus)
            .retry(retry)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.notifySpecialFocusIsSetting = false
                self.notifyConfig.notifySpecialFocus = notifySpecialFocus
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.notifySpecialFocusIsSetting = false
                self.notifyConfig.notifySpecialFocus = self.notifyConfig.notifySpecialFocus // 值不变，但仍要发射一个信号
                UserGeneralSettingsImpl.logger.error("[notifySpecialFocus] update notification status failed", error: error)
            })
    }

    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem]) -> Observable<Bool> {
        return updateNotificationStatus(items: items, retry: 1)
    }

    func updateNotificationStatus(items: [Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem],
                                  retry: Int) -> Observable<Bool> {
        if self.notifySoundsSetting { return Observable.just(false) }
        self.notifySoundsSetting = true

        return self.chatterSettingAPI
            .updateNotificationStatus(items: items)
            .retry(retry)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.notifySoundsSetting = false
                let voices = self.notifyConfig.notifySounds.items.map { voice in
                    guard let item = items.first(where: {
                        $0.key == voice.key
                    }) else {
                        return voice
                    }
                    var new = voice
                    new.value = item.value
                    return new
                }

                self.notifyConfig.notifySounds.items = voices

                var dict: [String: String] = [:]
                voices.forEach { item in
                    dict[item.key] = item.value
                }

                DispatchQueue.global().async {
                    KVPublic.Notify.notifySounds.setValue(dict)
                }
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                self.notifySoundsSetting = false
                self.notifyConfig.notifySounds = self.notifyConfig.notifySounds
            })
    }

    /// 获取notifyConfig
    private func fetchDeviceNotifySetting(strategy: RustPB.Basic_V1_SyncDataStrategy) {
        UserGeneralSettingsImpl.logger.info("openSettingLog/api/deviceNotifySetting/getReq: strategy: \(strategy.rawValue)")
        self.chatterAPI.fetchDeviceNotifySetting(strategy: strategy)
            .subscribe(onNext: { [weak self] (config) in
                guard let `self` = self else { return }
                UserGeneralSettingsImpl.logger.info("openSettingLog/api/deviceNotifySetting/getRes: ok "
                                                    + "atNotifyOpen: \(config.atNotifyOpen), notifyDisable: \(config.notifyDisable) notifySpecialFocus: \(config.notifySpecialFocus)")
                self.notifyConfig.atNotifyOpen = config.atNotifyOpen
                self.notifyConfig.notifyDisable = config.notifyDisable
                self.notifyConfig.notifySpecialFocus = config.notifySpecialFocus
                self.notifyConfig.notifySounds = config.notifySounds

                var dict: [String: String] = [:]
                config.notifySounds.items.forEach { item in
                    dict[item.key] = item.value
                }

                DispatchQueue.global().async {
                    KVPublic.Notify.notifySounds.setValue(dict)
                }
            }, onError: { error in
                UserGeneralSettingsImpl.logger.error("openSettingLog/api/deviceNotifySetting/getRes: error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    /// 从服务端获取notifyConfig
    func fetchDeviceNotifySettingFromServer() {
        self.fetchDeviceNotifySetting(strategy: .forceServer)
    }

    private func setProperties(fieldGroups: [String: String]) {
        /// non-atomic
        if let createQuasiMessageConfig = CreateQuasiMessageConfig(fieldGroups: fieldGroups) {
            self.createQuasiMessageConfig = createQuasiMessageConfig
        }
        if let sendVideoConfig = SendVideoConfig(fieldGroups: fieldGroups) {
            self.sendVideoConfig = sendVideoConfig
        }
        if let videoCompress = MessengerVideoCompress(fieldGroups: fieldGroups) {
            self.videoCompress.accept(videoCompress)
        }
        if let fileUploadSizeLimit = FileUploadSizeLimit(fieldGroups: fieldGroups) {
            self.fileUploadSizeLimit.accept(fileUploadSizeLimit)
        }
        if let skipTestConfig = SkipTestConfig(fieldGroups: fieldGroups) {
            self.skipTestConfig.accept(skipTestConfig)
        }
        if let originVideoCompress = OriginVideoCompressConfig(fieldGroups: fieldGroups) {
            self.originVideoCompress.accept(originVideoCompress)
        }
        let abSetting = Tracker.experimentValue(key: "ve_synthesis_settings_ab_config", shouldExposure: true) as? [String: [String: Any]]
        if let videoSynthesisSetting = VideoSynthesisSetting(fieldGroups: fieldGroups, abConfig: abSetting) {
            self.videoSynthesisSetting.accept(videoSynthesisSetting)
        }
        if let videoPreprocessConfig = VideoPreprocessConfig(fieldGroups: fieldGroups) {
            self.videoPreprocessConfig.accept(videoPreprocessConfig)
        }
        if let groupConfig = GroupConfig(fieldGroups: fieldGroups) {
            self.groupConfig = groupConfig
        }
        if let userGrowthConfig = UserGrowthConfig(fieldGroups: fieldGroups) {
            self.userGrowthConfig = userGrowthConfig
        }
        if let pushDowngradeAppLagConfig = PushDowngradeAppLagConfig(fieldGroups: fieldGroups) {
            self.pushDowngradeAppLagConfig = pushDowngradeAppLagConfig
        }
        if let messagePreProcessConfig = MessagePreProcessConfig(fieldGroups: fieldGroups) {
            self.messagePreProcessConfig = messagePreProcessConfig
        }
        if let deviceClassifyConfig = DeviceClassifyConfig(fieldGroups: fieldGroups) {
            self.deviceClassifyConfig = deviceClassifyConfig
        }
        if let gifLoadConfig = GIFLoadConfig(filedGroups: fieldGroups) {
            self.gifLoadConfig = gifLoadConfig
        }
        if let messageBubbleFoldConfig = MessageBubbleFoldConfig(fieldGroups: fieldGroups) {
            self.messageBubbleFoldConfig = messageBubbleFoldConfig
        }
        if let chatTabAddUGLinkConfig = ChatTabAddUGLinkConfig(fieldGroups: fieldGroups) {
            self.chatTabAddUGLinkConfig = chatTabAddUGLinkConfig
        }
        if let chatSecureViewEnableConfig = ChatSecureViewEnableConfig(fieldGroups: fieldGroups) {
            self.chatSecureViewEnableConfig = chatSecureViewEnableConfig
        }
        if let memberListNonDepartmentConfig = MemberListNonDepartmentConfig(fieldGroups: fieldGroups) {
            self.memberListNonDepartmentConfig = memberListNonDepartmentConfig
        }

        /// atomic
        let chatPinOnboardingDetailLinkConfig = ChatPinOnboardingDetailLinkConfig(fieldGroups: fieldGroups)
        let bgTaskConfig = BGTaskConfig(fieldGroups: fieldGroups)
        let helpdeskCommon = HelpdeskCommon(fieldGroups: fieldGroups)
        let dominManagePolicyConfig = DominManagePolicyConfig(fieldGroups: fieldGroups)
        let contactsConfig = ContactsConfig(fieldGroups: fieldGroups)
        let ugBannerConfig = UGBannerConfig(fieldGroups: fieldGroups)
        let spotlightWorkspaceConfig = SpotlightWorkspaceConfig(fieldGroups: fieldGroups)
        let messengerFileConfig = MessengerFileConfig(fieldGroups: fieldGroups)
        let helpCenterDomainConfig = HelpCenterBizDomainConfig(fieldGroups: fieldGroups)
        let bitableGroupNoteConfig = BitableGroupNoteConfig(fieldGroups: fieldGroups)
        self.rwLock.wlock()
        if let value = bitableGroupNoteConfig {
            self._bitableGroupNoteConfig.setNonatomic(value)
        }
        if let value = chatPinOnboardingDetailLinkConfig {
            self._chatPinOnboardingDetailLinkConfig.setNonatomic(value)
        }
        if let value = bgTaskConfig {
            self._bgTaskConfig.setNonatomic(value)
        }
        if let value = helpdeskCommon {
            self._helpdeskCommon.setNonatomic(value)
        }
        if let value = dominManagePolicyConfig {
            self._dominManagePolicyConfig.setNonatomic(value)
        }
        if let value = contactsConfig {
            self._contactsConfig.setNonatomic(value)
        }
        if let value = ugBannerConfig {
            self._ugBannerConfig.setNonatomic(value)
        }
        if let value = spotlightWorkspaceConfig {
            self._spotlightWorkspaceConfig.setNonatomic(value)
        }
        if let value = messengerFileConfig {
            self._messengerFileConfig.setNonatomic(value)
        }
        if let value = helpCenterDomainConfig {
            self._helpDeskBizDomainConfig.setNonatomic(value)
        }
        self.rwLock.unlock()

        if ugBannerConfig != nil {
            self.ugBannerConfigChangeVariable.accept(())
        }
    }

    /// 拉取字节云平台配置
    func fetchCloudSetting() {
        let guideConfigKey = "guide_config_data"
        let customConfig = "custom_exception_config"
        let fields = [HelpdeskCommon.HelpdeskCommonRequestKey,
                      FileUploadSizeLimit.key,
                      SkipTestConfig.key,
                      SendVideoConfig.key,
                      BGTaskConfig.key,
                      MessengerVideoCompress.key,
                      OriginVideoCompressConfig.key,
                      GroupConfig.key,
                      UserGrowthConfig.key,
                      DominManagePolicyConfig.key,
                      ContactsConfig.key,
                      guideConfigKey,
                      customConfig,
                      UGBannerConfig.key,
                      GadgetEngineConfig.key,
                      SpotlightWorkspaceConfig.key,
                      HelpCenterBizDomainConfig.key,
                      OPMonitorConfig.key,
                      PushDowngradeAppLagConfig.key,
                      MessagePreProcessConfig.key,
                      DeviceClassifyConfig.key,
                      GIFLoadConfig.key,
                      VideoSynthesisSetting.key,
                      VideoPreprocessConfig.key,
                      MessengerFileConfig.key,
                      MessageBubbleFoldConfig.key,
                      ChatTabAddUGLinkConfig.key,
                      ChatPinOnboardingDetailLinkConfig.key,
                      BitableGroupNoteConfig.key,
                      MemberListNonDepartmentConfig.key,
                      ChatSecureViewEnableConfig.key]
        self.configAPI.fetchSettingsRequest(fields: fields)
            .subscribe(onNext: { [weak self] (fieldGroups) in
                guard let `self` = self else { return }
                self.setProperties(fieldGroups: fieldGroups)
            }).disposed(by: self.disposeBag)
    }

    /// 拉取翻译设置
    func fetchTranslateLanguageSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<Void> {
        return self.configAPI.fetchTranslateLanguageSetting(strategy: strategy).do(onNext: { [weak self] (setting) in
            guard let `self` = self else { return }
            self.translateLanguageSettingVariable.accept(setting)
            UserGeneralSettingsImpl.logger.info("fetchTranslateLanguageSetting translateInfo: \(setting.info())")
        }).map({ _ in })
    }

    /// 设置自动翻译一级总开关
    func setAutoTranslateGlobalSwitch(isOpen: Bool) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        newSetting.autoTranslateGlobalSwitch = isOpen
        UserGeneralSettingsImpl.logger.info("setAutoTranslateGlobalSwitch begin translateInfo: \(newSetting.info())")
        /// 总开关打开下需要刷新页面Scopes的disable自动翻译文案，依赖二三级推送的更新, 不宜直接使用newSetting更新
        return self.configAPI.setAutoTranslateGlobalSwitch(isOpen: isOpen).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("setAutoTranslateGlobalSwitch error translateInfo: \(oldSetting.info())")
            self.translateLanguageSettingVariable.accept(oldSetting)
        })
    }

    /// 设置翻译目标语言
    func updateTranslateLanguageSetting(language: String) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        newSetting.targetLanguage = language
        UserGeneralSettingsImpl.logger.info("updateTranslateLanguageSetting begin translateInfo: \(newSetting.info())")
        self.translateLanguageSettingVariable.accept(newSetting)

        return self.configAPI.updateTranslateLanguageSetting(language: language).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("updateTranslateLanguageSetting error translateInfo: \(oldSetting.info())")
            self.translateLanguageSettingVariable.accept(oldSetting)
        })
    }

    /// 设置翻译语言key->翻译效果
    func updateLanguagesConfiguration(globalConf: RustPB.Im_V1_LanguagesConfiguration?, languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]?) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        if let conf = globalConf {
            newSetting.globalConf = conf
        }
        if let languagesConf = languagesConf {
            newSetting.languagesConf = languagesConf
        }
        UserGeneralSettingsImpl.logger.info("updateLanguagesConfiguration begin translateInfo: \(newSetting.info())")
        self.translateLanguageSettingVariable.accept(newSetting)

        return self.configAPI.updateLanguagesConfiguration(globalConf: globalConf, languagesConf: languagesConf).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("updateLanguagesConfiguration error translateInfo: \(oldSetting.info())")
            self.translateLanguageSettingVariable.accept(oldSetting)
        })
    }

    /// 设置翻译显示翻译效果开关(一级)
    func updateGlobalLanguageDisplayConfig(globalConf: RustPB.Im_V1_LanguagesConfiguration) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        newSetting.globalConf = globalConf
        /// update each config rule in language list
        newSetting.srcLanguagesConfig.keys.forEach {
            if var srcConfig = newSetting.srcLanguagesConfig[$0] {
                srcConfig.rule = globalConf.rule
                newSetting.srcLanguagesConfig[$0] = srcConfig
            }
        }
        UserGeneralSettingsImpl.logger.info("updateGlobalLanguageDisplayConfig begin translateInfo: \(newSetting.info())")
        self.translateLanguageSettingVariable.accept(newSetting)

        return self.configAPI.updateGlobalLanguageDisplayConfig(globalConf: globalConf).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("updateGlobalLanguageDisplayConfig error translateInfo: \(oldSetting.info())")
            self.translateLanguageSettingVariable.accept(oldSetting)
        })
    }

    /// 设置翻译源语言(三级) 的翻译效果
    func updateLanguagesConfigurationV2(srcLanguagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        /// update each config rule in language list
        newSetting.srcLanguagesConfig.keys.forEach {
            if var srcConfig = newSetting.srcLanguagesConfig[$0] {
                srcConfig.rule = srcLanguagesConf[$0]?.rule ?? srcConfig.rule
                newSetting.srcLanguagesConfig[$0] = srcConfig
                UserGeneralSettingsImpl.logger.debug("""
                    translate: srcLanguagesConf rule = \(String(describing: srcConfig.rule)),
                    srcConfig rule = \(srcConfig.rule),
                    srcLanguagesConf = \(String(describing: newSetting.srcLanguagesConfig[$0]))
                    """)
            }
        }
        UserGeneralSettingsImpl.logger.info("updateLanguagesConfigurationV2 begin translateInfo: \(newSetting.info())")
        self.translateLanguageSettingVariable.accept(newSetting)

        return self.configAPI.updateLanguagesConfigurationV2(srcLanguagesConf: srcLanguagesConf).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("updateLanguagesConfigurationV2 error translateInfo: \(oldSetting.info())")
            self.translateLanguageSettingVariable.accept(oldSetting)
        })
    }

    /// 修改源语种自动翻译设置(二级)scopes范围
    func updateAutoTranslateScope(scope: Int) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        newSetting.translateScope = scope

        let translateSettingsMainFGEnable = featureGatingService.staticFeatureGatingValue(with: "translate.settings.v2.enable")
        let updatedNewSettings = updateSrcLanguagesScopesAfterGlobleScopeChanges(newSetting: newSetting, oldSetting: oldSetting)
        let settings = translateSettingsMainFGEnable ? updatedNewSettings : newSetting
        UserGeneralSettingsImpl.logger.info("updateAutoTranslateScope begin scope = \(scope), translateInfo: \(settings.info())")

        return self.configAPI.updateAutoTranslateScope(scope: scope).do(
            onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.translateLanguageSettingVariable.accept(settings)
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                UserGeneralSettingsImpl.logger.info("updateAutoTranslateScope error translateInfo: \(oldSetting.info())")
                self.translateLanguageSettingVariable.accept(oldSetting)
            })
    }

    /// 修改源语种自动翻译设置(三级)scopes范围
    func updateSrcLanguageScopes(srcLanguagesScope: Int, language: String) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        if var srcConfig = newSetting.srcLanguagesConfig[language] {
            srcConfig.scopes = Int32(srcLanguagesScope)
            newSetting.srcLanguagesConfig[language] = srcConfig
        }
        UserGeneralSettingsImpl.logger.debug("check srcLanguagesConfig = \(String(describing: newSetting.srcLanguagesConfig[language])), srcLanguagesScope = \(srcLanguagesScope)")
        UserGeneralSettingsImpl.logger.info("updateSrcLanguageScopes begin translateInfo: \(newSetting.info(srcLanguage: language))")
        self.translateLanguageSettingVariable.accept(newSetting)

        return self.configAPI.updateSrcLanguageScopes(srcLanguagesScope: srcLanguagesScope, language: language).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("updateSrcLanguageScopes error translateInfo: \(oldSetting.info(srcLanguage: language))")
            self.translateLanguageSettingVariable.accept(oldSetting)
        })
    }

    /// 设置不自动翻译的语言，这里传该用户后期设置过的全量数据
    func updateDisableAutoTranslateLanguages(languages: [String]) -> Observable<Void> {
        let oldSetting: TranslateLanguageSetting = self.translateLanguageSetting
        var newSetting: TranslateLanguageSetting = self.translateLanguageSetting
        newSetting.disAutoTranslateLanguagesConf = languages
        UserGeneralSettingsImpl.logger.info("updateDisableAutoTranslateLanguages begin translateInfo: \(newSetting.info())")
        self.translateLanguageSettingVariable.accept(newSetting)

        return self.configAPI.updateDisableAutoTranslateLanguages(languages: languages).do(onError: { [weak self] (_) in
            guard let `self` = self else { return }
            UserGeneralSettingsImpl.logger.info("updateDisableAutoTranslateLanguages error translateInfo: \(oldSetting.info())")
            self.translateLanguageSettingVariable.accept(oldSetting)
        }).map({ _ in })
    }
}

extension UserGeneralSettingsImpl {
    /// 自动翻译二级全局开关的某个scope切换时，更新源语言列表对应的scope状态
    private func updateSrcLanguagesScopesAfterGlobleScopeChanges(newSetting: TranslateLanguageSetting, oldSetting: TranslateLanguageSetting) -> TranslateLanguageSetting {
        /// enumate the srcLanguages config, update the change scope
        let globalScope = Int32(abs(newSetting.translateScope - oldSetting.translateScope))
        /// 全局开关scope为0，代表全局开关关闭，打开则>0
        guard globalScope != 0 else { return oldSetting }
        let _newSetting = newSetting
        let globalScopes = Int32(newSetting.translateScope)
        let isGlobalScopeOpen = (globalScopes & globalScope) != 0
        UserGeneralSettingsImpl.logger.debug("""
            updateSrcLanguagesScopesAfterGlobleScopeChanges isGlobalScopeOpen = \(isGlobalScopeOpen),
            globalScopes = \(globalScopes), globalScope = \(globalScope)
            """)
        /* 这里本地数据计算有误，暂时注掉
        /// update each config in each srclanguage
        newSetting.srcLanguagesConfig.keys.forEach {
            if var srcConfig = newSetting.srcLanguagesConfig[$0] {
                let isScopeOpen = (srcConfig.scopes & globalScope) != 0
                if isGlobalScopeOpen, !isScopeOpen {
                    /// 该scope切为全局打开， 需要打开原来源语言关闭的Scope
                    srcConfig.scopes += globalScope
                    _newSetting.srcLanguagesConfig[$0] = srcConfig
                } else if !isGlobalScopeOpen, isScopeOpen {
                    /// 该scope切为全局关闭 需要关闭原来源语言打开的Scope
                    srcConfig.scopes -= globalScope
                    _newSetting.srcLanguagesConfig[$0] = srcConfig
                }
            }
        }
        */
        return _newSetting
    }
}

extension UserGeneralSettingsImpl {

    private func fetchGeneralSetting() {
        // 企业实体词
        self.configAPI.getEnterpriseEntityWordConfig()
            .subscribe(onNext: { [weak self] (response) in
                UserGeneralSettingsImpl.logger.info("getEnterpriseEntityWordConfig response: \(response)")
                guard let self = self else { return }
                let setting = response.setting.nautilusSetting
                KVPublic.Setting.enterpriseEntityTenantSwitch.setValue(setting.isTenantEnabled, forUser: self.userId)
                KVPublic.Setting.enterpriseEntityTenantSwitch.setValue(true, forUser: self.userId)
                KVPublic.Setting.enterpriseEntityMessage.setValue(setting.messengerSetting.isEnabled, forUser: self.userId)
                KVPublic.Setting.enterpriseEntityMinutes.setValue(setting.minutesSetting.isEnabled, forUser: self.userId)
                KVPublic.Setting.enterpriseName.setValue(setting.brandSetting.brandName, forUser: self.userId)
                if self.featureGatingService.staticFeatureGatingValue(with: "ai.abbreviation.docs") {
                    KVPublic.Setting.enterpriseEntityDoc.setValue(setting.docsSetting.isEnabled, forUser: self.userId)
                }
            }, onError: { (error) in
                UserGeneralSettingsImpl.logger.error("getEnterpriseEntityWordConfig error: \(error)")
            }).disposed(by: disposeBag)

        // 智能纠错
        if featureGatingService.staticFeatureGatingValue(with: "ai.smartcorrect.message") {
            self.configAPI.getSmartCorrectConfig().subscribe(onNext: { [weak self] (response) in
                UserGeneralSettingsImpl.logger.info("getSmartCorrectConfig sucess: \(response)")
                guard let self = self else { return }
                KVPublic.Setting.smartCorrect.setValue(
                    response.correctionSetting.messengerSetting.isEnabled,
                    forUser: self.userId
                )
            }, onError: { (error) in
                UserGeneralSettingsImpl.logger.error("getSmartCorrectConfig error: \(error)")
            }).disposed(by: disposeBag)
        }

        if featureGatingService.staticFeatureGatingValue(with: "suite.ai.smart_compose.mobile.enabled") {
            self.configAPI.getSmartComposeConfig().subscribe(onNext: { [weak self] (response) in
                UserGeneralSettingsImpl.logger.info("getSmartComposeConfig sucess: \(response)")
                guard let self = self else { return }
                KVPublic.Setting.smartComposeMessage.setValue(
                    response.composerSetting.isMessengerEnabled,
                    forUser: self.userId
                )
            }, onError: { (error) in
                UserGeneralSettingsImpl.logger.error("getSmartComposeConfig error: \(error)")
            }).disposed(by: disposeBag)
        }
    }
}
