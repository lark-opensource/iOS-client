//
//  OpenNativeComponentInterceptor.swift
//  LarkWebviewNativeComponent
//
//  Created by X-MAN on 2022/9/9.
//

import Foundation
import LarkWebViewContainer

public protocol OpenNativeComponentObserverble {
    static func receivedJSInsertEvent(with componentId: String, params: [AnyHashable: Any], error: Error?)
    static func updateComponentBounds(with componentId: String, params: [AnyHashable: Any], error: Error?)
    static func renderViewOnCreate(with componentId:String, params: [AnyHashable: Any], error: Error?)
    static func componentAdd(with componentId: String, params: [AnyHashable: Any], error: Error?)

}

final class OpenNativeComponentInterceptor {
    
    static func classType(_ from: String, webView: LarkWebView?) -> OpenNativeComponentObserverble.Type? {
        return webView?.op_typeManager?.componentClass(type: from) as? OpenNativeComponentObserverble.Type
    }
    
    static func classType(_ from: OpenNativeBaseComponent) -> OpenNativeComponentObserverble.Type? {
        return  from.self as? OpenNativeComponentObserverble.Type
    }
    
}
