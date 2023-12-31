//
//  OpenConfigModel.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetEnvVariableResult: OpenAPIBaseResult {
    public let config: [AnyHashable: Any]
    public init(config: [AnyHashable: Any]) {
        self.config = config
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["config": config]
    }
}

final class OpenAPIGetKAInfoResult: OpenAPIBaseResult {
    public let channel: String
    public init(channel: String) {
        self.channel = channel
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["channel": channel]
    }
}

final class OpenAPIGetServerTimeResult: OpenAPIBaseResult {
    public let time: Int
    public init(time: Int) {
        self.time = time
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["time": time]
    }
}




