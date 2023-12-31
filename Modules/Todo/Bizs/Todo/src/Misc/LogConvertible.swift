//
//  LogConvertible.swift
//  Todo
//
//  Created by 张威 on 2020/12/12.
//

import Foundation

protocol LogConvertible {
    var logInfo: String { get }
}

extension LogConvertible {
    var debugDescription: String { logInfo }
}
