//
//  NativeAppBaseResponse.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/10.
//

import UIKit

@objc
public protocol NativeAppAPIJSONDict: NSObjectProtocol {}

@objc
public protocol NativeAppAPIResultProtocol: NativeAppAPIJSONDict {}

@objcMembers
open class NativeAppAPIBaseResult: NSObject, NativeAppAPIResultProtocol {
    public var resultType: NativeAppApiResultType
    public var data: [AnyHashable: Any]?
    
    
    public init(resultType: NativeAppApiResultType, data: [AnyHashable: Any]? = nil) {
        self.resultType = resultType
        self.data = data
    }

    open func toJSONDict() -> [AnyHashable: Any]? {
        return self.data
    }
}
