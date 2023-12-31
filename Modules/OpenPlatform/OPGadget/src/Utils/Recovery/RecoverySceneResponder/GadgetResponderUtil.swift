//
//  GadgetResponderUtil.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp
import OPFoundation

struct GadgetResponderUtil {
    /// 在当前小程序之上弹出包含有取消以及重试按钮的EMAAlert
    static func alertCancelOrReload(context: RecoveryContext, title: String, content: String, reloadAction: @escaping ()->()) {
        DispatchQueue.main.async {
            // 取得弹窗plugin
            guard let modalPlugin = BDPTimorClient.shared().modalPlugin.sharedPlugin() as? BDPModalPluginDelegate else {
                GadgetRecoveryLogger.logger.error("ReloadModalAlert: fail to show reloadModel beacause can not get modalPlugin")
                return
            }
            // 查找renderSlot
            guard let renderSlot = (context.container as? OPGadgetContainer)?.currentRenderSlot else {
                GadgetRecoveryLogger.logger.error("ReloadModalAlert: fail to show reloadModel beacause can not get current renderSlot")
                return
            }
            // 查找弹窗目标控制器
            guard let targetVC = renderSlot.window?.rootViewController else {
                GadgetRecoveryLogger.logger.info("ReloadModalAlert: fail to show reloadModel beacause can not get target view controller")
                return
            }
            UDDialogForOC.presentDialog(from: targetVC, title: title, content: content, cancelTitle: BDPI18n.cancel, cancelDismissCompletion: {

            }, confirmTitle: BDPI18n.retry) {
                GadgetRecoveryLogger.logger.info("ReloadModalAlert: reload button is clicked, reload action will execute")
                reloadAction()
            }
        }
    }
    
    
    /// 错误统一弹窗
    /// - Parameters:
    ///   - context: 错误上下文
    ///   - errorStyle: 错误页样式
    ///   - action: 响应按钮行为
    static func unifyErrorAlert(context: RecoveryContext, errorStyle:UnifyExceptionStyle, comfirmAction: @escaping ()->(), cancelAction: @escaping ()->()) {
        DispatchQueue.main.async {
            // 取得弹窗plugin
            guard let modalPlugin = BDPTimorClient.shared().modalPlugin.sharedPlugin() as? BDPModalPluginDelegate else {
                GadgetRecoveryLogger.logger.error("unifyErrorAlert: Failed to alert beacause can‘t found modalPlugin")
                return
            }
            // 查找renderSlot
            guard let renderSlot = (context.container as? OPGadgetContainer)?.currentRenderSlot else {
                GadgetRecoveryLogger.logger.error("unifyErrorAlert: Failed to alert beacause can’t get current renderSlot")
                return
            }
            // 查找弹窗目标控制器
            guard let targetVC = renderSlot.window?.rootViewController else {
                GadgetRecoveryLogger.logger.info("unifyErrorAlert: Failed to alert beacause can’t get target view controller")
                return
            }
            
            UDDialogForOC.presentDialog(from: targetVC, title: nil, content: errorStyle.content, cancelTitle: errorStyle.actions?.cancelButton?.actionText, cancelDismissCompletion: {
                GadgetRecoveryLogger.logger.info("unifyErrorAlert: cancel button is clicked, dismiss action will execute")
                cancelAction()
            }, confirmTitle: errorStyle.actions?.primaryButton?.actionText) {
                GadgetRecoveryLogger.logger.info("unifyErrorAlert: reload button is clicked, reload action will execute")
                comfirmAction()
            }
        }
    }
}
