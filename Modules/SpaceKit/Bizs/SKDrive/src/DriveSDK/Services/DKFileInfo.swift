//
//  DKFileInfo.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/17.
//

import SKFoundation
import Foundation
import SKCommon
import SpaceInterface
import SKInfra
import LarkDocsIcon

struct DKFileInfo: DKFileProtocol {
    let appID: String
    let fileID: String
    let name: String
    let size: UInt64
    let authExtra: String?
    /// 文件类型（从 mimeType 信息转换得来，否则为文件后缀名）
    var type: String
    /// 保存到云盘的状态 0：未保存 1：已保存
    var saveStatus: Int?
    /// 保存到云盘对应的 token
    let fileToken: String?
    /// 是否支持 wps 预览
    let webOffice: Bool
    /// 预览状态。1:可以生成预览;4:文件类型无法预览; 5:文件太大无法预览; 6:文件大小为0无法预览
    var previewStatus: Int?
    /// 文件 MIMEType(对标文件后缀名)
    var mimeType: String?
    /// 后端识别的 MIMEType
    var realMimeType: String?
    /// 后端支持的转码类型
    var availableTypes: [DrivePreviewFileType]
    /// 文件预览信息
    var previewMetas: [DrivePreviewFileType: DriveFilePreview]
    /// mountPoint只为了兼容协议，不做处理
    var mountPoint: String
    /// 保存到云空间的状态
    var saveState: DKSaveToSpaceState {
        guard let saveStatus = saveStatus else { return .unsave }
        guard saveStatus == 1 else { return .unsave }
        guard let fileToken = fileToken else {
            DocsLogger.error("drive.sdk.fileInfo --- failed to get fileToken when save status is 1")
            return .unsave
        }
        return .saved(fileToken: fileToken)
    }
    
    /// 优先使用的预览类型
    var previewType: DrivePreviewFileType? {
        let configSupportTypes = DKConfig.config.supportTypes(for: type, appID: appID).compactMap { (supportType) -> DrivePreviewFileType? in
            guard case .serverTransform(let type) = supportType else {
                return nil
            }
            return type
        }
        var previewType: DrivePreviewFileType?
        for type in configSupportTypes {
            if availableTypes.contains(type) {
                previewType = type
                break
            }
        }
        // 如果mina没有配置有限使用的预览方式，使用默认方式预览，对齐drive
        if previewType == nil {
            if availableTypes.count != 0 {
                // txt优先选择下载txt格式，再pdf兜底
                if availableTypes.contains(DrivePreviewFileType.transcodedPlainText) {
                    previewType = .transcodedPlainText
                } else if availableTypes.contains(DrivePreviewFileType.linerizedPDF),
                        !DriveFileType(fileExtension: type).isExcel {
                    // 非excel 文件，优先使用线性化PDF
                    previewType = .linerizedPDF
                } else {
                    previewType = availableTypes[0]
                }
            }
        }
        return previewType
    }
    
    var isIMFile: Bool { return true }
    
    var wpsInfo: DriveWPSPreviewInfo {
        return DriveWPSPreviewInfo(fileId: fileID, fileType: fileType, appId: appID, authExtra: authExtra)
    }
    
    var wpsEnable: Bool {
        guard fileType.isWpsOffice else { return false }
        return DriveFeatureGate.wpsEnable
    }
    
    init?(data: [String: Any], appId: String, fileId: String, authExtra: String?) {
        guard let name = data["name"] as? String,
              let size = data["size"] as? UInt64 else {
                return nil
        }
        self.appID = appId
        self.fileID = fileId
        self.authExtra = authExtra
        self.name = name
        self.size = size
        self.fileToken = data["file_token"] as? String
        self.saveStatus = data["save_status"] as? Int
        self.previewStatus = data["preview_status"] as? Int
        self.webOffice = data["weboffice"] as? Bool ?? false
        self.mimeType = data["mime_type"] as? String
        self.type = SKFilePath.getFileExtension(from: name) ?? ""
        self.availableTypes = []
        self.previewMetas = [:]
        self.mountPoint = ""
        
        // 解析 PreviewMeta 信息，包含文件转码预览信息和 MIMEType
        if let meta = data["preview_meta"] as? [String: Any],
           let data = meta["data"] as? [String: Any] {
            for type in DrivePreviewFileType.allCases {
                guard let dataDict = data[String(type.rawValue)] as? [String: Any],
                    let data = try? JSONSerialization.data(withJSONObject: dataDict, options: []),
                    let filePreview = try? JSONDecoder().decode(DriveFilePreview.self, from: data) else {
                        continue
                }
                if type == .mime {
                    self.realMimeType = filePreview.mimeType
                } else {
                    // 从 previewMeta 信息中获取 availableTypes 数据
                    if filePreview.previewStatus.isAvalible {
                        availableTypes.append(type)
                        previewMetas[type] = filePreview
                    }
                }
            }
        }
        // 加上原文件预览方式
        if !availableTypes.contains(.similarFiles) {
            availableTypes.append(.similarFiles)
        }
    }
    
    init(appId: String, fileId: String, name: String, size: UInt64, fileToken: String, authExtra: String?) {
        self.appID = appId
        self.fileID = fileId
        self.authExtra = authExtra
        self.name = name
        self.size = size
        self.fileToken = fileToken
        self.webOffice = false
        self.type = SKFilePath.getFileExtension(from: name) ?? ""
        self.availableTypes = []
        self.previewMetas = [:]
        self.mountPoint = ""
    }
}

extension DKFileInfo {

    /// DriveFileType
    var fileType: DriveFileType {
        return DriveFileType(fileExtension: type)
    }
    
    var dataVersion: String? {
        return nil
    }
    
    var videoCacheKey: String {
        let encryptedFileID = DocsTracker.encrypt(id: fileID)
        return "\(appID)_\(encryptedFileID)"
    }
    
    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: name)
    }
    
    func getPreviewDownloadURLString(previewType: DrivePreviewFileType) -> String? {
        return Self.generatePreviewDownloadURL(appID: appID,
                                               fileID: fileID,
                                               authExtra: authExtra,
                                               previewType: previewType)?.absoluteString
    }
    
    func getPreferPreviewType(isInVCFollow: Bool?) -> DrivePreviewFileType? {
        return self.previewType
    }

    func getMeta() -> DriveFileMeta? {
        spaceAssertionFailure("DKFileInfo has not fileMeta")
        return nil
    }
    
    static func generatePreviewDownloadURL(appID: String,
                                           fileID: String,
                                           authExtra: String?,
                                           previewType: DrivePreviewFileType) -> URL? {
        var preferedPreviewType = previewType
        if preferedPreviewType == .videoMeta {
            preferedPreviewType = .similarFiles
        }
        let typeValue = preferedPreviewType.rawValue
        
        var params: [String: Any] = ["app_id": appID, "app_file_id": fileID, "preview_type": typeValue]
        if let extra = authExtra, extra.count > 0 {
            params["auth_extra"] = extra
        }
        // 给 URL Params 按 Key 值排序，避免最终拼接 URL 字符串不一致导致断点续传失败
        let sortedParams = params.sorted(by: { $0.0 < $1.0 })

        var components = URLComponents()
        components.scheme = OpenAPI.docs.currentNetScheme
        components.host = DomainConfig.driveDomain
        components.path = DomainConfig.pathPrefix + OpenAPI.APIPath.driveFetchPreviewFileV2
        components.queryItems = sortedParams.map({ (arg) -> URLQueryItem in
            let (key, value) = arg
            let stringValue = value as? String ?? "\(value)"
            return URLQueryItem(name: key, value: stringValue)
        })

        let url = components.url
        DocsLogger.driveInfo("DKFileInfo previewURL: host: \(components.host), path: \(components.path)")
        return url
    }
}
