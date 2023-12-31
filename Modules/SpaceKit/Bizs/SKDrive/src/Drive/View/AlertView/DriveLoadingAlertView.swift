//
//  DriveLoadingAlertView.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/22.
//

import UIKit
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignToast
import UniverseDesignProgressView
import UniverseDesignColor
import UniverseDesignDialog
import EENavigator
import Swinject
import SpaceInterface
import SKInfra

class DriveLoadingAlertView: ProgressAlertView {
    private var downloadService: DriveDownloadService?
    override func didCanceled() {
        downloadService?.stop()
        super.didCanceled()
    }
}

public struct ShowLoadingViewContext {
    public let fileMeta: DriveFileMeta
    public let isLatest: Bool
    public let fromVC: UIViewController
    public let skipCellularCheck: Bool
    public let appealAlertFrom: DriveAppealAlertFrom
}

extension DriveLoadingAlertView {
    
    private func setupDownloador(fileMeta: DriveFileMeta,
                                 isLatest: Bool,
                                 skipCellularCheck: Bool,
                                 fromVC: UIViewController,
                                 appealAlertFrom: DriveAppealAlertFrom = .unknown,
                                 completed: (() -> Void)?) {
        guard downloadService == nil else { return }
        let downloadType = DriveDownloadService.DownloadType.origin(fileMeta: fileMeta)
        let fileInfo = DriveFileInfo(fileMeta: fileMeta)
        let cacheSource: DriveCacheService.Source = isLatest ? .standard : .history
        let cacheService = DriveCacheServiceImpl(fileToken: fileMeta.fileToken)
        let dependency = DriveDownloadServiceDependencyImpl(fileInfo: fileInfo, downloadType: downloadType, cacheSource: cacheSource, cacheService: cacheService)
        downloadService = DriveDownloadService(dependency: dependency,
                                               priority: .userInteraction,
                                               skipCellularCheck: skipCellularCheck,
                                               apiType: .drive,
                                               authExtra: fileMeta.authExtra,
                                               callBack: {[weak self] (status) in
            guard let `self` = self else { return }
            switch status {
            case .downloading(let progress):
                self.updateProgress(progress)
            case .failed(let errorCode):
                guard let window = self.window else {
                    self.removeFromSuperview()
                    return
                }
                let context = PermissionCommonErrorContext(objToken: fileMeta.fileToken, objType: .file, operation: .download)
                let error = NSError(domain: errorCode, code: Int(errorCode) ?? 0)
                if let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self),
                   let handler = permissionSDK.canHandle(error: error, context: context) {
                    handler(fromVC, BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed)
                } else {
                    let text = BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed
                    //恶意文件检测错误码
                    if let code = Int(errorCode), code == 90003501 {
                        self.showAppealAlert(fromVC: fromVC, fileMeta: fileMeta, appealAlertFrom: appealAlertFrom)
                    } else {
                        UDToast.showFailure(with: text, on: window)
                    }
                }
                self.removeFromSuperview()
            case .success:
                self.removeFromSuperview()
                completed?()
            case .retryFetch:
                self.removeFromSuperview()
            }
        })
        downloadService?.hostContainer = fromVC
        downloadService?.beginDownload = { [weak self] in
            self?.isHidden = false
        }
        downloadService?.forbidDownload = { [weak self] in
            self?.dismiss()
        }
        downloadService?.start()
    }

    static weak var currentDownloadingView: DriveLoadingAlertView?

    class func show(context: ShowLoadingViewContext, completed: (() -> Void)?) -> DriveLoadingAlertView {
        if let view = currentDownloadingView {
            return view
        }
        let downloadingView = DriveLoadingAlertView(frame: .zero)
        downloadingView.titleText = BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_downloading
        // 显示流量提醒时，不隐藏的话会两个弹框之间会有重叠的效果，影响UI体验
        // 由于下载逻辑放在了View里面，所以流量提醒框必定会处于这个view的上面
        downloadingView.isHidden = true
        context.fromVC.view.addSubview(downloadingView)
        downloadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        downloadingView.setupDownloador(fileMeta: context.fileMeta,
                                        isLatest: context.isLatest,
                                        skipCellularCheck: context.skipCellularCheck,
                                        fromVC: context.fromVC,
                                        appealAlertFrom: context.appealAlertFrom,
                                        completed: completed)
        currentDownloadingView = downloadingView
        return downloadingView
    }
    
    private func showAppealAlert(fromVC: UIViewController, fileMeta: DriveFileMeta, appealAlertFrom: DriveAppealAlertFrom = .unknown) {
        DocsLogger.driveInfo("showAppealAlert")
        var params: [String: Any] = ["view_from": appealAlertFrom.rawValue]
        DriveStatistic.reportEvent(DocsTracker.EventType.driveAppealAlertView, fileId: nil, fileType: nil, params: params)
        let config = UDDialogUIConfig(style: .vertical)
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Wiki_FileSecurity_CantDownload_Mob)
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Wiki_FileSecurity_CantDownload_Body_Mob)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Wiki_FileSecurity_CantDownload_Confirm_Button_Mob, dismissCompletion: {
            params.updateValue("known", forKey: "click")
            DriveStatistic.reportClickEvent(DocsTracker.EventType.driveAppealAlertClick,
                                            clickEventType: DriveStatistic.DriveAppealAlertClickEventType.known,
                                            fileId: nil, fileType: nil, params: params)
            DocsLogger.driveInfo("user cancelled")
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Wiki_FileSecurity_CantDownload_Appeal_Button_Mob, dismissCompletion: { [weak self] in
            // Drive数据埋点：取消上传的确认
            params.updateValue("launch_complain", forKey: "click")
            DriveStatistic.reportClickEvent(DocsTracker.EventType.driveAppealAlertClick,
                                            clickEventType: DriveStatistic.DriveAppealAlertClickEventType.launch_complain,
                                            fileId: nil, fileType: nil, params: params)
            let locale = DocsSDK.currentLanguage.rawValue.replacingOccurrences(of: "_", with: "-")
            let version = Int(fileMeta.version ?? "0") ?? 0
            let dependency = DocsContainer.shared.resolve(AppealAlertDependency.self)!
            dependency.openAppealAlert(objToken: fileMeta.fileToken, version: version, locale: locale)
        })
        Navigator.shared.present(dialog, from: fromVC)
    }
}
