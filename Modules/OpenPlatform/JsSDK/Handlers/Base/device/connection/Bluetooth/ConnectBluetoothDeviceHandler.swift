//
//  ConnectBluetoothDeviceHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import CoreBluetooth
import LKCommonsLogging
import WebBrowser
import OPFoundation

class ConnectBluetoothDeviceHandler: NSObject, JsAPIHandler {
    private weak var api: WebBrowser?

    var scanHandler: ScanBluetoothDeviceHandler?

    lazy var blueToothManager: CBCentralManager = {
        let manager = CBCentralManager()
        _blueToothManager = manager
        return manager
    }()
    private var _blueToothManager: CBCentralManager?

//    private var callBack: String?
    private var callback: WorkaroundAPICallBack?

    static let logger = Logger.log(ConnectBluetoothDeviceHandler.self, category: "Module.JSSDK")

    private var toBeConnectedIDs = Set<String>()

    init(api: WebBrowser) {
        self.api = api
        super.init()
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let id = args["id"] as? String else {
            ConnectBluetoothDeviceHandler.logger.error("参数有误")
            return
        }

        self.callback = callback
        blueToothManager.delegate = self

        if let peripheral = peripheralForID(id) {
           
            do {
                try OPSensitivityEntry.connect(forToken: .jssdkConnectBluetoothDeviceHandler ,
                                          centralManager: blueToothManager,
                                          peripheral: peripheral,
                                          options: nil)
                toBeConnectedIDs.insert(id)
            } catch {
                ConnectBluetoothDeviceHandler.logger.error("connect(peripheral throws error:\(error)")
                callback.callbackSuccess(param: ["state": 0])
            }
        } else {
//            api.call(funcName: onSuccess, arguments: [["state": 0]])
            callback.callbackSuccess(param: ["state": 0])
        }
    }

    private func peripheralForID(_ id: String) -> CBPeripheral? {
         if let scanHandler = scanHandler {
            if let peripheral = scanHandler.peripheralMap[id] {
                return peripheral
            }
        }
        return nil
    }

    deinit {
        _blueToothManager?.delegate = nil
        _blueToothManager?.stopScan()
    }
}

extension ConnectBluetoothDeviceHandler: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let id = peripheral.identifier.uuidString
        if toBeConnectedIDs.contains(id) {
//            self.api?.call(funcName: callBack, arguments: [["state": 1]])
            callback?.callbackSuccess(param: ["state": 1])
        }
        toBeConnectedIDs.remove(id)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier.uuidString
        if toBeConnectedIDs.contains(id) {
//            self.api?.call(funcName: callBack, arguments: [["state": 0]])
            callback?.callbackSuccess(param: ["state": 0])
        }
        toBeConnectedIDs.remove(id)
    }
}
