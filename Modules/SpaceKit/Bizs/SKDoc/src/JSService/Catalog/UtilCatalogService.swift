//
//  UtilCatalogService.swift
//  SpaceKit
//
//  Created by Webster on 2019/4/24.
//

import Foundation
import WebKit
import SKCommon
import SKUIKit
import SKBrowser
import SKFoundation
import SKInfra

public final class UtilCatalogService: BaseJSService {
    ///前端传输过来的目录详情
    private var catalogItems: [CatalogItemDetail]?
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        ui.gestureProxy?.addObserver(self)
    }
}

extension UtilCatalogService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        catalogItems = nil
        ui?.catalog?.resetCatalog()
        ui?.gestureProxy?.removeObserver(self)
    }

    public func browserDidDismiss() {
        ui?.catalog?.hideCatalogDetails()
    }
}

extension UtilCatalogService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.catalogDisplay, .ipadCatalogDisplay, .iPadCatalogButtonState, .setActiveCatalogItem, .setCatalogVisible]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.catalogDisplay.rawValue:
            parseParagraphsDetails(params)
        case DocsJSService.ipadCatalogDisplay.rawValue:
            iPadCatalogDisplay(params)
        case DocsJSService.iPadCatalogButtonState.rawValue:
            setIPadCatalogButtonState(params)
        case DocsJSService.setActiveCatalogItem.rawValue:
            setActiveCatalogItem(params)
        case DocsJSService.setCatalogVisible.rawValue:
            setCatalogVisible(params)
        default:
            ()
        }
    }
    private func parseParagraphsDetails(_ data: [String: Any]) {
        guard let paragraphs = data["paragraphs"] as? [Any] else {
            return
        }
        let realParagraphs = paragraphs.map { (json) -> CatalogItemDetail in
            if let info = json as? [String: Any] {
                return CatalogItemDetail(json: info)
            }
            return CatalogItemDetail(title: "", level: 1, yOffset: 0)
        }
        catalogItems = realParagraphs
        catalogItems = catalogItems?.filter({ (item) -> Bool in
            return !item.title.isEmpty && item.showParagraph
        })
        DocsLogger.info("catalogData count is \(String(describing: catalogItems?.count))")
        if let datas = catalogItems {
            ui?.catalog?.prepareCatalog(datas)
        }
    }

    // 收拢展示目录的场景
    // 具体有两种类型：1.手动展开点击目录按钮（isShow） 2.自动展开点击全屏按钮（autoShow)，不存在同时显示的场景。
    private func iPadCatalogDisplay(_ data: [String: Any]) {
        if let show = data["isShow"] as? Bool {
            ui?.catalog?.configIPadCatalog(show, autoPresentInEmbed: false, complete: { [weak self] (mode) in
                guard let self = self else { return }
                if mode != .embedded {
                    self.handleKeyBoardDisplayWithIPadCatalogStatus(show)
                }
            })
            CCMKeyValue.globalUserDefault.set(show, forKey: UserDefaultKeys.docxIpadCatalogDisplayLastScene)
        } else if let autoShow = data["autoShow"] as? Bool, autoShow {
            // 1. 判断是否有阅读权限和目录数据
            guard model?.permissionConfig.hostUserPermissions?.canView() == true,
                  let items = ui?.catalog?.catalogDetails(),
                  items.count > 0 else {
                return
            }
            let autoPresentInEmbed = data["autoPresentInEmbed"] as? Bool ?? false
            let lastScene = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.docxIpadCatalogDisplayLastScene, defaultValue: true)
            DocsLogger.info("UtilCatalogService lastScene value: \(lastScene)")
            // 2.无记忆目录上次操作场景缓存，打开目录； 判断缓存是否开启，缓存为开启打开目录，否则关闭
            if lastScene {
                // 自动展示不需要隐藏键盘
                // handleKeyBoardDisplayWithIPadCatalogStatus(true)
                ui?.catalog?.configIPadCatalog(true, autoPresentInEmbed: autoPresentInEmbed,complete: nil)
            }
        }
    }

    private func setIPadCatalogButtonState(_ data: [String: Any]) {
        guard let isOpen = data["isOpen"] as? Bool else {
            return
        }
        ui?.displayConfig.setIpadCatalogState(isOpen: isOpen)
    }

    private func setActiveCatalogItem(_ data: [String: Any]) {
        guard let identifier = data["hash"] as? String else {
            return
        }
        ui?.catalog?.setHighlightCatalogItemWith(identifier)
    }

    private func setCatalogVisible(_ data: [String: Any]) {
        guard let visible = data["visible"] as? Bool, SKDisplay.pad else { return }
        ui?.catalog?.configIPadCatalog(visible, autoPresentInEmbed: false,complete: nil)
        ui?.displayConfig.setIpadCatalogState(isOpen: visible)
    }

    private func handleKeyBoardDisplayWithIPadCatalogStatus(_ isShow: Bool) {
        // 判断键盘是否正常显示
        guard let browserVC = self.navigator?.currentBrowserVC as? BrowserViewController, browserVC.keyboard.isShow else {
            return
        }
        // 目前只有在目录显示情况才进行键盘隐藏操作
        guard isShow else {
            return
        }
        let info = SimulateKeyboardInfo()
        info.trigger = "editor"
        info.isShow = false
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
}

extension UtilCatalogService: EditorViewGestureObserver {
    public func receiveSingleTap(editorView: UIView?, gestureRecognizer: UIGestureRecognizer) {
        ui?.catalog?.hideCatalog()
    }
}
