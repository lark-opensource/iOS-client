//
//  PopViewManager.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/26.
//  

import Foundation
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignDialog
import UniverseDesignToast
import SKInfra
import EENavigator

public final class PopViewManager: PopViewManagerProtocol {
    public var hadShownDownloadJudge = false
    var isShowingPopView = false
    public func didReceivedFileOfflineStatusAction(_ action: ManualOfflineAction) {
        switch action.event {
        case .showDownloadJudgeUI(let fileSize):
            guard let file = action.files.first else {
                return
            }
            showDownloadJudge(toNotify: fileSize, of: file.objToken)
        case .showNoStorageUI:
            showSDCardIsFullPopView()
        default:
            ()
        }
    }

    public func clear() {
        hadShownDownloadJudge = false
    }
    func showDownloadJudge(toNotify fileSize: UInt64, of objToken: FileListDefine.ObjToken) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showDownloadJudge(toNotify: fileSize, of: objToken)
            }
            return
        }
        guard
            !hadShownDownloadJudge,
            let superVC = Self.viewControllerForPopViewManager()
            else {
            return
        }
        hadShownDownloadJudge = true

        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_OfflineDisconnectWIFI)
        dialog.setContent(text: BundleI18n.SKResource.Doc_Facade_OfflineMaxFileTips(FileSizeHelper.memoryFormat(fileSize)))
        // wifi 下载
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_OfflineWIFIDownload, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else { return true }
            self.choosedDownloadStrategy(.wifiOnly, for: objToken)
            return true
        })

        // 继续下载
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_OfflineProcess, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else { return true }
            self.choosedDownloadStrategy(.wwanAndWifi, for: objToken)
            return true
        })

        // 取消下载
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_List_Cancel, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else { return true }
            SKDataManager.shared.resetManualOfflineTag(objToken: objToken, isSetManuOffline: false)
            self.removeManuOffline(for: objToken)
            return true
        })
        superVC.present(dialog, animated: true, completion: nil)

    }
    private func choosedDownloadStrategy(_ strategy: ManualOfflineAction.DownloadStrategy,
                                         for objToken: FileListDefine.ObjToken) {
        guard let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
            return
        }
        let file = ManualOfflineFile(objToken: objToken, type: .file)
        moMgr.download(file, use: strategy)
    }

    private func removeManuOffline(for objToken: FileListDefine.ObjToken) {
        guard let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
            return
        }
        let file = ManualOfflineFile(objToken: objToken, type: .file)
        moMgr.removeFromOffline(by: file)
    }

    func showSDCardIsFullPopView() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.showSDCardIsFullPopView()
            }
            return
        }
        guard
            !isShowingPopView,
            let superVC = Self.viewControllerForPopViewManager()
        else {
            return
        }
        isShowingPopView = true
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_OfflineFullSpaceTitle)
        dialog.setContent(text: BundleI18n.SKResource.Doc_Facade_OfflineFullSpaceContent,
                           color: UIColor.ud.N900,
                           font: UIFont.systemFont(ofSize: 16),
                           alignment: .center,
                           lineSpacing: 3,
                           numberOfLines: 0)

        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_OfflineKnow, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.isShowingPopView = false
        })
        superVC.present(dialog, animated: true, completion: nil)
    }
}

private extension PopViewManager {
    // iPad 多窗口 workaround 寻找可用 VC 的方法，切勿滥用
    private static func viewControllerForPopViewManager() -> UIViewController? {
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
