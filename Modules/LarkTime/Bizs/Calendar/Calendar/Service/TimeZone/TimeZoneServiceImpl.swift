//
//  TimeZoneServiceImpl.swift
//  Calendar
//
//  Created by 张威 on 2020/1/16.
//

import RxCocoa
import RxSwift
import ThreadSafeDataStructure
import LarkContainer

class TimeZoneSelectServiceImpl: TimeZoneSelectService, UserResolverWrapper {

    internal let disposeBag = DisposeBag()
    let api: CalendarRustAPI

    let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        api = try userResolver.resolve(assert: CalendarRustAPI.self)
    }

    func getRecentTimeZones() -> Observable<[TimeZoneModel]> {
        api.getRecentTimeZoneIds()
            .map { ids in
                ids.map { TimeZone(identifier: $0) }
                    .filter { $0 != nil }
                    .map { $0! }
            }
            .observeOn(MainScheduler.instance)
    }

    func deleteRecentTimeZones(by ids: [TimeZoneModel.ID]) -> Observable<Void> {
        api.deleteRecentTimeZones(by: ids).observeOn(MainScheduler.instance)
    }

    func upsertRecentTimeZones(with ids: [TimeZoneModel.ID]) -> Observable<Void> {
        api.upsertRecentTimeZone(with: ids).observeOn(MainScheduler.instance)
    }

    func getCityTimeZones(by query: String) -> Observable<[TimeZoneCityPair]> {
        api.getCityTimeZones(by: query).observeOn(MainScheduler.instance)
    }
}

final class TimeZoneServiceImpl: TimeZoneSelectServiceImpl, TimeZoneService {
    private var preferredTimeZoneSubject: BehaviorRelay<TimeZoneModel>
    private var selectedTimeZoneSubject: BehaviorRelay<TimeZoneModel>
    private var additionalTimeZoneRelay: BehaviorRelay<TimeZoneModel?>
    private var showAdditionalTimeZoneRelay: BehaviorRelay<Bool>

    // 使用 `""` 表示设备时区
    private static let systemTimeZoneId = ""
    // 标记是否同步系统时区
    private var shouldSyncSystemTimeZone: Bool = false

    private let disposebag = DisposeBag()

    override init(userResolver: UserResolver) throws {
        preferredTimeZoneSubject = BehaviorRelay(value: TimeZone.current)
        selectedTimeZoneSubject = BehaviorRelay(value: TimeZone.current)
        additionalTimeZoneRelay = BehaviorRelay(value: TimeZone(identifier: KVValues.selectedAdditionalTimeZone))
        showAdditionalTimeZoneRelay = BehaviorRelay(value: KVValues.isShowAdditionalTimeZone)
        try super.init(userResolver: userResolver)
        observeSystemTimeZone()
    }

    func prepare() {
        loadPreferredTimeZone()
    }

    private func observeSystemTimeZone() {
        NotificationCenter.default.rx.notification(.NSSystemTimeZoneDidChange)
            .observeOn(MainScheduler.instance)
            .map { _ in TimeZone.current }
            .filter { [weak self] timeZone -> Bool in
                guard let self = self else { return false }
                guard self.shouldSyncSystemTimeZone else { return false }
                guard self.preferredTimeZone.value.identifier != timeZone.identifier else {
                    return false
                }
                return true
            }
            .bind(to: self.preferredTimeZoneSubject)
            .disposed(by: disposeBag)
    }

    private func loadPreferredTimeZone() {
        if FeatureGating.additionalTimeZoneOption(userID: self.userResolver.userID) {
            self.shouldSyncSystemTimeZone = true
            return
        }
        api.getPreferredTimeZoneId()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] id in
                guard let self = self else { return }

                let timeZone: TimeZone
                if SettingService.shared().getSetting().useSystemTimeZone {
                    self.shouldSyncSystemTimeZone = true
                    timeZone = TimeZone.current
                } else {
                    self.shouldSyncSystemTimeZone = false
                    timeZone = TimeZone(identifier: id) ?? TimeZone.current
                }

                let curTimeZone = self.preferredTimeZoneSubject.value
                guard curTimeZone.identifier != timeZone.identifier else { return }
                self.preferredTimeZoneSubject.accept(timeZone)
            })
            .disposed(by: disposeBag)
    }

    var preferredTimeZone: BehaviorRelay<TimeZoneModel> {
        preferredTimeZoneSubject
    }

    var selectedTimeZone: BehaviorRelay<TimeZoneModel> {
        selectedTimeZoneSubject
    }

    var additionalTimeZone: BehaviorRelay<TimeZoneModel?> {
        additionalTimeZoneRelay
    }

    var showAdditionalTimeZone: BehaviorRelay<Bool> {
        showAdditionalTimeZoneRelay
    }

    func setPreferredTimeZone(_ timeZone: TimeZoneModel) -> Observable<Void> {
         return api.setPreferredTimeZone(with: timeZone.identifier)
            .flatMap { SettingService.shared().loadSettingObserable().map { _ in () } }
            .do(onNext: { [weak self] in
                self?.loadPreferredTimeZone()
            })
            .observeOn(MainScheduler.instance)
    }

    func setAdditionalTimeZone(_ identifier: String) {
        KVValues.selectedAdditionalTimeZone = identifier
        additionalTimeZoneRelay.accept(TimeZone(identifier: identifier))
    }

    func setShowAdditionalTimeZone(_ isShow: Bool) {
        KVValues.isShowAdditionalTimeZone = isShow
        showAdditionalTimeZone.accept(isShow)
    }

    func saveAdditionalTimeZone(additionalTimeZones: [String],
                                onError: (() -> Void)? = nil) {
        var setting = SettingService.shared().getSetting()
        setting.additionalTimeZones = additionalTimeZones
        SettingService.shared().updateSaveSetting(setting,
                                                  shouldPublishUpdateView: true,
                                                  shouldPublishUpdateCalendarLoader: false,
                                                  editOtherTimezones: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] _ in
                guard let self = self else { return }
                onError?()
                let additionalTimeZones = SettingService.shared().getSetting().additionalTimeZones
                if let timeZone = self.additionalTimeZone.value {
                    if !additionalTimeZones.contains(timeZone.identifier) {
                        self.setAdditionalTimeZone("")
                    }
                } else {
                    if let timeZone = additionalTimeZones.first {
                        self.setAdditionalTimeZone(timeZone)
                    }
                }
            }).disposed(by: disposebag)
    }
}
