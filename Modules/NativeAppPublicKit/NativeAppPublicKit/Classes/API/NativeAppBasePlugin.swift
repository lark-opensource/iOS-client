//
//  NativeAppBasePlugin.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/9.
//

import Foundation

@objcMembers
open class NativeAppBasePlugin: NSObject {
    
    /// 端集成API插件上下文环境,生命周期和插件生命周期保持一致
    public var pluginContext : NativeAppPluginContextProtocol?  = nil {
        didSet {
            self.onPluginContextBind(context: self.pluginContext)
        }
    }
    
    ///异步

    public typealias AsyncHandler = (
        _ params: NativeAppAPIBaseParams,
        _ callback: @escaping (NativeAppAPIBaseResult) -> Void
    ) -> Void
    public var asyncHandlers: [String: AsyncHandler] = [:]
    
    ///同步
    public typealias SyncHandler = (
        _ params: NativeAppAPIBaseParams
    ) -> NativeAppAPIBaseResult
    public var syncHandlers: [String: SyncHandler] = [:]
    
    required public override init() {
        super.init()
    }
    
    /**
     绑定api插件上下文环境,通过getPlugin获取到插件后会立即绑定当前调用上下文环境。此函数目前为空实现，如果有需要，子类继承后可重写此方法监听上下文绑定事件。
     
     - Parameter context: 端集成api 插件上下文环境
     */
    open func onPluginContextBind(context: NativeAppPluginContextProtocol?) {
        
    }
    /**
     异步调用三方API

     - Parameters:
       - apiName: API名
       - params: 入参
       - callback: 回调：成功时会带上具体返回数据，失败时会带上
     */
    public func asyncHandle<Param>(
        apiName: String,
        params: Param,
        callback: @escaping (NativeAppAPIBaseResult) -> Void
    ) throws where Param:NativeAppAPIBaseParams {
        if let handler = asyncHandlers[apiName] {
            try handler(params, callback)
        } else if let handler = syncHandlers[apiName] {
            callback(try handler(params))
        } else {
            let data = ["error": "can not find handler for async call api \(apiName)"]
            let result = NativeAppAPIBaseResult(resultType: .fail, data: data)
            callback(result)
        }
    }
    
    /**
     同步调用三方API

     - Parameters:
       - apiName: API名
       - params: 入参
       - callback: 回调：成功时会带上具体返回数据，失败时会带上
     */
    public func syncHandle<Param>(
        apiName: String,
        params: Param
    ) throws -> NativeAppAPIBaseResult where Param: NativeAppAPIBaseParams {
        guard let handler = syncHandlers[apiName] else {
            return NativeAppAPIBaseResult(resultType: .fail, data: ["error": "can not find handler for async call api \(apiName)"])
        }
        return try handler(params)
    }
}

extension NativeAppBasePlugin {
    @objc
    public func registerAsyncHandler(
        for apiName: String,
        handler: @escaping AsyncHandler
    ) {
        assert(!syncHandlers.keys.contains(apiName), "一个 API 在 Plugin 只允许注册一次，请检查你是否重复注册或者 API 名称冲突。")
        let wrappedHandler: AsyncHandler = { params, callback in
            handler(params, { response in
                callback(response)
            })
        }
        asyncHandlers[apiName] = wrappedHandler
    }
}
