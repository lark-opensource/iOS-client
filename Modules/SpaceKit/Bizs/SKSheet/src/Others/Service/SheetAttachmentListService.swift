//
// Created by duanxiaochen.7 on 2021/2/19.
// Affiliated with SKSheet.
//
// Description:

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import HandyJSON

class SheetAttachmentListService: BaseJSService {
    
    weak var listPanel: SheetAttachmentListPanel?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension SheetAttachmentListService: BrowserViewLifeCycleEvent {
    
    func browserWillClear() {
        if let sheetVC = registeredVC as? SheetBrowserViewController {
            sheetVC.fabContainer?.cacheListeners.remove(self)
        }
    }
}

extension SheetAttachmentListService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetShowAttachmentList]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.sheetShowAttachmentList.rawValue:
            showAttachmentList(json: params)
        default: ()
        }
    }
    
    private func hidePanel() {
        self.listPanel?.hide(immediately: false)
    }

    func showAttachmentList(json: [String: Any]) {
        if json.isEmpty {
            hidePanel()
            return
        }
        guard let params = SheetAttachmentListParams.deserialize(from: json), !params.list.isEmpty else {
            DocsLogger.info("hide AttachmentList panel", component: LogComponents.sheetAttachmentList)
            hidePanel()
            return
        }

        guard let hostView = registeredVC?.view else {
            DocsLogger.error("get hostView failed")
            return
        }

        var showToolkitItem = false
        var showKeyboardItem = false

        if let sheetVC = registeredVC as? SheetBrowserViewController {
            showToolkitItem = sheetVC.fabContainer?.hasFABItem(.toolkit) ?? false
            showKeyboardItem = sheetVC.fabContainer?.hasFABItem(.keyboard) ?? false
            sheetVC.fabContainer?.cacheListeners.add(self)
        }
        
        if let listPanel = self.listPanel {
            DocsLogger.info("update CellContentPanel")
            listPanel.update(info: params.list, hideToolkitItem: !showToolkitItem, hideKeyboardItem: !showKeyboardItem, callbackFunc: params.callback)
        } else {
            DocsLogger.info("create new CellContentPanel")
            let listPanel = SheetAttachmentListPanel(hostView: hostView)
            listPanel.delegate = self
            self.listPanel = listPanel
            listPanel.update(info: params.list, hideToolkitItem: !showToolkitItem, hideKeyboardItem: !showKeyboardItem, callbackFunc: params.callback)
            listPanel.show()
        }
    }
}

extension SheetAttachmentListService: SheetAttachmentListPanelDelegate {
    
    func onHidePanel() {
        DocsLogger.info("listPanel onHidePanel")
        self.listPanel = nil
    }
    
    func didSelectAttachment(info: SheetAttachmentInfo, callback: String) {
        if let sheetVC = registeredVC as? BrowserViewController, sheetVC.isInVideoConference {
            hidePanel()
        }
        if UIApplication.shared.statusBarOrientation.isLandscape && info.isFileType {
            ScreeenToPortrait.forceInterfaceOrientationIfNeed(to: .portrait)
        }
        let params = info.toJSON()
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("[选择选项]\(String(describing: error))", component: LogComponents.sheetAttachmentList)
                return
            }
        })
    }
    
    func onClickToolkitButton() {
        hidePanel()
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateOpenSheetToolkit.rawValue, params: ["id": FABIdentifier.toolkit.rawValue])
    }
    
    func onClickKeyboardButton() {
        hidePanel()
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateOpenSheetToolkit.rawValue, params: ["id": FABIdentifier.keyboard.rawValue])
    }
    
    func onSizeChange(isShow: Bool, height: CGFloat) {
        guard let browserVC = registeredVC as? BrowserViewController else {
            return
        }
        let viewportHeight = isShow ? browserVC.webviewHeight - height : 0
        let info = BrowserKeyboard(height: viewportHeight,
                                   isShow: isShow,
                                   trigger: "sheetAttachmentList")
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
}

extension SheetAttachmentListService: FABCacheListener {
    func onFABButtonsChange() {
        if let sheetVC = registeredVC as? SheetBrowserViewController, let panel = self.listPanel {
            let showToolkitItem = sheetVC.fabContainer?.hasFABItem(.toolkit) ?? false
            let showKeyboardItem = sheetVC.fabContainer?.hasFABItem(.keyboard) ?? false
            panel.update(hideToolkitItem: !showToolkitItem, hideKeyboardItem: !showKeyboardItem)
        }
    }
}

struct SheetAttachmentListParams: HandyJSON {
    var list: [SheetAttachmentInfo] = []
    var callback: String = ""
}
