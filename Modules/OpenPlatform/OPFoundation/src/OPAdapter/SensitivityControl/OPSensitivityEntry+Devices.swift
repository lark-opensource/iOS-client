//
//  OPGeocoderEntry.swift
//  OPFoundation
//
//  Created by xudongzhang on 2022/11/16.
//

import CoreBluetooth
import CoreLocation
import CoreMotion
import Foundation
import LarkSensitivityControl
import LocalAuthentication
import NetworkExtension
import SystemConfiguration

// MARK: - CLGeocoder

public extension OPSensitivityEntry {
    static func reverseGeocodeLocation(forToken token: OPSensitivityEntryToken,
                                       geocoder: CLGeocoder,
                                       location: CLLocation,
                                       completionHandler: @escaping CLGeocodeCompletionHandler) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.reverseGeocodeLocation(forToken: token.psdaToken,
                                                       geocoder: geocoder,
                                                       userLocation: location,
                                                       completionHandler: completionHandler)
        } else {
            geocoder.reverseGeocodeLocation(location, completionHandler: completionHandler)
        }
    }
}

// MARK: - LAContext

public extension OPSensitivityEntry {
    static func evaluatePolicy(forToken token: OPSensitivityEntryToken,
                               laContext: LAContext,
                               policy: LAPolicy,
                               localizedReason: String,
                               reply: @escaping (Bool, Error?) -> Void) {
        if sensitivityControlEnable() {
            do {
                try DeviceInfoEntry.evaluatePolicy(forToken: token.psdaToken,
                                                   laContext: laContext,
                                                   policy: policy,
                                                   localizedReason: localizedReason,
                                                   reply: reply)
            } catch {
                reply(false, apiError(from: error))
            }
        } else {
            laContext.evaluatePolicy(policy, localizedReason: localizedReason, reply: reply)
        }
    }
}

// MARK: - Wifi

public extension OPSensitivityEntry {
    @available(iOS 14.0, *)
    static func fetchCurrent(forToken token: OPSensitivityEntryToken,
                             completionHandler: @escaping (NEHotspotNetwork?) -> Void) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.fetchCurrent(forToken: token.psdaToken, completionHandler: completionHandler)
        } else {
            NEHotspotNetwork.fetchCurrent(completionHandler: completionHandler)
        }
    }

    static func CNCopyCurrentNetworkInfo(forToken token: OPSensitivityEntryToken,
                                         interfaceName: CFString) throws -> CFDictionary? {
        if sensitivityControlEnable() {
            return try DeviceInfoEntry.CNCopyCurrentNetworkInfo(forToken: token.psdaToken, interfaceName)
        } else {
            return SystemConfiguration.CNCopyCurrentNetworkInfo(interfaceName)
        }
    }

    static func getifaddrs(forToken token: OPSensitivityEntryToken, ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!) throws -> Int32 {
        if sensitivityControlEnable() {
            return try DeviceInfoEntry.getifaddrs(forToken: token.psdaToken, ifad)
        } else {
            return Darwin.getifaddrs(ifad)
        }
    }

    /// getifaddrs for OC
    @objc class func getifaddrs(forToken token: OPSensitivityEntryToken, ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!, err: UnsafeMutablePointer<NSError?>?) -> Int32 {
        if sensitivityControlEnable() {
            return DeviceInfoEntry.getifaddrs(forToken: token.psdaToken, ifad, err: err)
        } else {
            return Darwin.getifaddrs(ifad)
        }
    }
}

// MARK: - CoreBluetooth

public extension OPSensitivityEntry {
    static func scanForPeripherals(forToken token: OPSensitivityEntryToken,
                                   centralManager: CBCentralManager,
                                   withServices serviceUUIDs: [CBUUID]?,
                                   options: [String: Any]? = nil) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.scanForPeripherals(forToken: token.psdaToken, manager: centralManager, withServices: serviceUUIDs, options: options)
        } else {
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        }
    }

    static func connect(forToken token: OPSensitivityEntryToken,
                        centralManager: CBCentralManager,
                        peripheral: CBPeripheral,
                        options: [String: Any]? = nil) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.connect(forToken: token.psdaToken, manager: centralManager, peripheral, options: options)
        } else {
            centralManager.connect(peripheral, options: options)
        }
    }

    static func discoverServices(forToken token: OPSensitivityEntryToken, peripheral: CBPeripheral, _ serviceUUIDs: [CBUUID]?) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.discoverServices(forToken: token.psdaToken, peripheral: peripheral, serviceUUIDs)
        } else {
            peripheral.discoverServices(serviceUUIDs)
        }
    }

    static func discoverCharacteristics(forToken token: OPSensitivityEntryToken, peripheral: CBPeripheral, _ characteristicUUIDs: [CBUUID]?, for service: CBService) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.discoverCharacteristics(forToken: token.psdaToken, peripheral: peripheral, characteristicUUIDs, for: service)
        } else {
            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }

    /// CBPeripheral readValueForCharacteristic
    static func readValue(forToken token: OPSensitivityEntryToken, peripheral: CBPeripheral, for characteristic: CBCharacteristic) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.readValue(forToken: token.psdaToken, peripheral: peripheral, for: characteristic)
        } else {
            peripheral.readValue(for: characteristic)
        }
    }

    /// CBPeripheral writeValueForCharacteristic
    static func writeValue(forToken token: OPSensitivityEntryToken, peripheral: CBPeripheral, _ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.writeValue(forToken: token.psdaToken, peripheral: peripheral, data, for: characteristic, type: type)
        } else {
            peripheral.writeValue(data, for: characteristic, type: type)
        }
    }
}

public extension OPSensitivityEntry {
    static func startDeviceMotionUpdates(forToken token: OPSensitivityEntryToken, manager: CMMotionManager, to queue: OperationQueue, withHandler handler: @escaping CMDeviceMotionHandler) throws {
        if sensitivityControlEnable() {
            try DeviceInfoEntry.startDeviceMotionUpdates(forToken: token.psdaToken, manager: manager, to: queue, withHandler: handler)
        } else {
            manager.startDeviceMotionUpdates(to: queue, withHandler: handler)
        }
    }
}
