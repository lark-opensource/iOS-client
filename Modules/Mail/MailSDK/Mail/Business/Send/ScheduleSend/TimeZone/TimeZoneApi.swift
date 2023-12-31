//
//  TimeZoneApi.swift
//  MailSDK
//
//  Created by majx on 2020/12/13.
//

import Foundation
import RxSwift

protocol TimeZoneApi {

    /// 获取最近使用的时区
    func getRecentTimeZoneIds() -> Observable<[TimeZoneModel.ID]>

    /// 新增/更新最近使用的时区
    func upsertRecentTimeZone(with timeZoneIdsToAdd: [TimeZoneModel.ID]) -> Observable<Void>

    /// 删除最近使用的时区
    func deleteRecentTimeZones(by timeZoneIdsToDelete: [TimeZoneModel.ID]) -> Observable<Void>

    /// 根据 query 获取对应的时区城市列表
    func getCityTimeZones(by query: String) -> Observable<[TimeZoneService.TimeZoneCityPair]>

    /// 获取 Preferred 时区
    func getPreferredTimeZoneId() -> Observable<TimeZoneModel.ID>

    /// 设置 Preferred 时区
    func setPreferredTimeZone(with timeZoneId: TimeZoneModel.ID) -> Observable<Void>

}
