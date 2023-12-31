//
//  SheetShowCellContentService.swift
//  SKSheet
//
//  Created by lijuyou on 2022/4/1.
//  


import Foundation
import SKBrowser
import SKCommon
import SKFoundation

class SheetShowCellContentService: BaseJSService {
    weak var cellPanel: SheetCellContentPanel?
    private var hasCopyPermission = true // 允许被截图，跟随sheet文档权限
    private let clickableSegmentTypes: [SheetSegmentType] = [.url, .attachment, .mention, .embedImage]
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.permissionConfig.permissionEventNotifier.addObserver(self)
    }
    
    private func updateCellContent(params: [String: Any]) -> Bool {
        if params.isEmpty {
            DocsLogger.info("hide cellContent Panel")
            hidePanel()
            return false
        }
        DocsLogger.info("show cellContent Panel")
        
        guard let hostView = registeredVC?.view else {
            return false
        }
        guard let info = SheetCellContentInfo.deserialize(from: params),
              let data = info.data else {
            DocsLogger.error("parse sheet cell content data failed")
            return false
        }
        var cellStyle = SheetCustomCellStyle(data.style, needExtraStyle: true)
        cellStyle.attachmentLineBreakMode = .byWordWrapping
        cellStyle.paragraphSpacing = 6
        cellStyle.underlineInLink = true
        guard let attrString = SheetFieldDataConvert.convertSegmentToAttString(from: data.realValue, cellStyle: cellStyle) else {
            DocsLogger.error("convertSegmentToAttString failed")
            return false
        }
        
        if let cellPanel = self.cellPanel {
            DocsLogger.info("update CellContentPanel")
            cellPanel.updateContent(attrString, copyable: info.copyable, hideFAB: info.hideFAB, callbackFunc: info.callback)
        } else {
            DocsLogger.info("create new CellContentPanel")
            let cellPanel = SheetCellContentPanel(hostView: hostView)
            cellPanel.delegate = self
            self.cellPanel = cellPanel
            cellPanel.updateContent(attrString, copyable: info.copyable, hideFAB: info.hideFAB, callbackFunc: info.callback)
            cellPanel.show()
            cellPanel.setCaptureAllowed(hasCopyPermission)
        }
        return true
    }
    
    private func hidePanel() {
        self.cellPanel?.hide(immediately: false)
    }
}

extension SheetShowCellContentService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetShowCellContent]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.sheetShowCellContent.rawValue:
            _ = updateCellContent(params: params)
        default:
            break
        }
    }
}

extension SheetShowCellContentService: SheetCellContentPanelDelegate {
    
    func onHidePanel() {
        DocsLogger.info("CellContent onHidePanel")
        self.cellPanel = nil
    }
    
    func onClickSegment(_ segment: SheetSegmentBase, callback: String) {
        DocsLogger.info("CellContent click on segment:\(segment.type)")
        guard clickableSegmentTypes.contains(segment.type) else {
            return
        }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: segment.toJSON()) { (_, error) in
            guard error == nil else {
                DocsLogger.error("callback error:\(String(describing: error))")
                return
            }
        }
    }
    
    func onClickToolkitButton() {
        hidePanel()
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateOpenSheetToolkit.rawValue, params: ["id": FABIdentifier.toolkit.rawValue])
    }
    
    func onSizeChange(isShow: Bool, height: CGFloat) {
        guard let browserVC = registeredVC as? BrowserViewController else {
            return
        }
        let viewportHeight = isShow ? browserVC.webviewHeight - height : 0
        let info = BrowserKeyboard(height: viewportHeight,
                                   isShow: isShow,
                                   trigger: "sheetCellContent")
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
}

extension SheetShowCellContentService: DocsPermissionEventObserver {
    
    func onCopyPermissionUpdated(canCopy: Bool) {
        hasCopyPermission = canCopy
        DocsLogger.info("SheetShowCellContentService set `isCaptureAllowed` -> \(canCopy)")
        cellPanel?.setCaptureAllowed(canCopy)
    }
}
