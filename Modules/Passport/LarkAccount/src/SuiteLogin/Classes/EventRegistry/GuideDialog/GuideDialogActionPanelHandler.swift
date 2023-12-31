//
//  GuideDialogActionPanelHandler.swift
//  LarkAccount
//
//  Created by au on 2023/5/18.
//

import LarkUIKit
import LKCommonsLogging
import UIKit
import UniverseDesignActionPanel

final class GuideDialogActionPanelHandler: GuideDialogHandlerProtocol {

    private static let logger = Logger.log(GuideDialogActionPanelHandler.self, category: "LarkAccount")

    func handle(info: GuideDialogStepInfo,
                context: UniContextProtocol,
                vcHandler: EventBusVCHandler?,
                success: @escaping EventBusSuccessHandler,
                failure: @escaping EventBusErrorHandler) {

        defer { success() }

        func presentGuideDialog(_ from: UIViewController) {
            let vm = GuideDialogViewModel(stepInfo: info, context: context, vcHandler: vcHandler)
            let vc = GuideDialogViewController(vm: vm)

            Self.logger.info("n_action_guide_dialog_action_panel_show")
            if Display.pad {
                vc.modalPresentationStyle = .formSheet
                if #available(iOS 13.0, *) {
                    vc.isModalInPresentation = true
                }
                from.present(vc, animated: true)
            } else {
                vc.view.setNeedsLayout()
                vc.view.layoutIfNeeded()
                let config = UDActionPanelUIConfig(originY: UIScreen.main.bounds.height - vc.getDisplayHeight(), canBeDragged: false, disablePanGestureViews: {
                    if let view = vc.view {
                        return [view]
                    }
                    return []
                })
                let panel = UDActionPanel(customViewController: vc, config: config)
                from.present(panel, animated: true) {
                    panel.setTapSwitch(isEnable: false)
                }
            }
        }

        guard let topVC = PassportNavigator.topMostVC else {
            Self.logger.error("n_action_guide_dialog_action_panel_no_vc")
            return
        }

        // 当视图的最上层是上一次弹出的风险 session 弹窗，将之前的弹窗关闭，再唤起本次新弹窗
        if topVC is UDActionPanel || topVC is GuideDialogViewController {
            Self.logger.warn("n_action_guide_dialog_action_panel_already_show")
            topVC.dismiss(animated: true) {
                if let from = PassportNavigator.topMostVC {
                    presentGuideDialog(from)
                } else {
                    Self.logger.error("n_action_guide_dialog_action_panel_no_backup_from")
                }
            }
        } else {
            presentGuideDialog(topVC)
        }
    }
    
}
