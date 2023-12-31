//
//  NativeAppCustomEvent.swift
//  NativeAppPublicKit
//
//  Created by ByteDance on 2023/3/16.
//

import Foundation

@objcMembers
open class NativeAppCustomEvent: NSObject {
    
    /// 开发者客户端和前端约定的事件名, 不可为空
    public var eventName: String
    
    /// 开发者客户端和前端约定的数据，可以为空
    public var data: [String : Any]?
    
    public init(eventName: String, data: [String : Any]?) {
        self.eventName = eventName
        self.data = data
    }
}
