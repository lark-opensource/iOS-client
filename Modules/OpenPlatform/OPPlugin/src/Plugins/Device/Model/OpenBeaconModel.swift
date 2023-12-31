//
//  OpeniBeaconModel.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/1.
//  iBeacon API的入参和出参

import Foundation
import LarkOpenAPIModel

final class StartBeaconParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "uuids", validChecker: {
        !$0.isEmpty
    })
    public var uuids: [String]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "ignoreBluetoothAvailable", defaultValue: false, validChecker: nil)
    public var ignoreBluetoothAvailable: Bool

    public var uuidArray = [UUID]()

    public convenience init(uuids: [String], ignoreBluetoothAvailable: Bool) throws {
        var dict = [String : Any]()
        dict["uuids"] = uuids
        dict["ignoreBluetoothAvailable"] = ignoreBluetoothAvailable
        try self.init(with: dict)
    }


    public required init(with params: [AnyHashable : Any]) throws {
        try super.init(with: params)

        var uuidArray = [UUID]()
        if let uuids = params["uuids"] as? [String] {
            for uuidString in uuids {
                if let proximityUUID = UUID(uuidString: uuidString) {
                    uuidArray.append(proximityUUID)
                }
            }
        }

        if uuidArray.isEmpty {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("uuids value invalid")
        }

        self.uuidArray = uuidArray
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_uuids, _ignoreBluetoothAvailable]
    }
}

final class OpenAPIGetBeaconResult: OpenAPIBaseResult {
    public let beacons: [[String : Any]]

    public init(beacons:[[String : Any]]) {
        self.beacons = beacons
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["beacons" : beacons]
    }
}
