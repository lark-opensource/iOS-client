//
//  OpenMapComponentModel.swift
//  OPPlugin
//
//  Created by yi on 2021/6/7.
//

import Foundation
import LarkOpenAPIModel

class OpenAPIMapComponentParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "mapId", defaultValue: "")
    public var mapId: String

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_mapId]
    }
}

final class OpenAPIMoveToLocationMapComponentParams: OpenAPIMapComponentParams {
    public var longitude: Double?

    public var latitude: Double?

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if let latitudeParam = (params["latitude"] as? NSNumber)?.doubleValue {
            self.latitude = latitudeParam
            if latitudeParam < -90 || latitudeParam > 90 {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("invaild latitude")
            }
        }
        if let longitudeParam = (params["longitude"] as? NSNumber)?.doubleValue {
            self.longitude = longitudeParam
            if longitudeParam < -180 || longitudeParam > 180 {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("invaild longitude")
            }
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return super.autoCheckProperties
    }
}

final class OpenAPIInsertMapComponentParams: OpenAPIBaseParams {

    @OpenAPIOptionalParam(jsonKey: "mapId")
    public var mapId: String?


    public var data: [AnyHashable: Any] = [:]

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if params.isEmpty {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("invaild parameter")
        }
        self.data = params
    }
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_mapId]
    }

}

final class OpenAPIInsertMapComponentResult: OpenAPIBaseResult {

    public var mapId: String

    public init(mapId: String) {
        self.mapId = mapId
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["mapId": mapId]
    }
}

final class OpenAPIUpdateMapComponentParams: OpenAPIMapComponentParams {
    public var data: [AnyHashable: Any] = [:]

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if params.isEmpty {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("invaild parameter")
        }
        self.data = params
    }
}


final class OpenAPIOperateMapComponentParams: OpenAPIMapComponentParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "type",
                          defaultValue: "")
    public var type: String

    @OpenAPIOptionalParam(jsonKey: "data")
    public var data: [AnyHashable: Any]?

    public var longitude: Double?

    public var latitude: Double?

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if self.type == "moveToLocation", let data = self.data {
            if let latitudeParam = (data["latitude"] as? NSNumber)?.doubleValue {
                self.latitude = latitudeParam
                if latitudeParam < -90 || latitudeParam > 90 {
                    throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setOuterMessage("invaild latitude")
                }
            }
            if let longitudeParam = (data["longitude"] as? NSNumber)?.doubleValue {
                self.longitude = longitudeParam
                if longitudeParam < -180 || longitudeParam > 180 {
                    throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setOuterMessage("invaild longitude")
                }
            }
        }
    }
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return super.autoCheckProperties + [_type, _data]
    }

}



