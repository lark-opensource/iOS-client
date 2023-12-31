//
//  RtcLogger.swift
//  ByteView
//
//  Created by kiri on 2022/8/10.
//

import Foundation
import ByteViewCommon

final class RtcLogger {
    @RwAtomic private var logger: Logger
    let contextId: String

    internal var uid: String = ""

    internal var channelName: String = "" {
        didSet {
            let tagCount = 4
            var channelTag = channelName
            if channelName.count > tagCount {
                channelTag = String(channelName[channelName.index(channelName.endIndex, offsetBy: -tagCount)...])
            }
            self.logger = logger.withTag("[Rtc(\(contextId))][\(channelTag)]")
        }
    }

    init(sessionId: String, instanceId: String) {
        self.contextId = sessionId.isEmpty ? instanceId : sessionId
        self.logger = Logger.byteRtc.withContext(contextId).withTag("[Rtc(\(contextId))]")
    }

    func info(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.info(msg, file: file, function: function, line: line)
    }

    func warn(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.warn(msg, file: file, function: function, line: line)
    }

    func error(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.error(msg, file: file, function: function, line: line)
    }
}
