//
//  ThumbDownloadStatistics.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/10/30.
//  

import Foundation
import SKFoundation
import SpaceInterface

public enum ThumbDownloadStatistics {

    public struct Result {

        let source: DocsImageDownloader.FromSource
        let isSucceed: Bool
        let fileType: DocsType
        let url: String
        let isUpdate: Bool
        let isNew: Bool
        let errorMsg: String?
        let code: Int?

        public init(source: DocsImageDownloader.FromSource, isSucceed: Bool, fileType: DocsType, url: String, isUpdate: Bool, isNew: Bool, errorMsg: String?, code: Int?) {
            self.source = source
            self.isSucceed = isSucceed
            self.fileType = fileType
            self.url = url
            self.isUpdate = isUpdate
            self.isNew = isNew
            self.errorMsg = errorMsg
            self.code = code
        }
    }

    public static func reportResult(_ rs: Result) {
        #if DEBUG
        return
        #else
        let enUrl = DocsTracker.encrypt(id: rs.url)
        var statusCode = ""
        if let code = rs.code {
            statusCode = "\(code)"
        }
        let params: [String: String] = [
            "source": rs.source.rawValue,
            "status_name": rs.isSucceed ? "1" : "0",
            "file_type": rs.fileType.name,
//            "url": enUrl,
            "is_update": rs.isUpdate ? "1" : "0",
            "is_new": rs.isNew ? "1" : "0",
            "errorMsg": rs.errorMsg ?? "",
            "network_status": DocsNetStateMonitor.shared.isReachable ? "1": "0",
            "response_status_code": statusCode
        ]
        DocsTracker.log(event: "thumb_request_result", parameters: params)
        #endif
    }

//    struct Info {
//        let isEncrypt: Bool
//        let fileType: DocsType
//        let source: DocsImageDownloader.FromSource
//        // 单位为 ms
//        let costTime: Int
//        // 单位为 KB
//        let fileSize: Int
//    }

//    static func report(info: Info) {
//        let params: [String: Any] = [
//            "is_encrypt": info.isEncrypt ? "1" : "0",
//            "file_type": info.fileType.name,
//            "source": info.source.rawValue,
//            "time_cost_ms": info.costTime,
//            "file_size": info.fileSize
//        ]
//        DocsLogger.debug("space.thumb --- reporting info", extraInfo: params)
//        DocsTracker.log(enumEvent: .thumbnailInfo, parameters: params)
//    }
}
