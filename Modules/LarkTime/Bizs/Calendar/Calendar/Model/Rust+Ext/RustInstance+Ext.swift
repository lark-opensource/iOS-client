//
//  RustInstance+Ext.swift
//  Calendar
//
//  Created by 张威 on 2020/8/19.
//

import Foundation

private let secondOfOneDay = 86_400
private let secondOf23Hours = 86_340

extension Rust.Instance {

    var tripleStr: String {
        return "\(calendarID)\(key)\(originalTime)"
    }

    var quadrupleStr: String {
        return "\(calendarID)\(key)\(originalTime)\(startTime)"
    }

    var keyWithTimeTuple: String {
        return "\(key)\(originalTime)\(startTime)"
    }

    var canEdit: Bool {
        calAccessRole == .writer || calAccessRole == .owner
    }

    var isGoogleType: Bool { source == .google }
    var isExchangeType: Bool { source == .exchange }

}
