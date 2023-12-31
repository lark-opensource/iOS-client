//
//  GetBluetoothDeviceStateHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//
import CoreBluetooth
import LKCommonsLogging
import WebBrowser

enum BlueToothState: Int {
    case Unknown
    case Open
    case Close
    case UnSupported
}

class GetBluetoothDeviceStateHandler: NSObject, JsAPIHandler {
    private weak var api: WebBrowser?
    private var bluetoothState: BlueToothState?

    lazy var blueToothManager: CBCentralManager = {
        let manager = CBCentralManager()
        _blueToothManager = manager
        return manager
    }()
    private var _blueToothManager: CBCentralManager?

    private var callBack: WorkaroundAPICallBack?

    static let logger = Logger.log(GetBluetoothDeviceStateHandler.self, category: "Module.JSSDK")

    init(api: WebBrowser) {
        self.api = api
        super.init()
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
//        guard let onSuccess = args["callback"] as? String  else {
//            GetBluetoothDeviceStateHandler.logger.error("参数有误")
//            return
//        }
        self.callBack = callback
        blueToothManager.delegate = self

        if let state = bluetoothState {
            //如果有旧的状态，则直接返回旧的状态
//            api.call(funcName: onSuccess, arguments: [["state": state.rawValue]])
            callback.callbackSuccess(param: ["state": state.rawValue])
            callBack = nil
        }
    }

    deinit {
        _blueToothManager?.stopScan()
        _blueToothManager?.delegate = nil
    }
}

extension GetBluetoothDeviceStateHandler: CBCentralManagerDelegate {
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
        default:
            break
        }

        if bluetoothState == nil, let callBack = callBack {
            //对于第一次update，需要等centralManagerDidUpdateState执行了再回调状态
//            self.api?.call(funcName: callBack, arguments: [["state": state.rawValue]])
            callBack.callbackSuccess(param: ["state": state.rawValue])
            self.callBack = nil
        }
        bluetoothState = state
    }
}
