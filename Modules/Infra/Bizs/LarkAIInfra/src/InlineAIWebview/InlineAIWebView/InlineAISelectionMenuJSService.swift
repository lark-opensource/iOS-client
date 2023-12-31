//
//  InlineAISelectionMenuJSService.swift
//  LarkInlineAI
//
//  Created by ByteDance on 2023/7/3.
//

import Foundation
import LarkEMM
import LarkSensitivityControl
import LarkWebViewContainer
import UniverseDesignToast

/// 选区气泡菜单处理
class InlineAISelectionMenuJSService: InlineAIJSServiceProtocol {
    
    private weak var webView: InlineAIWebView?
    
    weak var delegate: AIWebAPIHandlerDelegate?
    
    init(webView: InlineAIWebView?, delegate: AIWebAPIHandlerDelegate?) {
        self.webView = webView
        self.delegate = delegate
    }
    
    var handleServices: [InlineAIJSService] {
        return [.showMenu, .closeMenu, .longPress, .setScrollStatus]
    }
    
    func handle(params: [String : Any], serviceName: InlineAIJSService, callback: LarkWebViewContainer.APICallbackProtocol?) {
        LarkInlineAILogger.info("InlineAISelectionMenuJSService handle \(serviceName)")
        switch serviceName {
        case InlineAIJSService.showMenu:
            showMenu(params: params)
        case InlineAIJSService.closeMenu:
            closeMenu(params: params)
        case InlineAIJSService.longPress:
            UIImpactFeedbackGenerator(style: .light).impactOccurred() // 震动反馈
        case InlineAIJSService.setScrollStatus:
            LarkInlineAILogger.info("setScrollStatus: \(params)")
            let enable = (params["scrollEnable"] as? Int) == 1 // 0表示禁止下滑 1表示恢复下滑
            delegate?.handle(InlineAIEvent.panGestureRecognizerEnable(enabled: enable))
        default:
            break
        }
    }
    
    private func showMenu(params: [String : Any]) {
        guard let position = params["position"] as? [String: Any],
              let top = position["top"] as? CGFloat,
              let bottom = position["bottom"] as? CGFloat,
              let left = position["left"] as? CGFloat,
              let right = position["right"] as? CGFloat else {
            LarkInlineAILogger.info("cannot get menu position info")
            return
        }
        
        guard let webview = self.webView else { return }
        
        // 事件处理
        let menuInfos = params["selectionMenus"] as? [[String: Any]] ?? []
        let menuModels = menuInfos.map { MenuItemInfo(params: $0) }
        for model in menuModels {
            switch model.id {
            case .copy:
                let text = params["text"] as? String ?? "" // 选区text
                let htmlText = params["htmlText"] as? String ?? "" // 选区html text
                webview.registerCustomMenu(id: .copy, title: model.title, block: { [weak self] in
                    self?.prepareCopy(text: text, htmlText: htmlText)
                })
            case nil:
                break
            }
        }
        // 坐标
        let x = left; let y = top
        let width = max(right - left, 0); let height = max(bottom - top, 0)
        let targetRect = CGRect(x: x, y: y, width: width, height: height)
        webview.becomeFirstResponder()
        UIMenuController.shared.setTargetRect(targetRect, in: webview)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        LarkInlineAILogger.info("menu show, targetRect:\(targetRect)")
    }
    
    private func closeMenu(params: [String : Any]) {
        UIMenuController.shared.setMenuVisible(false, animated: true)
        LarkInlineAILogger.info("menu close")
    }
    
    private func prepareCopy(text: String, htmlText: String) {
        delegate?.handle(.getEncryptId(completion: { [weak self] encryptId in
            self?.handleCopy(encryptId: encryptId, text: text, htmlText: htmlText)
        }))
    }
    
    private func handleCopy(encryptId: String?, text: String, htmlText: String) {
        let content = "text.count:\(text.count), htmlText.count:\(htmlText.count)"
        LarkInlineAILogger.info("handle copy, encryptId:\(String(describing: encryptId)), \(content)")
        
        let token = LarkSensitivityControl.Token("LARK-PSDA-ios_inlineai_roadster_selection")
        let config = PasteboardConfig(token: token, pointId: encryptId, shouldImmunity: false)
        
        let items = [["public.utf8-plain-text": text, "public.html": htmlText]]
        // 系统会在 0.05s 之后又清空一遍剪贴板，因此需要延时处理一下
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            // https://openradar.appspot.com/36063433 设置 paste.string 有概率crash。。。
            if SCPasteboard.general(config).hasStrings {
                SCPasteboard.general(config).strings = nil
            }
            SCPasteboard.general(config).setItems(items)
        }
    }
}

private struct MenuItemInfo {
    
    var title = ""
    
    var id: InlineAIMenuID?
    
    init(params: [String: Any]) {
        self.title = (params["text"] as? String) ?? ""
        self.id = InlineAIMenuID(rawValue: (params["id"] as? String) ?? "")
    }
}
