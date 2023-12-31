//
//  BTJSService+AI.swift
//  SKBitable
//
//  Created by qiyongka on 2023/8/23.
//

import UIKit
import SKFoundation
import SKBrowser
import SKCommon
import EENavigator
import SKUIKit
import LarkUIKit
import RxSwift
import UniverseDesignColor


// 设置隐藏时，不传 aiPromptTx，因此设置为 option 类型
struct SetEditPanelVisibility: Codable {
    var fieldId: String = ""
    var isVisible: Bool = false
    var aiPromptTx: String?
}

extension BTJSService {
    
    func showAiOnBoarding(_ param: [String: Any]) {
        guard let browseVC = navigator?.currentBrowserVC as? BrowserViewController,
              let callbackString = param["callback"] as? String else {
            DocsLogger.btError("Error: AI onboarding error")
            return
        }
        
        var aiExtensionGuideVC = BTAiExtensionGuideViewController()
        aiExtensionGuideVC.delegate = self
        let nav = BTNavigationController(rootViewController: aiExtensionGuideVC)
        
        if SKDisplay.pad {
            /// 如果是iPad，就以formsheet形式弹出
            nav.modalPresentationStyle = .formSheet
            nav.presentationController?.delegate = aiExtensionGuideVC
        } else {
            /// 如果是iphone，就全屏弹出
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            nav.navigationBar.backgroundColor = .clear
            nav.setNavigationBarHidden(true, animated: false)
        }
        
        if let editController = self.editController {
            nav.view?.frame = editController.view.frame
            Navigator.shared.present(nav, from: editController, animated: false, completion: nil)
        } else {
            safePresent {
                Navigator.shared.present(nav, from: browseVC, animated: false, completion: nil)
            }
        }
        callBack = DocsJSCallBack(callbackString)
    }
    
    func setEditPanelVisibility(_ param: [String: Any]) {
        let setEditPanelVisibilityModel: SetEditPanelVisibility
        do {
            let data = try JSONSerialization.data(withJSONObject: param, options: [])
            setEditPanelVisibilityModel = try JSONDecoder().decode(SetEditPanelVisibility.self, from: data)
        } catch {
            DocsLogger.btError("Error: setEditPanelVisibility decode error")
            return
        }
        
        guard let browseVC = self.navigator?.currentBrowserVC else {
            DocsLogger.btError("Error: can not get currentBrowserVC")
            return
        }
        
        if setEditPanelVisibilityModel.isVisible {
            // 重新显示 editController，下掉前端的 AI 配置面板
            toolbarsContainer.isHidden = false
            self.editControllerTemporaryhidden = false
            self.removeMaskViewForAiForm()
            if let aiPromptTx = setEditPanelVisibilityModel.aiPromptTx {
                self.fieldEditViewModel?.fieldEditModel.showAIConfigTx = aiPromptTx
            }
            let baseContext = BaseContextImpl(baseToken: self.fieldEditViewModel?.fieldEditModel.baseId ?? "", service: self, permissionObj: self.permissionObj, from: self.editController?.currentMode == .add ? "addField" : "openEditField")
            presentBTFieldEditController(
                fieldEditModel: self.fieldEditViewModel?.fieldEditModel ?? BTFieldEditModel(),
                currentMode: self.fieldEditCurrentMode,
                sceneType: self.fieldEditViewModel?.fieldEditModel.sceneType ?? "", baseContext: baseContext)
            self.fieldEditViewModel = nil
        } else {
            /// 临时 下掉 editController，弹起前端的 AI 配置面板
            toolbarsContainer.isHidden = true
            guard let VC = editController else { return }
            self.editControllerTemporaryhidden = true
            self.fieldEditViewModel = VC.viewModel
            self.fieldEditCurrentMode = VC.currentMode
            VC.dismiss(animated: false)
            self.addMaskViewForAiForm()
        }
    }
}
