//
//  TimeZoneService.swift
//  Calendar
//
//  Created by 张威 on 2020/1/19.
//

import Foundation
import RxCocoa
import RxSwift

protocol TimeZoneSelectService {

    /// 获取最近使用的时区
    func getRecentTimeZones() -> Observable<[TimeZoneModel]>

    /// 删除最近使用的时区
    func deleteRecentTimeZones(by ids: [TimeZoneModel.ID]) -> Observable<Void>

    /// 新增/更新最近使用的时区
    func upsertRecentTimeZones(with ids: [TimeZoneModel.ID]) -> Observable<Void>

    /// 时区-城市对，每个时区可能对应多个城市
    typealias TimeZoneCityPair = (timeZone: TimeZoneModel, cityNames: [String])
    /// 根据城市搜索时区
    func getCityTimeZones(by query: String) -> Observable<[TimeZoneCityPair]>

}

protocol TimeZoneService: TimeZoneSelectService {

    /// preferred TimeZone 表示当前用户所青睐的时区
    /// TODO: 实现一个类似于 `BehaviorRelay` 但是 readonly 的 `Observable`，替换 `BehaviorRelay`
    var preferredTimeZone: BehaviorRelay<TimeZoneModel> { get }

    var additionalTimeZone: BehaviorRelay<TimeZoneModel?> { get }

    var showAdditionalTimeZone: BehaviorRelay<Bool> { get }

    /// 存放日历外业务选择时区
    var selectedTimeZone: BehaviorRelay<TimeZoneModel> { get }

    /// 设置 preferred 时区
    func setPreferredTimeZone(_ timeZone: TimeZoneModel) -> Observable<Void>

    /// 设置辅助时区
    func setAdditionalTimeZone(_ identifier: String)

    /// 设置是否展示辅助时区
    func setShowAdditionalTimeZone(_ isShow: Bool)

    func prepare()

    func saveAdditionalTimeZone(additionalTimeZones: [String], onError: (() -> Void)?)
}
