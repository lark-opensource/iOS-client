//
//  OpenPluginDeviceResult.swift
//  LarkOpenAPIModel
//
//  Created by baojianjun on 2023/5/29.
//

import Foundation

public final class OpenPluginDeviceResult: OpenAPIBaseResult {
    private let deviceID: String

    public init(deviceID: String) {
        self.deviceID = deviceID
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["deviceID": deviceID]
    }
}
