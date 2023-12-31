//
//  TimeServiceImpl.swift
//  Todo
//
//  Created by 张威 on 2020/11/24.
//

import RxSwift
import RxCocoa
import CTFoundation
import Swinject
// import LarkSDKInterface
import LKCommonsLogging
import LarkContainer
import TodoInterface

final class TimeServiceImpl: TimeService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    static let logger = Logger.log(TimeServiceImpl.self, category: "Todo.TimeService")

    var calendar: Calendar { Calendar(identifier: .gregorian) }
    var utcTimeZone: TimeZone { (TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0))! }

    let rx12HourStyle: BehaviorRelay<Bool>
    let rxCurrentDay: BehaviorRelay<JulianDay>
    let rxTimeZone: BehaviorRelay<TimeZone>

    private var cachedTsRanges = [String: ClosedRange<Int64>]()
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.userResolver = resolver
        var is24HourTime = BehaviorRelay(value: false)
        if let dep = try? resolver.resolve(assert: MessengerDependency.self) {
            is24HourTime = dep.is24HourTime
        }
        rx12HourStyle = .init(value: !is24HourTime.value)
        is24HourTime
            .map { !$0 }
            .bind(to: rx12HourStyle)
            .disposed(by: disposeBag)
        rxTimeZone = .init(value: .current)
        rxCurrentDay = .init(value: JulianDayUtil.julianDay(from: Date(), in: .current))
        subscribeTimezoneNotification()
    }

    private func subscribeTimezoneNotification() {
        NotificationCenter.default.rx
            .notification(UIApplication.significantTimeChangeNotification)
            .subscribe(onNext: { [weak self] (_) in
                Self.logger.info("get timezoneNotification: \(TimeZone.current)")
                self?.rxTimeZone.accept(.current)
                self?.rxCurrentDay.accept(JulianDayUtil.julianDay(from: Date(), in: .current))
            }).disposed(by: self.disposeBag)
    }
}
