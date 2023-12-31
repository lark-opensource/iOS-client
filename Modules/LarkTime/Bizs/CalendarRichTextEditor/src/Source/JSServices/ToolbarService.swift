//
//  ToolbarService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.
//

import UIKit
import Foundation
import UniverseDesignColor

final class ToolbarService {
    private lazy var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 128
        return cache
    }()

    private var toolbar: UIView {
        return _makeToolbar()
    }
    private var _storedToolbar: UIView?

    weak var uiDisplayConfig: RichTextViewDisplayConfig?
    weak var jsEngine: RichTextViewJSEngine?
    weak var uiResponder: RichTextViewUIResponse?

    init(uiResponder: RichTextViewUIResponse, uiDisplayConfig: RichTextViewDisplayConfig, jsEngine: RichTextViewJSEngine) {
        self.uiResponder = uiResponder
        self.uiDisplayConfig = uiDisplayConfig
        self.jsEngine = jsEngine
    }
}

extension ToolbarService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtNavToolBar]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let items = params["items"] as? [[String: Any]] else { return }
        Logger.info("RTEditor did set toolbar", extraInfo: ["itemcount": items.count])
        var callback: String
        if items.isEmpty {
            callback = ""
        } else {
            guard let tmpCallback = params["callback"] as? String else {
                Logger.error("RTEditor set toolbar without callback", extraInfo: ["itemcount": items.count])
                return
            }
            callback = tmpCallback
        }

        resolveToolbarInfoV2(items, callback: callback)
    }

    private func resolveToolbarInfoV2(_ items: [[String: Any]], callback: String) {
        guard let toolbar = toolbar as? ToolbarView else {
            Logger.error("ToolbarService can't resolve item for toolbar", extraInfo: ["ResolveVer": 2, "ToolbarVer": 1])
            return
        }
        let resolvedItems = ToolbarFactory.makeToolbar(items: items, jsMethod: callback)
        toolbar.items = resolvedItems
        if !resolvedItems.isEmpty {
            if uiResponder?.inputAccessory != toolbar {
                uiResponder?.inputAccessory = toolbar
            }
        } else {
            uiResponder?.inputAccessory = nil
        }
    }
}

extension ToolbarService {
    private func _makeToolbar() -> UIView {
        if let stoolbar = _storedToolbar {
            return stoolbar
        }
        var toolbar: UIView
        toolbar = ToolbarView()
        toolbar.frame.size.height = 44
        toolbar.backgroundColor = UIColor.ud.N00
        toolbar.layer.borderWidth = 1
        toolbar.ud.setLayerBorderColor(UDColor.N300)

        if let v2toolbar = toolbar as? ToolbarView {
            v2toolbar.delegate = self
        }

        _storedToolbar = toolbar
        return toolbar
    }
}

extension ToolbarService: ToolbarViewDelegate {
    func didClickedItem(_ item: ToolbarItem, clickWhenSelected: Bool) {
        let selectedStr = clickWhenSelected ? "true" : "false"
        let script = item.jsMethod + "({id:'\(item.identifier)',value:'\(selectedStr)'})"
//        let script = callback + "({id:'\(id)'})"
        self.jsEngine?.evaluateJavaScript(script, completionHandler: nil)
    }
}
