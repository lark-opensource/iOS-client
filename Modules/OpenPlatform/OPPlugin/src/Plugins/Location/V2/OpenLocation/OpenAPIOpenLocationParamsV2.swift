//
//  OpenAPIOpenLocationParamsV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkOpenAPIModel
import CoreLocation
import LarkCoreLocation

final class OpenAPIOpenLocationParamsV2: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "latitude", validChecker: {
        OpenAPILocationConstants.latitudeRange.contains($0)
    })
    public var latitude: CLLocationDegrees

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "longitude", validChecker: {
        OpenAPILocationConstants.longitudeRange.contains($0)
    })
    public var longitude: CLLocationDegrees

    public var scale: Int = OpenAPILocationConstants.scaleMax // 默认采用最大缩放比例

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)

        // 类型兼容String，以免引起双端打开地图scale效果不一致
        if let locationScale = params["scale"] as? NSNumber {
            self.scale = locationScale.intValue
        } else if let locationScale = Int(params["scale"] as? String ?? "") {
            self.scale = locationScale
        }
        // openLocation 文档 https://open.feishu.cn/document/uYjL24iN/uQTOz4CN5MjL0kzM
        let scale = self.scale
        if !OpenAPILocationConstants.scaleRange.contains(scale) {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("parameter value invalid: scale ")
        }

    }

    @OpenAPIOptionalParam(jsonKey: "name")
    public var name: String?

    @OpenAPIOptionalParam(jsonKey: "address")
    public var address: String?

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "type")
    public var type: OPLocationType

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_latitude, _longitude, _name, _address, _type]
    }
}
