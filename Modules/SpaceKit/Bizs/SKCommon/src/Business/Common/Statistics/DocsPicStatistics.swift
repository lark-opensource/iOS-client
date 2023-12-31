//
//  DocsDownloadPicStatistics.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/9/15.
//

import SKFoundation
import SpaceInterface


public enum SKPicStatisticsDownloadFrom: String {
    case preloadDrive
    case preloadDocsService
    case customSchemeDrive
    case customSchemeDocs
    case picOpenPluginComment
    case picOpenPluginOthers
    case commentCardDrive
    case commentCardDocs
}

public enum SKPicCacheType: Int {
    case none = 0
    case driveCache = 1
    case docCache = 2
}

public enum SKDownloadPickErrorCode: Int {
    case none = 0
    case successButNoData = -999
    case customTimeOut = -998
}

public final class SKDownloadPicStatistics {

    // swiftlint:disable line_length
    public class func downloadPicReport(_ resultStatus: Int, type: Int = 0, msg: String = "", from: SKPicStatisticsDownloadFrom, fileType: DocsType? = nil, picSize: Int = -1, cost: Int = -1, cache: SKPicCacheType = .none) {
        let param: [String: Any] = ["code": resultStatus,
                                    "image_type": type,
                                    "msg": msg,
                                    "pic_from": from.rawValue,
                                    "file_type": fileType?.name ?? "unknow",
                                    "pic_size": picSize,
                                    "cache": "\(cache.rawValue)",
                                    "cost_time": cost
        ]
        DocsTracker.log(enumEvent: .devPerformancePicDownload, parameters: param)
    }
}


public enum SKPicStatisticsUploadFrom: String {
    case comment
    case others
}

public enum SKPicStatisticsUploadTo: String {
    case copy
    case uploadToDocs
    case uploadToDrive
}


public final class SKUploadPicStatistics {

    public class func uploadPicReport(_ resultStatus: Int, from: SKPicStatisticsUploadFrom, uploadTo: SKPicStatisticsUploadTo, msg: String = "", picSize: Int = -1, cost: Int = -1) {
        let param: [String: Any] = ["code": resultStatus,
                                    "msg": msg,
                                    "pic_from": from.rawValue,
                                    "upload_to": uploadTo.rawValue,
                                    "pic_size": picSize,
                                    "cost_time": cost
        ]
        DocsTracker.log(enumEvent: .devPerformancePicUpload, parameters: param)
    }

    public class func uploadFileReport(_ resultStatus: Int,
                                       contentType: SKPickContentType,
                                       from: SKPicStatisticsUploadFrom,
                                       uploadTo: SKPicStatisticsUploadTo,
                                       msg: String = "",
                                       fileSize: Int = -1,
                                       cost: Int = -1) {
        let param: [String: Any] = ["code": resultStatus,
                                    "msg": msg,
                                    "uploadContentType": contentType.rawValue,
                                    "upload_from": from.rawValue,
                                    "upload_to": uploadTo.rawValue,
                                    "file_size": fileSize,
                                    "cost_time": cost
        ]
        DocsTracker.log(enumEvent: .devPerformanceFileUpload, parameters: param)
    }
}
