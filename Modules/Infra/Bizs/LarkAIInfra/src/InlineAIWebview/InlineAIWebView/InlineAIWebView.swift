//
//  InlineAIWebView.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/11.
//

import Foundation
import LarkWebViewContainer
import WebKit
import LarkOPInterface

protocol InlineAIWebViewDelegate: AnyObject {
    func contentDidRenderComplete(with contentHeight: CGFloat?)
}

class InlineAIWebView: LarkWebView {
    
    struct CustomMenuAction { // 自定义气泡菜单
        let id: InlineAIMenuID
        let title: String
        let block: () -> Void
    }
    
    private var customMenuActions = [Selector: CustomMenuAction]()

    weak var renderDelegate: InlineAIWebViewDelegate?
    
    /// 业务自定义的背景色, 由web渲染，优先级大于theme参数
    private(set) var customBackgroundColor: UIColor?
    
    init(frame: CGRect, configuration: WKWebViewConfiguration, parentTrace: OPTrace?, webviewDelegate: LarkWebViewDelegate?) {
        let config = LarkWebViewConfigBuilder()
            .setWebViewConfig(configuration)
            .setDisableClearBridgeContext(false)
            .build(
                bizType: LarkWebViewBizType("inlineAI"),
                isAutoSyncCookie: true,
                vConsoleEnable: false,
                promptFGSystemEnable: true
            )
        super.init(frame: frame, config: config, parentTrace: parentTrace, webviewDelegate: webviewDelegate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contentDidRenderComplete(contentHeight: CGFloat?) {
        self.renderDelegate?.contentDidRenderComplete(with: contentHeight)
    }
    
    func setCustomBackgroundColor(_ color: UIColor?) {
        customBackgroundColor = color
    }
    
    deinit {
        LarkInlineAILogger.info("[web] InlineAIWebView deinit")
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return customMenuActions[action] != nil
    }
}

// MARK: 气泡菜单
enum InlineAIMenuID: String {
    
    case copy
}

extension InlineAIWebView {
    
    func registerCustomMenu(id: InlineAIMenuID, title: String, block: @escaping () -> Void) {
        guard Thread.isMainThread else {
            return
        }
        guard let selector = menuSelectorMapping[id] else {
            return
        }
        customMenuActions[selector] = .init(id: id, title: title, block: block)
        updateMenuControllerItems()
    }
    
    private func updateMenuControllerItems() {
        var menuItems = [UIMenuItem]()
        for (_, value) in customMenuActions {
            if let selector = menuSelectorMapping[value.id] {
                menuItems.append(UIMenuItem(title: value.title, action: selector))
            }
        }
        UIMenuController.shared.menuItems = menuItems
        LarkInlineAILogger.info("menu update: \(menuItems.map{ $0.desc })")
    }
}

extension InlineAIWebView {
    
    private var menuSelectorMapping: [InlineAIMenuID: Selector] {
        [
            .copy: #selector(menuAction_copy)
        ]
    }
    
    @objc
    private func menuAction_copy(sender: Any?) {
        let key = #selector(menuAction_copy)
        guard let value = customMenuActions[key] else { return }
        value.block()
    }
}

private extension UIMenuItem {
    
    var desc: String { "title:\(title), action:\(action)" }
}
