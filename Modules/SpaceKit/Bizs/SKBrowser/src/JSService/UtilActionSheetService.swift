//
//  UtilActionSheetService.swift
//  SKBrowser
//
//  Created by zengsenyuan on 2022/4/29.
//

/*
 数据参数
 biz.util.showActionSheet:
 {
    "data":[{
        "actionId": "actionId",
        "title": "",
        "actionStyle": 0 //default:0, cancel:1, destructive:2 cancel 只能传一个。
        "clickable": false//不传为true
    }],
    "popPosition": { //这个只有 ipad 需要传过来
        "x": 100,
        "y": 100,
        "width": 100,
        "height": 100,
        "arrawDirection": 0 //up:0, down:1, left:2, right:3 []
    },
    "callback": {
        "actionId": "actionId"
    }
 }
 模拟调用
 model?.jsEngine.simulateJSMessage(DocsJSService.utilShowActionSheet.rawValue, params: ["data": [["actionId": "1", "title": "action1", "actionStyle": 0],
                                                                                               ["actionId": "2", "title": "action2", "actionStyle": 0]],
                                                                                       "popPosition": ["x": 0, "y": 0, "width": 100.0, "height": 100.0, "arrawDirection": 0],
                                                                                       "callback": "actionSheetCallback"])
*/


import SKFoundation
import SKCommon
import SKUIKit
import UniverseDesignActionPanel
import UniverseDesignColor

struct SKActionSheetData: Codable {
    var data: [SKActionItem] = []
    var popPosition: SKActionPopPosition?
    var callback: String = ""
    var title: String?
}

struct SKActionItem: Codable {
    var actionId: String
    var title: String
    var actionStyle: Int
    var clickable: Bool?
}

struct SKActionPopPosition: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var arrawDirection: Int = 0 //up:0, down:1, left:2, right:3 []
}

public final class UtilActionSheetService: BaseJSService {
    var logPrefix: String {
        return model?.jsEngine.editorIdentity ?? ""
    }
}

extension UtilActionSheetService: DocsJSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        return [.utilShowActionSheet]
    }

    public func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info(logPrefix + "UtilActionSheetService handle \(serviceName)", extraInfo: params, error: nil)
        switch serviceName {
        case DocsJSService.utilShowActionSheet.rawValue:
            guard let _actionSheetData = params.json,
               let actionSheetData = try? JSONDecoder().decode(SKActionSheetData.self, from: _actionSheetData) else {
                   DocsLogger.error(logPrefix + "UtilActionSheetService error action Sheet params", extraInfo: params, error: nil)
                   return
            }
            showActionSheet(data: actionSheetData)
        default:
            skAssertionFailure("UtilActionSheetService can not handler \(serviceName)")
        }
    }
    
    private func showActionSheet(data: SKActionSheetData) {
        var popSource: UDActionSheetSource?
        if let popPosition = data.popPosition, let editorView = ui?.editorView, let containerView = registeredVC?.view {
            let rectInWebView = CGRect(x: popPosition.x, y: popPosition.y, width: popPosition.width, height: popPosition.height)
            let rect = editorView.convert(rectInWebView, to: containerView)
            var arrawDirection: UIPopoverArrowDirection = .up
            switch popPosition.arrawDirection {
            case 0: arrawDirection = .up
            case 1: arrawDirection = .down
            case 2: arrawDirection = .left
            case 3: arrawDirection = .right
            default: arrawDirection = .up
            }
            popSource = UDActionSheetSource(sourceView: containerView, sourceRect: rect, arrowDirection: arrawDirection)
        }
        
        let actionSheet = UDActionSheet.actionSheet(title: data.title, popSource: popSource) {
            
        }
        data.data.forEach { actionData in
            let isEnable = actionData.clickable ?? true  //不传默认enable
            actionSheet.addItem(text: actionData.title,
                                textColor: isEnable ? nil : UDColor.textDisabled,
                                style: UDActionSheetItem.Style(rawValue: actionData.actionStyle) ?? .default,
                                isEnable: isEnable) { [weak self] in
                self?.model?.jsEngine.callFunction(DocsJSCallBack(data.callback), params: ["actionId": actionData.actionId], completion: nil)
            }
        }
        self.topMostOfBrowserVC()?.present(actionSheet, animated: true, completion: nil)
    }
}
