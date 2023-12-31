//
//  DriveThirdPartyFilePermission.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/8/8.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra
import SpaceInterface

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
class DriveThirdPartyFilePermission {
    let fileToken: String
    let authExtra: String?
    let mountPoint: String
    private var requestTask: DocsRequest<JSON>?
    private var failedBlock: ((PermissionResponseModel) -> Void)?
    private var permissionChangedBlock: PermissionChangedBlock?
    private var startFetchBlock: (() -> Void)?
    private var networkMonitor: SKNetStatusService
    private var isReachable: Bool {
        didSet {
            if isReachable != oldValue && isReachable {
                fetchPermissions()
            }
        }
    }

    let permissionService: UserPermissionService

    init(with fileToken: String,
         authExtra: String?,
         mountPoint: String,
         permissionService: UserPermissionService,
         networkMonitor: SKNetStatusService = DocsNetStateMonitor.shared) {
        self.fileToken = fileToken
        self.authExtra = authExtra
        self.mountPoint = mountPoint
        self.permissionService = permissionService
        self.networkMonitor = networkMonitor
        self.isReachable = networkMonitor.isReachable
        setupNetworkMonitor()
    }
    /// 监测网络连接变化
    private func setupNetworkMonitor() {
        networkMonitor.addObserver(self) { [weak self] (networkType, isReachable) in
            DocsLogger.debug("Current networkType is \(networkType)")
            self?.isReachable = isReachable
        }
    }
    func fetchPermission(completion: @escaping (DriveResult<DrivePermissionInfo>) -> Void) {
        requestTask?.cancel()
        var params = ["file_token": fileToken, "mount_point": mountPoint]
        if let extra = authExtra {
            params["extra"] = extra
        }
        requestTask = DocsRequest<JSON>(path: OpenAPI.APIPath.attachmentPermission, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: {[weak self] (json, error) in
                guard let self = self else { return }
                guard error == nil else {
                    DocsLogger.error("request attachmentPermission failed: \(error!.localizedDescription)")
                    completion(DriveResult.failure(error!))
                    return
                }
                guard let json = json,
                    let resultCode = json["code"].int else {
                        DocsLogger.error("request attachmentPermission failed: json is nil or result code is nil")
                        completion(.failure(DriveError.permissionError))
                        return
                }
                guard resultCode == 0 else {
                    DocsLogger.error("request attachmentPermission failed error code: \(resultCode)")
                    completion(.failure(DriveError.serverError(code: resultCode)))
                    return
                }
                guard let data = json["data"].dictionaryObject else {
                    DocsLogger.error("request attachmentPermission failed: data is nil")
                    completion(.failure(DriveError.permissionError))
                    return
                }
                if let permV2Data = json["data"]["perm_v2"].dictionaryObject {
                    let readable = permV2Data["view"] as? Int ?? AuthResultCode.allow.rawValue
                    let canExport = permV2Data["export"] as? Int ?? AuthResultCode.allow.rawValue
                    let copy = permV2Data["copy"] as? Int ?? AuthResultCode.allow.rawValue
                    let isCACBlockExport = (canExport == AuthResultCode.blockedByCAC.rawValue) || (copy == AuthResultCode.blockedByCAC.rawValue)
                    if readable == AuthResultCode.blockedByCAC.rawValue {
                        completion(DriveResult.success(self.parseData(data, permV2Data, true, isCACBlockExport)))
                    } else {
                        completion(DriveResult.success(self.parseData(data, permV2Data, false, isCACBlockExport)))
                    }
                } else {
                    completion(DriveResult.success(self.parseData(data, nil)))
                }
            })
        }
    func fetchPermissions() {
        startFetchBlock?()
        fetchPermission {[weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let info):
                self.permissionChangedBlock?(info)
            case .failure(let error):
                let model = PermissionResponseModel(userPermissions: nil,
                                                    publicPermissionMeta: nil,
                                                    permissionStatusCode: nil,
                                                    error: error)
                self.failedBlock?(model)
            }
        }
    }
    private func parseData(_ data: [String: Any],
                           _ bizExtra: [String: Any]?,
                           _ isCACBlockPreview: Bool = false,
                           _ isCACBlockExport: Bool = false) -> DrivePermissionInfo {
        let readable = data["view"] as? Bool ?? false
        let editable = data["edit"] as? Bool ?? false
        let canExport = data["export"] as? Bool ?? false
        let copy = data["copy"] as? Bool ?? false
        
        let canComment = false
        let canShowCollaboratorInfo = true
        let canDownload: Bool
        if isCACBlockExport {
            canDownload = true
        } else {
            canDownload = canExport
        }
        var info = DrivePermissionInfo(isReadable: readable,
                                       isEditable: editable,
                                       canComment: canComment,
                                       canExport: canDownload,
                                       canCopy: copy,
                                       canShowCollaboratorInfo: canShowCollaboratorInfo,
                                       isCACBlock: isCACBlockPreview,
                                       permissionStatusCode: nil,
                                       userPermissions: nil)
        info.bizExtra = bizExtra
        return info
    }
    
    /// 解析权限模型返回值
    private func isAllowFor(authResultCode: AuthResultCode) -> Bool {
        /// 默认放行，由后端兜底
        var res: Bool = true
        switch authResultCode {
        case .unknown, .allow:
            res = true
        case .deny, .error, .blockedByCAC:
            DocsLogger.error("Admin control operation:\(authResultCode.rawValue)")
            res = false
        @unknown default:
            res = true
        }
        return res
    }
    
}

extension DriveThirdPartyFilePermission: DrivePermissionHelperProtocol {

    func startMonitorPermission(startFetch: @escaping () -> Void,
                                permissionChanged: @escaping PermissionChangedBlock,
                                failed: @escaping (PermissionResponseModel) -> Void) {
        self.startFetchBlock = startFetch
        self.permissionChangedBlock = permissionChanged
        self.failedBlock = failed
        if isReachable {
            fetchPermissions()
        }
    }
    
    func unRegister() {
        // 没有长链不需要实现
    }
}
public enum AuthResultCode: Int {
    case allow = 1      // 有权限
    case deny = 2       // 无权限
    case unknown = 3    // 权限未知
    case error = 4      // 鉴权失败
    
    case blockedByCAC = 2002  // 被条件访问控制管控无权限
}

