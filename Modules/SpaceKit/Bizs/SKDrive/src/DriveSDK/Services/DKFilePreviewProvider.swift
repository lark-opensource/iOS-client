//
//  DKFilePreviewProvider.swift
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

// 接口文档：https://bytedance.feishu.cn/wiki/wikcnj55mEH7DzMViRaNgQc1OWg#AHE4gP

typealias DKFilePreview = DriveFilePreview

protocol FilePreviewProvider {
    func request() -> Single<DKFilePreview>
}

class DKFilePreviewProvider: FilePreviewProvider {
    private var fileInfo: DKFileInfo
    private let previewType: DrivePreviewFileType
    
    init(fileInfo: DKFileInfo, previewType: DrivePreviewFileType) {
        self.fileInfo = fileInfo
        self.previewType = previewType
    }

    func request() -> Single<DKFilePreview> {
        let params = composeParams()
        let previewURL = fileInfo.getPreviewDownloadURLString(previewType: previewType)
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.previewGetV2, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .background))
            .map { result -> DKFilePreview in
                guard let json = result,
                    let code = json["code"].int else {
                        DocsLogger.error("DriveSDK.PreviewProvider: result invalide")
                        throw DriveError.previewDataError
                }
                guard code == 0 else {
                    DocsLogger.error("DriveSDK.PreviewProvider: result code: \(code)")
                    throw DriveError.serverError(code: code)
                }
                guard let dataDic = json["data"].dictionaryObject,
                    let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []),
                    var filePreview = try? JSONDecoder().decode(DKFilePreview.self, from: data) else {
                        DocsLogger.error("DriveSDK.PreviewProvider: parse data to fileInfo failed")
                        throw DriveError.fileInfoParserError
                }
                filePreview.previewURL = previewURL
                return filePreview
            }
    }
    
    private func composeParams() -> [String: Any] {
        var params: [String: Any] = ["app_id": fileInfo.appID, "app_file_id": fileInfo.fileID, "preview_type": previewType.rawValue]
        if let extra = fileInfo.authExtra, extra.count > 0 {
            params["auth_extra"] = extra
        }
        return params
    }
}

class DriveFilePreviewProvider: FilePreviewProvider {
    private var fileInfo: DriveFileInfo
    private let previewType: DrivePreviewFileType

    init(fileInfo: DriveFileInfo, previewType: DrivePreviewFileType) {
        self.fileInfo = fileInfo
        self.previewType = previewType
    }
    
    func request() -> Single<DKFilePreview> {
        let params = composeParams()
        let previewURL = fileInfo.getPreviewDownloadURLString(previewType: previewType)
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.driveGetServerPreviewURL, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        return request.rxStart()
            .observeOn(SerialDispatchQueueScheduler(qos: .background))
            .map { result -> DKFilePreview in
                guard let json = result,
                    let code = json["code"].int else {
                        DocsLogger.error("DriveSDK.PreviewProvider: result invalide")
                        throw DriveError.previewDataError
                }
                guard code == 0 else {
                    DocsLogger.error("DriveSDK.PreviewProvider: result code: \(code)")
                    throw DriveError.serverError(code: code)
                }
                guard let dataDic = json["data"].dictionaryObject,
                    let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []),
                    var filePreview = try? JSONDecoder().decode(DKFilePreview.self, from: data) else {
                        DocsLogger.error("DriveSDK.PreviewProvider: parse data to fileInfo failed")
                        throw DriveError.fileInfoParserError
                }
                filePreview.previewURL = previewURL
                return filePreview
            }
    }
    
    private func composeParams() -> [String: Any] {
        var params = ["preview_type": previewType.rawValue,
                      "file_token": fileInfo.fileToken,
                      "mount_point": fileInfo.mountPoint,
                      "mount_node_token": fileInfo.mountNodeToken] as [String: Any]
        if let version = fileInfo.dataVersion {
            params["version"] = version
        }
        if let extra = fileInfo.authExtra {
            params["extra"] = extra
        }
        return params
    }
}
