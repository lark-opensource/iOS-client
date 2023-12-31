//
//  LKNativeAppAPIExternal.swift
//  LKNativeAppAPIExternal
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation
#if canImport(NativeAppPublicKit)
import NativeAppPublicKit
#endif

@objc
public protocol KANativeAppPluginDelegate: AnyObject {
    /// 返回 Plugin 唯一的名字，用于后续的注册与调用
    /// - Returns: Plugin 名字
    func getPluginName() -> String
    /// 支持的 api name list
    /// - Returns: api list
    func getPluginApiNames() -> [String]
    /// 事件处理方法
    /// - Parameters:
    ///   - event: H5/web 传回的 api name 和参数
    ///   - callback: 回调给 H5 的值
    func handle(event: KANativeAppAPIEvent, callback: @escaping (Bool, [String: Any]?) -> Void)
    /// 获取上下文，来对 js 进行持续 callback
    /// - Parameter context: 上下文对象
#if canImport(NativeAppPublicKit)
    func setContext(context: NativeAppPluginContextProtocol)
#endif
}
#if canImport(NativeAppPublicKit)
extension KANativeAppPluginDelegate {
    func setContext(context: NativeAppPluginContextProtocol) {
      
    }
}
#endif

@objcMembers
public class KANativeAppAPIEvent: NSObject {
    public var params: [String: Any]?
    public var name: NSString = ""
}

@objcMembers
public class KANativeAppAPIExternal: NSObject {
    public override init() {
        super.init()
#if canImport(NativeAppPublicKit)
        NativeAppConnectManager.shared.setupAPIManager(manager: wrapper)
#endif
    }
    public static let shared = KANativeAppAPIExternal()
#if canImport(NativeAppPublicKit)
    public var wrapper: NativeAppApiConfigWrapper = NativeAppApiConfigWrapper()
#endif
    public var delegate: KANativeAppPluginDelegate? {
        didSet {
#if canImport(NativeAppPublicKit)
            if let temp = delegate {
                wrapper.delegates.append(temp)
            }
#endif
        }
    }
}
