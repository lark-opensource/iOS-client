//
//  DKMainViewController+AearComment.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/27.
//

import Foundation
import LarkSuspendable
import SKCommon
import SKFoundation
import UniverseDesignToast
import SKResource

extension DKMainViewController: DriveAreaCommentDelegate {
    var commentViewFrame: CGRect {
        guard let host = viewModel.hostModule else { return .zero }
        return host.commentManager?.commentModule?.commentPluginView.frame ?? .zero
    }

    func commentAt(_ area: DriveAreaComment.Area, commentSource: DriveCommentSource) {
        guard let host = viewModel.hostModule, let hostView = self.view.window else { return }
        // 密级强制打标需求，当FA用户被admin设置强制打标时，不可发表评论
        let canManageMeta: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canManageMeta = host.permissionService.validate(operation: .managePermissionMeta).allow
        } else {
            canManageMeta = host.permissionRelay.value.userPermissions?.isFA ?? false
        }
        if SecretBannerCreater.checkForcibleSL(canManageMeta: canManageMeta,
                                               level: host.docsInfoRelay.value.secLabel) {
            UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requird_Toast,
                                operationText: BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_Set,
                                on: hostView) { _ in
                host.subModuleActionsCenter.accept(.clickSecretBanner)
            }
            return
        }
        host.subModuleActionsCenter.accept(.enterComment(area: area, commentSource: commentSource))
    }
    func didSelectAt(_ area: DriveAreaComment, commentSource: DriveCommentSource) {
        guard let host = viewModel.hostModule else { return }
        host.subModuleActionsCenter.accept(.viewComments(commentID: area.commentID, isFromFeed: false))
    }
    func dismissCommentViewController(){
        dismissCommentVCIfNeeded()
    }
    
    func getCommentVisible() -> Bool {
        let commentModule = viewModel.hostModule?.commentManager?.commentModule
        let isVisiable = commentModule?.isVisiable ?? false
        return isVisiable
    }
    func commentViewDisplay(controller: DriveSupportAreaCommentProtocol) {
        guard let host = viewModel.hostModule else { return }
        if let areas = host.commentManager?.areaCommentManager.filteredAreaComments {
            DocsLogger.driveInfo("areas count", extraInfo: ["count": areas.count])
            controller.updateAreas(areas)
        }
    }
    // 调用此方法需要处理版本协同问题,版本协同刷新时需要把isScrollEnabled设置为true
    func areaComment(controller: DriveSupportAreaCommentProtocol,
                     enter mode: DriveAreaCommentMode) {
        collectionView?.isScrollEnabled = (mode == .normal)
    }
}
