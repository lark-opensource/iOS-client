//
//  OpenPluginBluetoothManager.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/25.
//

import OPFoundation
import CoreBluetooth
import LarkOpenAPIModel
import ECOProbe
import ECOInfra
import LarkContainer

// 低功耗蓝牙操作方式
public enum BLECharacteristicOperation {
    // 对应notifyBLECharacteristicValueChange接口，state:是否启用notify或indicate
    case notify(state: Bool)
    // 对应readBLECharacteristicValue接口
    case read
    // 对应writeBLECharacteristicValue接口，value: 蓝牙设备特征值对应的值，16 进制字符串，限制在 20 字节内
    case write(value: String)
}

public enum OpenPluginBluetoothAdapterFailState: Int {
    /// 未知
    case unknown = 0
    /// 重置中
    case resetting
    /// 不支持
    case unsupported
    /// 未授权
    case unauthorized
    /// 未开启
    case poweredOff

}

extension CBManagerState {
    var adapterFailState: OpenPluginBluetoothAdapterFailState {
        switch self {
        case .resetting:
            return .resetting
        case .unsupported:
            return .unsupported
        case .unauthorized:
            return .unauthorized
        case .poweredOff:
            return .poweredOff
        default:
            return .unknown
        }
    }
}

extension CBCentralManager {
    var adapterAvailable: Bool {
        return self.state == .poweredOn
    }
}

protocol BluetoothManagerDelegate: AnyObject {
    /// - Parameters:监听蓝牙适配器状态变化事件
    ///   - available: 蓝牙适配器是否可用
    ///   - discovering: 蓝牙适配器是否处于搜索状态
    func bluetoothAdapterStateDidChange(available: Bool, _ discovering: Bool)

    /// 监听寻找到新设备的事件
    /// - Parameter devices: 新搜索到的设备列表
    func bluetoothDeviceDidFound(devices: [BluetoothDeviceModel])


    /// 设备连接状态发生改变
    /// - Parameters:
    ///   - deviceID: 设备ID
    ///   - connected: 是否连接
    func bluetoothConnectionStateDidChange(deviceID: String, connected: Bool)

    /// 设备特征值发生变化
    func bluetoothDeviceCharacteristicValueDidChange(deviceID: String, serviceID: String, characteristicID: String, value: String)

}

final class BluetoothReportConfig {
    /// 默认值为0。上报设备的间隔。0 表示找到新设备立即上报，其他数值根据传入的间隔上报。
    var reportInterval: TimeInterval = 0 {
        didSet {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: reportInterval, repeats: true) { [weak self] _ in
                self?.reportAction?()
            }
        }
    }
    /// 是否立即上报
    var reportImmediately: Bool {
        return reportInterval <= 0
    }
    /// 上报新设备定时器
    private var timer: Timer?

    func stopReport() {
        timer?.invalidate()
        timer = nil
    }
    
    private var reportAction: os_block_t?

    func setReport(interval: TimeInterval,  action: @escaping os_block_t) {
        reportAction = action
        reportInterval = interval
        if reportImmediately {
            reportAction?()
            return
        }
    }
    
    deinit {
        stopReport()
    }
    
}

final class OpenPluginBluetoothManager: NSObject {
    
    let userResolver: UserResolver

    // 系统蓝牙设备管理对象，可以把它理解为主设备，通过它可以去扫描和连接外设
    private(set) var centerManager: CBCentralManager?

    // 当前发现的设备
    private let devicesLock = DispatchSemaphore(value: 1)
    var devices: [String: BluetoothDeviceModel] = [:]

    // delegate
    weak var delegate: BluetoothManagerDelegate?
    var openAdapterCompletion: ((_ error: BluetoothErrorCode, _ status: OpenPluginBluetoothAdapterFailState) -> Void)?

    // 上报配置config
    var config = BluetoothReportConfig()

    // util
    let trace: OPTrace

    public init(with resolver: UserResolver, trace: OPTrace?, delegate: BluetoothManagerDelegate?) {
        userResolver = resolver
        self.trace = trace ?? OPTraceService.default().generateTrace()
        self.delegate = delegate
    }

    deinit {
        trace.info("bluetooth manager deinit")
        config.stopReport()
        observeScanning(observe: false)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == Self.scanningKey,
              let manager = centerManager,
              object as? CBCentralManager == manager else {
            trace.warn("value chaged for key \(keyPath ?? "")")
            return
        }
        let new = change?[NSKeyValueChangeKey.newKey] as? Bool
        let old = change?[NSKeyValueChangeKey.oldKey] as? Bool
        guard new != old else {
            trace.warn("value didn't chaged for key \(keyPath ?? ""), old=\(String(describing: old)), new=\(String(describing: new))")
            return
        }
        delegate?.bluetoothAdapterStateDidChange(available: manager.adapterAvailable, new ?? manager.isScanning)
    }
    
    public func clearAndNotifyDeviceForCBCentralManagerPoweredOff() {
        trace.info("clearAndNotifyDeviceForCBCentralManagerPoweredOff")
        devices.forEach { deviceID, aDevice in
            guard aDevice.connected else {
                return
            }
            aDevice.connected = false
            delegate?.bluetoothConnectionStateDidChange(deviceID: deviceID, connected: false)
        }
        devices.removeAll()
    }
    
}

extension OpenPluginBluetoothManager {
    /// 初始化蓝牙模块，检查蓝牙是否可用，如果不可用，提示用户开启蓝牙
    /// - 其他蓝牙相关 API 必须在 tt.openBluetoothAdapter 调用之后使用。否则 API 会返回错误（errCode=10000）。
    /// - 在用户蓝牙开关未开启或者手机不支持蓝牙功能的情况下，调用 tt.openBluetoothAdapter 会返回错误（errCode=10001），表示手机蓝牙功能不可用。此时小程序蓝牙模块已经初始化完成，可通过 tt.onBluetoothAdapterStateChange 监听手机蓝牙状态的改变，也可以调用蓝牙模块的所有API。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10001    not available    当前蓝牙适配器不可用
    func openBluetoothAdapter(with completion: @escaping (_ error: BluetoothErrorCode, _ status: OpenPluginBluetoothAdapterFailState) -> Void) {
        trace.info("openBluetoothAdapter")
        guard let manager = centerManager else {
            trace.info("init centerManager")
            openAdapterCompletion = completion
            // 初始化并设置委托和线程队列，最后一个线程的参数可以为nil，默认会就main线程
            centerManager = CBCentralManager(delegate: self, queue: nil)
            // 监听蓝牙搜寻状态
            observeScanning(observe: true)
            devices.removeAll()
            return
        }
        completion(manager.adapterAvailable ? .ok : .notAvailable, manager.state.adapterFailState)
    }

    /// 获取本机蓝牙适配器状态。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10000    not init    未初始化蓝牙适配器
    /// 10001    not available    当前蓝牙适配器不可用
    /// @param completion 检查蓝牙各种状态
    /// @param successInfo discovering:是否正在搜索设备，available:蓝牙适配器是否可用
    func getBluetoothAdapterState(with completion: (_ error: BluetoothErrorCode, _ successInfo: (available: Bool, discovering: Bool)) -> Void) {
        trace.info("getBluetoothAdapterState")
        guard preCheckResult == .ok else {
            completion(preCheckResult, (false, false))
            return
        }
        completion(preCheckResult, (centerManager!.adapterAvailable, centerManager!.isScanning))
    }

    /// 关闭蓝牙模块。调用该方法将断开所有已建立的连接并释放系统资源。建议在使用蓝牙流程后，与 tt.openBluetoothAdapter 成对调用。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10000    not init    未初始化蓝牙适配器
    /// 10001    not available    当前蓝牙适配器不可用
    func closeBluetoothAdapter(with completion: (_ error: BluetoothErrorCode) -> Void) {
        trace.info("closeBluetoothAdapter")
        guard preCheckResult == .ok else {
            completion(preCheckResult)
            return
        }
        /// 断开所有已连接的设备
        devices.values.filter({ $0.connected })
            .forEach({ centerManager?.cancelPeripheralConnection($0.peripheral) })
        /// 停止扫描
        centerManager?.stopScan()
        config.stopReport()
        if centerManager != nil {
            observeScanning(observe: false)
        }
        centerManager = nil
        devices.removeAll()
        completion(.ok)
    }

    /// 开始搜寻附近的蓝牙外围设备。此操作比较耗费系统资源，请在搜索并连接到设备后调用 wx.stopBluetoothDevicesDiscovery 方法停止搜索。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10000    not init    未初始化蓝牙适配器
    /// 10001    not available    当前蓝牙适配器不可用
    /// @param services 要搜索的蓝牙设备主 service 的 uuid 列表。某些蓝牙设备会广播自己的主 service 的 uuid。如果设置此参数，则只搜索广播包有对应 uuid 的主服务的蓝牙设备。建议主要通过该参数过滤掉周边不需要处理的其他蓝牙设备。
    /// @param allowDuplicatesKey 默认值为NO。是否允许重复上报同一设备。如果允许重复上报，则 wx.onBlueToothDeviceFound 方法会多次上报同一设备，但是 RSSI 值会有不同。
    /// @param interval 默认值为0。上报设备的间隔。0 表示找到新设备立即上报，其他数值根据传入的间隔上报。
    func startBluetoothDevicesDiscovery(with params: OpenAPIStartBluetoothDevicesDiscoveryParams, token: OPSensitivityEntryToken, completion: (_ error: BluetoothErrorCode) -> Void) throws {
        trace.info("startBluetoothDevicesDiscovery, interval=\(params.interval) allowDuplicatesKey=\(params.allowDuplicatesKey)")
        guard preCheckResult == .ok, let centerManager = centerManager else {
            completion(preCheckResult)
            return
        }
        /** 开始扫描周围的外设
         第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
              - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
        */
        let services = Self.generateCBUUID(for: params.services ?? [], trace: trace)

        config.setReport(interval: TimeInterval(params.interval / 1000.0)) { [weak self] in
            guard let `self` = self else {
                return
            }
            let unreported = self.devices.values.filter({ !$0.reported && !$0.retrieveConnected })
            if !unreported.isEmpty {
                self.delegate?.bluetoothDeviceDidFound(devices: unreported)
            }
            self.devices.forEach({
                $0.value.reported = true
            })
            
        }
        
        try OPSensitivityEntry
            .scanForPeripherals(forToken: .openPluginBluetoothStartBluetoothDevicesDiscovery,
                                centralManager: centerManager,
                                withServices: services,
                                options: [CBCentralManagerScanOptionAllowDuplicatesKey: params.allowDuplicatesKey]);
        
        completion(.ok)
    }

    /// 停止搜寻附近的蓝牙外围设备。若已经找到需要的蓝牙设备并不需要继续搜索时，建议调用该接口停止蓝牙搜索。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10000    not init    未初始化蓝牙适配器
    /// 10001    not available    当前蓝牙适配器不可用
    func stopBluetoothDevicesDiscovery(with completion: (_ error: BluetoothErrorCode) -> Void) {
        trace.info("stopBluetoothDevicesDiscovery")
        guard preCheckResult == .ok else {
            completion(preCheckResult)
            return
        }
        centerManager?.stopScan()
        config.stopReport()
        completion(.ok)
    }

    /// 获取在蓝牙模块生效期间所有已发现的蓝牙设备。包括已经和本机处于连接状态的设备。
    /// 注意事项
    /// 1. 该接口获取到的设备列表为蓝牙模块生效期间所有搜索到的蓝牙设备，若在蓝牙模块使用流程结束后未及时调用 wx.closeBluetoothAdapter 释放资源，会存在调用该接口会返回之前的蓝牙使用流程中搜索到的蓝牙设备，可能设备已经不在用户身边，无法连接。
    /// 2. 蓝牙设备在被搜索到时，系统返回的 name 字段一般为广播包中的 LocalName 字段中的设备名称，而如果与蓝牙设备建立连接，系统返回的 name 字段会改为从蓝牙设备上获取到的 GattName。若需要动态改变设备名称并展示，建议使用 localName 字段。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10000    not init    未初始化蓝牙适配器
    /// 10001    not available    当前蓝牙适配器不可用
    /// @return uuid 对应的的已连接设备列表
    func getBluetoothDevices(with completion: (_ error: BluetoothErrorCode, _ devices: [BluetoothDeviceModel]) -> Void) {
        trace.info("getBluetoothDevices")
        guard preCheckResult == .ok else {
            completion(preCheckResult, [])
            return
        }
        completion(.ok, devices.map{ $0.value }.filter{ !$0.retrieveConnected })
    }

    /// 根据 uuid 获取处于已连接状态的设备。
    /// 错误码    错误信息    说明
    /// 0    ok    正常
    /// 10000    not init    未初始化蓝牙适配器
    /// 10001    not available    当前蓝牙适配器不可用
    /// @param services 蓝牙设备主 service 的 uuid 列表
    /// @return 搜索到的设备列表
    func getConnectedBluetoothDevices(with params: OpenAPIGetConnectedBluetoothDevicesParams, completion: (_ error: BluetoothErrorCode, _ devices: [BluetoothPeripheralModel]) -> Void) {
        trace.info("getConnectedBluetoothDevices, servicesCount=\(params.services.count)")
        guard !params.services.isEmpty else {
            trace.info("getConnectedBluetoothDevices services is empty")
            completion(.ok, [])
            return
        }
        // 对齐 Android 逻辑 检查蓝牙状态的逻辑后置
        guard preCheckResult == .ok else {
            completion(preCheckResult, [])
            return
        }
        let uuids = Self.generateCBUUID(for: params.services, trace: trace)
        let peripherals = centerManager!.retrieveConnectedPeripherals(withServices: uuids)
        for peripheral in peripherals {
            let device = devices[peripheral.identifier.uuidString]
            if device == nil {
                let deviceModel = BluetoothDeviceModel(with: peripheral, advertisementData: [:], RSSI: 0, trace: trace)
                deviceModel.retrieveConnected = true
                devices[peripheral.identifier.uuidString] = deviceModel // 通过系统连接后停止广播的设备将发现不了，进而导致之后api都无法调用，通过加入发现列表解决此问题
            }
            trace.info("addRetrieveConnectedDevice, already added \(device == nil ? false : true)")
        }
        completion(.ok, peripherals.map{ BluetoothPeripheralModel(name: $0.name ?? "", deviceID: $0.identifier.uuidString) })
    }

    func operateBLEDevice(token: OPSensitivityEntryToken, connect: Bool, params: OpenAPIBLEDeviceParams, completion: @escaping (_ error: BluetoothErrorCode) -> Void) throws {
        trace.info("operateBLEDevice, connect=\(connect), deviceID=\(params.deviceID)")
        if connect {
            guard let device = devices[params.deviceID] else {
                trace.warn("can not find discoverd device")
                completion(.noDevice)
                return
            }
            // 对齐 Android 逻辑 检查蓝牙状态的逻辑后置
            guard preCheckResult == .ok, let centerManager = centerManager else {
                completion(preCheckResult)
                return
            }
            
            device.deviceListener.connectCompletion = { (errorCode) in
                completion(errorCode)
            }
            try OPSensitivityEntry.connect(forToken: token, centralManager: centerManager, peripheral: device.peripheral)
        } else {
            guard let device = devices[params.deviceID], device.connected else {
                trace.warn("can not find discoverd device")
                completion(.noConnection)
                return
            }
            guard device.connected else {
                trace.warn("device is unconnected")
                completion(.noConnection)
                return
            }
            // 对齐 Android 逻辑 检查蓝牙状态的逻辑后置
            guard preCheckResult == .ok else {
                completion(preCheckResult)
                return
            }
            device.deviceListener.disconnectCompletion = { (errorCode) in
                completion(errorCode)
            }
            centerManager?.cancelPeripheralConnection(device.peripheral)
        }
    }

    func getBLEDeviceServices(params: OpenAPIBLEDeviceParams,
                              token: OPSensitivityEntryToken,
                              completion: @escaping (_ error: BluetoothErrorCode, _ services: [BLEDeviceServiceModel]) -> Void) throws {
        trace.info("getBLEDeviceServices, deviceID=\(params.deviceID)")
        guard let device = devices[params.deviceID] else {
            trace.warn("can not find discoverd device")
            completion(.noDevice, [])
            return
        }
        // 如果 services 不为 nil，说明之前已经 discover 过，直接返回即可
        if let service = device.peripheral.services {
            completion(.ok, service.map({ BLEDeviceServiceModel(service: $0) }))
            return
        }
        guard device.connected else {
            trace.warn("can not find discoverd device")
            completion(.noConnection, [])
            return
        }
        // 对齐 Android 逻辑 检查蓝牙状态的逻辑后置
        guard preCheckResult == .ok else {
            completion(preCheckResult, [])
            return
        }
        device.peripheralListener.getServicesCompletion = { (errorCode, services) in
            completion(errorCode, services)
        }
        
        try OPSensitivityEntry.discoverServices(forToken: token, peripheral: device.peripheral, nil)
    }

    func getBLEDeviceCharacteristics(token: OPSensitivityEntryToken,
                                     params: OpenAPIBLEServiceParams,
                                     completion: @escaping (_ error: BluetoothErrorCode, _ characteristics: [BluetoothDeviceCharacteristicModel]) -> Void) throws {
        trace.info("getBLEDeviceCharacteristics, deviceID=\(params.deviceID) serviceID=\(params.serviceID)")
        guard let device = devices[params.deviceID] else {
            trace.warn("can not find discoverd device")
            completion(.noDevice, [])
            return
        }
        guard let service = device.peripheral.services?.first(where: { $0.uuid.realUUIDString == params.serviceID }) else {
            trace.warn("can not find discoverd service")
            completion(.noService, [])
            return
        }
        // 如果 characteristics 不为 nil，说明之前已经 discover 过，直接返回即可
        if let characteristics = service.characteristics {
            completion(.ok, characteristics.map({ BluetoothDeviceCharacteristicModel(characteristics: $0) }))
            return
        }
        
        guard device.connected else {
            trace.warn("can not find discoverd device")
            completion(.noConnection, [])
            return
        }
        // 对齐 Android 逻辑 检查蓝牙状态的逻辑后置
        guard preCheckResult == .ok else {
            completion(preCheckResult, [])
            return
        }
        device.peripheralListener.getCharacteristicsCompletion = { (errorCode, characteristics) in
            completion(errorCode, characteristics)
        }
        try OPSensitivityEntry.discoverCharacteristics(forToken: token, peripheral: device.peripheral, nil, for: service)
    }

    func operateBLECharacteristic(token: OPSensitivityEntryToken,
                                  type: BLECharacteristicOperation,
                                  deviceID: String,
                                  serviceID: String,
                                  characterID: String,
                                  completion: @escaping (_ error: BluetoothErrorCode, _ characteristic: BluetoothDeviceCharacteristicModel?) -> Void) throws {
        trace.info("operateBLECharacteristic, deviceID=\(deviceID) serviceID=\(serviceID), characterID=\(characterID)")
        guard let device = devices[deviceID] else {
            trace.warn("can not find discoverd device")
            completion(.noDevice, nil)
            return
        }
        
        guard device.connected else {
            trace.warn("device ID: \(deviceID) is no connected")
            completion(.noConnection, nil)
            return
        }
        guard let service = device.peripheral.services?.first(where: { $0.uuid.realUUIDString == serviceID }) else {
            trace.warn("can not find discoverd service")
            completion(.noService, nil)
            return
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.realUUIDString == characterID }) else {
            trace.warn("can not find discoverd characteristic")
            completion(.noCharacteristic, nil)
            return
        }
        // 对齐 Android 逻辑 检查蓝牙状态的逻辑后置
        guard preCheckResult == .ok else {
            completion(preCheckResult, nil)
            return
        }
        switch type {
        case let .notify(state: notify):
            guard characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) else {
                trace.warn("can not set notify characteristic, notify\(notify)")
                completion(.propertyNotSupport, nil)
                return
            }
            device.peripheralListener.notifyCharacteristicCompletion = { (errorCode) in
                completion(errorCode, nil)
            }
            if notify {
                device.peripheralListener.characteristicValueChange = { [weak self] (errorCode, characteristic) in
                    #if swift(>=5.5)
                    let deviceID: String = characteristic.service?.peripheral?.identifier.uuidString ?? ""
                    let serviceID: String = characteristic.service?.uuid.realUUIDString ?? ""
                    #else
                    let deviceID: String = characteristic.service.peripheral.identifier.uuidString
                    let serviceID: String = characteristic.service.uuid.realUUIDString
                    #endif
                    self?.delegate?.bluetoothDeviceCharacteristicValueDidChange(
                        deviceID: deviceID,
                        serviceID: serviceID,
                        characteristicID: characteristic.uuid.realUUIDString,
                        value: characteristic.value?.characteristicsValueHexString ?? "")
                }
            } else {
                device.peripheralListener.characteristicValueChange = nil
            }
            device.peripheral.setNotifyValue(notify, for: characteristic)
        case .read:
            guard characteristic.properties.contains(.read) else {
                trace.warn("can not read characteristic")
                completion(.propertyNotSupport, nil)
                return
            }
            device.peripheralListener.readCharacteristicValueCompletion = { (errorCode, character) in
                completion(errorCode, BluetoothDeviceCharacteristicModel(characteristics: character))
            }
            try OPSensitivityEntry.readValue(forToken: token, peripheral: device.peripheral, for: characteristic)
        case let .write(value: value):
            guard characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) else {
                trace.warn("can not write characteristic")
                completion(.propertyNotSupport, nil)
                return
            }

            /// 如果字符串长度不为偶数，则自动在最前面的追加 0
            let hexStr = value.count % 2 != 0 ? "0"+value : value
            guard let data = NSString(string: hexStr).hexStringToData() else {
                trace.error("can not generate data from hexString, \(value.count)")
                completion(.invalidData, nil)
                return
            }
            device.peripheralListener.writeCharacteristicValueCompletion = { (errorCode) in
                completion(errorCode, nil)
            }
            try OPSensitivityEntry.writeValue(forToken: token, peripheral: device.peripheral, data, for: characteristic, type:  characteristic.properties.contains(.write) ? .withResponse : .withoutResponse)
        }
    }
}

extension OpenPluginBluetoothManager {

    private static let scanningKey = "isScanning"

    // 调用蓝牙接口的前置检测
    var preCheckResult: BluetoothErrorCode {
        /// 检查是否已初始化蓝牙适配器
        guard let manager = centerManager else {
            trace.warn("centerManager is nil")
            return .notInit
        }
        /// 检查当前蓝牙适配器是否可用
        guard manager.adapterAvailable else {
            trace.warn("centerManager not poweredOn, state=\(manager.state)")
            return .notAvailable
        }
        return .ok
    }

    // 监听蓝牙搜寻状态
    private func observeScanning(observe: Bool) {
        trace.info("observe centerManager isScanning, observe=\(observe)")
        if observe {
            centerManager?.addObserver(self, forKeyPath: Self.scanningKey, options: [.new, .old], context: nil)
        } else {
            centerManager?.removeObserver(self, forKeyPath: Self.scanningKey, context: nil)
        }
    }
}

extension OpenPluginBluetoothManager {

    // 使用string生成CBUUID，内部会抛nsexception，所以要做一层防护处理
    static func generateCBUUID(for services: [String], trace: OPTrace) -> [CBUUID] {
        var uuids: [CBUUID] = []
        services.forEach({ service in
            do {
                try OPObjcExceptionHandler.catchException {
                    let uuid = CBUUID(string: service)
                    uuids.append(uuid)
                }
            } catch {
                trace.error("can not generate cbuuid with \(service), error \(error)")
            }
        })
        return uuids
    }

}
