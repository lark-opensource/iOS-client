//
//  OpenBasePlugin.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/2/1.
//

import Foundation
import ECOProbe
import LarkContainer
import ECOInfra

@objcMembers
open class OpenBasePlugin: NSObject, UserResolverWrapper {
    
    public let userResolver: UserResolver

    public typealias SyncHandler<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ params: Param,
        _ context: OpenAPIContext
    ) throws -> OpenAPIBaseResponse<Result>
    
    public typealias SyncHandlerInstance<PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ this: PluginType,
        _ params: Param,
        _ context: OpenAPIContext
    ) throws -> OpenAPIBaseResponse<Result>
    
    public typealias AsyncHandler<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ params: Param,
        _ context: OpenAPIContext,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void
    
    public typealias AsyncHandlerInstance<PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ this: PluginType,
        _ params: Param,
        _ context: OpenAPIContext,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void

    private typealias SyncHandlerWrapper = SyncHandler<OpenAPIBaseParams, OpenAPIBaseResult>
    private typealias AsyncHandlerWrapper = AsyncHandler<OpenAPIBaseParams, OpenAPIBaseResult>

    // 缓存注册的APIHandler，内部实现出入参父子类转换，在init的时候设置，所以不加锁了
    private var syncHandlers: [String: SyncHandlerWrapper] = [:]
    private var asyncHandlers: [String: AsyncHandlerWrapper] = [:]
    // 多播事件管理器
    private let eventManager = OpenEventManager()
    // extension注册者
    public weak var extensionResolver: ExtensionResolver?

    /// 进入后台
    open func onBackground() {}
    
    /// 进入前台
    open func onForeground() {}

    
    /// 处理异步api，派发到具体的apihandler实现
    ///
    /// 注意：
    /// * 既可以直接调用注册的异步 API，也可以以异步方式调用同步 API
    ///
    /// - Parameters:
    ///   - apiName: 接口名
    ///   - params: 入参
    ///   - context: 整个pm调度过程中的context
    ///   - callback: 回调：成功时会带上具体返回数据，失败时会带上
    public func asyncHandle<Param>(
        apiName: String,
        params: Param,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) throws where Param:OpenAPIBaseParams {
        if let handler = asyncHandlers[apiName] {
            context.apiTrace.info("async call api \(apiName) by async handler")
            try handler(params, context, callback)
        } else if let handler = syncHandlers[apiName] {
            context.apiTrace.info("async call sync api \(apiName) by sync handler")
            callback(try handler(params, context))
        } else {
            context.apiTrace.error("can not find handler for async call api \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("can not find handler for async call api \(apiName)")
            callback(.failure(error: error))
        }
    }

    /// 处理同步api，派发到具体的apihandler实现
    /// - Parameters:
    ///   - apiName: 接口名
    ///   - params: 入参
    ///   - context: 整个pm调度过程中的context
    /// - Returns: 调用结果：成功时会带上具体返回数据，失败时会带上错误信息
    public func syncHandle<Param>(
        apiName: String,
        params: Param,
        context: OpenAPIContext
    ) throws -> OpenAPIBaseResponse<OpenAPIBaseResult> where Param: OpenAPIBaseParams {
        guard let handler = syncHandlers[apiName] else {
            context.apiTrace.error("can not find syncHandler for api \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("can not find syncHandler for api \(apiName)")
            return .failure(error: error)
        }
        context.apiTrace.info("sync call api \(apiName) by sync handler")
        return try handler(params, context)
    }

    /// 派发多播事件
    /// - Parameters:
    ///   - apiName: 接口名
    ///   - params: 入参
    ///   - context: 整个pm调度过程中的context
    /// - Returns: 调用结果：成功时会带上具体返回数据，失败时会带上错误信息
    public func postEvent<Param, Result>(
        apiName: String,
        params: Param,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        try eventManager.post(event: apiName, data: params, apiContext: context) { data in
            callback(.success(data: data))
        } errorHanlder: { error in
            callback(.failure(error: error))
        }
    }
    
    required public init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init()
    }
}

// MARK: - Async Register
extension OpenBasePlugin {
    public func registerInstanceAsyncHandler<PluginType, Param, Result>(
        for apiName: String,
        pluginType: PluginType.Type = PluginType.self,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping AsyncHandlerInstance<PluginType, Param, Result>
    ) where PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        registerAsyncHandler(for: apiName, paramsType: paramsType, resultType: resultType) { [weak self] params, context, callback in
            guard let self = self as? PluginType else {
                let message = "Plugin: self is nil When call \(apiName) API"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(message)
                    .setErrno(OpenAPICommonErrno.unknown)
                context.apiTrace.error(message)
                callback(.failure(error: error))
                return
            }
            try handler(self, params, context, callback)
        }
    }
    
    public func registerAsyncHandler<Param, Result>(
        for apiName: String,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping AsyncHandler<Param, Result>
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        assert(!syncHandlers.keys.contains(apiName), "一个 API 在 Plugin 只允许注册一次，请检查你是否重复注册或者 API 名称冲突。")
        let wrappedHandler: AsyncHandlerWrapper = { params, context, callback in
            let response = params.isParam(paramsType, apiName, context)
            switch response {
            case let .success(realParam):
                try handler(realParam, context, {
                    callback($0.downcast)
                })
            case let .failure(error):
                callback(.failure(error: error))
            }
        }
        asyncHandlers[apiName] = wrappedHandler
    }
}

// MARK: - Sync Register
extension OpenBasePlugin {
    public func registerInstanceSyncHandler<PluginType, Param, Result>(
        for apiName: String,
        pluginType: PluginType.Type = PluginType.self,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping SyncHandlerInstance<PluginType, Param, Result>
    ) where PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        registerSyncHandler(for: apiName, paramsType: paramsType, resultType: resultType) { [weak self] params, context in
            guard let self = self as? PluginType else {
                let message = "Plugin: self is nil When call \(apiName) API"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(message)
                    .setErrno(OpenAPICommonErrno.unknown)
                context.apiTrace.error(message)
                return .failure(error: error)
            }
            return try handler(self, params, context)
        }
    }
    
    public func registerSyncHandler<Param, Result>(
        for apiName: String,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping SyncHandler<Param, Result>
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        assert(!syncHandlers.keys.contains(apiName), "一个 API 在 Plugin 只允许注册一次，请检查你是否重复注册或者 API 名称冲突。")
        let wrappedHandler: SyncHandlerWrapper = { params, context in
            let response = params.isParam(paramsType, apiName, context)
            switch response {
            case let .success(realParam):
                return try handler(realParam, context).downcast
            case let .failure(error):
                return .failure(error: error)
            }
        }
        syncHandlers[apiName] = wrappedHandler
    }
}

// MARK: - Event Register & Post
extension OpenBasePlugin {

    public func registerEvent<Result>(
        event: String,
        handler: @escaping AsyncHandler<OpenAPIBaseParams, Result>
    ) where Result: OpenAPIBaseResult {
        registerEvent(event: event, paramsType: OpenAPIBaseParams.self, handler: handler)
    }

    // 多播消息注册
    public func registerEvent<Param, Result>(
        event: String,
        paramsType: Param.Type,
        handler: @escaping AsyncHandler<Param, Result>
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        let transformHandler: AsyncHandler<OpenAPIBaseParams, Result> = { params, context, callback in
            let response = params.isParam(paramsType, event, context)
            switch response {
            case .success(let realParams):
                try handler(realParams, context, callback)
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        let eventHandler = OpenEventManagerHandler(handleWork: transformHandler)
        eventManager.register(event: event, handler: eventHandler)
    }

    // 支持的多播事件
    open class func supportEvents() -> [Any] {
        return []
    }
}

fileprivate extension OpenAPIBaseResponse {
    var downcast: OpenAPIBaseResponse<OpenAPIBaseResult> {
        switch self {
        case let .failure(error):
            return .failure(error: error)
        case let .success(data):
            return .success(data: data)
        case let .continue(event: event, data: data):
            return .continue(event: event, data: data)
        }
    }
}

fileprivate extension OpenAPIBaseParams {
    func isParam<Param>(_ paramsType: Param.Type, _ apiName: String, _ context: OpenAPIContext) -> Result<Param, OpenAPIError> {
        guard let realParam = self as? Param else {
            context.apiTrace.error("can not convert \(self.self) to \(paramsType) for api \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: "params class")))
                .setMonitorMessage("can not convert \(self.self) to \(paramsType) for api \(apiName)")
            return .failure(error)
        }
        return .success(realParam)
    }
}
