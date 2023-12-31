//
//  DocContentReactionService.swift
//  SKBrowser
//
//  Created by chensi(陈思) on 2022/8/10.
//  


import UIKit
import Foundation
import Lottie
import SKCommon
import SKFoundation
import LarkEmotion
import LarkEmotionKeyboard

/// 文档正文Reaction服务
final class DocContentReactionService: BaseJSService {
    
    private var callBackFunc: String?
    private weak var reactionMenuController: ContentReactionMenuController?
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension DocContentReactionService: DocsJSServiceHandler {
    
    var handleServices: [DocsJSService] {
        [.showContentReactionPanel,
         .closeContentReactionPanel]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .showContentReactionPanel:
            _showContentReactionPanel(params)
        case .closeContentReactionPanel:
            _closeContentReactionPanel(params)
        default: break
        }
    }
}

extension DocContentReactionService {
    
    private func _showContentReactionPanel(_ params: [String: Any]) {
        guard let browserVCView = ui?.hostView.superview else { return }
        guard let hostVC = browserVCView.affiliatedViewController else { return }
        
        callBackFunc = params["callback"] as? String
        
        let from = ContentReactionMenuController.TriggerFrom.docContent(trigerView: browserVCView)
        let menu = ContentReactionMenuController(triggerFrom: from, onItemClicked: { [weak self] action in
            guard let funcName = self?.callBackFunc, !funcName.isEmpty else { return }
            let jsCallBack = DocsJSCallBack(funcName)
            let params = action.toParams()
            DocsLogger.info("click content-reaction: callBack:\(funcName), params:\(params)")
            self?.model?.jsEngine.callFunction(jsCallBack, params: params, completion: nil)
            if !action.isUserCancelled && !action.reactionKey.isEmpty {
                // 更新用户最近和最常使用表情
                EmojiImageService.default?.updateUserReaction(key: action.reactionKey)
            }
            
            self?.reactionMenuController?.dismiss(animated: true, params: nil)
        })
        reactionMenuController = menu
        menu.showIn(controller: hostVC)
    }
    
    private func _closeContentReactionPanel(_ params: [String: Any]) {
        reactionMenuController?.hiddenMenuBar(animation: false)
        reactionMenuController?.dismiss(animated: false, params: nil)
        reactionMenuController = nil
        callBackFunc = nil
    }
}
