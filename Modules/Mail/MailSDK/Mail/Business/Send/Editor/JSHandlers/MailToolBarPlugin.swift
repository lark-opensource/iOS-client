//
//  EditorToolBarPlugin.swift
//  MailSDK
//
//  Created by majx on 2019/6/13.
//

import Foundation
import RxSwift

// MARK: - MailEditorToolBarPlugin
class MailEditorToolBarPlugin: EditorBaseToolBarPlugin {
    var isInQuote = false
    var threadID: String?
    var statInfo: MailSendStatInfo = MailSendStatInfo(from: .routerPullUp, newCoreEventLabelItem: "none")
    var permissionCode: MailPermissionCode?
    var sendAction: MailSendAction?
    let disposeBag = DisposeBag()
    var currentStatus: [EditorToolBarItemInfo]?
    // 更新工具条
    override init(_ config: EditorBaseToolBarConfig) {
        super.init(config)

        MailCommonDataMananger
            .shared
            .sharePermissionChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.shareMailPermissionChange(change)
            }).disposed(by: disposeBag)
    }

    func shareMailPermissionChange(_ change: ShareMailPermissionChange) {
        guard change.threadId == threadID else {
            return
        }
        mainToolBar?.isHidden = change.permissionCode == .view
    }

    private func updateMainToolBar(_ status: [EditorToolBarItemInfo]) {
        currentStatus = status
        if let idx = status.firstIndex(where: { $0.identifier == "attribution" }) {
            status[idx].isEnable = !isInQuote
        }

        let newStatus = statInfo.from == .outOfOffice ? status.filter { $0.identifier != "attachment" } : status
        if let view = mainToolBar {
            view.refreshStatus(status: newStatus, service: workingMethod, isInQuote: isInQuote, permissionCode: permissionCode)
            return
        } else {
            mainToolBar = config.uiCreater?.updateMainToolBarPanel(newStatus, service: workingMethod)
            mainToolBar?.refreshStatus(status: newStatus, service: workingMethod, isInQuote: isInQuote, permissionCode: permissionCode)
            mainToolBar?.delegate = self
        }
    }

    // 更新子面板
    private func updateSubToolBarPanel(_ status: [EditorToolBarItemInfo]) {
        for item in status {
            // if view exists, just update ui
            if let view = subPanels[item.identifier],
            (item.identifier == EditorToolBarButtonIdentifier.insertImage.rawValue ||
                item.identifier == EditorToolBarButtonIdentifier.attachment.rawValue) {
                // nothing
            } else if let view = subPanels[item.identifier], let children = item.children {
                view.updateStatus(status: MailSubToolBar.statusTransfer(status: children))
            } else if let newView = config.uiCreater?.updateSubToolBarPanel(item.children, identifier: item.identifier) {
                // if view is nil, then create one
                newView.panelDelegate = self
                if let toolBar = mainToolBar as? MailMainToolBar {
                    newView.toolDelegate = toolBar
                }
                subPanels[item.identifier] = newView
            }
        }
    }

    // JSHandle 入口
    override func handle(params: [String: Any], serviceName: String) {
        guard let callback = params["callback"] as? String,
              let items = params["items"] as? [[String: Any]] else {
                return
        }
        workingMethod = EditorJSService(rawValue: serviceName)
        jsMethod = callback
        jsItems = items
        toolBarInfos.removeAll()
        /// 解析 itemInfo， 创建 EditorToolBarItemInfo
        for info in jsItems {
            guard let sId = info["id"] as? String else { continue }
            let itemModel = EditorToolBarItemInfo(identifier: sId, json: info, jsMethod: jsMethod)
            itemModel.jsMethod = jsMethod
            toolBarInfos.append(itemModel)
        }

        // 工具条管理类
        let tool = currentTool()
        let toolBar = currentTool().toolBar

        if !toolBarInfos.isEmpty {
            // 更新工具条状态
            updateMainToolBar(toolBarInfos)
            updateSubToolBarPanel(toolBarInfos)
            if displayToolBar() {
                tool.set(EditorToolbarManager.ToolConfig(toolBar), mode: .toolbar)
            }
            if let view = mainToolBar { pluginProtocol?.requestDisplayMainTBPanel(view) }
            // 这个要改 first timer 怎么判断
            pluginProtocol?.didReceivedOpenToolBarInfo(firstTimer: false, doubleClick: (params["input"] == nil))
        }
    }

    // 是否需要显示工具条
    private func displayToolBar() -> Bool {
        switch workingMethod {
        case .setToolBarJsName:
            return currentTool().currentMode != .atSelection
        default:
            return true
        }
    }

    // 当前工具条
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

    func setIsInQuote(_ isInQuote: Bool) {
        self.isInQuote = isInQuote
        if let status = currentStatus {
            updateMainToolBar(status)
        }
    }
}
