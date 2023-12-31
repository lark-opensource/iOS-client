//
//  CallBackForWebAppEngineNewBridgeProtocol.swift
//  Timor
//
//  Created by 新竹路车神 on 2020/11/11.
//

import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import ECOProbe

private let log = Logger.oplog(CallBackForWebAppEngineNewBridgeProtocol.self)

// 该文件唯一作用是兼容OC
@objcMembers
public final class CallBackForWebAppEngineNewBridgeProtocol: NSObject {
    /// 新协议回调统一方法
    public static func callbackString(with params: [AnyHashable: Any], callbackID: String, type: BDPJSBridgeCallBackType) -> String {
        do {
            return try LarkWebViewBridge.buildCallBackJavaScriptString(
                callbackID: callbackID,
                params: params,
                extra: ["bizDomain" : "open_platform"], // 用于识别业务域，区别editor code from yiying
                type: buildTypeString(with: type)
            )
        } catch {
            log.error("build callbackString error", error: error)
            return "" // 避免evaluate一个nil，导致崩溃，打个补丁
        }
        
    }
    /// 通过BDPJSBridgeCallBackType转换为新协议所需的callbackType字符串
    private static func buildTypeString(with type: BDPJSBridgeCallBackType) -> CallBackType {
        switch type {
        //  新协议只有这三种
        case .success:
            return .success
        case .failed:
            return .failure
        case .userCancel:
            return .cancel
        case .continued:
            return .continued
        //  原先的其他情况收敛为 failure
        default:
            return .failure
        }
    }
}
