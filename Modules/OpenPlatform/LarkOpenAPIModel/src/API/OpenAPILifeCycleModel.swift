//
//  OpenAPILifeCycleModel.swift
//  LarkOpenAPIModel
//
//  Created by yi on 2021/7/22.
//

import Foundation

// worker环境加载的上下文
open class OpenAPIEnviromentDidLoadParams: OpenAPIBaseParams {
    public var data: [AnyHashable: Any] = [:] // worker加载携带参数

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}

open class OpenAPIWorkerEnviromentParams: OpenAPIBaseParams {
    public var data: [AnyHashable: Any] = [:] // worker携带参数

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}
