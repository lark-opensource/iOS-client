//
//  DriveParseFileConfig.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/26.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra
import RxSwift

final class DriveConvertFileConfig {
    
    private static let defaultFileSizeLimit: Int = 20

    static var fileSizeLimit: Int {
        return SettingConfig.convertFileSizeLimit ?? defaultFileSizeLimit
    }

    static var performanceLogger: DrivePerformanceRecorder?

    static func parseFileEnabled(fileToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard self.isFeatureGatingEnabled() else {
            DocsLogger.driveInfo("DriveConvertFileConfig.parseFileEnabled: FG is cloced")
            completion(.failure(ConvertFileError.fgClosed))
            return
        }
        performanceLogger = DrivePerformanceRecorder(fileToken: fileToken, fileType: "", sourceType: .other, additionalStatisticParameters: nil)
        performanceLogger?.stageBegin(stage: .canImport)
        fetchFileInfo(fileToken: fileToken) { (result) in
            switch result {
            case .success:
                fetchPermission(token: fileToken, completion: completion)
            case .failure(let error):
                completion(.failure(error))
                DocsLogger.driveInfo("DriveConvertFileConfig.parseFileEnabled: false")
            }
        }
    }

    private static func fetchPermission(token: String, completion: @escaping(Result<Void, Error>) -> Void) {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let service = permissionSDK.userPermissionService(for: .document(token: token, type: .file))
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            service.updateUserPermission().subscribe { _ in
                performanceLogger?.stageEnd(stage: .canImport)
                if service.validate(operation: .importToOnlineDocument).allow {
                    completion(.success(()))
                    DocsLogger.driveInfo("DriveConvertFileConfig.parseFileEnabled: true")
                } else {
                    if service.validate(operation: .view).allow {
                        completion(.failure(ConvertFileError.noExportPermission))
                    } else {
                        completion(.failure(ConvertFileError.noReadablePermission))
                    }
                    DocsLogger.driveInfo("DriveConvertFileConfig.parseFileEnabled: false")
                }
            } onError: { error in
                DocsLogger.driveError("DriveConvertFileConfig.parseFileEnabled failed", error: error)
                completion(.failure(error))
            }
        } else {
            let permissionHelper = DrivePermissionHelper(fileToken: token, type: .file, permissionService: service)
            permissionHelper.fetchAllPermission(completion: { (_) in
                performanceLogger?.stageEnd(stage: .canImport)
                if permissionHelper.canExport {
                    completion(.success(()))
                    DocsLogger.driveInfo("DriveConvertFileConfig.parseFileEnabled: true")
                } else {
                    if !permissionHelper.isReadable {
                        completion(.failure(ConvertFileError.noReadablePermission))
                    } else {
                        completion(.failure(ConvertFileError.noExportPermission))
                    }
                    DocsLogger.driveInfo("DriveConvertFileConfig.parseFileEnabled: false")
                }
            })
        }
    }

    /// 文件信息请求 - 基本文件元数据信息
    private static var fetchFileInfoRequest: DocsRequest<JSON>?

    // MARK: - FileInfo
    private static func fetchFileInfo(fileToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchFileInfoRequest?.cancel()
        let params = ["file_token": fileToken, "mount_point": DriveConstants.driveMountPoint]
        fetchFileInfoRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfo,
                                                 params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .set(timeout: Double(ListConfig.requestTimeOut))
        fetchFileInfoRequest?.start(result: { (result, error) in

            if let error = error {
                DocsLogger.driveInfo("DriveParseFileConfig: fetch fileInfo failed \(error)")
                completion(.failure(ConvertFileError.importFailedRetry))
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    DocsLogger.driveInfo("DriveParseFileConfig: get Json data failed")
                    completion(.failure(ConvertFileError.importFailedRetry))
                    return
            }
            if code != 0 { // 解析错误码
                DocsLogger.driveInfo("DriveParseFileConfig: code is not zero")
                guard let fileInfoError = DriveFileInfoErrorCode(rawValue: code) else {
                    completion(.failure(ConvertFileError.importFailedRetry))
                    return
                }
                switch fileInfoError {
                case .fileDeletedOnServerError:
                    completion(.failure(ConvertFileError.isDeleted))
                case .fileNotFound:
                    completion(.failure(ConvertFileError.notExist))
                default:
                    completion(.failure(ConvertFileError.importFailedRetry))
                }
                return
            }
            guard let dataDic = json["data"].dictionaryObject,
                let fileSize = dataDic["size"] as? UInt64 else {
                completion(.failure(ConvertFileError.importFailedRetry))
                return
            }
            /// 判断fileSize是否超出限制
            if DriveConvertFileConfig.isSizeOverLimit(fileSize) {
                completion(.failure(ConvertFileError.fileSizeOverLimit))
                return
            }
            completion(.success(()))
        })
    }

    // MARK: - Feature Gating
    static func isFeatureGatingEnabled() -> Bool {
        let dic: [String: Bool] = CCMKeyValue.globalUserDefault.dictionary(
            forKey: UserDefaultKeys.moreVCNewFeature) as? [String: Bool] ?? [:]
        if dic["import_docs"] == true {
            return true
        }
        return false
    }

    static func getFileSizeText(from size: UInt64) -> String {
        return FileSizeHelper.memoryFormat(size)
    }

    static func isSizeOverLimit(_ byte: UInt64) -> Bool {
        let smallFileThreadhold = UInt64(fileSizeLimit * 1024 * 1024)
        return byte > smallFileThreadhold
    }

    /// 是否要显示各个转在线文档入口处的红色标识引导
    /// 小红点，或者new标识
    static func needShowRedGuide() -> Bool {
        // isOwner 不影响转在线文档的判断，暂时写死 false
        return MoreVCGuideConfig.shouldDisplayGuide(docsType: .file, itemType: .importAsDocs(nil), isOwner: false)
    }

    /// 记录已经展示过了，不再显示
    static func recordHadClickRedGuide() {
        MoreVCGuideConfig.markHasFinishGuide(docsType: .file, itemType: .importAsDocs(nil))
    }
}


extension DriveConvertFileConfig: DriveConvertFileConfigBase {
    static var featureEnabled: Bool { isFeatureGatingEnabled() }
    static var importSizeLimit: Int64 {
        Int64(fileSizeLimit) * 1024 * 1024
    }
}
