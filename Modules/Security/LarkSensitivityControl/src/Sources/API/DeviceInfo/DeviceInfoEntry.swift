//
//  DeviceInfoEntry.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit
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

/// DeviceInfo
@objc
final public class DeviceInfoEntry: NSObject {
    private static func getService() -> DeviceInfoApi.Type {
        if let service = LSC.getService(forTag: tag) as? DeviceInfoApi.Type {
            return service
        }
        return DeviceInfoWrapper.self
    }
}

/// Network & Wifi & IP
extension DeviceInfoEntry: DeviceInfoApi {

    /// NEHotspotNetwork fetchCurrent
    @available(iOS, introduced: 14.0)
    public static func fetchCurrent(forToken token: Token,
                                    completionHandler: @escaping (NEHotspotNetwork?) -> Void) throws {
        let context = Context([AtomicInfo.DeviceInfo.fetchCurrent.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().fetchCurrent(forToken: token, completionHandler: completionHandler)
    }

    /// CNCopyCurrentNetworkInfo
    @available(iOS, introduced: 4.1, deprecated: 100000)
    public static func CNCopyCurrentNetworkInfo(forToken token: Token,
                                                _ interfaceName: CFString) throws -> CFDictionary? {
        let context = Context([AtomicInfo.DeviceInfo.CNCopyCurrentNetworkInfo.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().CNCopyCurrentNetworkInfo(forToken: token, interfaceName)
    }

    /// getifaddrs
    public static func getifaddrs(forToken token: Token,
                                  _ ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!) throws -> Int32 {
        let context = Context([AtomicInfo.DeviceInfo.getifaddrs.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().getifaddrs(forToken: token, ifad)
    }

    /// NEHotspotNetwork ssid
    public static func ssid(forToken token: Token, net: NEHotspotNetwork) throws -> String {
        let context = Context([AtomicInfo.DeviceInfo.ssid.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().ssid(forToken: token, net: net)
    }

    /// NEHotspotNetwork bssid
    public static func bssid(forToken token: Token, net: NEHotspotNetwork) throws -> String {
        let context = Context([AtomicInfo.DeviceInfo.bssid.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().bssid(forToken: token, net: net)
    }
}

// MARK: - For Objective-C Interface

extension DeviceInfoEntry {

    /// CNCopyCurrentNetworkInfo for OC
    @objc
    @available(iOS, introduced: 4.1, deprecated: 100000)
    public static func CNCopyCurrentNetworkInfo(forToken token: Token,
                                                _ interfaceName: CFString,
                                                err: UnsafeMutablePointer<NSError?>?) -> CFDictionary? {
        do {
            return try CNCopyCurrentNetworkInfo(forToken: token, interfaceName)
        } catch {
            err?.pointee = error as NSError
        }
        return nil
    }

    /// getifaddrs for OC
    @objc
    public static func getifaddrs(forToken token: Token,
                                  _ ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!,
                                  err: UnsafeMutablePointer<NSError?>?) -> Int32 {
        do {
            return try getifaddrs(forToken: token, ifad)
        } catch {
            err?.pointee = error as NSError
        }
        return -1
    }
}

/// UIView
extension DeviceInfoEntry {

    /// UIView drawHierarchy
    public static func drawHierarchy(forToken token: Token,
                                     view: UIView,
                                     rect: CGRect,
                                     afterScreenUpdates afterUpdates: Bool) throws -> Bool {
        let context = Context([AtomicInfo.DeviceInfo.drawHierarchy.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().drawHierarchy(forToken: token, view: view, rect: rect, afterScreenUpdates: afterUpdates)
    }

    /// RPSystemBroadcastPickerView initWithFrame
    @available(iOS, introduced: 12.0)
    public static func createRPSystemBroadcastPickerViewWithFrame(forToken token: Token,
                                                                  frame: CGRect) throws -> RPSystemBroadcastPickerView {
        let context = Context([AtomicInfo.DeviceInfo.RPSystemBroadcastPickerViewInit.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().createRPSystemBroadcastPickerViewWithFrame(forToken: token, frame: frame)
    }
}

/// Location
extension DeviceInfoEntry {

    /// CLGeocoder reverseGeocodeLocation
    public static func reverseGeocodeLocation(forToken token: Token,
                                              geocoder: CLGeocoder,
                                              userLocation: CLLocation,
                                              completionHandler: @escaping CLGeocodeCompletionHandler) throws {
        let context = Context([AtomicInfo.DeviceInfo.reverseGeocodeLocation.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().reverseGeocodeLocation(forToken: token, geocoder: geocoder,
                                                userLocation: userLocation, completionHandler: completionHandler)
    }
}

#if canImport(CoreTelephony)
/// Call
extension DeviceInfoEntry {

    /// CTCallCenter currentCalls
    @available(iOS, introduced: 4.0, deprecated: 10.0)
    public static func currentCalls(forToken token: Token,
                                    callCenter: CTCallCenter) throws -> Set<CTCall>? {
        let context = Context([AtomicInfo.DeviceInfo.currentCalls.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().currentCalls(forToken: token, callCenter: callCenter)
    }
}
#endif

/// BiologyInfo
extension DeviceInfoEntry {

    /// LAContext evaluatePolicy
    public static func evaluatePolicy(forToken token: Token,
                                      laContext: LAContext,
                                      policy: LAPolicy,
                                      localizedReason: String,
                                      reply: @escaping (Bool, Error?) -> Void) throws {
        let context = Context([AtomicInfo.DeviceInfo.evaluatePolicy.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().evaluatePolicy(forToken: token, laContext: laContext,
                                        policy: policy, localizedReason: localizedReason, reply: reply)
    }
}

/// Proximity Monitor
extension DeviceInfoEntry {

    /// UIDevice isProximityMonitoringEnabled
    public static func isProximityMonitoringEnabled(forToken token: Token,
                                                    device: UIDevice) throws -> Bool {
        let context = Context([AtomicInfo.DeviceInfo.isProximityMonitoringEnabled.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().isProximityMonitoringEnabled(forToken: token, device: device)
    }

    /// UIDevice proximityState
    public static func proximityState(forToken token: Token,
                                      device: UIDevice) throws -> Bool {
        let context = Context([AtomicInfo.DeviceInfo.proximityState.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().proximityState(forToken: token, device: device)
    }

    /// UIDevice setProximityMonitoringEnabled
    public static func setProximityMonitoringEnabled(forToken token: Token,
                                                     device: UIDevice,
                                                     isEnabled: Bool) throws {
        let context = Context([AtomicInfo.DeviceInfo.setProximityMonitoringEnabled.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setProximityMonitoringEnabled(forToken: token, device: device, isEnabled: isEnabled)
    }
}

/// Sensor
extension DeviceInfoEntry {
    /// CMMotionManager startDeviceMotionUpdatesToQueue
    @objc
    public static func startDeviceMotionUpdates(forToken token: Token,
                                                manager: CMMotionManager,
                                                to queue: OperationQueue,
                                                withHandler handler: @escaping CMDeviceMotionHandler) throws {
        let context = Context([AtomicInfo.DeviceInfo.startDeviceMotionUpdatesToQueue.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startDeviceMotionUpdates(forToken: token, manager: manager, to: queue, withHandler: handler)
    }

    /// CMMotionManager startAccelerometerUpdatesToQueue
    public static func startAccelerometerUpdates(forToken token: Token,
                                                 manager: CMMotionManager,
                                                 to queue: OperationQueue,
                                                 withHandler handler: @escaping CMAccelerometerHandler) throws {
        let context = Context([AtomicInfo.DeviceInfo.startAccelerometerUpdatesToQueue.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startAccelerometerUpdates(forToken: token, manager: manager, to: queue, withHandler: handler)
    }

    #if !os(visionOS)
    /// CMPedometer queryPedometerData
    public static func queryPedometerData(forToken token: Token,
                                          pedometer: CMPedometer,
                                          from start: Date,
                                          to end: Date,
                                          withHandler handler: @escaping CMPedometerHandler) throws {
        let context = Context([AtomicInfo.DeviceInfo.queryPedometerData.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().queryPedometerData(forToken: token, pedometer: pedometer, from: start, to: end, withHandler: handler)
    }
    #endif
}

/// Bluetooth
extension DeviceInfoEntry {
    /// CBCentralManager scanForPeripherals
    @objc
    public static func scanForPeripherals(forToken token: Token,
                                          manager: CBCentralManager,
                                          withServices serviceUUIDs: [CBUUID]?,
                                          options: [String: Any]? = nil) throws {
        let context = Context([AtomicInfo.DeviceInfo.scanForPeripherals.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().scanForPeripherals(forToken: token, manager: manager,
                                            withServices: serviceUUIDs, options: options)
    }

    /// CBCentralManager connectPeripheral
    public static func connect(forToken token: Token,
                               manager: CBCentralManager,
                               _ peripheral: CBPeripheral,
                               options: [String: Any]? = nil) throws {
        let context = Context([AtomicInfo.DeviceInfo.connect.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().connect(forToken: token, manager: manager, peripheral, options: options)
    }

    /// CBPeripheral discoverServices
    public static func discoverServices(forToken token: Token,
                                        peripheral: CBPeripheral,
                                        _ serviceUUIDs: [CBUUID]?) throws {
        let context = Context([AtomicInfo.DeviceInfo.discoverServices.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().discoverServices(forToken: token, peripheral: peripheral, serviceUUIDs)
    }

    /// CBPeripheral discoverCharacteristics
    public static func discoverCharacteristics(forToken token: Token,
                                               peripheral: CBPeripheral,
                                               _ characteristicUUIDs: [CBUUID]?,
                                               for service: CBService) throws {
        let context = Context([AtomicInfo.DeviceInfo.discoverCharacteristics.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().discoverCharacteristics(forToken: token, peripheral: peripheral,
                                                 characteristicUUIDs, for: service)
    }

    /// CBPeripheral readValueForCharacteristic
    public static func readValue(forToken token: Token,
                                 peripheral: CBPeripheral,
                                 for characteristic: CBCharacteristic) throws {
        let context = Context([AtomicInfo.DeviceInfo.readValueForCharacteristic.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().readValue(forToken: token, peripheral: peripheral, for: characteristic)
    }

    /// CBPeripheral writeValueForCharacteristic
    public static func writeValue(forToken token: Token,
                                  peripheral: CBPeripheral,
                                  _ data: Data,
                                  for characteristic: CBCharacteristic,
                                  type: CBCharacteristicWriteType) throws {
        let context = Context([AtomicInfo.DeviceInfo.writeValue.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().writeValue(forToken: token, peripheral: peripheral, data, for: characteristic, type: type)
    }

    /// CBPeripheralManager startAdvertising
    @objc
    public static func startAdvertising(forToken token: Token,
                                        manager: CBPeripheralManager,
                                        advertisementData: [String: Any]?) throws {
        let context = Context([AtomicInfo.DeviceInfo.startAdvertising.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startAdvertising(forToken: token, manager: manager, advertisementData: advertisementData)
    }
}

/// deviceID
extension DeviceInfoEntry {

    /// UIDevice name
    @objc
    public static func getDeviceName(forToken token: Token,
                                     device: UIDevice) throws -> String {
        let context = Context([AtomicInfo.DeviceInfo.getDeviceName.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().getDeviceName(forToken: token, device: device)
    }
}
