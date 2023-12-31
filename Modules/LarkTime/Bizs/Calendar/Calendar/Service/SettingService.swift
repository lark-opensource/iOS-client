//
//  SettingService.swift
//  Calendar
//
//  Created by 白言韬 on 2020/9/24.
//

import Foundation
import CalendarFoundation
import RxSwift
import RustPB
import ThreadSafeDataStructure
import RxCocoa
import CryptoSwift
import LarkContainer
import LarkStorage
import EEAtomic

final class SettingService {

    private init() {}
    private static let _shared = SettingService()

    /// 数据有为空的风险
    class func shared() -> SettingService {
        return _shared
    }

    class func rxShared() -> Observable<SettingService> {
        if _shared.isSettingEmpty {
            return _shared.loadSettingObserable()
        }
        return .just(_shared)
    }

    let remindNoDeclineChanged: PublishSubject<Void> = .init()
    @Provider var calendarApi: CalendarRustAPI
    @Provider var calendarDependency: CalendarDependency
    @Provider var pushService: RustPushService
    @Provider var localRefreshService: LocalRefreshService
    private let disposeBag = DisposeBag()
    var stateManager = ServiceStateManager()

    var feedTempTopObservable: Observable<Bool> {
        self.pushService.rxFeedTempTop.asObserver()
    }

    func setDependency(
        calendarWorkQueue: DispatchQueue,
        cipher: CalendarCipher?
    ) {
        self.calendarWorkQueue = calendarWorkQueue
        self.addPushListener(pushPub: pushService.rxSettingRefresh,
                             tenantSettingUpdate: pushService.rxTenantSettingChanged)
        self.stateManager.delegate = self

        do {
            self.aesCipher = try cipher?.generateAES()
        } catch {
            operationLog(message: "xxx generate cipher error")
        }
    }

    // MARK: - 数据源
    private var isSettingEmpty = true
    private var setting: SafeAtomic<Setting> = SettingModel() + .readWriteLock {
        didSet {
            isSettingEmpty = false
        }
    }

    private(set) var settingExtension = SettingExtension(
        eventAttendeeLimit: 2000,
        attendeeTimeZoneEnableLimit: 300,
        exchangeHelperUrl: "",
        departmentMemberUpperLimit: 1000,
        outlookHelperUrl: ""
    )
    var is12HourStyle: BehaviorRelay<Bool> {
        return calendarDependency.is12HourStyle
    }

    // 日程参与人数量总限制上限
    var finalEventAttendeeLimit: Int {
        if let tenantSetting = self.tenantSetting,
           tenantSetting.hasAttendeeNumberControlConfig {
            return Int(tenantSetting.attendeeNumberControlConfig.attendeeMaxCount)
        }
        // attendeeNumberControlConfig 没有的话，走 settingExtension 兜底
        return self.settingExtension.eventAttendeeLimit
    }

    /// 日程参与人权限设置
    /// 取值方式：1. FG外 guestCanInvite 2. 优先取个人设置  3.其次取租户配置(admin fg 开启下) 4. guestCanModify进行兜底
    /// 影响范围：1. 个人设置页面展示  2. 日程创建页面默认展示
    var guestPermission: GuestPermission {
        guard FG.guestPermission else { return .guestCanInvite }
        if let permission = setting.value.guestPermission {
            return permission
        } else if let permission = tenantSetting?.guestPermission,
                  FG.adminGuestPermission {
            return permission
        } else {
            return .guestCanModify
        }
    }

    func getSetting() -> Setting {
        return setting.value
    }

    // MARK: - 通知
    var updateViewSettingPublish = PublishSubject<Void>()
    var updateAdditionalTimeZoneSettingPublish = PublishSubject<Void>()

    private func addPushListener(
        pushPub: Observable<Void>,
        tenantSettingUpdate: PublishSubject<Calendar_V1_CalendarTenantSettingsRow>
    ) {
        pushPub.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            if self.stateManager.isActive {
                self.loadSetting()
            } else {
                self.stateManager.isClean = false
            }
        }).disposed(by: self.disposeBag)

        tenantSettingUpdate
            .flatMapLatest { [weak self] requestParam -> Observable<CalendarTenantSetting> in
                guard let self = self else { return .empty() }
                return self.calendarApi.getCalendarTenantSetting(with: requestParam, from: .local)
            }
            .catchErrorJustReturn(Self.defaultTenantSetting)
            .subscribeForUI { [weak self] setting in
                if setting.hasResourceSubscribeCondition {
                    self?.tenantSetting?.resourceSubscribeCondition = setting.resourceSubscribeCondition
                }
                if setting.hasAttendeeNumberControlConfig {
                    self?.tenantSetting?.attendeeNumberControlConfig = setting.attendeeNumberControlConfig
                }
                if setting.hasCalendarAdminAccessConfig {
                    self?.tenantSetting?.calendarAdminAccessConfig = setting.calendarAdminAccessConfig
                }
                if setting.hasCalendarEventEditSetting {
                    self?.tenantSetting?.calendarEventEditSetting = setting.calendarEventEditSetting
                }
            }.disposed(by: self.disposeBag)
    }

    // MARK: - 数据加载
    func prepare(onFinish: @escaping () -> Void, loadSettingOnFinish: ((Setting) -> Void)? = nil) {
        self.loadDiskCache(onSucess: onFinish) { [weak self] in
            self?.syncLocalSetting(onFinish: onFinish)
        }
        self.loadSetting(loadSettingOnFinish: loadSettingOnFinish)
        self.updateFullTenantSettingFromServer()
        self.loadSettingExtension()
    }

    func syncLocalSetting(onFinish: @escaping () -> Void) {
        DispatchQueue.global().async {
            TimerMonitorHelper.shared.launchTimeTracer?.loadSetting.start()
            self.calendarApi
                .getCalendarSettings()
                .subscribe(onNext: { [weak self] (setting) in
                    TimerMonitorHelper.shared.launchTimeTracer?.loadSetting.end()
                    self?.updateSetting(setting)
                    onFinish()
                }, onError: { (_) in
                    onFinish()
                }).disposed(by: self.disposeBag)
        }
    }

    private var isFirstTime = true
    private func loadSetting(loadSettingOnFinish: ((Setting) -> Void)? = nil) {
        let getCalendarSettingsTwiceIfError = calendarApi.getCalendarSettingsTwiceIfError()
        if FeatureGating.feedTopEvent(userID: calendarApi.userResolver.userID) {
            let getFeedTopEventSetting = calendarApi.getFeedTopEventSettingRequest()
            Observable.zip(getCalendarSettingsTwiceIfError, getFeedTopEventSetting.materialize())
                .subscribeOn(calendarApi.requestScheduler)
                .subscribe(onNext: { [weak self] (setting, res) in
                    var newSetting = setting
                    newSetting.feedTopEvent = res.element ?? false
                    self?.processSetting(setting: newSetting, loadSettingOnFinish: loadSettingOnFinish)
                }, onError: { [weak self] (_) in
                    self?.updateSetting(SettingModel())
                }).disposed(by: self.disposeBag)
        } else {
            getCalendarSettingsTwiceIfError
                .subscribeOn(calendarApi.requestScheduler)
                .subscribe(onNext: { [weak self] (setting) in
                    self?.processSetting(setting: setting, loadSettingOnFinish: loadSettingOnFinish)
                }, onError: { [weak self] (_) in
                    self?.updateSetting(SettingModel())
                }).disposed(by: self.disposeBag)
        }
    }

    private func processSetting(setting: Setting, loadSettingOnFinish: ((Setting) -> Void)? = nil) {
        if setting.remindNoDecline != self.setting.value.remindNoDecline || self.isFirstTime {
            self.remindNoDeclineChanged.onNext(())
            self.isFirstTime = false
        }
        let oldSetting = self.setting.value
        self.updateSetting(setting)
        loadSettingOnFinish?(setting)
        if setting.shouldUpdateEventView(oldSetting) {
            self.updateViewSettingPublish.onNext(())
        }

        if setting.additionalTimeZones != oldSetting.additionalTimeZones {
            self.updateAdditionalTimeZoneSettingPublish.onNext(())
        }

        self.stateManager.isClean = true
    }

    func loadSettingObserable() -> Observable<SettingService> {
        let getCalendarSettingsTwiceIfError = calendarApi.getCalendarSettingsTwiceIfError()
        if FeatureGating.feedTopEvent(userID: calendarApi.userResolver.userID) {
            let getFeedTopEventSetting = calendarApi.getFeedTopEventSettingRequest()
            return Observable.zip(getCalendarSettingsTwiceIfError, getFeedTopEventSetting.materialize())
                .subscribeOn(calendarApi.requestScheduler)
                .map { [weak self] (setting, res) -> SettingService in
                    var newSetting = setting
                    newSetting.feedTopEvent = res.element ?? false
                    self?.processSetting(setting: newSetting)
                    return Self._shared
                }
        } else {
            return getCalendarSettingsTwiceIfError
                .subscribeOn(calendarApi.requestScheduler)
                .map { [weak self] (setting) -> SettingService in
                    self?.processSetting(setting: setting)
                    return Self._shared
                }
        }
    }

    private func loadSettingExtension() {
        calendarApi.getSettingExtension()
            .subscribeOn(calendarApi.requestScheduler)
            .subscribe(onNext: { [weak self] (settingExtension) in
                self?.settingExtension = settingExtension
            })
            .disposed(by: self.disposeBag)
    }

    // MARK: - 数据更新
    func updateSaveSetting(_ setting: Setting,
                           shouldPublishUpdateView: Bool,
                           shouldPublishUpdateCalendarLoader: Bool,
                           editOtherTimezones: Bool = false) -> Observable<Void> {
        let saveCalendarSettings = self.calendarApi.saveCalendarSettings(setting: setting.getPB(), editOtherTimezones: editOtherTimezones)
        return saveCalendarSettings.do(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            if setting.remindNoDecline != self.setting.value.remindNoDecline {
                self.remindNoDeclineChanged.onNext(())
            }
            self.updateSetting(setting)
            if shouldPublishUpdateView {
                self.updateViewSettingPublish.onNext(())
            }
            if shouldPublishUpdateCalendarLoader {
                self.localRefreshService.rxCalendarNeedRefresh.onNext(())
            }
        })
    }

    func updateSaveFeedToTopSetting(_ setting: Setting) {
        self.calendarApi
            .patchFeedTopEventSettingRequest(value: setting.feedTopEvent)
            .subscribe(onNext: { [weak self] (_) in
                self?.updateSetting(setting)
            }).disposed(by: disposeBag)
    }

    private func updateSetting(_ value: Setting) {
        self.setting.value = value
        writeToDiscIfNeeded(value)
    }

    // MARK: - 磁盘缓存
    private var settingHash: Int = 0

    @SafeLazy
    private var cacheDir: IsoPath = {
        @Provider var calendarDependency: CalendarDependency
        return calendarDependency.userLibraryPath() + "home"
    }()
    private lazy var cachePath: IsoPath = {
        cacheDir + "setting"
    }()
    private var aesCipher: CryptoSwift.Cipher?
    private var calendarWorkQueue: DispatchQueue?

    private func loadDiskCache(onSucess: @escaping () -> Void, onError: @escaping () -> Void) {

        guard cachePath.exists,
            let aesCipher = self.aesCipher else {
                operationLog(message: "xxx no disk cache \(cachePath)")
                onError()
                return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                TimerMonitorHelper.shared.launchTimeTracer?.loadSetting.start()
                let cacheData = try Data.read(from: self.cachePath)

                guard let cacheSettingObject = NSKeyedUnarchiver.unarchiveObject(with: cacheData) as? SettingCacheObject else {
                    operationLog(message: "xxx cache unacrchvie error")
                    onError()
                    return
                }

                if let infoDecryptedData = try cacheSettingObject.info?.decrypt(cipher: aesCipher) {
                    let cacheInfo = NSKeyedUnarchiver.unarchiveObject(with: infoDecryptedData) as? HomeCacheInfoObject

                    let currentUser = self.calendarDependency.currentUser
                    guard cacheInfo?.userId == currentUser.id, cacheInfo?.tenantId == currentUser.tenantId else {
                        operationLog(message: "xxx account changed")
                        onError()
                        return
                    }
                }

                if let settingDecryptedData = try cacheSettingObject.setting?.decrypt(cipher: aesCipher) {
                    if self.isSettingEmpty {
                        let setting = try CalendarSetting(serializedData: settingDecryptedData)
                        self.setting.value = SettingModel(pb: setting)
                        self.settingHash = try setting.serializedData().hashValue
                        operationLog(message: "xxx load disk cache done \(self.settingHash)")
                    } else {
                        operationLog(message: "xxx Invalid loading, server has returned")
                    }
                }
                TimerMonitorHelper.shared.launchTimeTracer?.loadSetting.end()
                onSucess()
            } catch CipherError.decrypt {
                onError()
                operationLog(message: "xxx disk cache decrpyt error")
            } catch {
                onError()
                operationLog(message: "xxx serialized data error")
            }

        }
    }

    private func writeToDiscIfNeeded(_ value: Setting) {
        guard let aesCipher = self.aesCipher else {
                debugPrint("xxx 无需更新setting磁盘缓存")
                return
        }
        guard let calendarWorkQueue = calendarWorkQueue else {
            assertionFailureLog("calendarWorkQueue doesn't exist")
            return
        }
        let currentUser = calendarDependency.currentUser
        calendarWorkQueue.async {
            do {
                let settingData = try value.getPB().serializedData()
                let settingNewHash = settingData.hashValue
                guard settingNewHash != self.settingHash else {
                    return
                }
                let info = HomeCacheInfoObject(userId: currentUser.id,
                                               tenantId: currentUser.tenantId)
                let infoData = NSKeyedArchiver.archivedData(withRootObject: info)
                let infoEncryptedData = try infoData.encrypt(cipher: aesCipher)
                let settingEncryptedData = try settingData.encrypt(cipher: aesCipher)

                let instanceObject = SettingCacheObject(setting: settingEncryptedData, info: infoEncryptedData)
                let data = NSKeyedArchiver.archivedData(withRootObject: instanceObject)
                if !self.cachePath.exists {
                    try? self.cacheDir.createDirectory()
                    try self.cachePath.createFile()
                }

                try data.write(to: self.cachePath)
                operationLog(message: "xxx write to disc finish \(settingNewHash)")
                self.settingHash = settingNewHash
            } catch CipherError.encrypt {
                operationLog(message: "xxx encrypt error")
            } catch let error {
                operationLog(message: "xxx write file error \(error)")
            }
        }
    }

    var tenantSetting: CalendarTenantSetting?

    class func rxTenantSetting() -> Observable<CalendarTenantSetting> {
        if let setting = _shared.tenantSetting {
            return .just(setting)
        } else {
            return _shared.getFullTenantSettingFromLocal().take(1)
                .do { setting in
                    _shared.tenantSetting = setting
                }
        }
    }

    private func getFullTenantSettingFromLocal() -> Observable<CalendarTenantSetting> {
        var requestParam = Calendar_V1_CalendarTenantSettingsRow()
        requestParam.resourceDisplayType = true
        requestParam.enableMultiSelection = true
        requestParam.resourceSubscribeCondition = true
        requestParam.attendeeNumberControlConfig = true
        requestParam.disableEncrypt = true
        requestParam.calendarBotID = true
        requestParam.calendarAdminAccessConfig = true
        requestParam.calendarEventEditSetting = true
        return calendarApi.getCalendarTenantSetting(with: requestParam, from: .local)
            .debug("get setting from local")
            .catchError({ [weak self] error -> Observable<CalendarTenantSetting> in
                guard let self = self else { return Observable.error(error) }
                return self.calendarApi.getCalendarTenantSetting(with: requestParam, from: .server)
                    .debug("get setting from server")
                    .catchErrorJustReturn(SettingService.defaultTenantSetting)
            })
    }

    private func updateFullTenantSettingFromServer() {
        var requestParam = Calendar_V1_CalendarTenantSettingsRow()
        requestParam.resourceDisplayType = true
        requestParam.enableMultiSelection = true
        requestParam.resourceSubscribeCondition = true
        requestParam.attendeeNumberControlConfig = true
        requestParam.disableEncrypt = true
        requestParam.calendarBotID = true
        requestParam.calendarAdminAccessConfig = true
        requestParam.calendarEventEditSetting = true
        calendarApi.getCalendarTenantSetting(with: requestParam, from: .server)
            .debug("get setting from server")
            .subscribeForUI { [weak self] setting in
                print("get setting from server: \(setting.debugDescription)")
                self?.tenantSetting = setting
            }.disposed(by: disposeBag)
    }

    public static let defaultTenantSetting: CalendarTenantSetting = {
        var setting = CalendarTenantSetting()
        setting.resourceDisplayType = .buildingLike
        setting.enableMultiSelection = false
        var defaultCondition = Calendar_V1_ResourceSubscribeCondition()
        defaultCondition.limitPerDay = 0
        defaultCondition.forbidInRecursiveEvent = false
        defaultCondition.oneMostPerEvent = false
        setting.resourceSubscribeCondition = defaultCondition
        return setting
    }()

    // 用户从非辅助时区版本升级到辅助时区版本
    static func additionalTimeZoneUpgrade(setting: Setting,
                                          timeZoneService: TimeZoneService,
                                          settingProvider: SettingProvider,
                                          disposeBag: DisposeBag) {
        // 用户升级过，不执行升级逻辑
        if KVValues.didAdditionalTimeZoneUpgrade { return }
        KVValues.didAdditionalTimeZoneUpgrade = true
        // 用户在视图页中未设置时区或者设置的时区与当前设备时区相同，不执行升级逻辑
        if setting.useSystemTimeZone ||
            setting.timeZone == TimeZone.current.identifier { return }
        // 辅助时区列表中包含视图页设置的时区，直接将其转换为辅助时区
        let normalViewTimeZone = setting.timeZone
        var additionalTimeZones = setting.additionalTimeZones
        if additionalTimeZones.contains(normalViewTimeZone) {
            timeZoneService.setAdditionalTimeZone(normalViewTimeZone)
            timeZoneService.setShowAdditionalTimeZone(true)
            return
        }
        // 辅助时区列表不包含视图页设置的时区
        // 辅助时区列表已满，不执行升级逻辑
        if additionalTimeZones.count < AdditionalTimeZone.maxAdditionalTimeZones {
            // 辅助时区列表未满，将视图页设置的时区添加至辅助时区列表，展示辅助时区
            var newSetting = setting
            additionalTimeZones.append(normalViewTimeZone)
            newSetting.additionalTimeZones = additionalTimeZones
            settingProvider.updateSaveSetting(newSetting,
                                              shouldPublishUpdateView: true,
                                              shouldPublishUpdateCalendarLoader: false,
                                              editOtherTimezones: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                timeZoneService.setAdditionalTimeZone(normalViewTimeZone)
                timeZoneService.setShowAdditionalTimeZone(true)
            }).disposed(by: disposeBag)
        }
    }
}

// MARK: - ServiceStateManagerDelegate
extension SettingService: ServiceStateManagerDelegate {
    func reloadData() {
        loadSetting()
    }

    func clearData() {
        setting.value = SettingModel()
        tenantSetting = nil
        isSettingEmpty = true
    }
}

// 后端以key-map形式配置的，长期不会变更的配置
struct SettingExtension {
    var eventAttendeeLimit: Int
    var attendeeTimeZoneEnableLimit: Int
    var exchangeHelperUrl: String
    var departmentMemberUpperLimit: Int
    var outlookHelperUrl: String
    var vcCalendarMeeting: Int?
}

protocol SettingProvider: AnyObject {
    func getSetting() -> Setting
    func getEventViewSetting() -> EventViewSetting
    func getSettingExtension() -> SettingExtension
    func updateSaveSetting(_ setting: Setting,
                           shouldPublishUpdateView: Bool,
                           shouldPublishUpdateCalendarLoader: Bool,
                           editOtherTimezones: Bool) -> Observable<Void>
    func getServerSetting() -> Observable<Setting>
    /// 涉及日历页设置（皮肤，蒙白，每周起始）更改信号，使用方自己订阅
    var updateViewSettingPublish: PublishSubject<Void> { get }
    func prepare(onFinish: @escaping () -> Void, loadSettingOnFinish: ((Setting) -> Void)?)
}

// 仅用于兼容旧逻辑
final class SettingProviderMock: SettingProvider {
    func getSetting() -> Setting {
        return SettingService.shared().getSetting()
    }

    func getEventViewSetting() -> EventViewSetting {
        return SettingService.shared().getSetting()
    }

    func getSettingExtension() -> SettingExtension {
        return SettingService.shared().settingExtension
    }

    func updateSaveSetting(_ setting: Setting,
                           shouldPublishUpdateView: Bool,
                           shouldPublishUpdateCalendarLoader: Bool,
                           editOtherTimezones: Bool = false) -> Observable<Void> {
        return SettingService.shared().updateSaveSetting(setting, shouldPublishUpdateView: shouldPublishUpdateView, shouldPublishUpdateCalendarLoader: shouldPublishUpdateCalendarLoader, editOtherTimezones: editOtherTimezones)
    }

    func getServerSetting() -> Observable<Setting> {
        return SettingService.rxShared().map { $0.getSetting() }
    }

    var updateViewSettingPublish = SettingService.shared().updateViewSettingPublish

    func prepare(onFinish: @escaping () -> Void, loadSettingOnFinish: ((Setting) -> Void)?) {
        SettingService.shared().prepare(onFinish: onFinish, loadSettingOnFinish: loadSettingOnFinish)
    }
}
