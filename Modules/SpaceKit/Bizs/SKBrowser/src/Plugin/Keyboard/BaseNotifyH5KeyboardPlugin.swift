//
//  BaseNotifyH5KeyboardService.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/19.
//

import Foundation
import SKUIKit
import SKCommon
import SKFoundation
import LarkWebViewContainer
import SpaceInterface
import SKInfra

enum KeyboardScene {
    //小程序场景
    case editor
    //文档场景
    case docs(type: DocsType?)
}

protocol SKBaseNotifyH5KeyboardPluginProtocol: SKExecJSFuncService {}

public final class SimulateKeyboardInfo: SKKeyboardInfoProtocol, CustomStringConvertible {
    public static let key = "simulateKeyboard"
    public var height: CGFloat = 0
    public var isShow: Bool = false
    public var trigger: String = ""
    
    public init() {}
    
    public init(height: CGFloat, isShow: Bool, trigger: String) {
        self.height = height
        self.isShow = isShow
        self.trigger = trigger
    }
    
    public var description: String {
        return "isShow:\(isShow),height:\(height),trigger:\(trigger)"
    }
}

class SKBaseNotifyH5KeyboardPlugin: JSServiceHandler {
    var logPrefix: String = ""
    var scene: KeyboardScene
    var keyboardCallback: String?
    var keyboardNativeCallback: APICallbackProtocol?
    weak var pluginProtocol: SKBaseNotifyH5KeyboardPluginProtocol?
    private var prevShowStatus: Bool = false
    var handleServices: [DocsJSService] {
        return [.onKeyboardChanged, .simulateKeyboardChange]
    }

    private var throttle = SKThrottle(interval: 0.5)

    private var needFilterEvent: Bool {
        guard SKDisplay.pad, #available(iOS 17.0, *) else {
            return false
        }
        if case .docs(let type) = scene, type != .doc {
            return false
        }
        let currentVersion = UIDevice.current.systemVersion
        if let maxVersion = SettingConfig.ios17CompatibleConfig?.fixSmartKeyboardIssueVersion {
            //当前系统版本小于setting下发版本
            return currentVersion.compare(maxVersion, options: .numeric) == .orderedAscending
        }
        return false
    }
    
    init(scene: KeyboardScene) {
        self.scene = scene
    }

    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol? = nil) {
        if serviceName == DocsJSService.onKeyboardChanged.rawValue {
            keyboardNativeCallback = callback
        }
        handle(params: params, serviceName: serviceName)
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.onKeyboardChanged.rawValue:
            handleFrontKeyboard(params: params)
        case DocsJSService.simulateKeyboardChange.rawValue:
            handleSimulateKeyboard(params: params)
        default:
            ()
        }
    }

    private func handleSimulateKeyboard(params: [String: Any]) {
        guard let info = params[SimulateKeyboardInfo.key] as? SKKeyboardInfoProtocol else { return }
        onKeyboardInfoChange(info, fromSimulate: true)
    }

    private func handleFrontKeyboard(params: [String: Any]) {
        guard let callback = params["callback"] as? String else {
            skInfo(logPrefix + "callback 传空了")
            return
        }
        keyboardCallback = callback // 前端传过来的键盘回调事件
    }

    func onKeyboardInfoChange(_ info: SKKeyboardInfoProtocol, fromSimulate: Bool = false) {        
        let flag = info.isShow ? 1 : 0
        var params = [
            "isOpenKeyboard": flag,
            "innerHeight": info.height,
            "keyboardType": info.trigger
            ] as [String: Any]

        let jobId = "\(info.isShow)_\(info.trigger)_\(info.height)"

        //修复doc1.0以及小程序在iPadOS 17设备上使用外接键盘最小化工具栏无法弹出的问题
        //这个bug的原因是iPadOS17的妙控键盘在最小化的状态下，系统键盘事件通知缺失，键盘出现时没有收到任何事件
        //在没收到事件的情况下，代码逻辑认为键盘是隐藏状态，返回给前端的状态不对导致工具栏无法展示
        //解决方式是过滤掉不符合预期的回调
        if needFilterEvent {
            if fromSimulate, info.trigger == DocsKeyboardTrigger.editor.rawValue, !info.isShow, prevShowStatus == false {
                //keyboardChange来自代码模拟simulateKeyboardChange，trigger为editor，键盘状态为隐藏且上次回调时键盘状态也为隐藏的情况下，直接过滤掉
                return
            } else if !fromSimulate, !info.isShow {
                //由于系统键盘通知只剩下hide事件，每次hide事件的isOpenKeyboard、innerHeight和keyboardType都相同，前端的过滤逻辑会忽略掉这些相同事件导致工具栏无法隐藏掉
                //这里每次hide的高度增加一个小的随机值，可以绕过前端的过滤逻辑
                params["innerHeight"] = info.height + CGFloat.random(in: 0...0.1)
            }
            prevShowStatus = info.isShow
        }

        DocsLogger.info("KeyboardPlugin show: \(info.isShow) height:\(info.height) trigger:\(info.trigger) callback:\(keyboardCallback)", component: LogComponents.toolbar)

        if info.trigger == DocsKeyboardTrigger.blockEquation.rawValue ||
            info.trigger == DocsKeyboardTrigger.NOTShowToolBar.rawValue ||
            !info.isShow {
            //公式的话直接发出JS
            callFunction(params: params)
        } else {
            //非公式沿用旧逻辑
            throttle.schedule({ [weak self] in
                self?.callFunction(params: params)
            }, jobId: jobId)
        }
//        print("gracotest: 系统分发 show:\(info.isShow) height:\(info.height) trigger:\(info.trigger) \(NSDate().timeIntervalSince1970)")
    }

    func callFunction(params: [String: Any]) {
        if let callback = self.keyboardCallback {
            pluginProtocol?.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
        } else {
            keyboardNativeCallback?.callbackSuccess(param: params, extra: ["bizDomain": "ccm"])
        }
    }
}
