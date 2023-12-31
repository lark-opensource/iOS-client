//
//  SpaceListSlideDelegateProxyV2+Delete.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/3/13.
//


import Foundation
import RxSwift
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignDialog
import UniverseDesignToast
import LarkUIKit
import EENavigator
import SpaceInterface

// 删除流程参考 https://bytedance.feishu.cn/wiki/YSoWwPcy7iAXTzkS3Qect3BfnJh#VCYWd0ee4oe0yuxkfYkcXe2xnmd
// MARK: - Delete Event
extension SpaceListSlideDelegateProxyV2 {
    typealias ReviewerUserInfo = AuthorizedUserInfo
    func applyDelete(meta: SpaceMeta, isFolder: Bool, reviewerInfo: ReviewerUserInfo) {
        guard let helper else { return }
        let title = isFolder
        ? BundleI18n.SKResource.LarkCCM_CM_RequestToDeleteFolder_Title
        : BundleI18n.SKResource.LarkCCM_CM_RequestToDeleteDoc_Title
        var config = SKApplyPanelConfig(userInfo: reviewerInfo,
                                        title: title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: { BundleI18n.SKResource.LarkCCM_CM_NoPermToDeletePageWithParentPageSettings_Description($0) })
        config.actionHandler = { [weak self] controller, reason in
            DocsLogger.info("user confirm to apply delete space entry")
            self?.confirmApplyDelete(meta: meta,
                                     reviewerInfo: reviewerInfo,
                                     reason: reason,
                                     controller: controller)
        }
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .cmApplyDelete,
                                                                 query: ["from": "ccm_permission_delete"])
                config.accessoryHandler = { [weak self] controller in
                    self?.helper?.userResolver.navigator.present(url,
                                                                 context: ["showTemporary": false],
                                                                 wrap: LkNavigationController.self,
                                                                 from: controller)
                }
            } catch {
                DocsLogger.error("failed to generate helper center URL when apply delete in space from space list", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        helper.slideActionInput.accept(.present(viewController: controller))
    }

    private func confirmApplyDelete(meta: SpaceMeta, reviewerInfo: ReviewerUserInfo, reason: String?, controller: UIViewController) {
        guard let helper else { return }
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast, on: controller.view.window ?? controller.view)
        helper.interactionHelper.applyDelete(meta: meta, reviewerID: reviewerInfo.userID, reason: reason)
            .subscribe { [weak helper, weak controller] in
                guard let controller, let helper else { return }
                UDToast.removeToast(on: controller.view.window ?? controller.view)
                controller.dismiss(animated: true)
                helper.slideActionInput.accept(.showHUD(.success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast)))
            } onError: { [weak controller] error in
                DocsLogger.error("submit delete space apply failed", error: error)
                guard let controller else { return }
                UDToast.removeToast(on: controller.view.window ?? controller.view)
                let errorMessage: String
                if let docsError = error as? DocsNetworkError,
                   let message = docsError.code.errorMessage {
                    errorMessage = message
                } else {
                    let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                    if error == .applyForbiddenByAdmin {
                        errorMessage = BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AdminNotificationOff
                    } else {
                        errorMessage = error.deleteErrorDescription
                    }
                }
                UDToast.showFailure(with: errorMessage, on: controller.view.window ?? controller.view)
            }
            .disposed(by: disposeBag)

    }
}
