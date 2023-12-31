//
//  BDPWebView+NativeComponent.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/6/30.
//

import Foundation
import TTMicroApp
import OPPluginManagerAdapter
import LarkWebviewNativeComponent

extension BDPWebView {
    @objc override open func setupNativeComponent() {
        
        LarkNativeComponent.enableNativeComponent(webView: self, components: [
            OpenNativeMapComponent.self,
            OpenNativeVideoComponent.self,
            OpenNativeInputComponent.self,
            OpenNativeTextAreaComponent.self,
            OpenNativeCameraComponent.self,
        ])
        
    }
}
