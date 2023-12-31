//
//  ComponentJSRegister.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/31.
//

import Foundation
import LarkWebViewContainer

struct ParamsObject {
    let tagName: String
    let id: String
    let data: [String: Any]

    static func createObject(params: [String: Any]) -> ParamsObject? {
        guard let tagName = params["tagName"] as? String else {
            lkAssertionFailure("no tagName")
            return nil
        }

        guard let id = params["id"] as? String else {
            lkAssertionFailure("no id")
            return nil
        }

        let data = params["data"] as? [String: Any] ?? [:]
        return ParamsObject(tagName: tagName, id: id, data: data)
    }
}

final class ComponentJSRegister {
    /// 注册基本必要的方法
    /// - Parameters:
    ///   - webview: webview description
    ///   - bridgeManager: bridgeManager description
    static func baseRegister(bridgeManager: JSBridgeManager) {
        bridgeManager.registerHandler(methodName: "insertNativeTag") { [weak bridgeManager] (params, callback) in
            guard let webview = bridgeManager?.webview else {
                lkAssertionFailure("no webview")
                return
            }
            guard let insertData = params["data"] as? [[String: Any]] else {
                return
            }
            var resultMap: [String: Int] = [:]
            var inserting: [String] = []
            for data in insertData {
                guard let params = ParamsObject.createObject(params: data),
                      let compnent = webview.componentManager.createCompentWithTagName(tagName: params.tagName)
                      else {
                    continue
                }
                inserting.append(params.id)
                compnent.weakRef.webview = webview
                compnent.willInsertComponent(params: params.data)
                webview.insertComponent(view: compnent.nativeView, atIndex: params.id) { [weak compnent] (success) in
                    if success {
                        compnent?.id = params.id
                        compnent?.didInsertComponent(params: params.data)
                        webview.componentManager.insertComponent(component: compnent)
                        resultMap[params.id] = 0
                    } else {
                        resultMap[params.id] = -1
                    }
                    if resultMap.count == inserting.count {
                        // 全部插入完再回调
                        callback.callbackSuccess(param: resultMap)
                    }
                }
            }
        }

        bridgeManager.registerHandler(methodName: "updateNativeTag") { [weak bridgeManager] (params, callback) in
            guard let webview = bridgeManager?.webview else {
                lkAssertionFailure("no webview")
                return
            }
            guard let updateDatas = params["data"] as? [[String: Any]] else {
                return
            }
            for data in updateDatas {
                if let param = ParamsObject.createObject(params: data),
                      let compnent = webview.componentManager.findComponent(id: param.id) {
                    compnent.updateCompoent(params: param.data)
                }
            }
        }

        bridgeManager.registerHandler(methodName: "removeNativeTag") { [weak bridgeManager] (params, callback) in
            guard let webview = bridgeManager?.webview else {
                lkAssertionFailure("no webview")
                return
            }
            guard let removeDatas = params["data"] as? [[String: Any]] else {
                return
            }
            for data in removeDatas {
                if let param = ParamsObject.createObject(params: data),
                      let compnent = webview.componentManager.findComponent(id: param.id) {
                    compnent.willBeRemovedComponent(params: param.data)
                    webview.removeComponent(index: param.id)
                    webview.componentManager.removeComponent(id: param.id)
                }
            }
        }
    }
}
