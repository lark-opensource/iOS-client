//  Created by Songwen on 2018/10/24.

import Foundation
import SKCommon
import SKUIKit

public final class UtilAlertService: BaseJSService {
    lazy var internalPlugin: SKBaseAlertPlugin = {
        let config = SKBaseAlertPluginConfig(executeJsService: model?.jsEngine, hostView: self.ui?.hostView)
        config.hostService = self
        let plugin = SKBaseAlertPlugin(config)
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        return plugin
    }()

    public var isShowingAlert: Bool { internalPlugin.currentAlertWindow != nil }
}

extension UtilAlertService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return internalPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        let blockDocsInfo = self.getblockDocsInfo(params: params)  //区分syncedBlock权限
        let docsInfo = blockDocsInfo ?? self.hostDocsInfo
        internalPlugin.docsInfo = docsInfo
        internalPlugin.handle(params: params, serviceName: serviceName)
        if SKDisplay.pad,
           hostDocsInfo?.inherentType == .sheet,
           ui?.editorView.isFirstResponder == true || UIResponder.docsFirstResponder() == nil {
            //sheet文档类型且焦点不在输入框上时不会有键盘出现，不执行endEditing
            return
        }
        if let browserVC = navigator?.currentBrowserVC as? BaseViewController {
            browserVC.keyboardWillHide()
        }
        self.navigator?.currentBrowserVC?.view.affiliatedWindow?.endEditing(true)
    }
}
