//
//  PositionKeeperService.swift
//  SpaceKit
//
//  Created by nine on 2019/12/25.
//

import Foundation
import SKCommon
import SKFoundation

public final class PositionKeeperService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.scrollProxy?.addObserver(self)
    }
}

extension PositionKeeperService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.getPositionKeeperStatus]
    }

    public func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.getPositionKeeperStatus.rawValue {
            guard let callback = params["callback"] as? String else { DocsLogger.error("\(serviceName)缺少callback"); return }
            var isEnable = true
            // vcfollow模式下，关闭保存位置
            if model?.vcFollowDelegate != nil {
                isEnable = false
            }
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["enabled": isEnable], completion: nil)
        } else {
            DocsLogger.error("\(serviceName)缺少实现")
        }
    }
}

extension PositionKeeperService: EditorScrollViewObserver {
    
    public func editorViewScrollViewWillScrollToTop(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        let function = DocsJSCallBack("window.lark.biz.content.scrollToTop") // 点击状态栏
        model?.jsEngine.callFunction(function, params: [:], completion: nil)
        DocsLogger.info("editorView scrollView willScrollToTop")
    }
}
