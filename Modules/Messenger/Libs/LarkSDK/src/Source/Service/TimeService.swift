//
//  TimeService.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/12/29.
//

import Foundation
import RxCocoa
import RxSwift
import LarkSDKInterface
import LarkExtensions

final class TimeFormatSettingImpl: TimeFormatSettingService {
    var is24HourTime: Bool {
        get { return Date.lf.is24HourTime }
        set { Date.lf.is24HourTime = newValue }
    }
}

final class ServerNTPTimeImpl: ServerNTPTimeService {

    private(set) var ntpAPI: NTPAPI
    /// ntp time unit second
    var serverTime: Int64 {
        return getNTPTime()
    }

    lazy var burnTimer: Observable<Int64> = {
        return Observable<Int64>
            .timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
            .map({ _ in self.serverTime })
    }()

    func afterThatServerTime(time: Int64) -> Bool {
        return time > self.serverTime * 1000
    }

    init(ntpAPI: NTPAPI) {
        self.ntpAPI = ntpAPI
    }

    private func getNTPTime() -> Int64 {
        let serverNTPTime = self.ntpAPI.getNTPTime()
        return serverNTPTime / 1000
    }
}
