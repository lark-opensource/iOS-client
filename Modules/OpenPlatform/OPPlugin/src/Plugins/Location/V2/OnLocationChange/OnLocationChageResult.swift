//
//  OnLocationChageResult.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import CoreLocation
import LarkCoreLocation
import LarkOpenAPIModel
/// onLocationChange Model
final class OnLocationChangeResult: OpenAPIBaseResult {
    /// 纬度
    public let latitude: CLLocationDegrees
    /// 经度
    public let longitude: CLLocationDegrees
    /// 高度 iOS 特有
    let altitude: CLLocationDistance
    /// 垂直方向精度
    public let verticalAccuracy: CLLocationAccuracy
    /// 水平方向精度
    public let horizontalAccuracy: CLLocationAccuracy
    /// 时间戳 秒
    public let timestamp: Int64
    /// type
    public let type: OPLocationType
    public let authorizationAccuracy: AuthorizationAccuracy
    public let locations: [OnLocationChangeResult]
    
    init(latitude: CLLocationDegrees,
         longitude: CLLocationDegrees,
         altitude: CLLocationDistance,
         verticalAccuracy: CLLocationAccuracy,
         horizontalAccuracy: CLLocationAccuracy,
         time: Date,
         type: OPLocationType,
         authorizationAccuracy: AuthorizationAccuracy,
         locations: [OnLocationChangeResult])
    {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.verticalAccuracy = verticalAccuracy
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = Int64(time.timeIntervalSince1970 * 1000)
        self.authorizationAccuracy = authorizationAccuracy
        self.type = type
        self.locations = locations
    }

    override public func toJSONDict() -> [AnyHashable: Any] {
        var result = pureToJsonDict()
        if !locations.isEmpty {
            result["locations"] = locations.map { $0.pureToJsonDict() }
        }
        return result
    }

    private func pureToJsonDict() -> [AnyHashable: Any] {
        return ["latitude": latitude,
                "longitude": longitude,
                "altitude": altitude,
                "accuracy": horizontalAccuracy,
                "verticalAccuracy": verticalAccuracy,
                "horizontalAccuracy": horizontalAccuracy,
                "timestamp": timestamp,
                /// 老版本的持续定位并没返回authorizationAccuracy，打卡小程序的开发者强烈建议返回，所以在新版本的API返回也与与getLocation对齐
                "authorizationAccuracy": authorizationAccuracy.authorizationAccuracyString,
                "type": type.rawValue]
    }
}

private extension AuthorizationAccuracy {
    var authorizationAccuracyString: String {
        switch self {
        case .full, .unknown:
            return "full"
        case .reduced:
            return "reduced"
        }
    }
}
extension OnLocationChangeResult {
    convenience init(location: LarkLocation, locations: [LarkLocation]) {
        self.init(latitude: location.location.coordinate.latitude,
                   longitude: location.location.coordinate.longitude,
                   altitude: location.location.altitude,
                   verticalAccuracy: location.location.verticalAccuracy,
                   horizontalAccuracy: location.location.horizontalAccuracy,
                   time: location.location.timestamp,
                   type: location.locationType.opLocationType,
                   authorizationAccuracy: location.authorizationAccuracy,
                   locations: locations.map { OnLocationChangeResult(location: $0, locations: []) })
    }
}
