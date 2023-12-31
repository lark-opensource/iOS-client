//
//  TimeZoneApiImpl.swift
//  MailSDK
//
//  Created by majx on 2020/12/13.
//

import Foundation
import RustPB
import RxSwift
import Homeric

extension DataService: TimeZoneApi {
    /// 获取最近使用的时区
    func getRecentTimeZoneIds() -> Observable<[TimeZoneModel.ID]> {
        // UserDefaults.standard.object(forKey: "RecentTimeZoneIds")
        let req = Calendar_V1_GetRecentTimezonesRequest()
        return sendAsyncRequest(req).map({ (resp: Calendar_V1_GetRecentTimezonesResponse) -> [TimeZoneModel.ID] in
            return resp.timezoneIds
        })
    }

    /// 新增/更新最近使用的时区
    func upsertRecentTimeZone(with timeZoneIdsToAdd: [TimeZoneModel.ID]) -> Observable<Void> {
        var req = Calendar_V1_UpdateRecentTimezonesRequest()
        req.addedTimezoneIds = timeZoneIdsToAdd
        return sendAsyncRequest(req).map({ (resp: Calendar_V1_UpdateRecentTimezonesResponse) -> Void in
            return ()
        })
    }

    /// 删除最近使用的时区
    func deleteRecentTimeZones(by timeZoneIdsToDelete: [TimeZoneModel.ID]) -> Observable<Void> {
        var req = Calendar_V1_UpdateRecentTimezonesRequest()
        req.deletedTimezoneIds = timeZoneIdsToDelete
        return sendAsyncRequest(req).map({ (resp: Calendar_V1_UpdateRecentTimezonesResponse) -> Void in
            return ()
        })
    }

    /// 根据 query 获取对应的时区城市列表
    func getCityTimeZones(by query: String) -> Observable<[TimeZoneService.TimeZoneCityPair]> {
        var req = Calendar_V1_GetTimezoneByCityRequest()
        req.city = query

        return sendAsyncRequest(req).map({ (resp: Calendar_V1_GetTimezoneByCityResponse) -> [TimeZoneService.TimeZoneCityPair] in
            let timezones = resp.cityTimezones.map { (timeZone: TimeZoneModelImpl(timezoneID: $0.timezone.timezoneID,
                                                                                  timezoneName: $0.timezone.timezoneName,
                                                                                  timezoneOffset: $0.timezone.timezoneOffset),
                                                      cityNames: $0.cityNames)
            }
            return timezones
        })
    }

    /// 获取 Preferred 时区
    func getPreferredTimeZoneId() -> Observable<TimeZoneModel.ID> {
        let req = Calendar_V1_GetMobileNormalViewTimezoneRequest()
        return sendAsyncRequest(req).map({ (resp: Calendar_V1_GetMobileNormalViewTimezoneResponse) -> TimeZoneModel.ID in
            return resp.timezoneID
        })
    }

    /// 设置 Preferred 时区
    func setPreferredTimeZone(with timeZoneId: TimeZoneModel.ID) -> Observable<Void> {
        var req = Calendar_V1_SetMobileNormalViewTimezoneRequest()
        req.timezoneID = timeZoneId
        return sendAsyncRequest(req).map({ (resp: Calendar_V1_SetMobileNormalViewTimezoneResponse) -> Void in
            return ()
        }).observeOn(MainScheduler.instance)
    }
}
