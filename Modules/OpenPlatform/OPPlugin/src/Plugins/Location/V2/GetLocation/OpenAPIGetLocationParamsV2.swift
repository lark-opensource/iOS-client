//
//  OpenAPIGetLocationParamsV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkOpenAPIModel
import CoreLocation
import LarkCoreLocation

final class OpenAPIGetLocationParamsV2: OpenAPIBaseParams {

    private static let timoutRange = 3...180
    private static let cacheTimeoutRange = 0...60

    @OpenAPIOptionalParam(jsonKey: "timeout")
    public var timeout: Int!

    @OpenAPIOptionalParam(jsonKey: "cacheTimeout")
    public var cacheTimeout: Int!

    @OpenAPIOptionalParam(jsonKey: "accuracy")
    public var accuracy: OpenAPILocationAccuracy!

    @OpenAPIRequiredParam(userOptionWithJsonKey: "baseAccuracy", defaultValue: 0)
    public var baseAccuracy: Int

    required init(with params: [AnyHashable : Any]) throws {
        let accuracyKey = _accuracy.jsonKey
        if params[accuracyKey] is NSNull {
            throw  OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter type invalid: \(accuracyKey)")
        }
        try super.init(with: params)
        accuracy = accuracy ?? .high
        timeout = timeout ?? 5
        cacheTimeout = cacheTimeout ?? 0
        if !Self.timoutRange.contains(self.timeout) {
            switch accuracy {
            case .high:
                timeout = 3
            case .best:
                timeout = 10
            case .none:
                break
            }
        }
        if !Self.cacheTimeoutRange.contains(cacheTimeout) {
            cacheTimeout = 0
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_timeout, _cacheTimeout, _accuracy, _baseAccuracy]
    }
}
