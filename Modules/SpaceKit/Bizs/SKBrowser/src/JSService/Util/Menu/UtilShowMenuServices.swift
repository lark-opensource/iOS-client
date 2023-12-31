//
//  UtilShowMenuServices.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/4/11.
//  

import Foundation
import RxSwift
import SKCommon
import SKFoundation
import SKUIKit
import SKResource

public final class UtilShowMenuServices: BaseJSService {
    var callback: String?
    weak var ipadMenuVC: ShowMenuViewController?
    weak var ipadTargetView: UIView?
}

extension UtilShowMenuServices: JSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilShowMenu]
    }

    public func handle(params: [String: Any], serviceName: String) {
        // 用于iPad键盘正文滚动隐藏菜单
        if let shouldDismiss = params["dismiss"] as? Bool, shouldDismiss {
            didReceiveWebviewScroll()
            return
        }
        if serviceName == DocsJSService.utilShowMenu.rawValue {
            // 构建 callback
            _constructMenuCallBack(params)

            // 构建 menu
            let menuItems = _constructMenuItems(params)

            if let position = params["position"] as? [String: CGFloat],
               SKDisplay.pad,
               ui?.editorView.isMyWindowRegularSize() ?? false { // 走popover路径
                showMenuWithPosition(position, menuItems: menuItems)
                return
            }

            let title = params["title"] as? String
            let menu = BrowserMenu(menuItems, title: title)
            // 无需加入 disposeBag, 内部实现了释放
            _ = menu.selectAction.subscribe(onNext: { (id) in
                if let callback = self.callback {
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": id], completion: nil)
                }
            })
            let browserVC = registeredVC as? BrowserViewController
            menu.present(fromVc: browserVC)
        }
    }

    private func _constructMenuItems(_ params: [String: Any]) -> [BrowserMenuItem] {
        guard let items = params["items"] as? [[String: Any]], let showCancel = params["showCancel"] as? Bool else {
            DocsLogger.info("缺少 items Or callback")
            return []
        }

        var menuItems: [BrowserMenuItem] = []

        items.forEach { item in
            if let id = item["id"] as? String, let style = item["style"] as? Int, let text = item["text"] as? String {
                let menuItem = BrowserMenuItem(id: id, text: text, style: style, isCancel: false)
                menuItems.append(menuItem)
            }
        }

        // C模式下默认要加上取消按钮
        if showCancel || (SKDisplay.pad && ui?.editorView.isMyWindowRegularSize() == false) {
            let menuItem = BrowserMenuItem(id: "Cancel", text: BundleI18n.SKResource.Doc_Facade_Cancel, style: 0, isCancel: true)
            menuItems.append(menuItem)
        }

        return menuItems
    }

    private func _constructMenuCallBack(_ params: [String: Any]) {
        if let callback = params["callback"] as? String {
            self.callback = callback
        }
    }
}
