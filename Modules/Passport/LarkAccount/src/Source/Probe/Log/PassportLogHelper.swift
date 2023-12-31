//
//  PassportLogHelper.swift
//  LarkAccount
//
//  Created by au on 2021/9/22.
//

import Foundation
import EEAtomic
import LKTracing
import AppContainer

final class PassportLogHelper {

    static let shared = PassportLogHelper()

    private init() {

    }

    func fetchMessageID() -> Int {
        let value = messageID
        messageID += 1
        return value
    }

    func setLogByOPMonitor(_ enable: Bool) {

    }

    // MARK: Private

    /// 单次 log 递增
    @AtomicObject
    private var messageID: Int = 0

    /// v6.9 起，停止实时日志上报
    var enableLogByOPMonitor: Bool { false }

    private static let enableLogByOPMonitorKey = "Passport.PassportLog.enableLogByOPMonitorKey"

}
