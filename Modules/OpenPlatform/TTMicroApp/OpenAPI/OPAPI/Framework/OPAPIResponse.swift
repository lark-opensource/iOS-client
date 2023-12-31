//
//  OPAPIResponse.swift
//  Timor
//
//  Created by yinyuan on 2020/9/9.
//

import Foundation
import LarkOPInterface

/// API Callback
public typealias OPAPICallback = ((_ code: Int, _ data: [AnyHashable: Any]) -> Void)
public typealias OPAPICode = Int

/// OPAPIResponse 基类，目前需要兼容 OC，不能完美使用 Codeable 能力，所以使用了 JSONModel
@objcMembers public final class OPAPIResponse: OPAPIModel {
    
    /// 返回码
    public private(set) var errCode = OPGeneralAPICode.unkonwError.rawValue
    
    /// 兼容旧代码，强制指定自定义的 msg
    public var errMsg: String?
    
    /// 兼容旧代码，强制指定自定义的返回数据
    public var data: [AnyHashable: Any]?
    
    /// Response Callback
    fileprivate var callback: OPAPICallback
    
    /// 是否已经回调
    private var callbackInvoked = false;
    
    public required init(callback: @escaping OPAPICallback) {
        self.callback = callback
        super.init()
    }
    
    /// 兼容旧代码的写法，后续全量替换后删除
    public required init(
        jsBridgeCallback: BDPJSBridgeCallback?,
        logger: OPContextLogger?,
        funcName: String?) {
        
        // 自动设置日志 Tag 为 API Name
//        logger?.tag = OPAPIResponse.parseAPINameFromFunctionName(funcName: funcName)
        
        self.callback = { (code, data) in
            
            // 增加统一兜底日志
            if code == OPGeneralAPICode.ok.rawValue {
                logger?.logDebug(message: "api callback \(code)")
            } else if code == OPGeneralAPICode.cancel.rawValue {
                logger?.logWarn(message: "api callback \(code)")
            } else {
                logger?.logError(message: "api callback \(code)")
            }
            
            if let jsBridgeCallback = jsBridgeCallback {
                //BDPApiCode2CallBackType 对 errCode 进行转义
                //先转成原来的errCode，待灰度后需去掉 BDPApiCode2CallBackType 的转换
                jsBridgeCallback(BDPApiCode2CallBackType(code), data)
            } else {
                OPAssertionFailureWithLog("\(funcName) jsBridgeCallback should not be nil")
            }
        }
        super.init()
    }
    
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal required init(data: Data!) throws {
        fatalError("init(data:) has not been implemented")
    }
    
    internal required init(dictionary dict: [AnyHashable : Any]!) throws {
        fatalError("init(dictionary:) has not been implemented")
    }
    
    /// 自定义对 errCode 的 JSON 处理
    func JSONObjectForErrCode() -> NSNumber? {
        return NSNumber(value: errCode)
    }
    
    deinit {
        if !self.callbackInvoked {
            // OPAPIResponse 已释放但是没有被回调，说明存在调用黑洞
//            OPAssertionFailureWithLog("you may forget to invoke the callback for the api, please check the logic right now.")
            // 兜底 callback, 系统内部错误
//            callback(OPGeneralAPICode.unkonwError.rawValue)
        }
    }
    
    /// 禁用一些属性解析 JSON
    public override class func propertyIsIgnored(_ propertyName: String!) -> Bool {
        if ["callback", "logger", "data", "callbackInvoked"].contains(propertyName) {
            return true
        }
        return false
    }
    
    /// 兼容现有逻辑，检查参数合法性
    public func checkParamValidAndCallbackIfNeeded(_ paramDic: [AnyHashable: Any]?, paramArr: [Any]?) -> Bool {
        return BDPPluginBase.isParamValid({ (type, params) in
            self.data = params
            self.callback(OPGeneralAPICode.param.rawValue)
        }, paramDic: paramDic, paramArr: paramArr)
    }
}

extension OPAPIResponse {
    
    /// 指定回调 code
    public func callback(_ code: Int) {
        assert(!self.callbackInvoked, "Do not callback repeatedly")
        
        self.callbackInvoked = true;
        
        self.errCode = code
        
        if var data = self.data {
            // 直接设置data，兼容历史逻辑，新API不允许再使用该逻辑
            return callback(code, data)
        } else {
            do {
                var data: [AnyHashable: Any] = [:]
                //保持 errMsg 兼容，若存在原始 errMsg，优先使用
                // APICode 统一后需要使用统一的 errMsg
                if let errMsg = self.errMsg {
                    data["errMsg"] = errMsg
                }
                return callback(code, data)
//                if let data = data as? [AnyHashable: Any] {
//                    return callback(code, data)
//                } else {
//                    // 内部错误：出参不合法
//                    BDPLogError(tag: .apiBridge, "response data invalid")
//                    return callback(OPGeneralAPICode.unkonwError.rawValue, [:])
//                }
            } catch {
                // 内部错误：出参不合法
                BDPLogError(tag: .apiBridge, "parse response failed, \(error.localizedDescription)")
                return callback(OPGeneralAPICode.param.rawValue, [:])
            }
        }
    }
    
    //通过 BDPAuthorizationPermissionResult 动态触发回调
    @objc
    public func callbackWithPermissionResult(result: BDPAuthorizationPermissionResult)  {
        switch result {
        case .enabled:
            callback(OPGeneralAPICode.ok.rawValue)
        case .systemDisabled:
            callback(OPGeneralAPICode.systemAuthDeny.rawValue)
        case .userDisabled:
            callback(OPGeneralAPICode.userAuthDenied.rawValue)
        case .platformDisabled:
            callback(OPGeneralAPICode.unkonwError.rawValue)
        case .invalidScope:
            callback(OPGeneralAPICode.unkonwError.rawValue)
        }
    }
    
    public func callbackWithErrno(_ errNo: Int, errString: String, legacyErrorCode: Int) {
        if data == nil {
            data = [:]
        }
        data?["errno"] = errNo
        data?["errString"] = errString
        callback(legacyErrorCode)
    }
    
    /// 从函数名中解析APIName，仅用于支持现有API快速转为OPAPIResponse，后续删除
    private static func parseAPINameFromFunctionName(funcName: String?) -> String? {
        guard let funcName = funcName else {
            OPAssertionFailureWithLog("the api funcName should not be nil.")
            return nil
        }
        // 形如 [TMAPluginTracker systemLogWithParam:callback:engine:controller:] 或者 [TMAPluginTracker monitorReportWithParam:callback:context:]
        if let beginRange = funcName.range(of: " "), let endRange = funcName.range(of: "WithParam:") {
            let apiName = funcName[beginRange.upperBound ..< endRange.lowerBound]
            return String(apiName)
        }
        OPAssertionFailureWithLog("the api funcName has changed pattern, please fix this logic.")
        return nil
    }
}
