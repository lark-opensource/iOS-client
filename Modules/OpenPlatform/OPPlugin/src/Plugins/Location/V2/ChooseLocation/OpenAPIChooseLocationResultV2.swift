//
//  OpenAPIChooseLocationResultV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import LarkOpenAPIModel
import CoreLocation
import LarkCoreLocation

final class OpenAPIChooseLocationResultV2: OpenAPIBaseResult {
    public let name: String
    public let address: String
    public let latitude: CLLocationDegrees
    public let longitude: CLLocationDegrees
    public let type: OPLocationType

    public init(name: String,
                address: String,
                latitude: CLLocationDegrees,
                longitude: CLLocationDegrees,
                type: OPLocationType) {

        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["name": name,
                "address": address,
                "latitude": latitude,
                "longitude": longitude,
                "type": type.rawValue]
    }
}
