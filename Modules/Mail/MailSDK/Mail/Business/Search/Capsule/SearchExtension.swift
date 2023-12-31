//
//  SearchExtension.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import UIKit
import DateToolsSwift

public final class LarkSearchExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

// swiftlint:disable identifier_name
public protocol LarkMailExtensionCompatible {
    associatedtype LarkSearchCompatibleType
    var mail: LarkSearchCompatibleType { get }
    static var mail: LarkSearchCompatibleType.Type { get }
}

public extension LarkMailExtensionCompatible {
    var mail: LarkSearchExtension<Self> {
        return LarkSearchExtension(self)
    }

    static var mail: LarkSearchExtension<Self>.Type {
        return LarkSearchExtension.self
    }
}


extension Date: LarkMailExtensionCompatible {}

public extension LarkSearchExtension where BaseType == Date {
    func compare(date: Date) -> ComparisonResult {
        if base.year > date.year {
            return .orderedDescending
        } else if base.year < date.year {
            return .orderedAscending
        } else {
            if base.month > date.month {
                return .orderedDescending
            } else if base.month < date.month {
                return .orderedAscending
            } else {
                if base.day > date.day {
                    return .orderedDescending
                } else if base.day < date.day {
                    return .orderedAscending
                } else {
                    return .orderedSame
                }
            }
        }
    }

    func greatOrEqualTo(date: Date) -> Bool {
        let compareResult = base.mail.compare(date: date)
        if compareResult == .orderedSame || compareResult == .orderedDescending {
            return true
        }
        return false
    }

    func lessOrEqualTo(date: Date) -> Bool {
        let compareResult = base.mail.compare(date: date)
        if compareResult == .orderedSame || compareResult == .orderedAscending {
            return true
        }
        return false
    }

    var beginDate: Date {
        return Date(year: base.year, month: base.month, day: base.day)
    }

    var endDate: Date {
        return Date(timeInterval: 24 * 60 * 60 - timeIntvl.ultraShort, since: beginDate)
    }
}
