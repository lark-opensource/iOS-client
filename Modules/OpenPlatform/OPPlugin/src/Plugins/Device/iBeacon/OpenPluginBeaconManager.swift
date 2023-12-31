//
//  OpenPluginiBeacon.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/1.
//  iBeacon 相关API

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import CoreLocation
import CoreBluetooth
import LKCommonsLogging
import ECOProbe
import ECOInfra
import LarkCoreLocation
import LarkContainer
import OPFoundation

public typealias OPBeaconCompletionBlock = (_ error: OpenAPIError?) -> Void
public typealias OPBeaconUpdateBlock = (_ iBeaconDatas: [CLBeacon]) -> Void
public typealias OPBeaconServiceChangeBlock = (_ available: Bool, _ discovering: Bool) -> Void

public typealias OPBeaconGetBLEStateBlock = (_ available: Bool) -> Void
public typealias OPBeaconLocationAuthorizeBlock = (_ authorization: Bool)-> Void

@objcMembers
final class OpenPluginBeaconManager: NSObject {
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.pausesLocationUpdatesAutomatically = false
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        return manager
    }()

    /// 定位权限相关
    @InjectedSafeLazy var locationAuth: LocationAuthorization // Global
    
    /// 系统蓝牙设备管理对象，可以把它理解为主设备，通过它可以去扫描和连接外设
    private var bluetoothManager: CBCentralManager?

    /// 是否已开启探测iBeacon设备
    private var hasStartedRangingBeacons = false

    /// iBeacon服务是否可用
    private var available = false {
        didSet {
            if available != oldValue {
                serviceChangeBlock?(available, discovering)
            }
        }
    }

    /// 当前discovering状态(注: 不是蓝牙的搜索状态)
    /// 当startBeaconDiscovery接口调用成功后, 该设为true;
    /// 当stopBeaconDiscovery调用成功后, 该值设为false
    private var discovering = false {
        didSet {
            if discovering != oldValue {
                serviceChangeBlock?(available, discovering)
            }
        }
    }

    /// 开始探测的regions
    private var startRegions = [CLBeaconRegion] ()

    /// 已经探测到过的iBeacon设备
    private var detectedBeaconMap = [String : CLBeacon]()

    /// 探测到新iBeacon设备的回调
    private var beaconUpdateBlock: OPBeaconUpdateBlock?

    /// 服务状态变化回调
    private var serviceChangeBlock: OPBeaconServiceChangeBlock?

    /// 获取蓝牙状态回调
    private var getBluetoothCompleteBlock: OPBeaconGetBLEStateBlock?

    /// 请求位置权限回调
    private var locationAuthorizeBlock: OPBeaconLocationAuthorizeBlock?

    let trace: OPTrace

    /// 开始搜索附近的 iBeacon 设备
    /// 该功能需要有定位权限和蓝牙权限
    /// - Parameters:
    ///   - uuids: 设备广播的uuid数组
    ///   - ignoreBluetoothAvailable: 是否忽略蓝牙能力
    ///   - serviceChangeCallback: iBeacon服务状态变化回调
    ///   - updateCallback: 设备更新回调
    ///   - completionCallback: 接口接调用结果回调
    public func startBeaconDiscovery(uuids: [UUID],
                                     ignoreBluetoothAvailable: Bool,
                                     serviceChangeCallback: @escaping OPBeaconServiceChangeBlock,
                                     beaconUpdateCallback: @escaping OPBeaconUpdateBlock,
                                     completionCallback: @escaping OPBeaconCompletionBlock) {
        trace.info("call startBeaconDiscovery, uuids count:\(uuids.count), ignoreBluetoothAvailable: \(ignoreBluetoothAvailable)")

        guard !uuids.isEmpty else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "uuids")))
            completionCallback(error)
            return
        }

        guard !hasStartedRangingBeacons else {
            let error = OpenAPIError(code: BeaconErrorCode.alreadyStart)
                .setErrno(OpenAPIBeaconErrno.alreadyStart)
            completionCallback(error)
            return
        }

        guard CLLocationManager.isRangingAvailable() else {
            let error = OpenAPIError(code: BeaconErrorCode.unsupport)
                .setErrno(OpenAPIBeaconErrno.nonsupport)
            completionCallback(error)
            return
        }

        requestAuthoriztion {[weak self] (authorize) in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage("self is nil When call API")
                completionCallback(error)
                return
            }

            guard authorize else {
                let error = OpenAPIError(code: BeaconErrorCode.locationUnavailable)
                    .setErrno(OpenAPIBeaconErrno.locationUnavailable)
                self.trace.error("location authorize fail")
                completionCallback(error)
                return
            }

            //是否需要忽略蓝牙状态
            if ignoreBluetoothAvailable {
                self.startBeaconDiscoveryHandler(uuids: uuids,
                                                 serviceChangeCallback: serviceChangeCallback,
                                                 beaconUpdateCallback: beaconUpdateCallback,
                                                 completionCallback: completionCallback)
                return
            }

            //检查蓝牙是否可用stopBeaconDiscovery
            self.getBluetoothState {(state) in
                guard state else {
                    let error = OpenAPIError(code: BeaconErrorCode.bluetoothUnavailable)
                        .setErrno(OpenAPIBeaconErrno.bluetoothUnavailable)
                    completionCallback(error)
                    return
                }

                self.startBeaconDiscoveryHandler(uuids: uuids,
                                                 serviceChangeCallback: serviceChangeCallback,
                                                 beaconUpdateCallback: beaconUpdateCallback,
                                                 completionCallback: completionCallback)
            }
        }

    }

    /// 停止搜索附近的 iBeacon 设备
    public func stopBeaconDiscovery(completionCallback: @escaping OPBeaconCompletionBlock) {
        guard hasStartedRangingBeacons else {
            let error = OpenAPIError(code: BeaconErrorCode.notStartDiscovery)
                .setErrno(OpenAPIBeaconErrno.notStartBeaconDiscovery)
            completionCallback(error)
            return
        }

        startRegions.forEach {
            self.locationManager.stopRangingBeacons(in: $0)
        }

        startRegions.removeAll()
        detectedBeaconMap.removeAll()

        hasStartedRangingBeacons = false
        discovering = false

        beaconUpdateBlock = nil
        serviceChangeBlock = nil

        completionCallback(nil)
    }

    /// 获取所有已搜索到的 iBeacon 设备
    public func getBeacons(completionCallback: @escaping (OpenAPIError?, [CLBeacon])->Void) {
        guard hasStartedRangingBeacons else {
            let error = OpenAPIError(code: BeaconErrorCode.notStartDiscovery)
                .setErrno(OpenAPIBeaconErrno.notStartBeaconDiscovery)
            completionCallback(error, [CLBeacon]())
            return
        }
        let datas = detectedBeaconMap.map {
            $0.value
        }
        trace.info("getBeacons count: \(datas.count)")
        completionCallback(nil, datas)
    }

    public init(with trace: OPTrace?) {
        self.trace = trace ?? OPTraceService.default().generateTrace()
    }

    deinit {
        if hasStartedRangingBeacons {
            trace.info("stopBeaconDiscovery before deinit")
            stopBeaconDiscovery { _ in
            }
        }
    }
}

extension OpenPluginBeaconManager: CLLocationManagerDelegate{
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }

        if status == .denied || status == .restricted {
            trace.error("CLLocation didChangeAuthorization deny or restricted")
            locationAuthorizeBlock?(false)
        } else {
            locationAuthorizeBlock?(true)
        }
        locationAuthorizeBlock = nil
    }

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if !beacons.isEmpty {
            // 保存已探测到的设备 
            beacons.forEach {
                self.detectedBeaconMap[$0.deviceId] = $0
            }

            if let updateCallback = beaconUpdateBlock {
                updateCallback(beacons)
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        trace.error("startRangingBeacons failed. error:\(error)")
    }
}

extension OpenPluginBeaconManager: CBCentralManagerDelegate{
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state == .poweredOn
        trace.info("centralManagerDidUpdateState: \(central.state)")
        available = state
        getBluetoothCompleteBlock?(state)
        getBluetoothCompleteBlock = nil
    }
}

private extension OpenPluginBeaconManager {
    // 获取定位权限
    private func requestAuthoriztion(_ completion: @escaping OPBeaconLocationAuthorizeBlock) {
        if !locationAuth.locationServicesEnabled() {
            trace.error("CLLocation locationServices is not enable")
            completion(false)
            return
        }

        switch CLLocationManager.authorizationStatus() {
        case .denied:
            trace.error("CLLocation authorization deny")
            completion(false)
        case .restricted:
            trace.error("CLLocation authorization restricted")
            completion(false)
        case .notDetermined:
            trace.info("CLLocation authorization notDetermined")
            do {
                try OPSensitivityEntry.requestWhenInUseAuthorization(forToken: .openPluginBeaconManagerStartBeaconDiscovery, manager: locationManager)
                locationAuthorizeBlock = completion
            } catch let error {
                trace.error(error.localizedDescription, error: error)
                completion(false)
            }
        default:
            completion(true)
        }
    }

    // 获取系统蓝牙开关状态
    private func getBluetoothState(completion: @escaping OPBeaconGetBLEStateBlock) {
        trace.info("call getBluetoothState")
        guard let manager = bluetoothManager else {
            getBluetoothCompleteBlock = completion
            bluetoothManager = CBCentralManager(delegate: self, queue: nil)
            return
        }

        completion(manager.state == .poweredOn)
    }

    // 开始搜索iBeacon设备
    private func startBeaconDiscoveryHandler(uuids: [UUID],
                                             serviceChangeCallback: @escaping OPBeaconServiceChangeBlock,
                                             beaconUpdateCallback: @escaping OPBeaconUpdateBlock,
                                             completionCallback: @escaping OPBeaconCompletionBlock) {
        trace.info("call startBeaconDiscoveryHandler")
        if !startRegions.isEmpty {
            startRegions.removeAll()
        }

        for proximityUUID in uuids {
            trace.info("start rangingBeacons with UUID: \(proximityUUID)")
            //开始查找iBeacon设备
            let region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: proximityUUID.uuidString)
            do {
                try OPSensitivityEntry.startRangingBeacons(forToken: .openPluginBeaconManagerStartBeaconDiscoveryHandler, manager: locationManager, region: region)
            } catch let error {
                trace.error(error.localizedDescription, error: error)
                let apiError = (error as? OpenAPIError) ?? OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                completionCallback(apiError)
                if !startRegions.isEmpty {
                    // 清理已经开启的
                    startRegions.forEach { region in
                        self.locationManager.stopRangingBeacons(in: region)
                    }
                    startRegions.removeAll()
                }
                return
            }
            startRegions.append(region)
        }
        
        serviceChangeBlock = serviceChangeCallback
        beaconUpdateBlock = beaconUpdateCallback

        discovering = true
        hasStartedRangingBeacons = true
        completionCallback(nil)
    }
}

public extension CLBeacon {
    var uuidString: String {
        if #available(iOS 13.0, *) {
            return self.uuid.uuidString
        } else {
            return self.proximityUUID.uuidString
        }
    }
}

fileprivate extension CLBeacon {
    //这个ID作为设备唯一标识符
    var deviceId: String {
        return self.uuidString + self.major.stringValue + self.minor.stringValue
    }
}
