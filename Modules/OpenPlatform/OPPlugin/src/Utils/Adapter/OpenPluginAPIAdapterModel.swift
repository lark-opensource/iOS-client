//
//  OpenPluginAPIAdapterModel.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/30.
//

import Foundation
import LarkOpenAPIModel

// MARK: Model

// FG的作用方式为： 控制register block是否调用，来决定是否强制走BDPJSBridge
// 这在pluginmanager里会一直走完鉴权、model序列化、调用到主线程，最后查找当前plugin是否有APIName对应的registerBlock，如果没有才会降级到BDPJSBridgeCenter
// 所以如果该Model会导致序列化失败，那就抛104的错误了，而不会走到unable -> BDPJSBridgeCenter
// 因此该入参不能有抛错的情况, 所以就不做参数校验了
final class OpenPluginAPIAdapterParams: OpenAPIBaseParams {
    let params: [AnyHashable: Any]

    required init(with params: [AnyHashable: Any]) throws {
        self.params = params
        try super.init(with: params)
    }
}

final class OpenPluginAPIAdapterResult: OpenAPIBaseResult {
    
    private let result: [AnyHashable: Any]
    
    init(result: [AnyHashable: Any]) {
        self.result = result
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] { result }
}
