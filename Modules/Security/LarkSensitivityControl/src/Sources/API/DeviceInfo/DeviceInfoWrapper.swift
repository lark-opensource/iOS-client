//
//  DeviceInfoWrapper.swift
//  LarkSensitivityControl
//
//  Created by yangyigfan on 2023/3/7.
//

import SystemConfiguration.CaptiveNetwork
import NetworkExtension
#if canImport(CoreTelephony)
import CoreTelephony
#endif
import LocalAuthentication
import CoreLocation
import CoreMotion
import CoreBluetooth
import ReplayKit

final class DeviceInfoWrapper: NSObject, DeviceInfoApi {
    /// NEHotspotNetwork fetchCurrent
    @available(iOS, introduced: 14.0)
    static func fetchCurrent(forToken token: Token,
                             completionHandler: @escaping (NEHotspotNetwork?) -> Void) throws {
        NEHotspotNetwork.fetchCurrent(completionHandler: completionHandler)
    }

    /// CNCopyCurrentNetworkInfo
    @available(iOS, introduced: 4.1, deprecated: 100000)
    static func CNCopyCurrentNetworkInfo(forToken token: Token,
                                         _ interfaceName: CFString) throws -> CFDictionary? {
        return SystemConfiguration.CNCopyCurrentNetworkInfo(interfaceName)
    }

    /// getifaddrs
    static func getifaddrs(forToken token: Token,
                           _ ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!) throws -> Int32 {
        return Darwin.getifaddrs(ifad)
    }

    /// UIView drawHierarchy
    static func drawHierarchy(forToken token: Token,
                              view: UIView,
                              rect: CGRect,
                              afterScreenUpdates afterUpdates: Bool) throws -> Bool {
        return view.drawHierarchy(in: rect, afterScreenUpdates: afterUpdates)
    }

    /// RPSystemBroadcastPickerView initWithFrame
    @available(iOS, introduced: 12.0)
    static func createRPSystemBroadcastPickerViewWithFrame(forToken token: Token, frame: CGRect) throws -> RPSystemBroadcastPickerView {
        return RPSystemBroadcastPickerView(frame: frame)
    }

    /// CLGeocoder reverseGeocodeLocation
    static func reverseGeocodeLocation(forToken token: Token,
                                       geocoder: CLGeocoder,
                                       userLocation: CLLocation,
                                       completionHandler: @escaping CLGeocodeCompletionHandler) throws {
        geocoder.reverseGeocodeLocation(userLocation, completionHandler: completionHandler)
    }

    #if canImport(CoreTelephony)
    /// CTCallCenter currentCalls
    @available(iOS, introduced: 4.0, deprecated: 10.0)
    static func currentCalls(forToken token: Token,
                             callCenter: CTCallCenter) throws -> Set<CTCall>? {
        return callCenter.currentCalls
    }
    #endif

    /// LAContext evaluatePolicy
    static func evaluatePolicy(forToken token: Token,
                               laContext: LAContext,
                               policy: LAPolicy,
                               localizedReason: String,
                               reply: @escaping (Bool, Error?) -> Void) throws {
        laContext.evaluatePolicy(policy, localizedReason: localizedReason, reply: reply)
    }

    /// UIDevice isProximityMonitoringEnabled
    static func isProximityMonitoringEnabled(forToken token: Token,
                                             device: UIDevice) throws -> Bool {
        return device.isProximityMonitoringEnabled
    }

    /// UIDevice proximityState
    static func proximityState(forToken token: Token,
                               device: UIDevice) throws -> Bool {
        return device.proximityState
    }

    /// UIDevice setProximityMonitoringEnabled
    static func setProximityMonitoringEnabled(forToken token: Token,
                                              device: UIDevice,
                                              isEnabled: Bool) throws {
        device.isProximityMonitoringEnabled = isEnabled
    }

    /// CMMotionManager startDeviceMotionUpdatesToQueue
    static func startDeviceMotionUpdates(forToken token: Token,
                                         manager: CMMotionManager,
                                         to queue: OperationQueue,
                                         withHandler handler: @escaping CMDeviceMotionHandler) throws {
        manager.startDeviceMotionUpdates(to: queue, withHandler: handler)
    }

    /// CMMotionManager startAccelerometerUpdatesToQueue
    static func startAccelerometerUpdates(forToken token: Token,
                                          manager: CMMotionManager,
                                          to queue: OperationQueue,
                                          withHandler handler: @escaping CMAccelerometerHandler) throws {
        manager.startAccelerometerUpdates(to: queue, withHandler: handler)
    }

    /// CBCentralManager scanForPeripherals
    static func scanForPeripherals(forToken token: Token,
                                   manager: CBCentralManager,
                                   withServices serviceUUIDs: [CBUUID]?,
                                   options: [String: Any]? = nil) throws {
        manager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }

    /// CBCentralManager connectPeripheral
    static func connect(forToken token: Token,
                        manager: CBCentralManager,
                        _ peripheral: CBPeripheral,
                        options: [String: Any]? = nil) throws {
        manager.connect(peripheral, options: options)
    }

    /// CBPeripheral discoverServices
    static func discoverServices(forToken token: Token,
                                 peripheral: CBPeripheral,
                                 _ serviceUUIDs: [CBUUID]?) throws {
        peripheral.discoverServices(serviceUUIDs)
    }

    /// CBPeripheral discoverCharacteristics
    static func discoverCharacteristics(forToken token: Token,
                                        peripheral: CBPeripheral,
                                        _ characteristicUUIDs: [CBUUID]?,
                                        for service: CBService) throws {
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }

    /// CBPeripheral readValueForCharacteristic
    static func readValue(forToken token: Token,
                          peripheral: CBPeripheral,
                          for characteristic: CBCharacteristic) throws {
        peripheral.readValue(for: characteristic)
    }

    /// CBPeripheral writeValueForCharacteristic
    static func writeValue(forToken token: Token,
                           peripheral: CBPeripheral,
                           _ data: Data,
                           for characteristic: CBCharacteristic,
                           type: CBCharacteristicWriteType) throws {
        peripheral.writeValue(data, for: characteristic, type: type)
    }

    /// CBPeripheralManager startAdvertising
    static func startAdvertising(forToken token: Token,
                                 manager: CBPeripheralManager,
                                 advertisementData: [String: Any]?) throws {
        manager.startAdvertising(advertisementData)
    }

    /// UIDevice name
    static func getDeviceName(forToken token: Token, device: UIDevice) throws -> String {
        return device.name
    }

    /// NEHotspotNetwork ssid
    static func ssid(forToken token: Token, net: NEHotspotNetwork) throws -> String {
        return net.ssid
    }

    /// NEHotspotNetwork bssid
    static func bssid(forToken token: Token, net: NEHotspotNetwork) throws -> String {
        return net.bssid
    }

    #if !os(visionOS)
    /// CMPedometer queryPedometerData
    static func queryPedometerData(forToken token: Token,
                                   pedometer: CMPedometer,
                                   from start: Date,
                                   to end: Date,
                                   withHandler handler: @escaping CMPedometerHandler) throws {
        pedometer.queryPedometerData(from: start, to: end, withHandler: handler)
    }
    #endif
}
