//
//  DriveFileInfo.swift
//  SpaceKit
//
//  Created by Wenjian Wu on 2019/3/14.
//  

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra
import SKResource
import SpaceInterface
import CoreServices
import RxSwift
import RxCocoa
import LarkDocsIcon

// 后端接口: https://bytedance.feishu.cn/space/doc/tSrvZGGj5N8WUT08s0vLlg#ubCPss
// 重构文档: https://bytedance.feishu.cn/space/doc/doccnqN0CcdG9dltwenKjLYvn5b#
// FileInfo 支持获取预览信息: https://bytedance.feishu.cn/docs/doccnFRoWlKLUUfkRW9qrf0mH6r

enum DriveFileInfoErrorCode: Int {
    case parameterError = 2
    case fileNotFound = 3
    case noPermission = 4
    case loginRequired = 5

    case fileDeletedOnServerError = 1002

    case machineAuditFailureError = 10_009           // 机器审核失败
    case humanAuditFailureError = 10_013             // 人工审核失败或者被举报
    case auditFailureInUploadError = 12_009

    case resourceFrozenByAdmin = 90_002_104           // DriveSDK 场景，文件被管理员撤回，冻结状态，可恢复
    case resourceShreddedByAdmin = 90_002_105         // DriveSDK 场景。文件被粉碎，无法恢复
    case fileCopying = 90_001_071
    case fileDamage = 90_001_072
    case fileKeyDeleted = 900_021_001                 // 密钥删除
    case dlpDetectingFailed = 900_099_003             //dlp检测失败
}

// 初始化 FileInfo 的来源，是后台接口返回的、还是缓存读取的、还是通过其他接口数据本地构造的
public enum DriveFileInfoSource: Int, Equatable {
    case server             // 服务器
    case cache              // 缓存
    case other              // 初始化构造

    var isFromCache: Bool {
        switch self {
        case .cache:
            return true
        default:
            return false
        }
    }

    var isFromServer: Bool {
        switch self {
        case .server:
            return true
        default:
            return false
        }

    }
}

/// 文件信息, PreviewViewModel中使用
struct DriveFileInfo: DriveFileCacheable {

    // 与DriveFileMeta相同
    /// 文件大小
    private(set) var size: UInt64
    /// 文件名
    var name: String
    /// 文件类型
    private(set) var type: String
    /// 文件token
    let fileToken: String
    /// 父节点token
    let mountNodeToken: String
    /// 挂载点
    let mountPoint: String
    /// 文件版本，任何改动都会更新
    var version: String?
    /// 文件数据版本，仅当内容改变时才会更新
    var dataVersion: String?

    // MARK: 下载相关
    /// 分片数量
    let numBlocks: Int?

    // MARK: 预览相关
    /// 后端预览状态
    let previewStatus: Int?
    /// 代表这个文件是否可以通过 WPS 预览
    let webOffice: Bool
    /// 文件创建者tenant id 目前用于数据上报
    var tenantID: String?
    /// 文件预览信息
    var previewMetas: [DrivePreviewFileType: DriveFilePreview]
    /// 文件 MIMEType（对标文件后缀名）
    var mimeType: String?
    /// 后端识别的 MIMEType
    var realMimeType: String?

    /// 预览文件类型
    private(set) var previewType: DrivePreviewFileType?
    /// 后端对于当前文件支持的转码类型
    private var availableTypes: [Int]?

    /// 能否转换为 PDF
    var canTransformPDF: Bool {
        if fileType == .pdf {
            return true
        }
        return availableTypes?.contains(DrivePreviewFileType.linerizedPDF.rawValue) ?? false
    }

    /// 判断fileInfo的信息来源，来自cache的fileInfo预览不能进行评论、不触发拉取评论
    var source: DriveFileInfoSource
    var authExtra: String? // 第三方附件接入业务可以通过authExtra透传参数给业务后方进行鉴权，根据业务需要可选

    /// 错误码
    var errorCode: DriveFileInfoErrorCode?
    /// 审核是否合规
    private(set) var auditState: DriveAuditState = (.legal, .none)

    /// 当前用户与Owner是否同租户
    public var isSameTenantWithOwner: Bool {
        return self.tenantID == User.current.info?.tenantID
    }

    init(fileMeta: DriveFileMeta,
         previewType: DrivePreviewFileType? = nil,
         previewStatus: Int? = nil,
         webOffice: Bool = false,
         previewMetas: [DrivePreviewFileType: DriveFilePreview] = [:]) {
        self.size = fileMeta.size
        self.name = fileMeta.name
        self.type = fileMeta.type
        self.fileToken = fileMeta.fileToken
        self.mountNodeToken = fileMeta.mountNodeToken
        self.mountPoint = fileMeta.mountPoint
        self.version = fileMeta.version
        self.dataVersion = fileMeta.dataVersion
        self.authExtra = fileMeta.authExtra

        self.numBlocks = nil
        self.previewStatus = previewStatus
        self.previewType = previewType
        self.availableTypes = nil
        self.source = .other
        self.webOffice = webOffice
        self.previewMetas = previewMetas
    }

    init?(data: [String: Any],
          fileToken: String,
          mountNodeToken: String,
          mountPoint: String,
          authExtra: String? = nil) {
        guard let name = data["name"] as? String,
            let size = data["size"] as? UInt64,
            let type = data["type"] as? String else {
                return nil
        }

        let numBlocks = data["num_blocks"] as? Int
        let version = data["version"] as? String
        let dataVersion = data["data_version"] as? String
        let previewStatus = data["preview_status"] as? Int
        let webOffice = data["weboffice"] as? Bool
        self.tenantID = data["creator_tenant_id"] as? String
        self.mimeType = data["mime_type"] as? String

        if let permissionStatusCode = data["permission_status_code"] as? Int {
            if permissionStatusCode == DriveFileInfoErrorCode.machineAuditFailureError.rawValue {
                self.auditState = (.ownerIllegal, .machineAuditFailed)
            }
            if permissionStatusCode == DriveFileInfoErrorCode.humanAuditFailureError.rawValue {
                self.auditState = (.ownerIllegal, .humanAuditFailed)
            }
        }

        self.size = size
        self.type = type
        self.name = name
        self.numBlocks = numBlocks
        self.version = version
        self.dataVersion = dataVersion
        self.previewStatus = previewStatus
        self.fileToken = fileToken
        self.mountNodeToken = mountNodeToken
        self.mountPoint = mountPoint
        self.source = .server
        self.webOffice = webOffice ?? false
        self.authExtra = authExtra
        self.availableTypes = []
        self.previewMetas = [:]

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
                        availableTypes?.append(type.rawValue)
                        previewMetas[type] = filePreview
                    }
                }
            }
        }

        // 兜底逻辑，当没有 preview_meta 信息时，availableTypes 从 "available_preview_type" 字段获取
        // 未来 available_preview_type 可能会被后端弃用，注意请求 FileInfo 时 option_params 参数带上 preview_meta
        if availableTypes?.isEmpty == true {
            availableTypes = (data["available_preview_type"] as? [Int])?.filter { $0 != 0 }
        }

        if let types = availableTypes, !types.isEmpty {
            // txt优先选择下载txt格式，再pdf兜底
            if types.contains(DrivePreviewFileType.transcodedPlainText.rawValue) {
                self.previewType = .transcodedPlainText
            } else if types.contains(DrivePreviewFileType.linerizedPDF.rawValue),
                    !DriveFileType(fileExtension: type).isExcel {
                // 非excel 文件，优先使用线性化PDF
                self.previewType = .linerizedPDF
            } else if types.contains(DrivePreviewFileType.html.rawValue) {
                // Excel优先使用HTML
                self.previewType = .html
            } else {
                self.previewType = DrivePreviewFileType(rawValue: types[0])
            }
        }
    }
}

extension DriveFileInfo {

    func getFileMeta() -> DriveFileMeta {
        let meta = DriveFileMeta(size: size,
                                 name: name,
                                 type: type,
                                 fileToken: fileToken,
                                 mountNodeToken: mountNodeToken,
                                 mountPoint: mountPoint,
                                 version: version,
                                 dataVersion: dataVersion,
                                 source: source,
                                 tenantID: tenantID,
                                 authExtra: authExtra)
        return meta
    }

    // 第三方附件基本信息，回调给调用方使用
    func attachmentInfo() -> DKAttachmentInfo {
        return DKAttachmentInfo(fileID: fileToken,
                                   name: name,
                                   type: type,
                                   size: size,
                                   localPath: nil)
    }

    mutating func updateFromCacheIfExist() {
        guard let record = DriveCacheService.shared.getFileRecord(token: fileToken) else {
            DocsLogger.driveInfo("file not exist in cache, fileToken: \(fileToken.encryptToken)")
            if name.isEmpty {
                name = ""
            }
            return
        }

        if name.isEmpty {
            name = record.originName
        }
        if let fileType = record.fileType {
            type = fileType
        } else if let fileExt = record.originFileExtension {
            type = fileExt
        }
        size = record.originFileSize ?? size

        dataVersion = record.version
        source = .cache
    }
}

// ref: https://bytedance.feishu.cn/space/doc/tSrvZGGj5N8WUT08s0vLlg#qc1vWZ
// {{domain}}/space/api/box/stream/download/preview/{{fileToken}}?version={}&preview_type={}
extension DriveFileInfo {
    // preview/get中的url会过期，导致后端出现400错误，需要使用session换取不会获取的url
    func getPreviewDownloadURLString(previewType: DrivePreviewFileType) -> String? {
        var params = [String: String]()
        if let v = dataVersion, !v.isEmpty {
            params["version"] = v
        }

        var preferedPreviewType: DrivePreviewFileType = previewType
        
        /// 不能把videoMeta拼接到预览链接中
        if preferedPreviewType == .videoMeta {
            preferedPreviewType = .similarFiles
        }
        params["preview_type"] = String(preferedPreviewType.rawValue)
        
        if let extra = self.authExtra {
            params["extra"] = extra
        }
        params["mount_point"] = mountPoint
        // 给 URL Params 按 Key 值排序，避免最终拼接 URL 字符串不一致导致无法断点续传
        let sortedParams = params.sorted(by: { $0.0 < $1.0 })

        var components = URLComponents()
        components.scheme = OpenAPI.docs.currentNetScheme
        components.host = DomainConfig.driveDomain
        components.path = DomainConfig.pathPrefix + OpenAPI.APIPath.driveFetchPreviewFile + fileToken
        components.queryItems = sortedParams.map({ (arg) -> URLQueryItem in
            let (key, value) = arg
            return URLQueryItem(name: key, value: value)
        })

        DocsLogger.driveInfo("DriveFileInfo -- scheme: \(OpenAPI.docs.currentNetScheme), host: \(components.host), path: \(DomainConfig.pathPrefix + OpenAPI.APIPath.driveFetchPreviewFile)")

        // Getting a URL from our components is as simple as
        // accessing the 'url' property.
        let url = components.url

        return url?.absoluteString
    }

    var videoCacheKey: String {
        let version = dataVersion ?? ""
        let token = DocsTracker.encrypt(id: fileToken)
        return "\(token)_\(version)"
    }
}

extension DriveFileInfo: Equatable {
    public static func == (lhs: DriveFileInfo, rhs: DriveFileInfo) -> Bool {
        return lhs.fileToken.elementsEqual(rhs.fileToken)
            && lhs.dataVersion == rhs.dataVersion
            && lhs.version == rhs.version
            && lhs.name.elementsEqual(rhs.name)
            && lhs.source == rhs.source
    }
}

extension DriveFileInfo: DKFileProtocol {
    func getPreferPreviewType(isInVCFollow: Bool?) -> DrivePreviewFileType? {
        if isInVCFollow == true {
            // VCFollow 下，Office 文件优先用 PDF 转码预览
            if fileType.isOffice {
                return canTransformPDF ? .linerizedPDF : self.previewType
            }
            return self.previewType
        } else {
            return self.previewType
        }
    }

    func getMeta() -> DriveFileMeta? {
        return getFileMeta()
    }
    
    var isIMFile: Bool {
        return false
    }

    var fileID: String {
        return fileToken
    }

    var wpsInfo: DriveWPSPreviewInfo {
        return DriveWPSPreviewInfo(fileToken: fileToken, fileType: fileType, authExtra: authExtra, isEditable: BehaviorRelay<Bool>(value: false))
    }

    var wpsEnable: Bool {
        guard fileType.isWpsOffice else { return false }
        return DriveFeatureGate.wpsEnable
    }
}
