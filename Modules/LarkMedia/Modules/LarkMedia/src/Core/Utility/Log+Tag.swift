//
//  Log+Tag.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2021/10/18.
//

import LKCommonsLogging

extension Log {
    func getTag() -> String {
        String(format: "%03X", Date().timeIntervalSince1970)
    }

    func debug(with tag: String, _ msg: String,
               file: String = #file, function: String = #function, line: Int = #line) {
        debug(msg, additionalData: ["contextID": tag], file: file, function: function, line: line)
    }

    func info(with tag: String, _ msg: String,
              file: String = #file, function: String = #function, line: Int = #line) {
        info(msg, additionalData: ["contextID": tag], file: file, function: function, line: line)
    }

    func warn(with tag: String, _ msg: String,
              file: String = #file, function: String = #function, line: Int = #line) {
        warn(msg, additionalData: ["contextID": tag], file: file, function: function, line: line)
    }

    func error(with tag: String, _ msg: String,
               file: String = #file, function: String = #function, line: Int = #line) {
        error(msg, additionalData: ["contextID": tag], file: file, function: function, line: line)
    }
}
