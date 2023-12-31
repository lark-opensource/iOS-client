//
//  DKDefaultRouter.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/7/7.
//

import UIKit
import EENavigator
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import SpaceInterface
import LarkUIKit
import SKInfra

// 文件转在线文档类型
enum DKConvertFileType {
    // space、第三方附件
    case attachment(info: DriveFileInfo)
    // im附件
    case im(info: DKFileInfo, msgID: String)
}

protocol DKRouter {
    func openDrive(token: String,
                   appID: String,
                   from: UIViewController)
    func openWith3rdApp(filePath: URL,
                        from: UIViewController,
                        sourceView: UIView?,
                        sourceRect: CGRect?,
                        callback: ((String, Bool) -> Void)?)
    func downloadAndOpenWithOtherApp(meta: DriveFileMeta,
                                     from: UIViewController,
                                     sourceView: UIView?,
                                     sourceRect: CGRect?,
                                     callback: ((String, Bool) -> Void)?)
    func downloadIfNeed(fileInfo: DriveFileInfo,
                        from: UIViewController,
                        appealAlertFrom: DriveAppealAlertFrom,
                        previewFrom: DrivePreviewFrom,
                        completed: @escaping (UIViewController, DKAttachmentInfo) -> Void)
    func pushConvertFileVC(type: DKConvertFileType,
                           actionSource: DriveStatisticActionSource,
                           previewFrom: DrivePreviewFrom,
                           from: UIViewController)
}

struct DKDefaultRouter: DKRouter {
    var permissionSDK: PermissionSDK {
        DocsContainer.shared.resolve(PermissionSDK.self)!
    }
    func openDrive(token: String, appID: String, from: UIViewController) {
        let file = SpaceEntryFactory.createEntry(type: .file, nodeToken: "", objToken: token)
        var statisticInfo = [String: String]()
        if let supportedApp = DKSupportedApp(rawValue: appID),
           let moduleString = supportedApp.statisticModuleString {
            // 目前在 DriveSDK 从 spaceEntry 方式调用 Drive 打开文件，module 的事件有 _link 后缀
            statisticInfo[DriveStatistic.ReportKey.module.rawValue] = moduleString + "_link"
            statisticInfo[DriveStatistic.ReportKey.srcModule.rawValue] = ""
            statisticInfo[DriveStatistic.ReportKey.subModule.rawValue] = ""
            statisticInfo[DriveStatistic.ReportKey.srcObjId.rawValue] = ""
        }
        let driveVC = DriveVCFactory.shared.makeDrivePreview(file: file, fileList: [file], from: .driveSDK, statisticInfo: statisticInfo)
        Navigator.shared.push(driveVC, from: from)
    }
    
    func openWith3rdApp(filePath: URL, from: UIViewController, sourceView: UIView?, sourceRect: CGRect?, callback: ((String, Bool) -> Void)?) {
        if CacheService.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] 开启KA加密不能导出文件到第三方应用")
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast,
                                on: from.view.window ?? from.view)
            return
        }
        openWithActivityVC(filePath: filePath, from: from, sourceView: sourceView, sourceRect: sourceRect, callback: callback)
    }
    
    private func openWithActivityVC(filePath: URL,
                                    from: UIViewController,
                                    sourceView: UIView?,
                                    sourceRect: CGRect?,
                                    callback: ((String, Bool) -> Void)?) {
        let itemProvider = SimpleMetadataUIActivityItemProvider(fileURL: filePath, isSimple: false)
        let sourceAnchorParam = ActivityAnchorParam(sourceController: from,
                                                    sourceView: sourceView,
                                                    sourceRect: sourceRect,
                                                    arrowDirection: .up)
        DriveRouter.openWithActivityController(simpleProvider: itemProvider,
                                               anchorParam: sourceAnchorParam,
                                               callback: callback)
    }
    
    func downloadAndOpenWithOtherApp(meta: DriveFileMeta,
                                     from: UIViewController,
                                     sourceView: UIView?,
                                     sourceRect: CGRect?,
                                     callback: ((String, Bool) -> Void)?) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: meta.fileToken, type: .file, operation: .openWithOtherApp, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: from)
            guard response.allow else { return }
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: .ccm,
                                                               docType: .file, token: meta.fileToken)
            if !result.allow && result.validateSource == .fileStrategy {
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileDownload, fileBizDomain: .ccm,
                                                             docType: .file, token: meta.fileToken)
                return
            } else if !result.allow && result.validateSource == .securityAudit {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: from.view.window ?? from.view)
                return
            }
        }
        let sourceParam = ActivityAnchorParam(sourceController: from,
                                              sourceView: sourceView,
                                              sourceRect: sourceRect,
                                              arrowDirection: .up)
        let open3rdAppContext = OpenInOtherAppContext(fileMeta: meta,
                                                      sourceParam: sourceParam,
                                                      isLatest: true,
                                                      actionSource: .unknow,
                                                      previewFrom: .unknown,
                                                      skipCellularCheck: false,
                                                      additionalParameters: nil,
                                                      appealAlertFrom: .unknown)
        DriveRouter.openWith3rdApp(context: open3rdAppContext,
                                   callback: callback)
    }
    
    func downloadIfNeed(fileInfo: DriveFileInfo,
                        from: UIViewController,
                        appealAlertFrom: DriveAppealAlertFrom = .unknown,
                        previewFrom: DrivePreviewFrom = .unknown,
                        completed: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: fileInfo.fileToken, type: .file, operation: .download, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: from)
            guard response.allow else { return }
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint,
                                                               docType: .file, token: fileInfo.fileToken)
            if !result.allow && result.validateSource == .fileStrategy {
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint,
                                                             docType: .file, token: fileInfo.fileToken)
                return
            } else if !result.allow && result.validateSource == .securityAudit {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: from.view.window ?? from.view)
                return
            }
        }

        var info = fileInfo.attachmentInfo()
        let cacheService = DriveCacheService.shared
        if let file = try? cacheService.getDriveFile(type: .origin,
                                                     token: fileInfo.fileToken,
                                                     dataVersion: fileInfo.dataVersion,
                                                     fileExtension: fileInfo.fileExtension).get() {
            if !UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                /// 产品要求：有缓存时，用dlp做下鉴权
                let dlpStatus = DlpManager.status(with: fileInfo.fileToken, type: .file, action: .EXPORT)
                guard dlpStatus == .Safe else {
                    DocsLogger.driveInfo("dlp control, can not download. dlp \(dlpStatus.rawValue)")
                    let text = dlpStatus.text(action: .EXPORT, isSameTenant: fileInfo.isSameTenantWithOwner)
                    let type: DocsExtension<UDToast>.MsgType = dlpStatus == .Detcting ? .tips : .failure
                    PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .EXPORT, status: dlpStatus, isSameTenant: fileInfo.isSameTenantWithOwner)
                    UDToast.docs.showMessage(text, on: from.view.window ?? from.view, msgType: type)
                    return
                }
            }
            
            guard let fileURL = file.fileURL else {
                spaceAssertionFailure("DKDefaultRouter -- cache node fileURL not set")
                return
            }
            
            let tmpPath = cacheService.getItemURL(pathURL: fileURL, fileName: info.name)
            info.localPath = tmpPath.pathURL
            completed(from, info)
        } else {
            if !DocsNetStateMonitor.shared.isReachable {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: from.view.window ?? from.view)
                return
            }
            let fileMeta = fileInfo.getFileMeta()
            let pathURL = cacheService.driveFileDownloadURL(cacheType: .origin,
                                                            fileToken: fileMeta.fileToken,
                                                            dataVersion: fileMeta.dataVersion ?? "",
                                                            fileExtension: fileMeta.type)
            let context = ShowLoadingViewContext(fileMeta: fileMeta, isLatest: true, fromVC: from, skipCellularCheck: false, appealAlertFrom: appealAlertFrom)
            let loadingView = DriveLoadingAlertView.show(context: context, completed: {
                let params: [String: Any] = ["click": "finish", "target": "none"]
                DriveStatistic.reportEvent(DocsTracker.EventType.driveFileDownloadClick, fileId: fileInfo.fileID, fileType: fileInfo.type, params: params)
                DriveStatistic.reportEvent(DocsTracker.EventType.driveFileDownloadView, fileId: fileInfo.fileID, fileType: fileInfo.type)
                DocsLogger.driveInfo("download success")
                if let path = try? cacheService.getDriveFile(type: .origin,
                                                             token: fileInfo.fileToken,
                                                             dataVersion: fileInfo.dataVersion,
                                                             fileExtension: fileInfo.fileExtension).get().fileURL {
                    let tmpPath = cacheService.getItemURL(pathURL: path, fileName: fileMeta.name)
                    info.localPath = tmpPath.pathURL
                    completed(from, info)
                } else {
                    DocsLogger.driveInfo("fileNotFound")
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: from.view.window ?? from.view)
                }
            })
            loadingView.cancelAction = {
                let params: [String: Any] = ["click": "cancel", "target": "none"]
                DriveStatistic.reportEvent(DocsTracker.EventType.driveFileDownloadClick, fileId: fileInfo.fileID, fileType: fileInfo.type, params: params)
                DocsLogger.driveInfo("cancle downloading")
            }
        }
    }
    
    // 跳转到转码界面
    func pushConvertFileVC(type: DKConvertFileType, actionSource: DriveStatisticActionSource, previewFrom: DrivePreviewFrom, from: UIViewController) {
        switch type {
        case let .im(info, msgID):
            pushImFileConvertFile(fileInfo: info,
                                  msgID: msgID,
                                  actionSource: actionSource,
                                  previewFrom: previewFrom,
                                  from: from)
        case let .attachment(info):
            pushAttachmentConvertFile(fileInfo: info,
                                      actionSource: actionSource,
                                      previewFrom: previewFrom,
                                      from: from)
        }
    }
    
    // 云盘文件、第三方附件类型转在线文档
    private func pushAttachmentConvertFile(fileInfo: DriveFileInfo,
                                           actionSource: DriveStatisticActionSource,
                                           previewFrom: DrivePreviewFrom,
                                           from: UIViewController) {
        DocsLogger.driveInfo("DKDefaultRouter -- attachment file import as online file")
        let performanceLogger = DrivePerformanceRecorder(fileToken: fileInfo.fileToken,
                                                         fileType: fileInfo.fileType.rawValue,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let viewModel = DriveConvertFileViewModel(fileInfo: fileInfo, performanceLogger: performanceLogger)
        let vc = DriveConvertFileViewController(viewModel: viewModel,
                                                loadingView: DocsContainer.shared.resolve(DocsLoadingViewProtocol.self),
                                                actionSource: actionSource,
                                                previewFrom: previewFrom)
        Navigator.shared.push(vc, from: from)
    }
    
    // im附件转在线文档
    private func pushImFileConvertFile(fileInfo: DKFileInfo,
                                       msgID: String,
                                       actionSource: DriveStatisticActionSource,
                                       previewFrom: DrivePreviewFrom,
                                       from: UIViewController) {
        DocsLogger.driveInfo("DKDefaultRouter -- im file import as online file")
        let performanceLogger = DrivePerformanceRecorder(fileToken: fileInfo.fileID,
                                                         fileType: fileInfo.fileType.rawValue,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        performanceLogger.previewFrom = .im
        let dependency = DKIMFileConvertVMDependencyImpl()
        let vm = DKIMFileConvertViewModel(fileInfo: fileInfo,
                                          msgID: msgID,
                                          dependency: dependency,
                                          performanceLogger: performanceLogger)
        let vc = DriveConvertFileViewController(viewModel: vm,
                                                loadingView: DocsContainer.shared.resolve(DocsLoadingViewProtocol.self),
                                                performanceLogger: performanceLogger,
                                                actionSource: actionSource,
                                                previewFrom: previewFrom)
        Navigator.shared.push(vc, from: from)
    }
}
