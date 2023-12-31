//
//  DriveMoreAction.swift
//  SKDrive
//
//  Created by ByteDance on 2022/8/26.
//

import Foundation
import SKCommon
import SwiftyJSON
import SKFoundation
import RxSwift
import UIKit
import UniverseDesignToast
import SKResource
import LarkSecurityComplianceInterface
import SKInfra
import SpaceInterface

public final class DriveFileExportCapacity: DriveMoreActionProtocol {
    private init() {
    }
    public static let shared = DriveFileExportCapacity()
    private var disposeBag = DisposeBag()
    private var saveToSpaceRequest: DocsRequest<JSON>?
    private var netManager: DrivePreviewNetManagerProtocol?
    private let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!

    public func saveToLocal(fileSize: UInt64,
                            fileObjToken: String,
                            fileName: String,
                            sourceController: UIViewController) {
        let meta = getDriveFileMeta(fileObjToken: fileObjToken, fileSize: fileSize, fileName: fileName)
        let info = DriveFileInfo(fileMeta: meta)
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: fileObjToken, type: .file, operation: .saveFileToLocal, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: sourceController)
            guard response.allow else { return }
            DriveRouter.saveToLocal(fileInfo: info, from: sourceController, appealAlertFrom: .driveAttachmentDownload)
        } else {
            checkPolicy(entityOperate: .ccmFileDownload, fileToken: meta.fileToken, sourceController: sourceController) {
                DriveRouter.saveToLocal(fileInfo: info, from: sourceController, appealAlertFrom: .driveAttachmentDownload)
            }
        }
    }
    
    public func saveToSpace(fileObjToken: String,
                            fileSize: UInt64,
                            fileName: String,
                            sourceController: UIViewController) {
        let pathExtention = (fileName as NSString).pathExtension
        let meta = getDriveFileMeta(fileObjToken: fileObjToken, fileSize: fileSize, fileName: fileName)
        let info = DriveFileInfo(fileMeta: meta)
        let performanceRecorder = DrivePerformanceRecorder(fileToken: fileObjToken,
                                                           fileType: pathExtention,
                                                           previewFrom: .docsAttach,
                                                           sourceType: .preview,
                                                           additionalStatisticParameters: [DrivePerformanceRecorder.ReportKey.sdkAppID.rawValue: ""])
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: fileObjToken, type: .file, operation: .uploadAttachment, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: sourceController)
            guard response.allow else { return }
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmAttachmentUpload, fileBizDomain: .ccm,
                                                               docType: .file, token: meta.fileToken)
            if !result.allow && result.validateSource == .fileStrategy {
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmAttachmentUpload, fileBizDomain: .ccm,
                                                             docType: .file, token: meta.fileToken)
                return
            } else if !result.allow && result.validateSource == .securityAudit {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: sourceController.view.window ?? sourceController.view)
                return
            }
        }
        netManager = DrivePreviewNetManager(performanceRecorder, fileInfo: info)
        netManager?.saveToSpace(fileInfo: info) {[weak self] (result) in
            switch result {
            case .success:
                DocsLogger.error("docx save to space  success")
                UDToast.showSuccess(with: BundleI18n.SKResource.Drive_Drive_SaveSuccess, on: sourceController.view.window ?? sourceController.view)
            case let .failure(error):
                DocsLogger.error("docx save to space  failure")
                self?.handleError(error, fileToken: fileObjToken, fileSize: fileSize, sourceController: sourceController)
            }
        }
    }
    
    public func openDriveFileWithOtherApp(fileSize: UInt64,
                                          fileObjToken: String,
                                          fileName: String,
                                          sourceController: UIViewController) {
        let router = DKDefaultRouter()
        let meta = getDriveFileMeta(fileObjToken: fileObjToken, fileSize: fileSize, fileName: fileName)
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: fileObjToken, type: .file, operation: .openWithOtherApp, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: sourceController)
            guard response.allow else { return }
            router.downloadAndOpenWithOtherApp(meta: meta, from: sourceController, sourceView: nil, sourceRect: nil, callback: nil)
        } else {
            checkPolicy(entityOperate: .ccmFileDownload, fileToken: meta.fileToken, sourceController: sourceController) {
                router.downloadAndOpenWithOtherApp(meta: meta, from: sourceController, sourceView: nil, sourceRect: nil, callback: nil)
            }
        }
    }
    
    private func handleError(_ error: Error, fileToken: String, fileSize: UInt64, sourceController: UIViewController) {
        guard case let DriveError.serverError(code) = error else {
            UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SaveFailed, on: sourceController.view.window ?? sourceController.view)
            return
        }
        if QuotaAlertPresentor.shared.enableTenantQuota && code == DocsNetworkError.Code.createLimited.rawValue {
            QuotaAlertPresentor.shared.showQuotaAlert(type: .saveToSpace, from: sourceController)
        } else if QuotaAlertPresentor.shared.enableUserQuota && code == DocsNetworkError.Code.driveUserStorageLimited.rawValue {
            let bizParams = SpaceBizParameter(module: .docx, fileID: fileToken, fileType: .file)
            QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil, mountPoint: nil, from: sourceController, bizParams: bizParams)
        } else if SettingConfig.sizeLimitEnable && code == DocsNetworkError.Code.spaceFileSizeLimited.rawValue {
            QuotaAlertPresentor.shared.showUserUploadAlert(mountNodeToken: nil, mountPoint: nil, from: sourceController, fileSize: Int64(fileSize), quotaType: .bigFileSaveToSpace)
        } else {
            if let docsError = DocsNetworkError(code),
                let message = docsError.code.errorMessage {
                UDToast.showFailure(with: message, on: sourceController.view.window ?? sourceController.view)
            } else {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SaveFailed, on: sourceController.view.window ?? sourceController.view)
            }
        }
    }
    
    private func getDriveFileMeta(fileObjToken: String,
                             fileSize: UInt64,
                             fileName: String) -> DriveFileMeta {
        let pathExtention = (fileName as NSString).pathExtension
        let meta = DriveFileMeta(size: fileSize,
                                 name: fileName,
                                 type: pathExtention,
                                 fileToken: fileObjToken,
                                 mountNodeToken: "",
                                 mountPoint: DriveConstants.driveMountPoint,
                                 version: nil,
                                 dataVersion: nil,
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        return meta
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func checkPolicy(entityOperate: EntityOperate, fileToken: String, sourceController: UIViewController, handler: (() -> Void)?) {
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: entityOperate, fileBizDomain: .ccm,
                                                           docType: .file, token: fileToken)
        
        if result.allow {
            handler?()
        } else {
            if result.validateSource == .fileStrategy {
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: entityOperate, fileBizDomain: .ccm,
                                                             docType: .file, token: fileToken)
            } else  {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: sourceController.view.window ?? sourceController.view)
            }
        }
    }
    
}

