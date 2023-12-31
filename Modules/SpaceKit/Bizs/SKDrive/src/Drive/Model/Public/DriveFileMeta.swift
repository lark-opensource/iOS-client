//
//  DriveFileMeta.swift
//  SpaceKit
//
//  Created by Wenjian Wu on 2019/3/14.
//  

import Foundation
import SKCommon
import SKFoundation
import SKInfra

/// 文件元数据，外部模块传入预览模块
public struct DriveFileMeta: DriveFileCacheable {
    /// 大小
    public let size: UInt64
    /// 文件名称
    public let name: String
    /// 文件类型
    public let type: String

    /// 文件token
    public let fileToken: String
    /// 父节点token
    public let mountNodeToken: String

    public let mountPoint: String

    /// 文件版本，其实是后端定义的时间戳，重命名后会改动
    public var version: String?

    /// 文件数据版本，重命名之后不会变
    public var dataVersion: String?

    /// 文件owner租户id
    var tenantID: String?

    /// 判断fileInfo的信息来源，来自cache的fileInfo预览不能进行评论、不触发拉取评论
    var source: DriveFileInfoSource
    var authExtra: String? // 第三方附件接入业务可以通过authExtra透传参数给业务后方进行鉴权，根据业务需要可选

    public init(size: UInt64,
                name: String,
                type: String,
                fileToken: String,
                mountNodeToken: String,
                mountPoint: String,
                version: String?,
                dataVersion: String?,
                source: DriveFileInfoSource,
                tenantID: String?,
                authExtra: String?) {
        self.size = size
        self.name = name
        self.type = type
        self.fileToken = fileToken
        self.mountNodeToken = mountNodeToken
        self.mountPoint = mountPoint
        self.version = version
        self.dataVersion = dataVersion
        self.source = source
        self.authExtra = authExtra
        self.tenantID = tenantID
    }

    /// 当前用户与Owner是否同租户
    public var isSameTenantWithOwner: Bool {
        return self.tenantID == User.current.info?.tenantID
    }

    /// 下载预览相似文件的 URL
    var downloadPreviewURL: URL? {
        var params = [String: String]()
        if let v = dataVersion, !v.isEmpty {
            params["version"] = v
        }
        params["preview_type"] = String(DrivePreviewFileType.similarFiles.rawValue)
        if let extra = self.authExtra {
            params["extra"] = extra
        }
        params["mount_point"] = mountPoint
        let sortedParams = params.sorted(by: { $0.0 < $1.0 })

        var components = URLComponents()
        components.scheme = OpenAPI.docs.currentNetScheme
        components.host = DomainConfig.driveDomain
        components.path = DomainConfig.pathPrefix + OpenAPI.APIPath.driveFetchPreviewFile + fileToken
        components.queryItems = sortedParams.map({ (arg) -> URLQueryItem in
            let (key, value) = arg
            return URLQueryItem(name: key, value: value)
        })

        DocsLogger.driveInfo("DriveFileMeta -- scheme: \(OpenAPI.docs.currentNetScheme), host: \(components.host), path: \(DomainConfig.pathPrefix + OpenAPI.APIPath.driveFetchPreviewFile)")

        let url = components.url
        return url
    }
}
