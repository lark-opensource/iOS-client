//
//  UploadFileCommonDefines.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/12/2.
//

import Foundation
import SKFoundation

// 上传来源
public enum UploadImageFrom: String {
    case unknow
    case comment
}

// 上传错误信息
public enum UploadError: Error {
    case dataIsNil
    case networkError(Error)
    case driveError(Int)
    case lackOfNecessaryParams // 缺少必要参数,参考接口注释
}

// 上传任务信息
typealias UploadFileSuccessType = (uuid: String, dataSize: Int?, params: [String: Any])
typealias UploadFileResultType = Result<UploadFileSuccessType, UploadError>
typealias UploadFileTaskCompletion = (UploadFileResultType) -> Void
typealias UploadFileProgressType = (bytesTransferred: Int64, bytesTotal: Int64)
typealias UploadFileTaskProgress = (UploadFileProgressType) -> Void

// 上传任务信息
public struct UploadFileTaskInfo: Hashable {
    let contentType: SKPickContentType
    let uuid: String // 在 cache 中的标识符, 同时也是任务的唯一标识符
    let fileName: String // 文件名
    var fileSize: Int? // 文件大小
    let localPath: SKFilePath //上传的本地地址
    let params: [String: AnyHashable]? // 额外参数
    let progress: UploadFileTaskProgress?
    let completion: UploadFileTaskCompletion // 上传回调

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(localPath)
        if let params = params {
            hasher.combine(params)
        }
    }

    public static func == (lhs: UploadFileTaskInfo, rhs: UploadFileTaskInfo) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
