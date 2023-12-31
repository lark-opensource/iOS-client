//
//  LeaderPermHandler.swift
//  SKCommon
//
//  Created by peilongfei on 2023/2/14.
//  


import Foundation
import SKFoundation
import SKResource
import UniverseDesignDialog
import EENavigator
import SpaceInterface

public class LeaderPermHandler {
    
    var topVC: UIViewController?
    
    public init() {}

    public func showLeaderManagerAlertIfNeeded(token: String, permissionContainer: UserPermissionContainer?, topVC: UIViewController?) {
        guard UserScopeNoChangeFG.PLF.leaderAutoAuthEnabled else {
            DocsLogger.info("LeaderPermHandler: fg leaderAutoAuthEnabled disabled")
            return
        }
        guard let permissionContainer else {
            DocsLogger.error("LeaderPermHandler: userPermissionContainer is nil")
            return
        }
        guard let topVC else {
            DocsLogger.error("LeaderPermHandler: topVC is nil")
            return
        }
        guard permissionContainer.grantedViewPermissionByLeader else {
            DocsLogger.info("LeaderPermHandler: authReason is not leaderManager")
            return
        }
        showLeaderManagerAlert(token: token, topVC: topVC)
    }
    
    public func showLeaderManagerAlertIfNeeded(_ token: String, userPermission: UserPermissionAbility?, topVC: UIViewController?) {
        guard UserScopeNoChangeFG.PLF.leaderAutoAuthEnabled else {
            DocsLogger.info("LeaderPermHandler: fg leaderAutoAuthEnabled disabled")
            return
        }
        guard let userPermission = userPermission else {
            DocsLogger.error("LeaderPermHandler: userPermission is nil")
            return
        }
        guard let topVC = topVC else {
            DocsLogger.error("LeaderPermHandler: topVC is nil")
            return
        }
        
        let authReason = userPermission.actions[.view]?.authReason
        let isLeaderManager = userPermission.canView() && authReason == .leaderManager
        
        guard isLeaderManager else {
            DocsLogger.info("LeaderPermHandler: authReason is not leaderManager", extraInfo: ["authReason": authReason])
            return
        }
        showLeaderManagerAlert(token: token, topVC: topVC)
    }
    private func showLeaderManagerAlert(token: String, topVC: UIViewController) {
        // 防止重复上报
        if topVC != self.topVC {
            self.topVC = topVC
            PermissionStatistics.shared.reportPermissionAutomaticPermFinishView()
        }
        
        // PM提出要额外增加一个FG来控制展示上级自动授权提示弹框
        guard UserScopeNoChangeFG.PLF.leaderPermTipsDialogEnabled else {
            DocsLogger.info("LeaderPermHandler: fg leaderPermTipsDialogEnabled disabled")
            return
        }

        let userFlag = !OnboardingManager.shared.hasFinished(.permissionLeaderAutoAuth)
        guard userFlag else {
            DocsLogger.info("LeaderPermHandler: userFlag is false")
            return
        }
        
        let uid = User.current.info?.userID ?? ""
        let userDefault = CCMKeyValue.onboardingUserDefault(uid)
        let flagKey = OnboardingID.permissionLeaderAutoAuth.rawValue + token
        let docFlag = !userDefault.bool(forKey: flagKey)
        guard docFlag else {
            DocsLogger.info("LeaderPermHandler: docFlag is false")
            return
        }
        
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_CM_Perms_AuthoGrant_OnwerSet_Toast)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_CM_Perms_AuthoGrant_NotAgain_Button, dismissCompletion:  {
            PermissionStatistics.shared.reportPermissionAutomaticPermClick(click: .noneRemind)
            OnboardingManager.shared.markFinished(for: [.permissionLeaderAutoAuth])
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Onboarding_GotIt_Button, dismissCompletion:  { [weak self] in
            PermissionStatistics.shared.reportPermissionAutomaticPermClick(click: .knowDetail)
            userDefault.set(true, forKey: flagKey)
        })
        topVC.present(dialog, animated: true)
        PermissionStatistics.shared.reportPermissionAutomaticPermView()
    }
}
