//
//  CalendarExtension.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/7.
//  Copyright © 2017年 linlin. All rights reserved.
//

import Foundation

public final class CalendarExtension<BaseType> {
    public var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

public protocol CalendarExtensionCompatible {
    associatedtype CalendarCompatibleType
    var cd: CalendarCompatibleType { get }
    static var cd: CalendarCompatibleType.Type { get }
}

public extension CalendarExtensionCompatible {
    public var cd: CalendarExtension<Self> {
        return CalendarExtension(self)
    }

    public static var cd: CalendarExtension<Self>.Type {
        return CalendarExtension.self
    }
}
