//
//  DriveRouter.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/17.
// swiftlint:disable function_parameter_count

import Foundation
import LarkUIKit
import SpaceInterface
import UniverseDesignToast
import UniverseDesignDialog
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import EENavigator
import UIKit
import Photos
import LarkFoundation
import SKInfra
import LarkSensitivityControl
import LarkDocsIcon
/// Drive Interface

final public class DriveRouter {
    static var vc: UIActivityViewController?

    /// 用其他应用打开
    class func openWith3rdApp(context: OpenInOtherAppContext,
                                     callback: ((String, Bool) -> Void)? = nil) {
        let fileMeta = context.fileMeta
        let sourceController = context.sourceParam.sourceController
        let sourceControllerView: UIView = context.sourceParam.sourceController.view.window ?? context.sourceParam.sourceController.view
        let previewFrom = context.previewFrom
        let additionalParameters = context.additionalParameters
        let sourceAnchorParam = context.sourceParam

        DocsTracker.reportDriveDownload(event: .driveDownloadBeginClick,
                                        mountPoint: fileMeta.mountPoint,
                                        fileToken: fileMeta.fileToken,
                                        fileType: fileMeta.type)

        if CacheService.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] 开启KA加密不能导出文件到第三方应用")
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast,
                             on: sourceControllerView)
            return
        }
        // Drive数据埋点：用其他应用打开
        SecurityReviewManager.reportAction(.file,
                                           operation: OperationType.operationsOpenWith3rdApp,
                                           driveType: fileMeta.fileType,
                                           token: fileMeta.fileToken,
                                           appInfo: nil,
                                           wikiToken: nil)
        // 可用容量检查
        guard let diskSpace = SKFilePath.getFreeDiskSpace(), diskSpace > fileMeta.size else {
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_insufficient_toast,
                             on: sourceControllerView)
            return
        }
        // 最大下载限制
        let downloadLimit: UInt64 = DriveFeatureGate.downloadMaxSizeLimit
        guard fileMeta.size < downloadLimit else {
            let size = downloadLimit / 1024 / 1024 / 1024
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_TooLarge_toast(size),
                             on: sourceControllerView)
            return
        }

        if let userID = User.current.basicInfo?.userID,
           let reporter = DocsContainer.shared.resolve(DocumentActivityReporter.self) {
            let activity = DocumentActivity(objToken: fileMeta.fileToken, objType: .file, operatorID: userID,
                                            scene: .download, operationType: .openWithOtherApp)
            reporter.report(activity: activity)
        } else {
            spaceAssertionFailure()
        }

        DriveStatistic.toggleAttribute(fileId: fileMeta.fileToken,
                                       subFileType: fileMeta.type,
                                       action: .openInOtherApps,
                                       source: .headerbarMore,
                                       previewFrom: previewFrom.stasticsValue,
                                       additionalParameters: additionalParameters)
        let cacheService = DriveCacheService.shared
        if let itemProvider = cacheService.getDriveItemProvider(token: fileMeta.fileToken,
                                                                dataVersion: fileMeta.dataVersion,
                                                                fileExtension: fileMeta.fileExtension) {
            // TODO: 删除冗余的鉴权逻辑
            /// 产品要求：有缓存时，用dlp做下鉴权
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
                let request = PermissionRequest(token: fileMeta.fileToken, type: .file, operation: .openWithOtherApp, bizDomain: previewFrom.permissionBizDomain, tenantID: nil)
                let response = permissionSDK.validate(request: request)
                response.didTriggerOperation(controller: sourceController)
                guard response.allow else { return }
            } else {
                let dlpStatus = DlpManager.status(with: fileMeta.fileToken, type: .file, action: .EXPORT)
                guard dlpStatus == .Safe else {
                    DocsLogger.driveInfo("dlp control, can not openWith3rdApp. dlp \(dlpStatus.rawValue)")
                    let text = dlpStatus.text(action: .EXPORT, isSameTenant: fileMeta.isSameTenantWithOwner)
                    let type: DocsExtension<UDToast>.MsgType = dlpStatus == .Detcting ? .tips : .failure
                    PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .EXPORT, status: dlpStatus, isSameTenant: fileMeta.isSameTenantWithOwner)
                    UDToast.docs.showMessage(text, on: sourceController.view, msgType: type)
                    return
                }
            }
            
            openWithActivityController(activityItem: itemProvider,
                                       anchorParam: sourceAnchorParam,
                                       callback: callback)
        } else {
            if !DocsNetStateMonitor.shared.isReachable {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: sourceController.view)
                return
            }
            let pathURL = cacheService.driveFileDownloadURL(cacheType: .origin, fileToken: fileMeta.fileToken, dataVersion: fileMeta.dataVersion ?? "", fileExtension: fileMeta.type)
            let loadingViewContext = ShowLoadingViewContext(fileMeta: fileMeta,
                                                            isLatest: context.isLatest,
                                                            fromVC: sourceController,
                                                            skipCellularCheck: context.skipCellularCheck,
                                                            appealAlertFrom: context.appealAlertFrom)
            let loadingView = DriveLoadingAlertView.show(context: loadingViewContext, completed: {
                guard let itemProvider = cacheService.getDriveItemProvider(token: fileMeta.fileToken,
                                                                           dataVersion: fileMeta.dataVersion,
                                                                           fileExtension: fileMeta.fileExtension) else {
                    DocsLogger.error("Download Success but failed to get cache path when open with 3rd app")
                    let simpleProvider = SimpleMetadataUIActivityItemProvider(fileURL: pathURL.pathURL, isSimple: false)
                    openWithActivityController(simpleProvider: simpleProvider,
                                               anchorParam: sourceAnchorParam,
                                               callback: callback)
                    return
                }
                openWithActivityController(activityItem: itemProvider,
                                           anchorParam: sourceAnchorParam,
                                           callback: callback)
            })
            loadingView.cancelAction = {
                // Drive数据埋点：取消加载
                DriveStatistic.toggleAttribute(fileId: fileMeta.fileToken,
                                               subFileType: fileMeta.fileType.rawValue,
                                               action: DriveStatisticAction.cancelOpenInOtherApps,
                                               source: .window,
                                               previewFrom: previewFrom.stasticsValue,
                                               additionalParameters: additionalParameters)
            }
        }
    }

    /// 弹出系统ActivityController
    ///
    /// - Parameters:
    ///   - pathURL: 文件路径
    ///   - sourceController: 源控制器
    class func openWithActivityController(simpleProvider: SimpleMetadataUIActivityItemProvider,
                                          anchorParam: ActivityAnchorParam,
                                          callback: ((String, Bool) -> Void)?) {
        _openWithActivityController(provider: simpleProvider,
                                    anchorParam: anchorParam,
                                    callback: callback)
    }

    /// 弹出系统ActivityController
    ///
    /// - Parameters:
    ///   - activityItem: UIActivityItemProvider 对象
    ///   - sourceController: 源控制器
    private class func openWithActivityController(activityItem: DriveCacheItemProvider,
                                                  anchorParam: ActivityAnchorParam,
                                                  callback: ((String, Bool) -> Void)?) {
        DispatchQueue.global().async {
            _ = activityItem.item
            DispatchQueue.main.async {
                _openWithActivityController(provider: activityItem,
                                            anchorParam: anchorParam,
                                            callback: callback)
            }
        }
    }
    
    private class func _openWithActivityController(provider: UIActivityItemProvider,
                                                   anchorParam: ActivityAnchorParam,
                                                   callback: ((String, Bool) -> Void)?) {
        DocsLogger.driveInfo("open with UIActivityViewController")
        var activityController = UIActivityViewController(activityItems: [provider as Any], applicationActivities: nil)
        if SKDisplay.pad {
            _setupActivityController(&activityController, anchorParam: anchorParam)
        }
        DocsLogger.driveInfo("open with UIActivityViewController completionWithItemsHandler")
        activityController.completionWithItemsHandler = { activity, success, items, error in
            callback?(activity?.rawValue ?? "", success)
            DocsLogger.driveInfo("open with UIActivityViewController callback: activity \(String(describing: activity)), completed: \(success), error: \(String(describing: error)) ")
            DriveRouter.vc = nil
        }
        anchorParam.sourceController.present(activityController, animated: true, completion: nil)
        vc = activityController
    }

    private class func _setupActivityController(_ activityController: inout UIActivityViewController,
                                                anchorParam: ActivityAnchorParam) {
        activityController.popoverPresentationController?.sourceView = anchorParam.sourceView ?? anchorParam.sourceController.view
        activityController.modalPresentationStyle = .popover
        let defaultRect: CGRect
        if let currentWindow = anchorParam.sourceController.view.window {
            defaultRect = CGRect(x: currentWindow.frame.midX, y: currentWindow.frame.midY,
                                 width: 0, height: 0)
        } else {
            defaultRect = CGRect(x: 0, y: 0, width: 0, height: 0)
            DocsLogger.error("failed to get current window")
            assertionFailure()
        }
        activityController.popoverPresentationController?.sourceRect = anchorParam.sourceRect ?? defaultRect
    }
}

extension DriveRouter: DriveRouterBase {

    /// 展示媒体选择器DriveAssetPickerViewController
    ///
    /// - Parameters
    ///   - sourceController: 源控制器
    ///   - folderPathToken: 当前文件夹路径token
    public static func showAssetPickerViewController(sourceViewController: UIViewController,
                                                     mountToken: String,
                                                     mountPoint: String,
                                                     scene: DriveUploadScene,
                                                     completion: ((Bool) -> Void)?) {
        // Drive数据埋点：点击上传多媒体
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.driveClickUploadMultimedia,
                                               fileId: "")
        reportUploadClick()
        let imagePicker = DriveImagePickerHelper.getImagePicker(mountToken: mountToken, mountPoint: mountPoint, scene: scene, rootVC: sourceViewController)
        DriveImagePickerHelper.imagePickerFinishCallBack = {[weak imagePicker] finish in
            imagePicker?.dismiss(animated: true, completion: nil)
            completion?(finish)
        }
        sourceViewController.present(imagePicker, animated: true, completion: nil)
    }

    /// 展示文件选择器DriveDocumentPickerViewController
    ///
    /// - Parameters
    ///   - sourceController: 源控制器
    ///   - mountToken: 当前文件夹路径token
    ///   - mountPoint: drive: explorer, wiki: wiki
    public static func showDocumentPickerViewController(sourceViewController: UIViewController,
                                                        mountToken: String,
                                                        mountPoint: String,
                                                        scene: DriveUploadScene,
                                                        completion: ((Bool) -> Void)?) {
        let documentPicker = DriveDocumentPickerViewController(mountToken: mountToken,
                                                               mountPoint: mountPoint,
                                                               scene: scene,
                                                               sourceViewController: sourceViewController,
                                                               completion: completion)
        // Drive数据埋点：点击上传文件
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.driveClickUploadFile,
                                               fileId: "")
        reportUploadClick()
        sourceViewController.present(documentPicker, animated: false, completion: nil)
    }

    /// 展示上传列表页面
    ///
    /// - Parameters
    ///   - sourceController: 源控制器
    ///   - folderToken: 当前文件夹路径token
    ///   - scene: 上传场景,目前处理wiki使用.wiki,其他场景使用unknown
    ///   - params: 数据上报参数
    public static func showUploadListViewController(sourceViewController: UIViewController, folderToken: String, scene: DriveUploadScene, params: [String: Any]) {
        let uploadListVC = DriveUploadListViewController(folderToken: folderToken, scene: scene, params: params)
        let naVC = UINavigationController(rootViewController: uploadListVC)
        naVC.modalPresentationStyle = .formSheet
        Navigator.shared.present(naVC, from: sourceViewController)
    }
    
    private static func reportUploadClick() {
        DriveStatistic.reportUpload(action: .clickUpoad,
                                    fileID: "",
                                    module: SKCreateTracker.moduleString,
                                    subModule: SKCreateTracker.subModuleString,
                                    srcModule: SKCreateTracker.srcModuleString,
                                    isDriveSDK: false)
    }
}

extension DriveRouter {
    // iPad 多窗口 workaround 寻找可用 VC 的方法，切勿滥用
    static func viewControllerForDriveRouter() -> UIViewController? {
        // nolint-next-line: magic number
        guard #available(iOS 13.0, *) else {
            return UIApplication.shared.delegate?.window?.map { $0 }?.rootViewController
        }
        if let activeScene = UIApplication.shared.windowApplicationScenes.first(where: {
            $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
        }),
        let windowScene = activeScene as? UIWindowScene,
        let delegate = windowScene.delegate as? UIWindowSceneDelegate {
            return delegate.window?.map { $0 }?.rootViewController
        }
        return UIApplication.shared.delegate?.window?.map { $0 }?.rootViewController
    }
}

extension DriveRouter {
    
    static func saveToLocal(fileInfo: DriveFileInfo, 
                            from: UIViewController, 
                            appealAlertFrom: DriveAppealAlertFrom,
                            complete: ((UIViewController, DKAttachmentInfo) -> Void)? = nil) {
        DocsTracker.reportDriveDownload(event: .driveDownloadBeginClick,
                                        mountPoint: fileInfo.mountPoint,
                                        fileToken: fileInfo.fileToken,
                                        fileType: fileInfo.type)

        if CacheService.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] 开启KA加密不能保存到本地")
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast,
                                on: from.view.window ?? from.view)
            return
        }
        // Drive数据埋点：保存到本地
        SecurityReviewManager.reportAction(.file, operation: OperationType.operationsDownload, 
                                           driveType: fileInfo.fileType,
                                           token: fileInfo.fileToken,
                                           appInfo: nil,
                                           wikiToken: nil,
                                           renderItems: SecurityReviewManager.getDriveSecurityEventitem(driveType: fileInfo.fileType))
        guard let diskSpace = SKFilePath.getFreeDiskSpace(), diskSpace > fileInfo.size else {
            DriveStatistic.reportEvent(DocsTracker.EventType.driveExceedStorageLimit, fileId: fileInfo.fileID, fileType: fileInfo.type)
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_insufficient_toast, on: from.view.window ?? from.view)
            return
        }
        
        let downloadLimit: UInt64 = DriveFeatureGate.downloadMaxSizeLimit
        guard fileInfo.size < downloadLimit else {
            DriveStatistic.reportEvent(DocsTracker.EventType.driveExceedDownloadLimit, fileId: fileInfo.fileID, fileType: fileInfo.type)
            let size = downloadLimit / 1024 / 1024 / 1024
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_TooLarge_toast(size), on: from.view.window ?? from.view)
            return
        }
        checkPhotosAlbumPermissionIfNeed(fileInfo.fileType) { granted in
            if granted {
                DocsLogger.driveInfo("DriveRouter - saveToLocal has albumPermission")
                downloadFile(fileInfo: fileInfo, from: from, appealAlertFrom: appealAlertFrom, complete: complete)
            } else {
                showNoPhotoPermissionDialog()
                DocsLogger.driveInfo("DriveRouter - saveToLocal has no albumPermission")
            }
        }
    }
    
    static func saveRouter(fileType: DriveFileType, filePath: SKFilePath, from: UIViewController) {
        if CacheService.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] 开启KA加密不能保存到本地")
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast,
                                on: from.view.window ?? from.view)
            return
        }
        if fileType.isAblumImage {
            guard let imageData = try? Data.read(from: filePath),
                    let image = UIImage(data: imageData) else {
                DocsLogger.error("path error")
                return
            }
            
            if fileType == .gif {
                saveGif(path: filePath.pathURL, from: from)
            } else {
                do {
                    try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: Token(PSDATokens.Drive.drive_preview_image_click_download), image, nil, nil, nil)
                    UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_toAlbum_toast, on: from.view.window ?? from.view)
                } catch {
                    DispatchQueue.main.async {
                        DocsLogger.driveError("AlbumEntry UIImageWriteToSavedPhotosAlbum error")
                        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: from.view.window ?? from.view)
                    }
                }
            }
        } else if fileType.isAblumVideo {
            let videoPath: String = filePath.pathString
            guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) else {
                UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_Save_Failed_IncompatibleFileType, on: from.view.window ?? from.view)
                return
            }
            do {
                try AlbumEntry.UISaveVideoAtPathToSavedPhotosAlbum(forToken: Token(PSDATokens.Drive.drive_preview_video_click_download), 
                                                                   videoPath,
                                                                   nil,
                                                                   nil,
                                                                   nil)
                UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_toAlbum_toast, on: from.view.window ?? from.view)
            } catch {
                DispatchQueue.main.async {
                    DocsLogger.driveError("AlbumEntry UISaveVideoAtPathToSavedPhotosAlbum error")
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: from.view.window ?? from.view)
                }
            }
        } else {
            let vc = UIDocumentPickerViewController(url: filePath.pathURL, in: .exportToService)
            from.present(vc, animated: true, completion: nil)
        }
    }
    
    private static func saveGif(path: URL, from: UIViewController) {
        var isSuccessSave = true
        PHPhotoLibrary.shared().performChanges({
            do {
                let request = try AlbumEntry.forAsset(forToken: Token(PSDATokens.Drive.drive_preview_gif_click_download))
                request.addResource(with: .photo, fileURL: path, options: nil)
            } catch {
                    isSuccessSave = false
                    DocsLogger.driveError("AlbumEntry.forAsset error")
            }
        }) { success, error in
            if let error = error {
                DocsLogger.error("save gif to album error", error: error)
            } else if success && isSuccessSave {
                DispatchQueue.main.async {
                    UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_toAlbum_toast, on: from.view.window ?? from.view)
                }
            } else {
                DispatchQueue.main.async {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: from.view.window ?? from.view)
                    DocsLogger.driveError("AlbumEntry.forAsset error")
                }
            }
        }
    }
    
    public static func showNoPhotoPermissionDialog() {
        let dialog = UDDialog.noPermissionDialog(title: BundleI18n.SKResource.LarkCCM_Drive_PhotoAccessForSavePhoto_Mob,
                                                 detail: BundleI18n.SKResource.LarkCCM_Drive_EnablePhotoAccess_ChangeProfilePhoto_Mob())
        guard let fromVC = Navigator.shared.mainSceneWindow?.lu.visibleViewController() else {
            return
        }
        Navigator.shared.present(dialog, from: fromVC)
    }
    
    public static func checkPhotosAlbumPermissionIfNeed(_ fileType: DriveFileType, _ handler: @escaping (_ granted: Bool) -> Void) {
        if fileType.isAblumImage || fileType.isAblumVideo {
            do {
                try Utils.checkPhotoWritePermission(token: Token(PSDATokens.Drive.drive_preview_download_check_permission), handler)
            } catch {
                DocsLogger.error("Utils checkPhotoWritePermission error")
                handler(false)
            }
        } else {
            handler(true)
        }
    }
    
    private static func downloadFile(fileInfo: DriveFileInfo,
                                     from: UIViewController,
                                     appealAlertFrom: DriveAppealAlertFrom,
                                     complete: ((UIViewController, DKAttachmentInfo) -> Void)? = nil) {
        var attachInfo = fileInfo.attachmentInfo()
        let dkDefaultRouter = DKDefaultRouter()
        dkDefaultRouter.downloadIfNeed(fileInfo: fileInfo, from: from, appealAlertFrom: appealAlertFrom) { (from, info) in
            if let path = info.localPath {
                let filePath = SKFilePath(absUrl: path)
                self.saveRouter(fileType: fileInfo.fileType,
                                filePath: filePath,
                                from: from)
            }
            
            attachInfo.localPath = info.localPath
            complete?(from, attachInfo)
            if let userID = User.current.basicInfo?.userID,
               let reporter = DocsContainer.shared.resolve(DocumentActivityReporter.self) {
                let activity = DocumentActivity(objToken: fileInfo.fileToken, objType: .file, operatorID: userID,
                                                scene: .download, operationType: .saveToLocal)
                reporter.report(activity: activity)
            } else {
                spaceAssertionFailure()
            }
        }
    }
}

/// Popover菜单页面的锚点参数
struct ActivityAnchorParam {
    let sourceController: UIViewController
    let sourceView: UIView?
    let sourceRect: CGRect?
    let arrowDirection: UIPopoverArrowDirection
}

struct OpenInOtherAppContext {
    let fileMeta: DriveFileMeta
    let sourceParam: ActivityAnchorParam
    let isLatest: Bool
    let actionSource: DriveStatisticActionSource
    let previewFrom: DrivePreviewFrom
    let skipCellularCheck: Bool
    let additionalParameters: [String: String]?
    /// "保存到本地/其它应用打开"操作来源，用于埋点
    let appealAlertFrom: DriveAppealAlertFrom
}
