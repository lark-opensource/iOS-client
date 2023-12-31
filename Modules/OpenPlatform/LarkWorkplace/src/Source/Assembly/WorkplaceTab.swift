//
//  WorkplaceTab.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/26.
//

import Foundation
import LarkTab
import RxSwift
import RxRelay
import LKCommonsLogging

final class WorkplaceTab: TabRepresentable {
    static let logger = Logger.log(WorkplaceTab.self)

    var tab: Tab { .appCenter }
    let badge: BehaviorRelay<LarkTab.BadgeType>? = BehaviorRelay(value: .none)
    let badgeStyle: BehaviorRelay<BadgeRemindStyle>? = BehaviorRelay<BadgeRemindStyle>(value: .strong)
    let badgeOutsideVisiable: BehaviorRelay<Bool>? = BehaviorRelay<Bool>(value: true)

    init() {
        Self.logger.info("initialize workplace tab")
    }
}
