//
//  BaseToolBarPlugin.swift
//  DocsSDK
//
//  Created by Webster on 2019/5/18.
//

import Foundation
import Homeric

// MARK: - 工具条 Delegate
protocol EditorMainTBPanelDelegate: AnyObject {
    /// 点击工具条按钮触发的回调
    ///
    /// - Parameters:
    ///   - item: item 信息
    ///   - panel: panel 信息
    ///   - emptyClick: 是否是选中状态下的再次点击
    func didClickedItem(_ item: EditorToolBarItemInfo, panel: EditorMainToolBarPanel, emptyClick: Bool)
    func didClickSignatureItem(_ item: EditorToolBarItemInfo)
    func didClickAttachmentItem(_ item: EditorToolBarItemInfo)
    func didClickCalendarItem(_ item: EditorToolBarItemInfo)
    func didClickAIItem(_ item: EditorToolBarItemInfo)
}

// MARK: - 工具条
class EditorMainToolBarPanel: UIView {
    weak var delegate: EditorMainTBPanelDelegate?
    func refreshStatus(status: [EditorToolBarItemInfo], service: EditorJSService, isInQuote: Bool, permissionCode: MailPermissionCode?) {}
}

// MARK: - 子面板 Delegate
protocol EditorSubToolBarPanelDelegate: AnyObject {
    func select(item: EditorToolBarItemInfo, update value: String?, view: EditorSubToolBarPanel)
}

// MARK: - 子面板
class EditorSubToolBarPanel: UIView {
    weak var panelDelegate: EditorSubToolBarPanelDelegate?
    weak var toolDelegate: MailSubToolBarDelegate?
    func showRootView() {}
    func updateStatus(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {}
}

// MARK: - 工具条构造方法
protocol EditorToolBarUICreater {
    /// 工具条
    func updateMainToolBarPanel(_ status: [EditorToolBarItemInfo], service: EditorJSService) -> EditorMainToolBarPanel
    /// 子面板
    func updateSubToolBarPanel(_ status: [EditorToolBarItemInfo]?, identifier: String) -> EditorSubToolBarPanel?
}

// MARK: - biz.navigation.setDocToolbar
extension EditorJSService {
    /// 这里和Doc的方法保持一致
    static let setToolBarJsName = EditorJSService("biz.navigation.setDocToolbar")
}

struct EditorBaseToolBarConfig {
    var uiCreater: EditorToolBarUICreater?
    init(ui: EditorToolBarUICreater? = nil) {
        uiCreater = ui
    }
}

protocol EditorBaseToolBarPluginProtocol: EditorExecJSService {
    func requestDisplayMainTBPanel(_ panel: EditorMainToolBarPanel)
    func requestChangeSubTBPanel(_ panel: EditorSubToolBarPanel, info: EditorToolBarItemInfo)
    func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool)
    func didReceivedCloseToolBarInfo()
    func didReceivedInputText(text: Bool)
    func didClickSignatureItem()
    func didClickAttachmentItem()
    func didReceiveCalendarClick()
    func didReceiveAIClick()
}

extension EditorBaseToolBarPluginProtocol {
    func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool) { }
    func didReceivedCloseToolBarInfo() { }
    func didReceivedInputText(text: Bool) { }
}

// MARK: - EditorBaseToolBarPlugin
class EditorBaseToolBarPlugin: EditorJSServiceHandler {
    var logPrefix: String = ""
    weak var pluginProtocol: EditorBaseToolBarPluginProtocol?
    var mainToolBar: EditorMainToolBarPanel?
    var subPanels: [String: EditorSubToolBarPanel] = [String: EditorSubToolBarPanel]()
    var tool: EditorBrowserToolConfig?
    var workingMethod = EditorJSService.setToolBarJsName
    var jsMethod: String = ""

    internal let config: EditorBaseToolBarConfig
    internal var toolBarInfos: [EditorToolBarItemInfo] = [EditorToolBarItemInfo]()
    internal var jsItems: [[String: Any]] = [[String: Any]]()

    init(_ config: EditorBaseToolBarConfig) {
        self.config = config
    }

    var handleServices: [EditorJSService] {
        return [.setToolBarJsName]
    }

    func removeAllToolBarView() {
        mainToolBar = nil
        subPanels.removeAll()
    }

    // 更新工具条
    private func updateMainToolBar(_ status: [EditorToolBarItemInfo]) {
        if let view = mainToolBar {
//            view.refreshStatus(status: status, service: workingMethod)
            return
        } else {
            mainToolBar = config.uiCreater?.updateMainToolBarPanel(status, service: workingMethod)
//            mainToolBar?.refreshStatus(status: status, service: workingMethod)
            mainToolBar?.delegate = self
        }
    }

    // 更新子面板
    private func updateSubPanel(_ status: [EditorToolBarItemInfo]) {
        for item in status {
            if let view = subPanels[item.identifier],
                let children = item.children {
                view.updateStatus(status: MailSubToolBar.statusTransfer(status: children))
            } else if let newView = config.uiCreater?.updateSubToolBarPanel(item.children, identifier: item.identifier) {
                newView.panelDelegate = self
                subPanels[item.identifier] = newView
            }
        }
    }

    // 入口在这
    func handle(params: [String: Any], serviceName: String) {
        guard let callback = params["callback"] as? String,
            let items = params["items"] as? [[String: Any]] else { return }
        workingMethod = EditorJSService(rawValue: serviceName)
        jsMethod = callback
        jsItems = items
        toolBarInfos.removeAll()
        for info in jsItems {
            guard let sId = info["id"] as? String else { continue }
            let itemModel = EditorToolBarItemInfo(identifier: sId, json: info, jsMethod: jsMethod)
            itemModel.jsMethod = jsMethod
            toolBarInfos.append(itemModel)
        }
        
        let tool = currentTool()
        let toolBar = currentTool().toolBar
        if !toolBarInfos.isEmpty {
            updateMainToolBar(toolBarInfos)
            updateSubPanel(toolBarInfos)
            if displayToolBar() { tool.set(EditorToolbarManager.ToolConfig(toolBar), mode: .toolbar) }
            if let view = mainToolBar { pluginProtocol?.requestDisplayMainTBPanel(view) }
            /// 这个要改 first timer 怎么判断
            pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: (params["input"] == nil))
//            if let inputDict = params["input"] as? [String: Any] {
//                let value = inputDict["value"] as? String ?? ""
//                pluginProtocol?.didReceivedInputText(text: true)
//            }
        } else if canRemoveToolBar() {
            tool.remove(mode: .toolbar)
            removeAllToolBarView()
            pluginProtocol?.didReceivedCloseToolBarInfo()
        }
    }

    private func canRemoveToolBar() -> Bool {
        return false
    }

    private func displayToolBar() -> Bool {
        return true
    }

    private func currentTool() -> EditorBrowserToolConfig {
        if let reallyTool = tool {
            return reallyTool
        } else {
            let newTool = EditorToolbarManager()
            newTool.embed(EditorToolbarManager.ToolConfig(newTool.toolBar))
            tool = newTool
            return newTool
        }
    }
}

extension EditorBaseToolBarPlugin: EditorMainTBPanelDelegate {
    func didClickedItem(_ item: EditorToolBarItemInfo, panel: EditorMainToolBarPanel, emptyClick: Bool) {
        let selectedStr = emptyClick ? "true" : "false"
        let script = item.jsMethod + "({id:'\(item.identifier)',value:'\(selectedStr)'})"
        pluginProtocol?.evaluateJavaScript(script, completionHandler: nil)
        subPanels.values.forEach { (subpanel) in
            subpanel.isHidden = true
        }
        if let subPanel = subPanels[item.identifier] {
            subPanel.isHidden = false
            pluginProtocol?.requestChangeSubTBPanel(subPanel, info: item)
        }
    }
    func didClickSignatureItem(_ item: EditorToolBarItemInfo) {
        pluginProtocol?.didClickSignatureItem()
    }
    func didClickAttachmentItem(_ item: EditorToolBarItemInfo) {
        pluginProtocol?.didClickAttachmentItem()
    }
    func didClickCalendarItem(_ item: EditorToolBarItemInfo) {
        pluginProtocol?.didReceiveCalendarClick()
    }
    func didClickAIItem(_ item: EditorToolBarItemInfo) {
        pluginProtocol?.didReceiveAIClick()
    }
}

extension EditorBaseToolBarPlugin: EditorSubToolBarPanelDelegate {
    func select(item: EditorToolBarItemInfo, update value: String?, view: EditorSubToolBarPanel) {
        MailTracker.toolBarAboutStringLog(id: item.identifier)
        if let sValue = value {
            let script = item.jsMethod + "({id:'\(item.identifier)', value:'\(sValue)'})"
            pluginProtocol?.evaluateJavaScript(script, completionHandler: nil)
        } else {
            let script = item.jsMethod + "({id:'\(item.identifier)'})"
            pluginProtocol?.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}
