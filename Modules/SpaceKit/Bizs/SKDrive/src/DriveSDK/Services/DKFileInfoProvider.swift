//
//  DKFileInfoProvider.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/17.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra
import Alamofire

enum FileInfoResult<FileInfo> {
    case succ(info: FileInfo) // 获取到fileInfo
    case storing // 转存中，混合部署的情况
}
protocol DKFileInfoProvider {
    associatedtype FileInfo
    func request(version: String?) -> Observable<FileInfoResult<FileInfo>>
}

// 供 IM 使用，请求 sdk/file/info
// 接口文档 https://bytedance.feishu.cn/wiki/wikcnj55mEH7DzMViRaNgQc1OWg#IjVnJQ
class DKDefaultFileInfoProvider: DKFileInfoProvider {
    typealias FileInfo = DKFileInfo
    private let appID: String
    private let fileID: String
    private let authExtra: String?
    private let options: [String]?
    
    /// SDKFileInfo 重试逻辑（网络层错误重试一次）
    private var retryAction: RetryAction = { (request: URLRequest?, currentRetryCount: UInt, error: Error) in
        guard let urlError = error as? URLError else { return (false, 0) }
        if currentRetryCount < 1 {
            let extraInfo: [String: Any] = ["error": error.localizedDescription.toBase64(), "retryCount": currentRetryCount ]
            DocsLogger.driveInfo("FileInfo Network Retry", extraInfo: extraInfo)
            return (true, 1)
        } else {
            return (false, 0)
        }
    }
    
    init(appID: String,
         fileID: String,
         authExtra: String? = nil,
         options: [String]? = ["save_status", "preview_meta", "check_cipher"]) {
        self.appID = appID
        self.fileID = fileID
        self.authExtra = authExtra
        self.options = options
    }

    func request(version: String?) -> Observable<FileInfoResult<DKFileInfo>> {
        let fileInfoAppID = appID
        let fileInfoFileID = fileID
        let fileInfoAuthExtra = authExtra
        var params: [String: Any] = ["app_id": fileInfoAppID, "app_file_id": fileInfoFileID]
        if let extra = fileInfoAuthExtra {
            params["auth_extra"] = extra
        }
        if let options = options {
            params["option_params"] = options
        }
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfoV2, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .set(retryAction: retryAction)

        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .background))
            .map { (result) -> FileInfoResult<DKFileInfo> in
                guard let json = result,
                    let code = json["code"].int else {
                        DocsLogger.error("DriveSDK.FileInfoProvider: result invalide")
                        throw DriveError.fileInfoParserError
                }
                guard code == 0 else {
                    DocsLogger.error("DriveSDK.FileInfoProvider: result code: \(code)")
                    throw DriveError.serverError(code: code)
                }
                guard let data = json["data"].dictionaryObject else {
                    DocsLogger.error("DriveSDK.FileInfoProvider: result has no data")
                    throw DriveError.fileInfoParserError
                }
                if let fileInfo = DKFileInfo(data: data, appId: fileInfoAppID, fileId: fileInfoFileID, authExtra: fileInfoAuthExtra) {
                    return FileInfoResult.succ(info: fileInfo)
                } else {
                    throw DriveError.fileInfoParserError
                }
            }.asObservable()
    }
}
