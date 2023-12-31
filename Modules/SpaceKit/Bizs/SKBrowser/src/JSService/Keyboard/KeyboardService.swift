//
//  KeyboardService.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/11/11.
//

import Foundation
import SKCommon

class KeyboardService: BaseJSService {
    lazy var internalPlugin: SKBaseNotifyH5KeyboardPlugin = {
        let plugin = SKBaseNotifyH5KeyboardPlugin(scene: .docs(type: hostDocsInfo?.inherentType))
        plugin.pluginProtocol = self
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        return plugin
    }()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension KeyboardService: BrowserViewLifeCycleEvent {
    public func browserKeyboardDidChange(_ keyboardInfo: BrowserKeyboard) {
        // Fix:弹出评论输入框设置了trigger被其他地方覆盖的问题
        let isNormalCommentShowing = model?.jsEngine.fetchServiceInstance(CommentInputService.self)?.isShowingComment ?? false
        let isImgCommentShowing = model?.jsEngine.fetchServiceInstance(UtilOpenImgService.self)?.isShowCommentInput ?? false
        if isNormalCommentShowing || isImgCommentShowing {
            let kbInfo = BrowserKeyboard(height: keyboardInfo.height,
                                         isShow: keyboardInfo.isShow,
                                         trigger: DocsKeyboardTrigger.comment.rawValue)
            internalPlugin.onKeyboardInfoChange(kbInfo)
            return
        }
        internalPlugin.onKeyboardInfoChange(keyboardInfo)
    }
}

extension KeyboardService: SKBaseNotifyH5KeyboardPluginProtocol {

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}

extension KeyboardService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return internalPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        internalPlugin.scene = .docs(type: hostDocsInfo?.inherentType)
        internalPlugin.handle(params: params, serviceName: serviceName)
    }
}
