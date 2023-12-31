//
//  OpenBluetoothModel.swift
//  LarkOpenAPIModel
//
//  Created by lixiaorui on 2021/4/22.
//

import Foundation
import CoreBluetooth
import ECOProbe
import LarkSetting
import LarkOpenAPIModel

final class BluetoothPeripheralModel {
    /// 蓝牙设备名称
    public let name: String

    /// 用于区分设备的 id
    public let  deviceID: String

    public init(name: String, deviceID: String) {
        self.name = name
        self.deviceID = deviceID
    }

    public func toJSONDict() -> [AnyHashable : Any] {
        return ["name": name, "deviceId": deviceID]
    }
}

final class BluetoothDeviceCharacteristicModel {

    // 蓝牙设备特征值对应服务的 uuid
    public let characteristicID: String

    // 蓝牙设备特征值对应服务的 UUID
    public let serviceID: String

    // 蓝牙设备特征值对应的 16 进制值
    public let hexValue: String

    // 该特征值支持的操作类型
    public let operation: CBCharacteristicProperties

    public init(characteristicID: String, serviceID: String, hexValue: String, operation: CBCharacteristicProperties) {
        self.serviceID = serviceID
        self.characteristicID = characteristicID
        self.operation = operation
        self.hexValue = hexValue
    }

    public convenience init(characteristics: CBCharacteristic) {
        #if swift(>=5.5)
        let serviceID: String = characteristics.service?.uuid.realUUIDString ?? ""
        #else
        let serviceID: String = characteristics.service.uuid.realUUIDString
        #endif
        self.init(characteristicID: characteristics.uuid.realUUIDString,
                  serviceID: serviceID,
                  hexValue: characteristics.value?.characteristicsValueHexString ?? "",
                  operation: characteristics.properties)
    }

    public func toJSONDict() -> [AnyHashable: Any] {
        var result: [AnyHashable: Any] = ["serviceId": serviceID,
                                          "characteristicId": characteristicID,
                                          "value": hexValue]
        // TODOZJX
        if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.api_bluetooth_remove_property.disable") {
            result["properties"] = operation.operationDict
        }
        return result
    }

}


final class BLEDeviceServiceModel {

    // 蓝牙设备特征值对应服务的 uuid
    public let serviceID: String

    // 该服务是否为主服务
    public let primary: Bool

    public init(serviceID: String, primary: Bool) {
        self.serviceID = serviceID
        self.primary = primary
    }

    public func toJSONDict() -> [AnyHashable : Any] {
        return ["serviceId": serviceID,
                "isPrimary": primary]

    }

    public convenience init(service: CBService) {
        self.init(serviceID: service.uuid.realUUIDString, primary: service.isPrimary)
    }

}

final class BluetoothPeripheralListener {
    /// 当发现 Services 时会触发这个回调
    public var getServicesCompletion: ((_ errorCode: BluetoothErrorCode, _ services: [BLEDeviceServiceModel]) -> Void)?

    /// 当发现 Characteristics 时会触发这个回调
    public var getCharacteristicsCompletion: ((_ errorCode: BluetoothErrorCode, _ characteristics: [BluetoothDeviceCharacteristicModel]) -> Void)?

    /// 当开启/禁用特征的 notify 时会触发这个回调
    public var notifyCharacteristicCompletion: ((_ errorCode: BluetoothErrorCode) -> Void)?

    /// 读完特征值后会触发这个回调
    public var readCharacteristicValueCompletion: ((_ errorCode: BluetoothErrorCode, _ characteristic: CBCharacteristic) -> Void)?

    /// 写完这个特征值后会触发这个回调
    public var writeCharacteristicValueCompletion: ((_ errorCode: BluetoothErrorCode) -> Void)?

    /// 特征值变化后会触发这个回调
    public var characteristicValueChange: ((_ errorCode: BluetoothErrorCode, _ characteristic: CBCharacteristic) -> Void)?
}

final class BluetoothDeviceListener {
    /// 断开外围设备时，可以设置一个回调，断开成功或失败会调用这个 Block
    public var disconnectCompletion: ((_ errorCode: BluetoothErrorCode) -> Void)?

    /// 连接外围设备时，可以设置一个回调，连接成功或失败会调用这个 Block
    public var connectCompletion: ((_ errorCode: BluetoothErrorCode) -> Void)?
}


final class BluetoothDeviceModel: NSObject {
    /// baseInfo
    /// 相关联的外围设备
    public var peripheral: CBPeripheral

    /// 蓝牙设备名称，某些设备可能没有
    public var name: String = ""

    /// 用于区分设备的 id
    public let deviceID: String

    /// 当前蓝牙设备的信号强度
    public var RSSI: NSNumber = 0

    /// 当前蓝牙设备的广播数据段中的 ManufacturerData 数据段
    /// base64 string需要在jssdk转化为ArrayBuffer类型
    public var advertisData: String = ""

    /// 当前蓝牙设备的广播数据段中的 ServiceUUIDs 数据段
    public var advertisServiceUUIDs: [String] = []

    /// 当前蓝牙设备的广播数据段中的 LocalName 数据段
    public var localName: String = ""

    /// 当前蓝牙设备的广播数据段中的 ServiceData 数据段
    public var serviceData: [String : String] = [:]

    /// 内部状态
    /// 是否已上报
    public var reported: Bool = false

    /// 是否已连接
    public var connected: Bool = false

    /// 系统连接停止广播的设备
    public var retrieveConnected: Bool = false

    /// 外部监听
    public var peripheralListener = BluetoothPeripheralListener()

    public var deviceListener = BluetoothDeviceListener()

    /// 工具
    /// 诊断日志trace
    private let trace: OPTrace



    public init(with peripheral: CBPeripheral, advertisementData: [AnyHashable: Any], RSSI: NSNumber, trace: OPTrace) {
        self.peripheral = peripheral
        self.deviceID = peripheral.identifier.uuidString
        self.trace = trace
        super.init()
        self.update(with: peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }

    public func update(with peripheral: CBPeripheral, advertisementData: [AnyHashable: Any], RSSI: NSNumber) {
        guard peripheral.identifier.uuidString == deviceID else {
            trace.warn("can not update devie model \(deviceID) with \(peripheral.identifier.uuidString)")
            return
        }
        peripheral.delegate = self
        self.peripheral = peripheral
        self.name = peripheral.name ?? ""
        self.RSSI = RSSI
        if !advertisementData.isEmpty {
            self.retrieveConnected = false
        }
        if let advertisData = (advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            self.advertisData = advertisData
        }

        if let uuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map({ $0.uuidString }) {
            advertisServiceUUIDs = uuids
        }

        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            self.localName = localName
        }

        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            var data: [String: String] = [:]
            serviceData.forEach({
              data[$0.key.uuidString] = $0.value.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            })
            self.serviceData = data
        }
    }

    public func toJSONDict() -> [AnyHashable : Any] {
        return ["name": name,
                "deviceId": deviceID,
                "RSSI": RSSI,
                "advertisData": advertisData,
                "advertisServiceUUIDs": advertisServiceUUIDs,
                "localName": localName,
                "serviceData": serviceData]
    }
}

extension BluetoothDeviceModel: CBPeripheralDelegate {

    /// 外围设备发现了 Services 后，会调用这个方法，但当设备的 Service 发生变化时不会调用该方法
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        trace.info("peripheral \(peripheral.identifier) didDiscoverServices, error \(error)")
        peripheralListener.getServicesCompletion?(error == nil ? .ok : .systemError,
                                                  peripheral.services?.map({ BLEDeviceServiceModel(service: $0) }) ?? [])
        peripheralListener.getServicesCompletion = nil
    }

    /// 当 Service 的特征值发现完毕时，会调用这个方法
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        trace.info("peripheral \(peripheral.identifier) didDiscoverCharacteristicsFor service \(service.uuid.uuidString), error \(error)")
        peripheralListener.getCharacteristicsCompletion?(error == nil ? .ok : .systemError,
                                                         service.characteristics?.map({
                                                                                        BluetoothDeviceCharacteristicModel(characteristics: $0) }) ?? [])
        peripheralListener.getCharacteristicsCompletion = nil
    }

    /// 当调用 `setNotifyValue:forCharacteristic:` 后，会触发这个 Delegate 的方法
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        trace.info("peripheral \(peripheral.identifier) didUpdateNotificationStateFor characteristic \(characteristic.uuid.uuidString), error \(error)")
        peripheralListener.notifyCharacteristicCompletion?(error == nil ? .ok : .systemError)
        peripheralListener.notifyCharacteristicCompletion = nil
    }

    /// 这个 Delegate 方法有一定的误导性，并不是在写入特征值后会调用这个方法，而是「读取」完成后调用 `readValueForCharacteristic:`
    /// 如果设置过 ` setNotifyValue:forCharacteristic:` ，那么当特征值更新时，也会走这个方法
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        trace.info("peripheral \(peripheral.identifier) didUpdateValueFor characteristic \(characteristic.uuid.uuidString), error \(error)")
        let result: BluetoothErrorCode = error == nil ? .ok : .systemError
        peripheralListener.readCharacteristicValueCompletion?(result, characteristic)
        peripheralListener.readCharacteristicValueCompletion = nil

        peripheralListener.characteristicValueChange?(result, characteristic)
    }

    /// 向 Characteristic 写数据后，回触发这个回调
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        trace.info("peripheral \(peripheral.identifier) didWriteValueFor characteristic \(characteristic.uuid.uuidString), error \(error)")
        peripheralListener.writeCharacteristicValueCompletion?(error == nil ? .ok : .systemError)
        peripheralListener.readCharacteristicValueCompletion = nil
    }
}

fileprivate extension CBCharacteristicProperties {
    var operationDict: [String: Bool] {
        return ["read": self.contains(.read),
                "write": self.contains(.write),
                "notify": self.contains(.notify),
                "isIndicate": self.contains(.indicate),
                "indicate": self.contains(.indicate),
        ]
    }
}

extension CBUUID {
    var realUUIDString: String {
        /// 后面的 -0000-1000-8000-00805F9B34FB 是固定值：Bluetooth_Base_UUID
        if (uuidString.count == 4) {
            return "0000\(uuidString)-0000-1000-8000-00805F9B34FB"
        }
        if (uuidString.count == 8) {
            return "\(uuidString)-0000-1000-8000-00805F9B34FB"
        }
        return uuidString
    }
}

/**
 *  将NSData数据转换成十六进制字符串
 *
 *  @return 转换后的字符串
 */
extension Data {
    var characteristicsValueHexString: String {
        return map { String(format: "%02lx", $0) }.joined()
    }
}

