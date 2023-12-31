//
//  AIDebugDialog.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/11/27.
//  


import UIKit
import UniverseDesignDialog
import LarkEMM
import LarkSensitivityControl

class AIDebugDialog {

    static func createDebugDialog(content: String, primaryClick: @escaping (() -> Void)) -> UDDialog {
        let dialog = UDDialog(); dialog.setTitle(text: "Debug Info")
        let contentView = UIView.createCustomViewForDialog(string: content)
        dialog.setContent(view: contentView) // 原因：UDDialog内部无法添加UIScrollView视图，UIScrollView无法被内容撑开
        dialog.addPrimaryButton(text: BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Copy_Button, dismissCompletion: {
            let config = PasteboardConfig(token: Token("LARK-PSDA-message_menu_copy_quick_action_info"))
            SCPasteboard.general(config).string = content
            primaryClick()
        })
        dialog.addSecondaryButton(text: BundleI18n.LarkAIInfra.Lark_Legacy_Cancel)
        return dialog
    }

}
