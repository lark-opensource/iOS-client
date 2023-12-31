//
//  OpenComponentBaseResponse.swift
//  LarkWebviewNativeComponent
//
//  Created by baojianjun on 2022/7/29.
//

import Foundation
import LarkOpenAPIModel

open class OpenComponentBaseResult {
    
    public init() {}
    
    public var extraData: [String: Encodable]?
    
    open func toJSONDict() -> [String: Encodable] {
        return extraData ?? [:]
    }
}

public enum OpenComponentBaseResponse<Result: OpenComponentBaseResult> {
    case failure(error: OpenAPIError)
    case success(data: Result?)
}

public enum OpenComponentInsertResponse {
    case failure(error: OpenAPIError)
    case success(view: UIView)
}
