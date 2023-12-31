//
//  OpenPluginWatermarkChange.swift
//  OPPlugin
//
//  Created by bytedance on 2021/6/8.
//

import UIKit
import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginBiz
import OPFoundation
import LarkContainer

final class OpenPluginWatermarkChange: OpenBasePlugin {
    
    private var context: OpenAPIContext?
    
    @objc
    func notificationOnWatermarkChange(notification: NSNotification) {
        guard let context else {
            return
        }
        context.apiTrace.info("notificationOnWatermarkChange start")
        guard let hasWatermark = notification.userInfo?[Notification.Watermark.Key] as? Bool else {
            context.apiTrace.error("notificationOnWatermarkChange no watermark info")
            return
        }
        do {
            let fireEvent = try OpenAPIFireEventParams(event: "onWatermarkChange",
                                                       sourceID: NSNotFound,
                                                       data: ["hasWatermark": hasWatermark],
                                                       preCheckType: .none,
                                                       sceneType: .normal)
            let response = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            switch response {
            case let .failure(error: e):
                context.apiTrace.error("fire event onWatermarkChange fail \(e)")
            default:
                context.apiTrace.info("fire event onWatermarkChange success")
            }
        } catch {
            context.apiTrace.info("fire event onWatermarkChange params error \(error)")
        }
        context.apiTrace.info("notificationOnWatermarkChange end")
    }
    
    func onWatermarkChange(params: OpenAPIBaseParams, context:OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("onWatermarkChange start")
        self.context = context
        // 先移除再加，保证只触发一次
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationOnWatermarkChange(notification:)), name: NSNotification.Name.WatermarkDidChange, object: nil)
        callback(.success(data: nil))
        context.apiTrace.info("onWatermarkChange end")
    }
    
    func offWatermarkChange(params: OpenAPIBaseParams, context:OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("offWatermarkChange start")
        self.context = nil
        NotificationCenter.default.removeObserver(self)
        callback(.success(data: nil))
        context.apiTrace.info("offWatermarkChange end")
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "onWatermarkChange", pluginType: Self.self) { (this, params, context, callback) in
            
            this.onWatermarkChange(params: params, context:context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "offWatermarkChange", pluginType: Self.self) { (this, params, context, callback) in
            
            this.offWatermarkChange(params: params, context:context, callback: callback)
        }
    }
}
