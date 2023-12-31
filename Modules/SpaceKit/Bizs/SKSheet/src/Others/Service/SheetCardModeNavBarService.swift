//
// Created by duanxiaochen.7 on 2019/9/22.
// Affiliated with SpaceKit.
//
// Description: Sheet 进入卡片模式时设置顶部栏信息 \ 退出卡片模式时隐藏顶部栏

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import UniverseDesignIcon

class SheetCardModeNavBarService: BaseJSService {
    struct MenuInfo {
        var imageID: UDIconType
        var id: String
    }
    struct NaviInfo {
        var title: String = ""
        var leftMenus: [MenuInfo] = []
        var rightMenus: [MenuInfo] = []
        var callback: (String) -> Void
    }
    var headerView: SheetCardModeNavBar!
    var previousStatusBarColor: UIColor?
}

extension SheetCardModeNavBarService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetCardModeNavBar]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let barItems = params["items"] as? [String: Any], !barItems.isEmpty else {
            DocsLogger.debug("🍌前端啥都没传，要退出卡片模式")
            hideHeaderView()
            return
        }
        guard let leftItems = barItems["left"] as? [[String: String]], !leftItems.isEmpty else {
            DocsLogger.debug("🍌前端没传左边的按钮")
            return
        }
        guard let rightItems = barItems["right"] as? [[String: String]], !rightItems.isEmpty else {
            DocsLogger.debug("🍌前端没传右边的按钮")
            return
        }
        guard let title = params["title"] as? String else {
            DocsLogger.debug("🍌前端没传工作表标题")
            return
        }
        guard let color = params["bgColor"] as? String else {
            DocsLogger.debug("🍌前端没传背景颜色")
            return
        }
        guard let sbvc = registeredVC as? SheetBrowserViewController else {
            DocsLogger.debug("没有获取到 SheetBrowserViewController")
            return
        }
        guard let callback = params["callback"] as? String else {
            DocsLogger.debug("🍌前端没传按钮回调")
            return
        }
        let newStatusColor = UIColor.docs.rgb(color)
        if previousStatusBarColor == nil {
            previousStatusBarColor = sbvc.statusBar.backgroundColor
        }

        let leftMenus = makeMenus(items: leftItems)
        let rightMenus = makeMenus(items: rightItems)
        let naviInfo = NaviInfo(title: title, leftMenus: leftMenus, rightMenus: rightMenus) { [weak sbvc] id in
            sbvc?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": id], completion: nil)
        }
        if headerView == nil {
            headerView = SheetCardModeNavBar(backgroundColor: newStatusColor)
        }
        headerView.setup(info: naviInfo, bgColor: newStatusColor)
        sbvc.hideForceOrientationTip()

        let topContainer = sbvc.topContainer
        topContainer.addSubview(headerView)
        headerView.snp.remakeConstraints { (make) in
            make.edges.equalTo(topContainer.navBar)
        }

        headerView.startInterceptPopGesture(gesture: sbvc.navigationController?.interactivePopGestureRecognizer)
        sbvc.statusBar.backgroundColor = newStatusColor
        sbvc.hideTabSwitcher()
        sbvc.isInSheetCardMode = true
    }

    private func hideHeaderView() {
        headerView?.stopInterceptPopGesture()
        headerView?.removeFromSuperview()
        if let sbvc = self.registeredVC as? SheetBrowserViewController {
            sbvc.statusBar.backgroundColor = previousStatusBarColor
            sbvc.showTabSwitcher()
            sbvc.isInSheetCardMode = false
        }
        previousStatusBarColor = nil
    }

    private func makeMenus(items: [[String: String]]) -> [MenuInfo] {
        var menus = [MenuInfo]()
        for item in items {
            let id = item["id"] ?? ""
            let imageID = _iconNameMapping[id] ?? .closeOutlined
            let menuInfo = MenuInfo(imageID: imageID, id: id)
            menus.append(menuInfo)
        }
        return menus
    }

    private var _iconNameMapping: [String: UDIconType] {
        return [
            "back": .closeOutlined,
            "card": .sheetCardmodelOutlined,
            "list": .disorderListOutlined
        ]
    }
}
