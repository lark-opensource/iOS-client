//
//  OpenBluetoothResult.swift
//  LarkOpenAPIModel
//
//  Created by lixiaorui on 2021/4/26.
//

import Foundation
import CoreBluetooth
import LarkOpenAPIModel

final class OpenAPIBluetoothPeripheralsResult: OpenAPIBaseResult {

    let peripherals: [BluetoothPeripheralModel]

    public init(peripherals: [BluetoothPeripheralModel]) {
        self.peripherals = peripherals
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["devices": peripherals.map({ $0.toJSONDict() })]
    }
}

final class OpenAPIBluetoothDevicesResult: OpenAPIBaseResult {

    let devices: [BluetoothDeviceModel]

    public init(devices: [BluetoothDeviceModel]) {
        self.devices = devices
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["devices": devices.map({ $0.toJSONDict() })]
    }
}

final class OpenAPIBluetoothAdapterStateResult: OpenAPIBaseResult {

    // 是否正在扫描设备
    public let isDiscovering: Bool
    // 蓝牙适配器是否可用
    public let available: Bool

    public init(available: Bool, isDiscovering: Bool) {
        self.available = available
        self.isDiscovering = isDiscovering
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["available": available, "discovering": isDiscovering]
    }
}

final class OpenAPIBLEDeviceServicesResult: OpenAPIBaseResult {
    // 已发现的设备服务列表。
    public let services: [BLEDeviceServiceModel]

    public init(services: [BLEDeviceServiceModel]) {
        self.services = services
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["services": services.map({ $0.toJSONDict() })]
    }
}

final class OpenAPIBLEDeviceCharacteristicsResult: OpenAPIBaseResult {

    let characteristics: [BluetoothDeviceCharacteristicModel]

    public init(characteristics: [BluetoothDeviceCharacteristicModel]) {
        self.characteristics = characteristics
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["characteristics": characteristics.map({ $0.toJSONDict() })]
    }
}

final class OpenAPIBLEDeviceCharacteristicResult: OpenAPIBaseResult {

    let characteristic: BluetoothDeviceCharacteristicModel

    public init(characteristic: BluetoothDeviceCharacteristicModel) {
        self.characteristic = characteristic
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["characteristic": characteristic.toJSONDict()]
    }
}
