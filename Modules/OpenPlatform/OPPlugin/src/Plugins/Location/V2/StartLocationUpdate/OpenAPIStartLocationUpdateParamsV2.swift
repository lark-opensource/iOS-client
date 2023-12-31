//
//  OpenAPIStartLocationUpdateParamsV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import LarkOpenAPIModel
import CoreLocation
import LarkCoreLocation

final class OpenAPIStartLocationUpdateParamsV2: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "accuracy",
        defaultValue: .high
    )
    public var accuracy: OpenAPILocationAccuracy

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // set checkable properties here
        return [_accuracy]
    }
}
