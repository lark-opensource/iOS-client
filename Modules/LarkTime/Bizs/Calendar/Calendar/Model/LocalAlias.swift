//
//  LocalAlias.swift
//  Calendar
//
//  Created by 张威 on 2020/9/3.
//

import EventKit

/// Alias for Types from EventKit

enum Local {}

extension Local {
    typealias Instance = EKEvent
    typealias Event = EKEvent
}
