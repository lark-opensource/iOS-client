//
//  OPAPIHandlerBrightness.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/2.
//

import Foundation
import UIKit
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import LarkContainer

class OpenPluginBrightness: OpenBasePlugin {

    public func setKeepScreenOn(params: OpenAPISetKeepScreenOnParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = params.keepScreenOn
            callback(.success(data: nil))
        }
    }

    public func setScreenBrightness(params: OpenAPISetScreenBrightnessParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        DispatchQueue.main.async {
            context.apiTrace.info("setScreenBrightness invoke value \(params.value)")
            UIScreen.main.brightness = params.value
            callback(.success(data: nil))
        }
    }

    public func getScreenBrightness(params: OpenAPIBaseParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetScreenBrightnessResult>) -> Void) {
        DispatchQueue.main.async {
            let brightnessValue = UIScreen.main.brightness
            context.apiTrace.info("getScreenBrightness invoke value \(brightnessValue)")
            callback(.success(data: OpenAPIGetScreenBrightnessResult(value: brightnessValue)))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "setKeepScreenOn", pluginType: Self.self, paramsType: OpenAPISetKeepScreenOnParams.self) { (this, params, context, callback) in
            
            this.setKeepScreenOn(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "setScreenBrightness", pluginType: Self.self, paramsType: OpenAPISetScreenBrightnessParams.self) { (this, params, context, callback) in
            
            this.setScreenBrightness(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "getScreenBrightness", pluginType: Self.self, resultType: OpenAPIGetScreenBrightnessResult.self) { (this, params, context, callback) in
            
            this.getScreenBrightness(params: params, context: context, callback: callback)
        }
    }

}
