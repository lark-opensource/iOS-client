//
//  LarkConfigCenter.swift
//  Calendar
//
//  Created by 朱衡 on 2018/10/26.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import RustPB

//以后这个类放在主端，传给calendar Observable<CalendarConfigs>
final class LarkConfigManager {
    static func initialize(with calendarApi: CalendarRustAPI) {
        let configs = calendarApi.getConfigSetting().map({ (event) -> CalendarConfigs in
            return event.calendarConfigs
        })

        var disposeBag = DisposeBag()
        configs.subscribeOn(calendarApi.requestScheduler)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (configs) in
            LarkBadgeManager.setRedDotItems(configs.redDotItems, calendarApi: calendarApi)
            LocalCalendarManager.setCalDavDomain(configs.calDavDomain)
        }, onCompleted: {
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }
}
