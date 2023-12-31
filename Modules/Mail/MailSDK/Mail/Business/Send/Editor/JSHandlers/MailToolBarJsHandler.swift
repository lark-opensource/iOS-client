//
//  EditorToolBarJsHandler.swift
//  Lark
//
//  Created by majx on 2019/6/8.
//

import Foundation
import LarkUIKit

// MARK: - 设置及更新工具条的JS Handler
extension EditorJSService {
    // mail的前端接口，根据前端的实际接口情况进行替换
    static let mailSetToolBar = EditorJSService(rawValue: "biz.navigation.setToolBar")
    static let isInQuote = EditorJSService(rawValue: "biz.core.isinquoteselection")
}

class EditorToolBarJsHandler: MailJSServiceHandler {
    var threadID: String? {
        didSet {
            toolBarPlugin.threadID = threadID
        }
    }
    weak var uiDelegate: MailSendController?
    weak var imageHandler: MailImageHandler?
    var permissionCode: MailPermissionCode? {
        didSet {
            toolBarPlugin.permissionCode = permissionCode
        }
    }
    var statInfo: MailSendStatInfo = MailSendStatInfo(from: .routerPullUp, newCoreEventLabelItem: "none") {
        didSet {
            toolBarPlugin.statInfo = statInfo
        }
    }
    internal var handleServices: [EditorJSService] = [.fetchDocs, .isInQuote]
    private lazy var toolBarPlugin: MailEditorToolBarPlugin = {
        let toolUI = MailToolBarUICreater(uiDelegate: uiDelegate, mainToolDelegate: self, subToolDelegate: self)
        let config = EditorBaseToolBarConfig(ui: toolUI)
        let plugin = MailEditorToolBarPlugin(config)
        plugin.pluginProtocol = self
        plugin.statInfo = self.statInfo
        return plugin
    }()

    func handle(params: [String: Any], serviceName: String) {
        guard uiDelegate != nil else { return }
        if serviceName == EditorJSService.isInQuote.rawValue {
            handleIsInQuote(params)
        }
    }
    func cacheSetToolBar(params: [String: Any]) {
        toolBarPlugin.handle(params: params, serviceName: EditorJSService.mailSetToolBar.rawValue)
    }

    func handleIsInQuote(_ params: [String: Any]) {
        guard let isInQuote = params["isInQuote"] as? Bool else { mailAssertionFailure("wrong param"); return }
        toolBarPlugin.setIsInQuote(isInQuote)
    }
}

extension EditorToolBarJsHandler: EditorBaseToolBarPluginProtocol {
    func requestDisplayMainTBPanel(_ panel: EditorMainToolBarPanel) {
        uiDelegate?.updateMainToolBar(bar: panel)
    }

    /// 更换子面板
    func requestChangeSubTBPanel(_ panel: EditorSubToolBarPanel, info: EditorToolBarItemInfo) {
        /// 特殊处理 ImagePicker
        if let imagePicker = panel as? MailImagePickerToolView {
            imagePicker.suiteView?.delegate = imageHandler
            imagePicker.suiteView?.set(isOrigin: true)
            imagePicker.suiteView?.onPresentBlock = {_ in
                /// picker 被弹出
                /// guard let `self` = self else { return }
                /// self.tool?.toolBar.requestAddRestoreTag(item: nil, tag: DocsAssetToolBarItem.restoreTag)
            }
            imagePicker.suiteView?.finishSelectBlock = { _, _ in
                /// 选择完成
                /// guard let `self` = self else { return }
                /// self.tool?.toolBar.requestAddRestoreTag(item: nil, tag: nil)
            }
        }
        if let textPicker = panel as? MailAttributionView {
            textPicker.dismissFontPanel()
        }
        uiDelegate?.updateSubToolBarPanel(bar: panel, info: info)
    }

    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        uiDelegate?.requestEvaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool) {

    }

    func didReceivedCloseToolBarInfo() {

    }

    func didReceivedInputText(text: Bool) {

    }
    func didClickSignatureItem() {
        self.uiDelegate?.signatureEditClicked()
    }
    func didClickAttachmentItem() {
        self.uiDelegate?.attachmentItemClicked()
    }
    func didReceiveCalendarClick() {
        self.uiDelegate?.calendarItemClick()
    }
    func didReceiveAIClick() {
        self.uiDelegate?.aiItemClick()
    }
}

extension EditorToolBarJsHandler: MailMainToolBarDelegate {
    // 是否有子面板
    func itemHasSubPanel(_ item: EditorToolBarItemInfo, mainBar: MailMainToolBar) -> Bool {
        // 弹出图片选择面板
        if item.identifier == EditorToolBarButtonIdentifier.insertImage.rawValue ||
            item.identifier == EditorToolBarButtonIdentifier.attr.rawValue {
            return true
        }
        return false
    }

    func showSubToolBar(subBar: MailSubToolBar) {
        MailLogger.debug("\(#function)")
    }

    func subToolBarSelect(item: EditorToolBarItemInfo, update value: String?, view: EditorSubToolBarPanel) {
        toolBarPlugin.select(item: item, update: value, view: view)
    }
}

extension EditorToolBarJsHandler: MailSubToolBarDelegate {
    func setTitleView(_ titleView: UIView) {}
}
