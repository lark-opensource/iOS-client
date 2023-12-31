//
//  UploadLogger.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/11/14.
//

import Foundation
import LKCommonsLogging

///
/// use to upload log before UploadLogManager Appender have not  setup in LKCommonsLoggings
///

class UploadLogger {

    static let shared = UploadLogger()

    static let logger = Logger.plog(UploadLogger.self, category: "UploadLogger")

    private var logs: [LogModel] = []

    private var acceptLog: Bool = true

    private let logLimit: Int = 50

    private let lock = DispatchSemaphore(value: 1)

    private init() { }

   func log(_ logModel: LogModel) {
       lock.wait()
       defer {
           lock.signal()
       }
       guard acceptLog else {
           UploadLogger.logger.error("not accept log but get log msg: \(logModel.msg)")
           return
       }
       guard logs.count < logLimit else {
           UploadLogger.logger.error("upload logger over limit")
           return
       }
       logs.append(logModel)
   }

    func flushLog(_ uploadLog: UploadLog, logined: Bool) {
        lock.wait()
        defer {
            lock.signal()
        }
        acceptLog = false
        let toUploadLogs = logs
        logs = []
        if logined {
            UploadLogger.logger.error("user has logined not upload log", method: .local)
            return
        }
        toUploadLogs.forEach { log in
            // update time otherwise can not search on gray log
            log.time = UploadLogManager.getTime()
            uploadLog.log(log)
        }
    }
}
