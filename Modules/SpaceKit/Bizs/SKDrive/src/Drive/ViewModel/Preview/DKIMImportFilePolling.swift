//
//  DKIMImportFilePolling.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/5/26.
//

import Foundation
import SKFoundation
import SwiftyJSON
import LKCommonsLogging

class DKIMImportFilePolling: DrivePollingStrategy {
    static let logger = Logger.log(DKIMImportFilePolling.self, category: "DocsSDK.drive.convertIMFile")

    private let timeOut: Int
    private var index: Int = 0
    private var startTime: TimeInterval
    init(timeOut: Int) {
        self.timeOut = timeOut
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func nextInterval() -> PollingInterval {
        let curTime = CFAbsoluteTimeGetCurrent()
        guard curTime - startTime < CGFloat(timeOut) else {
            return .end
        }
        if index == 0 {
            index += 1
            return .interval(1)
        } else {
            index += 1
            return .interval(3)
        }
    }
    
    public func shouldPolling(data: JSON?, error: Error?) -> Bool {
        guard let json = data,
              let code = json["code"].int,
              code == 0 else {
                return false
        }
        guard let dicData = json["data"].dictionaryObject else {
            return false
        }
        guard let result = dicData["result"] as? [String: Any],
                let statusCode = result["job_status"] as? Int else {
            Self.logger.info("DKIMImportFilePolling -- has no job_status")
            return false
        }
        let status = DKFileImportResultStatus(rawValue: statusCode)
        Self.logger.info("status: \(status)")
        // 错误码，0表示成功， 1或2表示处理中继续轮询，其他失败
        if case .converting = status {
            return true
        }
        
        return false
    }
}
