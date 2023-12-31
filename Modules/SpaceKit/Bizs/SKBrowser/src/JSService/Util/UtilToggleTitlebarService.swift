//
//  UtilToggleTitlebarService.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/1/28.
//

import Foundation
import SKCommon
import SKFoundation

public final class UtilToggleTitlebarService: BaseJSService {
    
    var callback: String?

}

extension UtilToggleTitlebarService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.toggleTitleBar, .navBarFixedShowing, .getWebViewCoverHeight]
    }

    public func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.toggleTitleBar.rawValue {
            handleToggleTitleBar(params: params)
        } else if serviceName == DocsJSService.navBarFixedShowing.rawValue {
            setNavBarFixedShowing(params: params)
        } else if serviceName == DocsJSService.getWebViewCoverHeight.rawValue {
            guard let callback = params["callback"] as? String else { return }
            self.callback = callback
            getWebViewCoverHeight()
        }
    }

    private func handleToggleTitleBar(params: [String: Any]) {
        guard let titleBarState = params["states"] as? Bool else {
            DocsLogger.info("缺少导航栏状态")
            return
        }
        // 设置状态栏和导航栏显示或隐藏
        ui?.displayConfig.setTitleBarStatus(!titleBarState)
        
        // 隐藏Bitable目录
        ui?.displayConfig.setCatalogueBanner(visible: titleBarState)

        // 隐藏无网banner
        ui?.displayConfig.setOfflineTipViewStatus(!titleBarState)
    }


    private func setNavBarFixedShowing(params: [String: Any]) {
        guard let isFixed = params["fixed"] as? Bool else { return }
        ui?.displayConfig.setNavBarFixedShowing(isFixed)
    }
    
    private func getWebViewCoverHeight() {
        guard let callback = callback else { return }
        var height: CGFloat = ui?.displayConfig.getWebViewCoverHeight() ?? 0
        if height < 0 { height = 0 }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["height": height], completion: nil)
    }
}
