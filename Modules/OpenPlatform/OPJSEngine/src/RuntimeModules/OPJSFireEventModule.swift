//
//  OPJSFireEventModule.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/22.
//
// fireEvent module，提供native调用js的能力，提供给native的逻辑层/渲染层（publish的通道）等使用
import Foundation
import LKCommonsLogging
import LarkWebViewContainer
import LarkFeatureGating

public final class OPJSFireEventModule: NSObject, GeneralJSRuntimeModuleProtocol {

    static let logger = Logger.log(OPJSFireEventModule.self, category: "OPJSEngine")
    public weak var jsRuntime: GeneralJSRuntime?

    var fireEventQueue: OPSTLQueue = OPSTLQueue()

    private var _isFireEventReady: Bool = false
    // fire event 支持 array buffer 类型
    let enableBridgeFireEventArrayBuffer = LarkFeatureGating.shared.getFeatureBoolValue(for:"openplatfrom.bridge.fireeventarraybuffer.enable")

    // fire event 是否ready
    @objc public var isFireEventReady: Bool {
        get {
            return _isFireEventReady
        }
        set {
            if _isFireEventReady != newValue {
                _isFireEventReady = newValue
                if _isFireEventReady {
                    fireAllEventIfNeed()
                }
            }
        }
    }

    public override init() {
        super.init()
    }

    public func runtimeLoad() // js runtime初始化
    {
    }

    public func runtimeReady()
    {

    }

    // 使用方：BDPJSBridgeEngineProtocol & BDPEngineProtocol的bdp_fireEvent方法
    @objc public func fireEvent(_ event: String, data: [AnyHashable : Any]?, sourceID: Int,  useArrayBuffer: Bool) {
        guard let jsRuntime = self.jsRuntime else {
            Self.logger.error("fireEvent useArrayBuffer fail, jsRuntime is nil")
            return
        }
        guard let utils = OPJSEngineService.shared.utils else {
            Self.logger.error("fireEvent useArrayBuffer fail, utils is nil")
            return
        }
        if (utils.shouldUseNewBridge() && !jsRuntime.isSocketDebug) { // socket debug走的旧bridge
            
            var data = data
            if let encodeData = data as? NSDictionary {
                if !self.enableBridgeFireEventArrayBuffer { // 没有开启fg，就使用base64方式
                    data = encodeData.encodeNativeBuffersIfNeed()
                }
            }
            // 对齐旧worker，data为nil也可以fireEvent成功
            sendAsyncEventIfFireEventReady(event: event, params: data ?? [:], sourceID: sourceID)

            return
        }
        let fireEventInJSContext: (() -> Void) = { [weak self] in
            guard let `self` = self else {
                Self.logger.error("fireEvent useArrayBuffer fail, fireEventInJSContext fail, self is nil")
                return
            }
            guard let jsEngine = self.jsRuntime else {
                Self.logger.error("fireEvent useArrayBuffer fail, fireEventInJSContext fail, jsruntime is nil")
                return
            }

            if let enableAcceptAsyncCall = jsEngine.dispatchQueue?.enableAcceptAsyncCall, enableAcceptAsyncCall {
                var resData: Any?
                if useArrayBuffer {
                    if let data = data as? NSDictionary, let jsContext = jsEngine.jsContext {
                        let resValue = data.bdp_jsvalue(in: jsContext)
                        resData = resValue
                    } else if let data = data, self.jsRuntime?.runtimeType.isVMSDK() ?? false {
                        resData = data
                    }
                } else {
                    var dataJSONStr: String?
                    if let data = data as? NSDictionary, let dataDict = data.encodeNativeBuffersIfNeed() as? NSDictionary {
                        dataJSONStr = dataDict.jsonRepresentation()
                        if dataJSONStr?.count ?? 0 < 2 {
                            dataJSONStr = "{}"
                        }
                        resData = dataJSONStr
                    }
                }
                if let jsContext = jsEngine.jsContext {
                    let undefined = JSValue.init(undefinedIn: jsContext)
                    if sourceID == NSNotFound  {
                        self.fireEvent(arguments: [event, resData, undefined])
                    } else {
                        var webViewID: JSValue?
                        if let sourceIDConvert = Int32(exactly: sourceID) {
                            webViewID = JSValue.init(int32: sourceIDConvert, in: jsContext)
                        }
                        self.fireEvent(arguments: [event, resData, webViewID])
                    }
                } else if jsRuntime.runtimeType.isVMSDK() {
                    self.fireEvent(arguments: [event, resData, sourceID])
                }
            }
        }
        jsRuntime.dispatchQueue?.dispatchASync(fireEventInJSContext)
    }

    // 新bridge的处理
    /// 发送消息（OC调用请不要传入nil，一旦发现传入nil，需要负crash责任，revert代码，写case study，做复盘）对标- (void)fireEvent:(NSString *)event data:(NSDictionary *)data sourceID:(NSInteger)sourceID useArrayBuffer:(BOOL)arrayBufferMode
    func sendAsyncEventIfFireEventReady(event: String, params: [AnyHashable: Any], sourceID: Int) {

        let fireEventInJSContext = { [weak self] in
            guard let self = self else { return }
            guard let jsRuntime = self.jsRuntime else {
                return
            }

            guard let enableAcceptAsyncCall = jsRuntime.dispatchQueue?.enableAcceptAsyncCall, enableAcceptAsyncCall else { return }

            var extra = [AnyHashable: Any]()
            if sourceID != NSNotFound {
                extra["webviewId"] = sourceID
            }
            if self.isFireEventReady {
                if !self.fireEventQueue.empty() {
                    // 如果之前队列里面还有执行的event，这里必须要把新加入的event放到队尾，否则会有调用顺序问题，导致onAppLaunch合onAppEnterForeground回调前端的顺序问题
                    let e = [
                        "event": event,
                        "params": params
                    ] as [String : Any]
                    self.fireEventQueue.enqueue(e)
                    self.fireAllEventIfNeed()
                } else {
                    // 如果之前队列里面没有需要执行的event，则立刻执行就好
                    self.sendAsyncEvent(
                        event: event,
                        params: params,
                        extra: extra
                    )
                }
            } else {
                let e = [
                    "event": event,
                    "params": params,
                    "extra": extra
                ] as [String : Any]
                self.fireEventQueue.enqueue(e)
            }
        }
        self.jsRuntime?.dispatchQueue?.dispatchASync(fireEventInJSContext)
    }


    // 旧bridge处理
    func fireEvent(arguments: NSArray) {
        guard let jsRuntime = self.jsRuntime else {
            Self.logger.error("fireEventWithArguments fail, jsRuntime is nil")
            return
        }
        if arguments.count > 0 {
            if self.isFireEventReady {
                if !self.fireEventQueue.empty() {
                    // 如果之前队列里面还有执行的event，这里必须要把新加入的event放到队尾，否则会有调用顺序问题，导致onAppLaunch和onAppEnterForeground回调前端的顺序问题
                    self.fireEventQueue.enqueue(arguments)
                    self.fireAllEventIfNeed()
                } else {
                    if !jsRuntime.isSocketDebug {
                        jsRuntime.invokeJavaScriptModule(methodName: "subscribeHandler", moduleName: "ttJSBridge", params: arguments as? [Any])
                    } else {
                        if let arguments = arguments as? [Any] {
                            let message = jsRuntime.socketDebugModule.createMessage(arguments: arguments)
                            jsRuntime.socketDebugModule.sendMessage(message: message)
                        }
                    }
                }
            } else {
                self.fireEventQueue.enqueue(arguments)
            }
        }
    }

    // 清空发送js的事件队列
    func fireAllEventIfNeed() {
        self.jsRuntime?.dispatchQueue?.dispatchASync { [weak self] in
            guard let `self` = self else {
                Self.logger.error("worker fireAllEventIfNeed fail, self is nil")
                return
            }
            self.fireEventQueue.enumerateObjects { [weak self] (object, stop) in
                guard let `self` = self else {
                    Self.logger.error("worker fireAllEventIfNeed fail, enumerateObjects error, self is nil")
                    return
                }
                guard let jsRuntime = self.jsRuntime else {
                    return
                }
                if jsRuntime.isSocketDebug {
                    if let array = object as? [Any], !array.isEmpty {
                        let message = jsRuntime.socketDebugModule.createMessage(arguments: array)
                        jsRuntime.socketDebugModule.sendMessage(message: message)
                    }
                } else {
                    if let utils = OPJSEngineService.shared.utils, utils.shouldUseNewBridge() {
                        if let dic = object as? [AnyHashable: Any] {
                            let event = dic["event"] as? String ?? ""
                            let params = dic["params"] as? [AnyHashable: Any]
                            let extra = dic["extra"] as? [AnyHashable: Any]
                            self.sendAsyncEvent(event: event, params: params, extra: extra ?? [AnyHashable: Any]())
                        } else {
                            Self.logger.error("worker fire event error, event queue data invalid")
                        }
                    } else {
                        jsRuntime.invokeJavaScriptModule(methodName: "subscribeHandler", moduleName: "ttJSBridge", params: object as? [Any])
                    }
                }
            }
            self.fireEventQueue.clear()
        }
    }

    func sendAsyncEvent(event: String, params: [AnyHashable: Any]?, extra: [AnyHashable: Any]?) {
        if self.enableBridgeFireEventArrayBuffer {
            if let jsRuntime = self.jsRuntime {
                jsRuntime.invokeNativeCallback(callbackID: event, callbackType: "continued", data: params, extra: extra)
            } else {
                Self.logger.error("sendAsyncEvent failed, jsRuntime is nil, when call js module")
            }
        } else {
            let jsStr: String
            do {
                jsStr = try LarkWebViewBridge.buildCallBackJavaScriptString(
                    callbackID: event,
                    params: params ?? [AnyHashable: Any](),
                    extra: extra,
                    type: .continued
                )
            } catch {
                Self.logger.error("sendAsyncEvent failed, finalMap cannot trans to Data", error: error)
                return
            }
            jsRuntime?.evaluateScript(jsStr)
        }
    }

}
