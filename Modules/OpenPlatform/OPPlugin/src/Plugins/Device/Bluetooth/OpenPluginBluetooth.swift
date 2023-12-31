//
//  OpenPluginBluetooth.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/22.
//

import CoreBluetooth
import LarkOpenAPIModel
import LarkOpenPluginManager
import LKCommonsLogging
import OPFoundation
import LarkContainer

final class OpenPluginBluetooth: OpenBasePlugin {
    private static let selfReleasedMsg = "self released when call API"
    private static let logger = Logger.log(OpenPluginBluetoothManager.self, category: "OpenAPI")

    private(set) lazy var manager: OpenPluginBluetoothManager = {
        let manager = OpenPluginBluetoothManager(with: userResolver, trace: context?.apiTrace, delegate: self)
        return manager
    }()

    private var context: OpenAPIContext?

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "openBluetoothAdapter", pluginType: Self.self) { this, _, context, callback in
            
            this.context = context
            this.manager.openBluetoothAdapter { errorCode, status in
                switch errorCode {
                case .ok:
                    callback(.success(data: nil))
                default:
                    let error = OpenAPIError(code: errorCode)
                        .setBluetoothErrno(from: errorCode)
                        .setAddtionalInfo(["state": status.rawValue])
                    callback(.failure(error: error))
                }
            }
        }

        registerInstanceAsyncHandler(for: "getBluetoothAdapterState", pluginType: Self.self, resultType: OpenAPIBluetoothAdapterStateResult.self) { this, _, _, callback in
            
            this.manager.getBluetoothAdapterState { errorCode, info in
                switch errorCode {
                case .ok:
                    callback(.success(data: OpenAPIBluetoothAdapterStateResult(available: info.available,
                                                                               isDiscovering: info.discovering)))
                default:
                    let error = OpenAPIError(code: errorCode)
                        .setBluetoothErrno(from: errorCode)
                    callback(.failure(error: error))
                }
            }
        }

        registerInstanceAsyncHandler(for: "closeBluetoothAdapter", pluginType: Self.self) { this, _, _, callback in
            
            this.manager.closeBluetoothAdapter { errorCode in
                switch errorCode {
                case .ok:
                    callback(.success(data: nil))
                default:
                    let error = OpenAPIError(code: errorCode)
                        .setBluetoothErrno(from: errorCode)
                    callback(.failure(error: error))
                }
            }
        }

        registerInstanceAsyncHandler(for: "startBluetoothDevicesDiscovery", pluginType: Self.self, paramsType: OpenAPIStartBluetoothDevicesDiscoveryParams.self) { this, params, context, callback in
            
            do {
                try this.manager.startBluetoothDevicesDiscovery(with: params,
                                                                token: .openPluginBluetoothStartBluetoothDevicesDiscovery) { errorCode in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: nil))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("startBluetoothDevicesDiscovery throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        registerInstanceAsyncHandler(for: "getConnectedBluetoothDevices", pluginType: Self.self, paramsType: OpenAPIGetConnectedBluetoothDevicesParams.self, resultType: OpenAPIBluetoothPeripheralsResult.self) { this, params, _, callback in
            
            this.manager.getConnectedBluetoothDevices(with: params) { errorCode, peripherals in
                switch errorCode {
                case .ok:
                    callback(.success(data: OpenAPIBluetoothPeripheralsResult(peripherals: peripherals)))
                default:
                    let error = OpenAPIError(code: errorCode)
                        .setBluetoothErrno(from: errorCode)
                    callback(.failure(error: error))
                }
            }
        }

        registerInstanceAsyncHandler(for: "getBluetoothDevices", pluginType: Self.self, resultType: OpenAPIBluetoothDevicesResult.self) { this, _, _, callback in
            
            this.manager.getBluetoothDevices(with: { errorCode, devices in
                switch errorCode {
                case .ok:
                    callback(.success(data: OpenAPIBluetoothDevicesResult(devices: devices)))
                default:
                    let error = OpenAPIError(code: errorCode)
                        .setBluetoothErrno(from: errorCode)
                    callback(.failure(error: error))
                }
            })
        }

        registerInstanceAsyncHandler(for: "stopBluetoothDevicesDiscovery", pluginType: Self.self) { this, _, _, callback in
            
            this.manager.stopBluetoothDevicesDiscovery(with: { errorCode in
                switch errorCode {
                case .ok:
                    callback(.success(data: nil))
                default:
                    let error = OpenAPIError(code: errorCode)
                        .setBluetoothErrno(from: errorCode)
                    callback(.failure(error: error))
                }
            })
        }

        /// 连接低功耗蓝牙设备
        registerInstanceAsyncHandler(for: "connectBLEDevice", pluginType: Self.self, paramsType: OpenAPIBLEDeviceParams.self) { this, params, context, callback in
            
            do {
                try this.manager.operateBLEDevice(token: .openPluginBluetoothManagerConnectBLEDevice, connect: true, params: params) { errorCode in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: nil))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("operateBLEDevice throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        /// 断开低功耗蓝牙设备连接
        registerInstanceAsyncHandler(for: "disconnectBLEDevice", pluginType: Self.self, paramsType: OpenAPIBLEDeviceParams.self) { this, params, context, callback in
            

            do {
                try this.manager.operateBLEDevice(token: .placeholder, connect: false, params: params) { errorCode in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: nil))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("operateBLEDevice throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        /// 获取外围设备上所有可用的蓝牙服务
        /// 第一次会稍微慢些，需要先 discover，然后再通过 delegate 来触发 completion block
        /// 之后直接从外围设备上拿 devices 属性即可
        registerInstanceAsyncHandler(for: "getBLEDeviceServices", pluginType: Self.self, paramsType: OpenAPIBLEDeviceParams.self, resultType: OpenAPIBLEDeviceServicesResult.self) { this, params, context, callback in
            
            do {
                try this.manager.getBLEDeviceServices(params: params,
                                                      token: .openPluginBluetoothManagerDiscoverServices) { errorCode, services in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: OpenAPIBLEDeviceServicesResult(services: services)))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("getBLEDeviceServices throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        /// 获取读写特征
        /// 第一次会稍微慢些，需要先 discover，然后再通过 delegate 来触发 completion block
        /// 之后直接从 service 上拿特征值属性即可
        registerInstanceAsyncHandler(for: "getBLEDeviceCharacteristics", pluginType: Self.self, paramsType: OpenAPIBLEServiceParams.self, resultType: OpenAPIBLEDeviceCharacteristicsResult.self) { this, params, context, callback in
            
            do {
                try this.manager.getBLEDeviceCharacteristics(token: .openPluginBluetoothManagerGetBLEDeviceCharacteristics,
                                                             params: params) { errorCode, characteristics in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: OpenAPIBLEDeviceCharacteristicsResult(characteristics: characteristics)))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("getBLEDeviceCharacteristics throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        /// 监听特征值数据变化
        registerInstanceAsyncHandler(for: "notifyBLECharacteristicValueChange", pluginType: Self.self, paramsType: OpenAPIBLENotifyCharacteristicParams.self) { this, params, context, callback in
            
            do {
                try this.manager.operateBLECharacteristic(token: .placeholder,
                                                          type: .notify(state: params.notify),
                                                          deviceID: params.deviceID,
                                                          serviceID: params.serviceID, characterID: params.characteristicID) { errorCode, _ in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: nil))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("operateBLECharacteristic throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        /// 读取特征值数据
        /// 读取的结果会通过 Delegate 的 `peripheral:didUpdateValueForCharacteristic:error:` 返回
        /// 写入特征值后，通过 notify 获取到的特征值数据由于缓存原因，可能不是最新的，可以调用这个方法来获取
        registerInstanceAsyncHandler(for: "readBLECharacteristicValue", pluginType: Self.self, paramsType: OpenAPIBLECharacteristicParams.self, resultType: OpenAPIBLEDeviceCharacteristicResult.self) { this, params, context, callback in
            
            do {
                try this.manager.operateBLECharacteristic(token: .openPluginBluetoothManagerReadBLECharacteristicValue,
                                                          type: .read,
                                                          deviceID: params.deviceID,
                                                          serviceID: params.serviceID,
                                                          characterID: params.characteristicID) { errorCode, characteristic in
                    switch errorCode {
                    case .ok:
                        if let cha = characteristic {
                            callback(.success(data: OpenAPIBLEDeviceCharacteristicResult(characteristic: cha)))
                        } else {
                            context.apiTrace.error("operateBLECharacteristic ok, but characteristic is nil")
                            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setErrno(OpenAPICommonErrno.unknown)
                            callback(.failure(error: error))
                        }
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("operateBLECharacteristic throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }

        /// 写入特征值数据
        registerInstanceAsyncHandler(for: "writeBLECharacteristicValue", pluginType: Self.self, paramsType: OpenAPIBLEWriteCharacteristicParams.self) { this, params, context, callback in
            
            do {
                try this.manager.operateBLECharacteristic(token: .openPluginBluetoothManagerWriteBLECharacteristicValue,
                                                          type: .write(value: params.hexValue),
                                                          deviceID: params.deviceID,
                                                          serviceID: params.serviceID,
                                                          characterID: params.characteristicID) { errorCode, _ in
                    switch errorCode {
                    case .ok:
                        callback(.success(data: nil))
                    default:
                        let error = OpenAPIError(code: errorCode)
                            .setBluetoothErrno(from: errorCode)
                        callback(.failure(error: error))
                    }
                }
            } catch {
                context.apiTrace.error("operateBLECharacteristic throw error: \(error)")
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
            }
        }
    }
}

extension OpenPluginBluetooth: BluetoothManagerDelegate {
    private func fireEvent(_ event: String, data: [String: Any]) {
        guard let context = context else {
            let errMsg = "context is nil, may forget call openBluetoothAdapter"
            assertionFailure(errMsg)
            Self.logger.error("\(errMsg)")
            return
        }
        context.apiTrace.info("fireevent \(event)")
        do {
            let param = try OpenAPIFireEventParams(event: event,
                                                   sourceID: NSNotFound,
                                                   data: data,
                                                   preCheckType: .none,
                                                   sceneType: .normal)
            let result = context.syncCall(apiName: "fireEvent", params: param, context: context)
            switch result {
            case .success(data: _):
                context.apiTrace.info("fireevent \(event) success")
            case let .failure(error: error):
                context.apiTrace.error("can not fireevent bluetoothAdapterStateChange, error\(error)")
            case .continue(event: _, data: _):
                context.apiTrace.warn("fireevent \(event) continue")
            }
        } catch {
            context.apiTrace.error("can not fireevent \(event), error\(error)")
        }
    }

    public func bluetoothAdapterStateDidChange(available: Bool, _ discovering: Bool) {
        fireEvent("bluetoothAdapterStateChange",
                  data: ["available": available,
                         "discovering": discovering])
    }

    func bluetoothDeviceDidFound(devices: [BluetoothDeviceModel]) {
        fireEvent("bluetoothDeviceFound",
                  data: ["devices": devices.map { $0.toJSONDict() }])
    }

    public func bluetoothConnectionStateDidChange(deviceID: String, connected: Bool) {
        fireEvent("BLEConnectionStateChange",
                  data: ["deviceId": deviceID,
                         "connected": connected])
    }

    public func bluetoothDeviceCharacteristicValueDidChange(deviceID: String, serviceID: String, characteristicID: String, value: String) {
        fireEvent("BLECharacteristicValueChange",
                  data: ["serviceId": serviceID,
                         "deviceId": deviceID,
                         "characteristicId": characteristicID,
                         "value": value])
    }
}

private extension OpenAPIError {
    @discardableResult
    func setBluetoothErrno(from code: BluetoothErrorCode) -> OpenAPIError {
        switch code {
        case .connectionFail:
            setErrno(OpenAPIBluetoothErrno.connectionFailed)
        case .ok:
            break
        case .notInit:
            setErrno(OpenAPIBluetoothErrno.adapterUninitialized)
        case .notAvailable:
            setErrno(OpenAPIBluetoothErrno.adapterUnavailable)
        case .noDevice:
            setErrno(OpenAPIBluetoothErrno.deviceNotFound)
        case .noService:
            setErrno(OpenAPIBluetoothErrno.serviceNotFound)
        case .noCharacteristic:
            setErrno(OpenAPIBluetoothErrno.characteristicIdNotFound)
        case .noConnection:
            setErrno(OpenAPIBluetoothErrno.disconnect)
        case .propertyNotSupport:
            setErrno(OpenAPIBluetoothErrno.unsupportedFunctions)
        case .systemError:
            setErrno(OpenAPIBluetoothErrno.systemError)
        case .systemNotSupport:
            setErrno(OpenAPIBluetoothErrno.bleUnavailable)
        case .descriptorNotFound:
            setErrno(OpenAPIBluetoothErrno.descriptorNotFound)
        case .invalidDeviceId:
            setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "deviceId")))
        case .invalidServiceId:
            setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "serviceId")))
        case .invalidCharacteristicId:
            setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "characteristicId")))
        case .invalidData:
            setErrno(OpenAPIBluetoothErrno.invalidData)
        case .operateTimeout:
            setErrno(OpenAPIBluetoothErrno.operationTimeout)
        case .parametersNeeded:
            setErrno(OpenAPIBluetoothErrno.invalidData)
        case .failedToWriteCharacteristic:
            setErrno(OpenAPIBluetoothErrno.systemError)
        case .failedToReadCharacteristic:
            setErrno(OpenAPIBluetoothErrno.systemError)
        @unknown default:
            break
        }
        return self
    }
}
