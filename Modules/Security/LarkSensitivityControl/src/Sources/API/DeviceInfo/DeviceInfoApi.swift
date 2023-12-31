//
//  DeviceInfoApi.swift
//  LarkSensitivityControl
//
//  Created by yangyigfan on 2023/3/7.
//

import NetworkExtension
import CoreLocation
#if canImport(CoreTelephony)
import CoreTelephony
#endif
import LocalAuthentication
import CoreMotion
import CoreBluetooth
import ReplayKit

public extension DeviceInfoApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "deviceInfo"
    }
}

/// deviceInfo相关方法
public protocol DeviceInfoApi: SensitiveApi {

    @available(iOS, introduced: 14.0)
    static func fetchCurrent(forToken token: Token, completionHandler: @escaping (NEHotspotNetwork?) -> Void) throws

    static func CNCopyCurrentNetworkInfo(forToken token: Token, _ interfaceName: CFString) throws -> CFDictionary?

    static func getifaddrs(forToken token: Token,
                           _ ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!) throws -> Int32

    static func drawHierarchy(forToken token: Token, view: UIView, rect: CGRect,
                              afterScreenUpdates afterUpdates: Bool) throws -> Bool

    @available(iOS, introduced: 12.0)
    static func createRPSystemBroadcastPickerViewWithFrame(forToken token: Token, frame: CGRect) throws -> RPSystemBroadcastPickerView

    static func reverseGeocodeLocation(forToken token: Token, geocoder: CLGeocoder, userLocation: CLLocation,
                                       completionHandler: @escaping CLGeocodeCompletionHandler) throws

    #if canImport(CoreTelephony)
    @available(iOS, introduced: 4.0, deprecated: 10.0)
    static func currentCalls(forToken token: Token,
                             callCenter: CTCallCenter) throws -> Set<CTCall>?
    #endif

    static func evaluatePolicy(forToken token: Token, laContext: LAContext, policy: LAPolicy, localizedReason: String,
                               reply: @escaping (Bool, Error?) -> Void) throws

    static func isProximityMonitoringEnabled(forToken token: Token, device: UIDevice) throws -> Bool

    static func proximityState(forToken token: Token, device: UIDevice) throws -> Bool

    static func setProximityMonitoringEnabled(forToken token: Token, device: UIDevice, isEnabled: Bool) throws

    static func startDeviceMotionUpdates(forToken token: Token, manager: CMMotionManager, to queue: OperationQueue,
                                         withHandler handler: @escaping CMDeviceMotionHandler) throws

    static func startAccelerometerUpdates(forToken token: Token, manager: CMMotionManager, to queue: OperationQueue,
                                          withHandler handler: @escaping CMAccelerometerHandler) throws

    static func scanForPeripherals(forToken token: Token, manager: CBCentralManager,
                                   withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) throws

    static func connect(forToken token: Token, manager: CBCentralManager, _ peripheral: CBPeripheral,
                        options: [String: Any]?) throws

    static func discoverServices(forToken token: Token, peripheral: CBPeripheral, _ serviceUUIDs: [CBUUID]?) throws

    static func discoverCharacteristics(forToken token: Token, peripheral: CBPeripheral,
                                        _ characteristicUUIDs: [CBUUID]?, for service: CBService) throws

    static func readValue(forToken token: Token, peripheral: CBPeripheral, for characteristic: CBCharacteristic) throws

    static func writeValue(forToken token: Token, peripheral: CBPeripheral, _ data: Data,
                           for characteristic: CBCharacteristic,
                           type: CBCharacteristicWriteType) throws

    static func startAdvertising(forToken token: Token,
                                 manager: CBPeripheralManager,
                                 advertisementData: [String: Any]?) throws

    static func getDeviceName(forToken token: Token, device: UIDevice) throws -> String

    /// NEHotspotNetwork ssid
    static func ssid(forToken token: Token, net: NEHotspotNetwork) throws -> String

    /// NEHotspotNetwork bssid
    static func bssid(forToken token: Token, net: NEHotspotNetwork) throws -> String

    #if !os(visionOS)
    /// CMPedometer queryPedometerData
    static func queryPedometerData(forToken token: Token,
                                   pedometer: CMPedometer,
                                   from start: Date,
                                   to end: Date,
                                   withHandler handler: @escaping CMPedometerHandler) throws
    #endif
}
