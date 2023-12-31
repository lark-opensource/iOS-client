//
//  OpenWatermarkModel.swift
//  OPPlugin
//
//  Created by yi on 2021/3/23.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPICheckWatermarkResult: OpenAPIBaseResult {
    public var hasWatermark: Bool

    public init(hasWatermark: Bool) {
        self.hasWatermark = hasWatermark
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["hasWatermark": hasWatermark]
    }
}
