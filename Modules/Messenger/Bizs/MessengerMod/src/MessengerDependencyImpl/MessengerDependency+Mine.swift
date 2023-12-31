//
//  MessengerMockDependency+Mine.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//
import UIKit
import Foundation
import RxSwift
import Swinject
import EENavigator
import LarkMine
import LarkContainer
#if CalendarMod
import Calendar
#endif

public final class MineDependencyImpl: MineDependency {

    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func showTimeZoneSelectController(with timeZone: TimeZone?,
                                             from: UIViewController,
                                             onTimeZoneSelect: @escaping (TimeZone) -> Void) {
        #if CalendarMod
        (try? resolver.resolve(assert: CalendarInterface.self))?.showTimeZoneSelectController(with: timeZone, from: from, onTimeZoneSelect: onTimeZoneSelect)
        #endif
    }
}
