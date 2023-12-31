//
//  MindnoteShowThemeCardService.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/9/4.
//  

import Foundation
import SwiftyJSON
import SKCommon
import SKUIKit
import EENavigator
import SKFoundation

final class MindnoteShowThemeCardService: BaseJSService {
    private var callback: String?
    private var themeCard: MindnoteThemeViewController?
    private var showingCard = false
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension MindnoteShowThemeCardService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.mindnoteShowThemeCard]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("MindnoteShowThemeCardService handle \(serviceName)",
                        extraInfo: params,
                        component: LogComponents.toolbar,
                        traceId: browserTrace?.traceRootId)
        guard let callback = params["callback"] as? String else { return }
        self.callback = callback
        guard let model = ThemeDataParse.parse(data: params), let browserVC = navigator?.currentBrowserVC as? BaseViewController else { return }
        if showingCard {
            themeCard?.updateDatas(model)
        } else {
            if SKDisplay.pad, ui?.editorView.isMyWindowRegularSize() ?? false {
                let cardVC = MindnoteThemeViewController(delegate: self, hostViewController: browserVC)
                cardVC.updateDatas(model)
                showingCard = true
                themeCard = cardVC
                let browserVC = navigator?.currentBrowserVC as? BaseViewController
                let originY = (ui?.editorView.bounds.height ?? (ui?.editorView.window?.frame.height ?? 0)) - 76
                cardVC.modalPresentationStyle = .popover
                cardVC.popoverPresentationController?.canOverlapSourceViewRect = true
                cardVC.popoverPresentationController?.sourceView = ui?.editorView
                cardVC.popoverPresentationController?.sourceRect = CGRect(x: 20, y: originY, width: 38, height: 38)
                cardVC.popoverPresentationController?.permittedArrowDirections = .down
                if let sourceView = ui?.editorView {
                    cardVC.popoverPresentationController?.popoverLayoutMargins.left = sourceView.convert(sourceView.bounds, to: nil).minX + 4
                }
                browserVC?.present(cardVC, animated: true)
            } else {
                let cardVC = MindnoteThemeViewController(delegate: self, hostViewController: browserVC)
                cardVC.supportOrientations = browserVC.supportedInterfaceOrientations
                themeCard = cardVC
                themeCard?.updateDatas(model)
                showingCard = true
                self.navigator?.presentClearViewController(cardVC, animated: true)
            }
        }
    }
}

extension MindnoteShowThemeCardService: ThemeCardDelegate {
    func excuteJsCallBack(type: ThemeType, key: String) {
        guard let callback = callback else { return }
        var params = [String: String]()
        params["key"] = key
        params["type"] = type.rawValue
        if type == .close {
            params["key"] = ""
            params["type"] = ""
        }
        self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
    }

    func themeCardClosed() {
        showingCard = false
        themeCard = nil
    }
}

struct ThemeDataParse {
    static func parse(data: [String: Any]) -> MindnoteThemeModel? {
        let json = JSON(data)
        var themeModel = MindnoteThemeModel()
        themeModel.themes = parse(items: json["themes"])
        guard let themes = themeModel.themes, themes.count > 0 else { return nil }
        themeModel.structures = parse(items: json["structures"])
        guard let structures = themeModel.structures, structures.count > 0 else { return nil }
        themeModel.activeStructureKey = json["activeStructureKey"].string
        themeModel.activeThemeKey = json["activeThemeKey"].string
        return themeModel
    }

    static func parse(items: JSON) -> [ThemeItem] {
        var themeItems = [ThemeItem]()
        items.array?.forEach({ (item) in
            var theme = ThemeItem()
            theme.activeImg = item["activeImg"].string
            theme.normalImg = item["normalImg"].string
            theme.key = item["key"].string
            theme.title = item["title"].string
            themeItems.append(theme)
        })
        return themeItems
    }
}
