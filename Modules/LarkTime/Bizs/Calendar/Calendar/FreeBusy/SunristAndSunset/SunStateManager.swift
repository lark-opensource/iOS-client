//
//  SunStateManager.swift
//  Calendar
//
//  Created by huoyunjie on 2022/11/7.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkContainer

typealias SunriseAndSunsetTime = RustPB.Calendar_V1_SunriseAndSunsetTime

class SunStateService: UserResolverWrapper {

    @ScopedInjectedLazy var rustApi: CalendarRustAPI?

    var cityTimeMaps: [String: SunriseAndSunsetTime] = [:]

    var rxMapHasChanged = PublishRelay<Void>()

    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func loadData(citys: [String], date: Int64) {
        let citysWithOutHidden = citys.filter { !$0.isEmpty }
        rustApi?.getSunriseAndSunsetTime(timeZone: citysWithOutHidden, date: date)
            .map(\.cityTimeMap)
            .subscribeForUI(onNext: { [weak self] cityTimeMaps in
                self?.cityTimeMaps = cityTimeMaps
                self?.rxMapHasChanged.accept(())
            }).disposed(by: disposeBag)
    }

    func isLight(city: String, date: Int64) -> Bool {
        guard let cityTimeMap = cityTimeMaps[city] else {
            return false
        }

        let sunriseDate = Date(timeIntervalSince1970: TimeInterval(cityTimeMap.sunrise))
        let sunsetDate = Date(timeIntervalSince1970: TimeInterval(cityTimeMap.sunset))
        let currentDate = Date(timeIntervalSince1970: TimeInterval(date))

        if let timeZone = TimeZone(identifier: city) {
            let sunriseMinutes = getMinutes(date: sunriseDate, timeZone: timeZone)
            let sunsetMinutes = getMinutes(date: sunsetDate, timeZone: timeZone)
            let currentMinutes = getMinutes(date: currentDate, timeZone: timeZone)
            // 判断分钟数
            return currentMinutes >= sunriseMinutes && currentMinutes < sunsetMinutes
        } else {
            assertionFailure("transform timeZone failed: \(city)")
            return false
        }
    }

    private func getMinutes(date: Date, timeZone: TimeZone) -> Int32 {
        let dateComps = Calendar.gregorianCalendar.dateComponents(in: timeZone, from: date)
        return Int32(60 * dateComps.hour! + dateComps.minute!)
    }

}
