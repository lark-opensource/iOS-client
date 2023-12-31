//
//  HighlightPanelPlugin.swift
//  SpaceKit
//
//  Created by Gill on 2020/5/24.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import LarkWebViewContainer

public protocol HighlightPanelDataDelegate: AnyObject {
    func updateColorPickerPanelV2(models: [ColorPaletteModel], callback: String?)
}

protocol HighlightPanelPluginDelegate: AnyObject {
    var attributionView: DocsAttributionView? { get }
    func callback(callback: DocsJSCallBack, params: [String: Any], nativeCallback: APICallbackProtocol?)
}

extension DocsJSService {
    static let highlightPanelJsName = DocsJSService("biz.navigation.setHighlightPanel")
}

/// PRD: https://bytedance.feishu.cn/docs/doccnE4C0tKAjq52yDsKWkDAXrg
/// 技术文档: https://bytedance.feishu.cn/docs/doccnS9m3t70fqd5QWntIAprpBg#
public final class HighlightPanelPlugin: JSServiceHandler {
    weak var delegate: HighlightPanelPluginDelegate?
    public weak var dataDelegate: HighlightPanelDataDelegate?
    weak var jsEngine: SKExecJSFuncService?
    private(set) var callback: String?
    private(set) var nativeCallback: APICallbackProtocol?

    public init() {
    }

    public var handleServices: [DocsJSService] {
        return [.highlightPanelJsName]
    }
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        if serviceName == DocsJSService.highlightPanelJsName.rawValue {
            nativeCallback = callback
            handle(params: params, serviceName: serviceName)
        }
    }

    public func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.highlightPanelJsName.rawValue {
            _handleHighlightPanel(params)
        }
    }

    public func canHandle(_ serviceName: String) -> Bool {
        return handleServices.contains { return $0.rawValue == serviceName }
    }

    private func _handleHighlightPanel(_ params: [String: Any]) {
        // 1. JSON 转 Model
        // 1.1 先保存处于选中态的 Item
        let typeKeys = ["text", "background"] // 需要客户端保证顺序
        let selectedItems: [String] = typeKeys.compactMap {
            if let selected = params["selected"] as? [String: Any],
                let selectedItem = selected[$0] as? [String: Any],
                let key = selectedItem["key"] as? String {
                return key
            }
            return nil
        }
        
        // 1.2 获取整个 Items
        var models: [ColorPaletteModel] = typeKeys.compactMap {
            if let category = ColorPaletteItemCategory(rawValue: $0),
                let items = params[$0] as? [[String: Any]] {
                var model = ColorPaletteModel(category: category, items: ColorPaletteModel.makeItems(items, category: category, selected: selectedItems))
                //动态获取颜色数量
                if category == .text {
                    let numberOfLine = params["textColorSpanCount"] as? Int ?? ColorPaletteModel.defaultNumberOfLine
                    model.numberOfLine = numberOfLine
                } else if category == .background {
                    let numberOfLine = params["backgroundSpanCount"] as? Int ?? ColorPaletteModel.defaultNumberOfLine
                    model.numberOfLine = numberOfLine
                }
                return model
            }
            return nil
        }
        // 1.3 默认带上一个 Clear 按钮
        if let clear = params["clear"] as? [String: Any],
            let key = clear["key"] as? String {
            models.append(ColorPaletteModel.clearModel(key: key))
        } else if let reset = params["reset"] as? [String: Any],
                  let key = reset["key"] as? String {
            models.append(ColorPaletteModel.resetModel(key: key))
        }
        

        // 2. 渲染
        let isShow = (params["isShow"] as? Bool) ?? true
        delegate?.attributionView?.updateColorPickerPanelV2(models)
        delegate?.attributionView?.showColorPickerPanelV2(toShow: isShow)
        delegate?.attributionView?.colorPickerPanelV2.delegate = self

        // 3. 保存其他数据
        callback = params["callback"] as? String
        dataDelegate?.updateColorPickerPanelV2(models: models, callback: callback)
    }
}

extension HighlightPanelPlugin: ColorPickerPanelV2Delegate {
    public func hasUpdate(color: ColorPaletteItemV2,
                   in panel: ColorPickerPanelV2) {
        delegate?.attributionView?.colorView.updateHighlightPanel(info: color.asDict)
        delegate?.callback(callback: DocsJSCallBack(callback ?? ""),
                           params: color.callbackDict,
                           nativeCallback: nativeCallback)
    }
}
