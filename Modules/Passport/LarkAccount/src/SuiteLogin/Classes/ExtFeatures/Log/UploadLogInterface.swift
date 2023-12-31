//
//  UploadLog.swift
//  SuiteLogin
//
//  Created by quyiming on 2019/11/25.
//

import Foundation

protocol UploadLog {
    func log(_ log: LogModel)
}

class LogModel {
    var level: String
    var msg: String
    var file: String
    var line: Int
    var h5Log: Bool
    var time: String
    var thread: String

    public init(level: String, msg: String, file: String, line: Int, h5Log: Bool, time: String, thread: String) {
        self.level = level
        self.msg = msg
        self.file = file
        self.line = line
        self.h5Log = h5Log
        self.time = time
        self.thread = thread
    }
}
