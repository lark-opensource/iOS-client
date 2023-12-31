//
//  ScanBluetoothDeviceHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//
import CoreBluetooth
import LKCommonsLogging
import WebBrowser
import OPFoundation

class ScanBluetoothDeviceHandler: NSObject, JsAPIHandler {
    var peripheralMap = [String: CBPeripheral]()

    private var bluetoothState: BlueToothState?

    private var scanStartDate: Date?

    private var scanTimeOut: Int = 12_000 //扫描超时时间，默认12000毫秒

    private weak var api: WebBrowser?

    lazy var blueToothManager: CBCentralManager = {
        let manager = CBCentralManager()
        _blueToothManager = manager
        return manager
    }()
    private var _blueToothManager: CBCentralManager?

    private var callBack: WorkaroundAPICallBack?

    static let logger = Logger.log(ScanBluetoothDeviceHandler.self, category: "Module.JSSDK")

    init(api: WebBrowser) {
        self.api = api
        super.init()
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
//        guard let onSuccess = args["callback"] as? String else {
//            ScanBluetoothDeviceHandler.logger.error("参数有误")
//            return
//        }

        if let timeout = args["scanTimeOut"] as? Int {
            self.scanTimeOut = timeout
        }

        self.callBack = callback
        blueToothManager.delegate = self

        if let state = bluetoothState {
            //如果已经有状态
            if state != .Open {
                //如果state不是蓝牙开启，则直接返回。
                finishScanAndCallBack()
            } else {
                //如果蓝牙开启，过scanTimeOut时间返回周边设备
                self.perform(#selector(finishScanAndCallBack), with: nil, afterDelay: TimeInterval(scanTimeOut / 1000))
            }
        }
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        _blueToothManager?.delegate = nil
        _blueToothManager?.stopScan()
    }

    @objc
    private func finishScanAndCallBack() {
        guard let state = bluetoothState  else { return }

        let code = (state == .Close) ? 2 : 1
        let data = formatData(peripherals: Array(peripheralMap.values))
        let result: [String: Any] = ["code": code,
                                     "data": data]
//        api?.call(funcName: callBack, arguments: [result])
        callBack?.callbackSuccess(param: result)
    }

    private func formatData(peripherals: [CBPeripheral]) -> [[String: Any]] {
        return peripherals.map({ (peripheral) -> [String: Any] in
            var dic = [String: Any]()
            dic["id"] = peripheral.identifier.uuidString
            dic["name"] = peripheral.name ?? ""
            dic["state"] = peripheral.state == .connected ? 2 : 0
            return dic
        })
    }
}

extension ScanBluetoothDeviceHandler: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // iOS 10.0以上的系统使用CBManagerState这个枚举类型。为了兼容iOS 9,使用枚举的rawValue
        // 经测试iOS 9和 10枚举只是类型换了，rawValue没有变化
        var state: BlueToothState = .Unknown
        switch central.state.rawValue {
        case 2:
            state = .UnSupported
        case 4:
            state = .Close
        case 5:
            state = .Open
            do {
                try OPSensitivityEntry.scanForPeripherals(forToken: .jssdkScanBluetoothDeviceHandlerCentralManagerDidUpdateState,
                                                     centralManager: blueToothManager,
                                                     withServices: nil,
                                                     options: nil)
            } catch {
                ScanBluetoothDeviceHandler.logger.error("scanForPeripherals throw error: \(error)")
            }
            
        default:
            break
        }

        let originalBluetoothState = bluetoothState
        bluetoothState = state

        if originalBluetoothState == nil {
            if state != .Open {
                finishScanAndCallBack()
            } else {
                self.perform(#selector(finishScanAndCallBack), with: nil, afterDelay: TimeInterval(scanTimeOut / 1000))
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        peripheralMap[peripheral.identifier.uuidString] = peripheral
    }
}
