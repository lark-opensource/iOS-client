//
//  SpaceHomeViewController+Create.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/27.
//

import UIKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignToast
import EENavigator
import LarkUIKit
import UniverseDesignColor
import UniverseDesignDialog
import SpaceInterface
import SKInfra

// TODO: @wuwenjian.weston 完成创建功能的重构后，删除下面的代码
// MARK: - DocsCreateViewControllerRouter
extension SpaceHomeViewController: DocsCreateViewControllerRouter {
    public func routerPush(vc: UIViewController, animated: Bool) {
        // 为了适配 iPad 上首页新建的场景，需要在 detail 侧展示内容
        userResolver.navigator.docs.showDetailOrPush(vc, wrap: LkNavigationController.self, from: self, animated: animated)
    }
}

// MARK: - DocsCreateViewControllerDelegate
extension SpaceHomeViewController: DocsCreateViewControllerDelegate {

    public func createCancelled() {}

    public func createComplete(token: String?, type: DocsType, error: Error?) {
        if let docsError = error as? DocsNetworkError {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let context = PermissionCommonErrorContext(objToken: token ?? "", objType: type, operation: .createSubNode)
            if let behavior = permissionSDK.canHandle(error: docsError, context: context) {
                behavior(self, BundleI18n.SKResource.Doc_Facade_CreateFailed)
                return
            }
            if docsError.code == .createLimited {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000, execute: {
                    // 租户达到创建的上线，弹出付费提示
                    let dialog = UDDialog()
                    dialog.setTitle(text: BundleI18n.SKResource.Doc_List_CreateDocumentExceedLimit)
                    dialog.setContent(text: docsError.errorMsg)
                    dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
                    dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_NotifyAdminUpgrade)
                    self.present(dialog, animated: true, completion: nil)
                })
            } else {
                UDToast.showFailure(with: docsError.errorMsg, on: view.window ?? view)
            }
            return
        }
        if error != nil {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: view.window ?? view)
        }
    }

    // 列表创建文件夹后需要打开文件夹
    public func createFolderComplete(folderToken: String) {
        if let delay = SettingConfig.createFolderDelay, delay > 0 {
            // 延时单位是毫秒
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) { [weak self] in
                self?.didCreateFolderComplete(folderToken: folderToken)
            }
        } else {
            // 不延时
            didCreateFolderComplete(folderToken: folderToken)
        }
    }

    private func didCreateFolderComplete(folderToken: String) {
        guard let folderManager = try? userResolver.resolve(assert: FolderRouterService.self) else {
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_CreateSuccessfully, on: self.view)
            return
        }
        folderManager.destinationController(for: folderToken, sourceController: self) { [weak self] controller in
            guard let self = self else { return }
            self.userResolver.navigator.push(controller, from: self)
        }
    }
}
