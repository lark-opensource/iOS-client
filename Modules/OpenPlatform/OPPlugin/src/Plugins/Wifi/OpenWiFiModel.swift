//
//  OpenWiFiModel.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/5.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetWifiStatusResult: OpenAPIBaseResult {
    public var status: String
    public init(status: String) {
        self.status = status
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["status": status]
    }
}
