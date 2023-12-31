//
//  BadgeProxy.swift
//  Action
//
//  Created by tefeng liu on 2019/6/24.
//

import Foundation
import RxSwift

public enum BadgeType: Equatable {
    case none
    case dot(Int)
    case number(Int)
    case image(UIImage)

    static public func == (lhs: BadgeType, rhs: BadgeType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.dot(let num1), dot(let num2)):
            return num1 == num2
        case (.number(let num1), .number(let num2)):
            return num1 == num2
        case (.image(let l), .image(let r)):
            return l == r
        default:
            return false
        }
    }
}

public protocol BadgeProxy {
    func getMailBadgeCount() -> Observable<BadgeType>
}
