//
//  TimeZoneServiceImpl.swift
//  Calendar
//
//  Created by 张威 on 2020/1/16.
//

import RxCocoa
import RxSwift
import ThreadSafeDataStructure

class TimeZoneSelectServiceImpl: TimeZoneSelectService {

    internal let api: TimeZoneApi
    internal let disposeBag = DisposeBag()

    init(api: TimeZoneApi) {
        self.api = api
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

    // 使用 `""` 表示设备时区
    private static let systemTimeZoneId = ""
    // 标记是否同步系统时区
    private var shouldSyncSystemTimeZone: Bool = false

    override init(api: TimeZoneApi) {
        preferredTimeZoneSubject = BehaviorRelay(value: TimeZone.current)
        super.init(api: api)
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
        api.getPreferredTimeZoneId()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] id in
                guard let self = self else { return }

                let timeZone: TimeZone
                if id == TimeZoneServiceImpl.systemTimeZoneId {
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

    func setPreferredTimeZone(_ timeZone: TimeZoneModel) -> Observable<Void> {
        var timeZoneId = timeZone.identifier
        if timeZone.identifier == TimeZone.current.identifier {
            timeZoneId = Self.systemTimeZoneId
        }
        return api.setPreferredTimeZone(with: timeZoneId)
            .do(onNext: { [weak self] in
                self?.loadPreferredTimeZone()
            })
            .observeOn(MainScheduler.instance)
    }
}
