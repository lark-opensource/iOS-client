//
//  OpenLocationModel.swift
//  LarkOpenAPIModel
//
//  Created by yi on 2021/3/1.
//

import Foundation
import LarkOpenAPIModel
import CoreLocation

class OpenPluginChooseLocationParams: OpenAPIBaseParams {
    // 这边默认值要为wgs84,与Android保持一致.
    // NOTE:iOS和Android从早期开始, 这个API返回的结果就不一致, Android是wgs84而iOS则是根据系统来(国内是gcj02,国外是wgs84)
    // 这边已经确认进行break change, 改为默认wgs84;
    @OpenAPIRequiredParam(userOptionWithJsonKey: "type", defaultValue: "wgs84", validChecker: {
        ($0 == "wgs84") || ($0 == "gcj02")
    })
    public var type: String

    public convenience init(type: String) throws {
        var dict = [String : Any]()
        dict["type"] = type
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // set checkable properties here
        return [_type]
    }
}

final class OpenAPIChooseLocationResult: OpenAPIBaseResult {
    public let name: String
    public let address: String
    public let latitude: CLLocationDegrees
    public let longitude: CLLocationDegrees

    public init(name: String, address: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["name": name,
                "address": address,
                "latitude": String(latitude),
                "longitude": String(longitude)]
    }
}


let kOpenLocationLatitudeMax = 90.0
let kOpenLocationLatitudeMin = -90.0
let kOpenLocationLongitudeMax = 180.0
let kOpenLocationLongitudeMin = -180.0

final class OpenAPILocationParams: OpenAPIBaseParams {
    // openLocation 文档 https://open.feishu.cn/document/uYjL24iN/uQTOz4CN5MjL0kzM
    /// 缩放比例最小值
    static let kLocationScaleMin = 5
    /// 缩放比例最大值
    static let kLocationScaleMax = 18

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "latitude", validChecker: {
        kOpenLocationLatitudeMin - $0 <= Double.ulpOfOne && $0 - kOpenLocationLatitudeMax <= Double.ulpOfOne
    })
    public var latitude: CLLocationDegrees

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "longitude", validChecker: {
        kOpenLocationLongitudeMin - $0 <= Double.ulpOfOne && $0 - kOpenLocationLongitudeMax <= Double.ulpOfOne
    })
    public var longitude: CLLocationDegrees

    public var scale: Int = kLocationScaleMax // 默认采用最大缩放比例

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

        if scale > Self.kLocationScaleMax || scale < Self.kLocationScaleMin { // scale范围校验
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("parameter value invalid: scale ")
        }
    }

    @OpenAPIOptionalParam(jsonKey: "name")
    public var name: String?

    @OpenAPIOptionalParam(jsonKey: "address")
    public var address: String?

    @OpenAPIOptionalParam(jsonKey: "type", validChecker: {
        //如果用户传了参数, 则校验参数的合法性
        return $0 == "wgs84" || $0 == "gcj02"
    })
    public var type: String?

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_latitude, _longitude, _name, _address, _type]
    }
}

final class OpenAPIGetLocationParams: OpenAPIBaseParams {
    
    enum LocationType: String {
        case wgs84
        case gcj02
    }
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "type", defaultValue: LocationType.wgs84.rawValue)
    public var type: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "timeout", defaultValue: 5)
    public var timeout: TimeInterval
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "cacheTimeout", defaultValue: 0)
    public var cacheTimeout: TimeInterval
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "accuracy", defaultValue: "")
    public var accuracy: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "baseAccuracy", defaultValue: 0)
    public var baseAccuracy: Int

    public convenience init() throws {
        let dict: [String: Any] = [:]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_type, _timeout, _cacheTimeout, _accuracy, _baseAccuracy]
    }
}

final class OpenAPIGetLocationResult: OpenAPIBaseResult {
    public let data: [AnyHashable: Any]

    public init(data: [AnyHashable: Any]) {
        self.data = data
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}
