//
//  BTTipsService.swift
//  DocsSDK
//
//  Created by Webster on 2020/3/26.
//

import SKFoundation
import UniverseDesignToast
import SKCommon
import SKUIKit

// https://bytedance.feishu.cn/docs/doccnvxRbt14Bv6GugTA1EJLgVh#H7afAs

final class BTTipsService: BaseJSService {
    var toastWithID: (String, UDToast)?
    var userCanceled: [String: Bool] = [:] // nil: 前端主动隐藏。false: 延时消失。true: 用户点击按钮消失
    var showTipsCallBack = ""
    var hideTipsCallBack = ""

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension BTTipsService: DocsJSServiceHandler {

    var handleServices: [DocsJSService] {
        return [.bitableTip, .bitableHideTip]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch DocsJSService(serviceName) {
            case .bitableTip:
                showBitableTips(params)
            case .bitableHideTip:
                hideBitableTipsByJS(params)
            default:
            ()
        }
    }

    func showBitableTips(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String,
            let content = params["content"] as? String,
            let buttonText = params["confirmText"] as? String,
            let duration = params["duration"] as? Int,
            let identifier = params["id"] as? String else { return }
        let delayInterval = duration > 0 ? (TimeInterval)(duration) / 1000 : 0.0
        showTipsCallBack = callback
        if let hud = toastWithID {
            hud.1.remove()
        }
        createHud(with: identifier, content: content, buttonText: buttonText, delay: delayInterval)
    }

    func createHud(with identifier: String, content: String, buttonText: String, delay: TimeInterval = 3.0) {
        var window = self.navigator?.currentBrowserVC?.view.affiliatedWindow
        if UserScopeNoChangeFG.ZJ.btCardReform {
            window = self.navigator?.currentBrowserVC?.navigationController?.topViewController?.view.window
        }
        guard let window = window else { return }
        userCanceled[identifier] = false
        let toast = UDToast.showTips(with: content,
                                     operationText: buttonText,
                                     on: window,
                                     delay: delay,
                                     operationCallBack: { [weak self] _ in
                                        self?.userCanceled[identifier] = true
                                        self?.hudDidDismissByUser(identifier)
                                     },
                                     dismissCallBack: { [weak self] in
                                        if self?.userCanceled[identifier] == false {
                                            self?.hudDidDismissTimeout(identifier)
                                        }
                                     })
        toastWithID = (identifier, toast)
    }

    func hideBitableTipsByJS(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        hideTipsCallBack = callback
        if let (identifier, toast) = toastWithID {
            userCanceled[identifier] = nil
            toast.remove()
            model?.jsEngine.callFunction(DocsJSCallBack(hideTipsCallBack), params: [:], completion: nil)
        }
    }

    func hudDidDismissByUser(_ id: String) {
        toastWithID = nil
        let info: [String: Any] = ["id": id, "closeType": 1]
        model?.jsEngine.callFunction(DocsJSCallBack(showTipsCallBack), params: info, completion: nil)
    }

    func hudDidDismissTimeout(_ id: String) {
        toastWithID = nil
        let info: [String: Any] = ["id": id, "closeType": 0]
        model?.jsEngine.callFunction(DocsJSCallBack(showTipsCallBack), params: info, completion: nil)
    }
}


extension BTTipsService: BrowserViewLifeCycleEvent {
    func browserWillDismiss() {
        if let (identifier, toast) = toastWithID {
            toast.remove()
            hudDidDismissTimeout(identifier)
        }
    }
}
