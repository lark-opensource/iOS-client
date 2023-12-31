//
//  OpenAPIGetLocationResultV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import CoreLocation
import LarkOpenAPIModel
/// getLocation result
final class OpenAPIGetLocationResultV2: OpenAPIBaseResult {
    public enum AuthorizationAccuracy: String {
        case full = "full"
        case reduced = "reduced"
    }
    /// 纬度
    public let latitude: CLLocationDegrees
    /// 经度
    public let longitude: CLLocationDegrees
    ///
    let altitude: CLLocationDistance
    /// 精度
    public let accuracy: CLLocationDistance
    public let locationType: OPLocationType    /// 垂直方向精度
    public let verticalAccuracy: CLLocationDistance
    /// 水平方向精度
    public let horizontalAccuracy: CLLocationDistance
    /// 时间戳 毫秒
    public let timestamp: Int64
    /// 用户授予的精度
    public let authorizationAccuracy: AuthorizationAccuracy

    public init(latitude: CLLocationDegrees,
                longitude: CLLocationDegrees,
                altitude: CLLocationDistance,
                locationType: OPLocationType,
                accuracy: CLLocationDistance,
                verticalAccuracy: CLLocationDistance,
                horizontalAccuracy: CLLocationDistance,
                time: Date,
                authorizationAccuracy: AuthorizationAccuracy) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.locationType = locationType
        self.accuracy = accuracy
        self.verticalAccuracy = verticalAccuracy
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp =  Int64(time.timeIntervalSince1970 * 1000)
        self.authorizationAccuracy = authorizationAccuracy
    }


    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["latitude": latitude,
                "longitude": longitude,
                "altitude": altitude,
                "type": locationType.rawValue,
                "accuracy": accuracy,
                "verticalAccuracy": verticalAccuracy,
                "horizontalAccuracy": horizontalAccuracy,
                "timestamp": timestamp,
                "authorizationAccuracy": authorizationAccuracy.rawValue]
    }
}
