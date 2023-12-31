//
//  ShowMoreDialogService.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/10/12.
//  从群公告迁移出来的通用显示MoreDialog的能力

import Foundation
import SKCommon
import UniverseDesignColor
import SKFoundation
public final class ShowMoreDialogService: BaseJSService {
    private var floatActionCallback: String?
}

extension ShowMoreDialogService: DocsJSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        return [.showMoreDialog]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        
        guard let currentVC = navigator?.currentBrowserVC as? BaseViewController else { return }
        
        guard let items = params["items"] as? [[String: Any]],
              let callback = params["callback"] as? String else {
            return
        }
        
        floatActionCallback = callback
        var actioniItems: [FloatActionItem] = []
        items.forEach { (item) in
            guard let id = item["id"] as? String,
                  let text = item["text"] as? String,
                  let enable = item["enable"] as? Bool else {
                return
            }
            
            guard let type = FloatActionType(rawValue: id) else {
                DocsLogger.error("undefined show more dialog menu type:\(id)")
                return
            }
            var actionItem = type.item
            actionItem.setItemEnable(enable: enable)
            actionItem.setTitle(title: text)
            actioniItems.append(actionItem)
        }
        
        let actionView = FloatActionView(items: actioniItems)
        if isMyWindowRegularSize() {
            //popover模式
            let popoverVC = FloatActionPopoverViewController(actionView: actionView)
            popoverVC.actionView.delegate = self
            popoverVC.modalPresentationStyle = .popover
            popoverVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            currentVC.showPopover(to: popoverVC, at: -1)
        } else {
            //非popover模式
            let maskVC = FloatActionMaskViewController(actionView: actionView)
            maskVC.actionView.delegate = self
            maskVC.modalPresentationStyle = .overFullScreen
            currentVC.navigationController?.present(maskVC, animated: true, completion: nil)
        }
        
        
    }
    
    private func isMyWindowRegularSize() -> Bool {
        return navigator?.currentBrowserVC?.view.isMyWindowRegularSize() ?? false
    }
}

extension ShowMoreDialogService: FloatActionDelegate {
    public func floatAction(_ actionView: FloatActionView, selectWith type: FloatActionType) {
        guard let callback = floatActionCallback else { return }
        let params = ["id": type.rawValue]
        DocsLogger.debug("floatAction callback: \(callback)")
        self.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: params, completion: nil)
    }
}
