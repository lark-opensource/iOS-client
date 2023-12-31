//
//  ScenarioInterceptor.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/11.
//

import Foundation

public protocol ScenarioInterceptor: AnyObject {
    var isAlterShowing: Bool { get }
    var isPopoverShowing: Bool { get }
    var isDrawerShowing: Bool { get }
    var isModalShowing: Bool { get }
    var otherInterceptEvent: Bool { get }
}

extension ScenarioInterceptor {
    func canShowMagic() -> Bool {
        return !isAlterShowing
            && !isPopoverShowing
            && !isDrawerShowing
            && !isModalShowing
            && !otherInterceptEvent
    }
}
