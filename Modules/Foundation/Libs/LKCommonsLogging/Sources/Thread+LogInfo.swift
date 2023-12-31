//
//  Thread+LogInfo.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2019/12/15.
//

import Foundation

extension Thread {

    static var infoLock = NSLock()

    static var logInfo: String {

        if let name = current.name, !name.isEmpty {
            return name
        }

        if isMainThread {
            return "Main"
        }
        infoLock.lock(); defer { infoLock.unlock() }
        var tid: UInt64 = 0
        pthread_threadid_np(nil, &tid)
        let tag = String(format: "0x%llX", CLongLong(bitPattern: tid))

        return "T:\(tag)"
    }

}
