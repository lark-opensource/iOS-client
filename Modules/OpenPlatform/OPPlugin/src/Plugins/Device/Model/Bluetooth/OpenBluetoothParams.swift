//
//  OpenBluetoothParams.swift
//  LarkOpenAPIModel
//
//  Created by lixiaorui on 2021/4/22.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIStartBluetoothDevicesDiscoveryParams: OpenAPIBaseParams {
    // 要搜索的蓝牙设备主 service 的 uuid 列表。某些蓝牙设备会广播自己的主 service 的 uuid。如果设置此参数，则只搜索广播包有对应 uuid 的主服务的蓝牙设备。建议主要通过该参数过滤掉周边不需要处理的其他蓝牙设备
    @OpenAPIOptionalParam(jsonKey: "services")
    public var services: [String]?

    // 是否允许重复上报同一设备。如果允许重复上报，则 tt.onBlueToothDeviceFound 方法会多次上报同一设备，但是 RSSI 值会有不同
    @OpenAPIRequiredParam(userOptionWithJsonKey: "allowDuplicatesKey", defaultValue: false)
    public var allowDuplicatesKey: Bool

    //上报设备的间隔。0 表示找到新设备立即上报，其他数值根据传入的间隔上报。
    @OpenAPIRequiredParam(userOptionWithJsonKey: "interval", defaultValue: 0)
    public var interval: CGFloat

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_services, _allowDuplicatesKey, _interval]
    }

}

final class OpenAPIGetConnectedBluetoothDevicesParams: OpenAPIBaseParams {
    // 要搜索的蓝牙设备主 service 的 uuid 列表。某些蓝牙设备会广播自己的主 service 的 uuid。如果设置此参数，则只搜索广播包有对应 uuid 的主服务的蓝牙设备。建议主要通过该参数过滤掉周边不需要处理的其他蓝牙设备
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "services")
    public var services: [String]

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_services]
    }

}

class OpenAPIBLEDeviceParams: OpenAPIBaseParams {
    // 蓝牙设备 ID
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "deviceId", validChecker: {
        !$0.isEmpty
    })
    public var deviceID: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_deviceID]
    }
}

class OpenAPIBLEServiceParams: OpenAPIBLEDeviceParams {

    // 蓝牙特征值对应 service 的 UUID
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "serviceId", validChecker: {
        !$0.isEmpty
    })
    public var serviceID: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        var properties = super.autoCheckProperties
        properties.append(_serviceID)
        return properties
    }
}

class OpenAPIBLECharacteristicParams: OpenAPIBLEServiceParams {

    // 蓝牙特征值对应 service 的 UUID
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "characteristicId", validChecker: {
        !$0.isEmpty
    })
    public var characteristicID: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        var properties = super.autoCheckProperties
        properties.append(_characteristicID)
        return properties
    }
}

final class OpenAPIBLENotifyCharacteristicParams: OpenAPIBLECharacteristicParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "state", defaultValue: true)
    public var notify: Bool

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        var properties = super.autoCheckProperties
        properties.append(_notify)
        return properties
    }
}


final class OpenAPIBLEWriteCharacteristicParams: OpenAPIBLECharacteristicParams {

    // 蓝牙设备特征值对应的值，16 进制字符串，限制在 20 字节内
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "value", validChecker: {
        !$0.isEmpty
    })
    public var hexValue: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        var properties = super.autoCheckProperties
        properties.append(_hexValue)
        return properties
    }
}
