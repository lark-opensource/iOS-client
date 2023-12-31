//
//  OpenPluginBluetoothManager+ Delegate.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/25.
//

import Foundation
import CoreBluetooth
import LKCommonsLogging
import LarkOpenAPIModel
import LarkSetting
import LarkContainer

extension OpenPluginBluetoothManager: CBCentralManagerDelegate {

    // 系统蓝牙设备管理对象状态变化
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        trace.info("bluetooth: centralManagerDidUpdateState, \(central.state)")
        openAdapterCompletion?(central.adapterAvailable ? .ok : .notAvailable,
                               central.state.adapterFailState)
        openAdapterCompletion = nil
        
        if centerManager?.adapterAvailable == false, !userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api_bluetooth_powered_off_consistency.disable") {
            /// 对齐 Android 的实现，蓝牙开关关闭时
            /// 1. 将已连接的设备设置为 未连接，且发出 disConnected的通知
            /// 2. 清空已发现的设备
            clearAndNotifyDeviceForCBCentralManagerPoweredOff()
        }
        delegate?.bluetoothAdapterStateDidChange(available: central.adapterAvailable, central.isScanning)
    }

    /// 扫描到设备
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        trace.info("bluetooth: didDiscover, \(peripheral.identifier)")
        // 重复找到同一个设备时，避免被重复记录到发现的设备中
        let discoveredDevice: BluetoothDeviceModel
        
        if let model = devices[peripheral.identifier.uuidString] {
            model.update(with: peripheral, advertisementData: advertisementData, RSSI: RSSI)
            model.reported = config.reportImmediately
            discoveredDevice = model
        } else {
            discoveredDevice = BluetoothDeviceModel(with: peripheral, advertisementData: advertisementData, RSSI: RSSI, trace: trace)
            discoveredDevice.reported = config.reportImmediately
            devices[peripheral.identifier.uuidString] = discoveredDevice
        }

        if config.reportImmediately {
            // 上报
            trace.info("bluetooth: report peripheral discovered, \(peripheral.identifier)")
            delegate?.bluetoothDeviceDidFound(devices: [discoveredDevice])
        }
    }

    /// 连接到外围设备成功
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        trace.info("bluetooth: peripheral didConnect, \(peripheral.identifier)")
        if let device = devices[peripheral.identifier.uuidString] {
            device.connected = true
            device.deviceListener.connectCompletion?(.ok)
            device.deviceListener.connectCompletion = nil
        }

        // 对外告知连接状态的变化
        delegate?.bluetoothConnectionStateDidChange(deviceID: peripheral.identifier.uuidString, connected: true)
    }

    /// 外围设备断开连接
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        trace.info("bluetooth: didDisconnectPeripheral, \(peripheral.identifier), error: \(error)")
        if let device = devices[peripheral.identifier.uuidString] {
            device.connected = false
            device.deviceListener.disconnectCompletion?(.ok)
            device.deviceListener.disconnectCompletion = nil
        }
        // 对外告知连接状态的变化
        delegate?.bluetoothConnectionStateDidChange(deviceID: peripheral.identifier.uuidString, connected: false)
    }

    /// 连接到外围设备失败
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        trace.info("bluetooth: didFailToConnect peripheral=\(peripheral.identifier), error: \(error)")
        if let device = devices[peripheral.identifier.uuidString] {
            device.connected = false
            device.deviceListener.connectCompletion?(.connectionFail)
            device.deviceListener.connectCompletion = nil
        }
    }

}
