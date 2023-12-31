//
//  OpenAPINativeAppResult.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/6/23.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPINativeAppResult: OpenAPIBaseResult {
    public var data: [AnyHashable : Any]
    public init(data: [AnyHashable : Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}
