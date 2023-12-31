//
//  NativeRenderService.swfit.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/5.
//

import Foundation
import LarkWebViewContainer
import LarkWebviewNativeComponent

class NativeRenderService {
    static let shared = NativeRenderService()

    let enable: Bool

    private init() {
        enable = FeatureManager.open(.nativeRender)
    }
}

extension NativeRenderService {
    func enableNativeRender(webview: LarkWebView, componentManager: NativeComponentManageable?) {
        LarkWebviewNativeComponent.enableNativeRender(webview: webview, compenents: [NativeAvatarComponent.self], componentManager: componentManager)
    }
}
