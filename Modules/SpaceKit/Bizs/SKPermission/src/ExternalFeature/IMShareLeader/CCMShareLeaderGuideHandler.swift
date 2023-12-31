//
//  CCMShareLeaderGuideHandler.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/12/12.
//

import Foundation
import SpaceInterface
import EENavigator
import LarkContainer
import LarkNavigator
import UniverseDesignDialog
import UniverseDesignToast
import SKFoundation
import SKCommon
import SKResource

class CCMShareLeaderGuideHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { CCMUserScope.compatibleMode }
    func handle(_ body: CCMShareLeaderGuideBody, req: EENavigator.Request, res: Response) throws {
        let fromController = req.from.fromViewController
        let userSettings = try userResolver.resolve(assert: CCMUserSettings.self)
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_SetAutomaticGrantViewPermToMymanager_Title)
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_GrantViewPermForeverOrNot_Desc)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Normal_OK, dismissCompletion: {
            _ = userSettings.updateCommonSettings(with: [.imShareLeader: .imShareLeader(state: .auto)], meta: nil)
                .map { result -> Void in
                    guard result[.imShareLeader] == true else { throw DocsNetworkError.invalidData }
                    return ()
                }
                .subscribe { [weak fromController] in
                    DocsLogger.info("update imShareLeader setting success from applink")
                    guard let fromController else { return }
                    UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_AutomaticGrantingTurnedOn_Toast, on: fromController.view.window ?? fromController.view)
                } onError: { error in
                    DocsLogger.error("update imShareLeader setting failed from applink", error: error)
                    // guard let fromController else { return }
                    // UDToast.showSuccess(with: "I18n - 设置失败", on: fromController.view.window ?? fromController.view)
                }
            DocsTracker.newLog(enumEvent: .permissionLeaderAuthorizeSetClick, parameters: [
                "click": "confirm",
                "target": "none"
            ])
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_OnlyGrantViewPermThisTime_Button, dismissCompletion: {
            DocsTracker.newLog(enumEvent: .permissionLeaderAuthorizeSetClick, parameters: [
                "click": "only_for_this_time",
                "target": "none"
            ])
        })
        res.end(resource: dialog)
        DocsTracker.newLog(enumEvent: .permissionLeaderAuthorizeSetView, parameters: nil)
    }
}

