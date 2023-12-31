//
//  Utils+AppAlert.swift
//  Todo
//
//  Created by 白言韬 on 2020/12/3.
//

import Foundation

extension Utils {
    struct AppAlert { }
}

extension Utils.AppAlert {
    static func getDisappearTime(dueTime: Int64, isAllDay: Bool) -> Int64 {
        let existSeconds: Int64 = 30 * 60
        if isAllDay {
            return Int64(Date().timeIntervalSince1970) + existSeconds
        } else {
            return dueTime + existSeconds
        }
    }
}
