//
//  NaiveAppOpenAPIContext.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/3/16.
//

import Foundation
import LKCommonsLogging
import NativeAppPublicKit
import LarkOpenPluginManager
import LarkOpenAPIModel

@objcMembers
open class NativeAppOpenAPIContext: NSObject, NativeAppPluginContextProtocol{
    
    static private let logger = Logger.log(NativeAppOpenAPIContext.self, category: "NativeAppOpenAPIContext")
    
    var openApiContext : OpenAPIContext?
    
    public func fireEvent(event: NativeAppPublicKit.NativeAppCustomEvent) {
        guard let openApiContext = openApiContext else {
            NativeAppOpenAPIContext.logger.info("openApiContext is nil")
            return
        }

        NativeAppOpenAPIContext.logger.info("fire custom event:\(event.eventName), data:\(event.data)")
        var data = [
            "eventName" : event.eventName,
            "data" : event.data
        ] as [String : Any]
        let param = [
            "event" : "fireCustomEvent",
            "data" : data
        ] as [String : Any]
        openApiContext.syncCall(apiName: "fireEvent", params: param, context: openApiContext)
    }
}
