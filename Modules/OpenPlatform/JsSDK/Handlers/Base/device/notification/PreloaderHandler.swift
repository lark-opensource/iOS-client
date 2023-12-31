//
//  PreloaderHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import LKCommonsLogging
import LarkUIKit
import WebBrowser
import RoundedHUD

class HidePreloaderHandler: JsAPIHandler {
    static let logger = Logger.log(HidePreloaderHandler.self, category: "Module.JSSDK")
    var hud: PreloaderHud
    init(hud: PreloaderHud) {
        self.hud = hud
    }
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        HidePreloaderHandler.logger.info("handle hide preloader")
        self.hud.hide()
    }
}
class ShowPreloaderHandler: JsAPIHandler {
    static let logger = Logger.log(ShowPreloaderHandler.self, category: "Module.JSSDK")
    var hud: PreloaderHud
    init(hud: PreloaderHud) {
        self.hud = hud
    }
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let text = args["text"] as? String else {
            ShowPreloaderHandler.logger.error("required text parameter invalid")
            return
        }
        guard let view = api.view else {
            ShowPreloaderHandler.logger.error("no container view to display preLoader")
            return
        }
        ShowPreloaderHandler.logger.info("handle show preLoader")   //  这里打Log用错了对象导致编译不过，此处有疑问请联系 @liuwanlin
        hud.show(text: text, in: view)
    }
}
class PreloaderHud {
    fileprivate var hud: RoundedHUD?
    func show(text: String, in view: UIView) {
        hud?.remove()
        //  使用true会导致主导航模式整个页面卡死
        hud = RoundedHUD.showLoading(with: text, on: view, disableUserInteraction: false)
    }
    func hide() {
        hud?.remove()
        hud = nil
    }
}
