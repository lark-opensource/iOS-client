//
//  OpenBasePlugin+Extension.swift
//  LarkOpenPluginManager
//
//  Created by baojianjun on 2023/6/2.
//

import Foundation

public struct OpenAPIRegisterInfo<PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> {
    public let pluginType: PluginType.Type
    public let paramsType: Param.Type
    public let resultType: Result.Type
    
    public init(pluginType: PluginType.Type, paramsType: Param.Type = Param.self, resultType: Result.Type = Result.self) {
        self.pluginType = pluginType
        self.paramsType = paramsType
        self.resultType = resultType
    }
}

public struct OpenAPIExtensionInfo<Extension: OpenBaseExtension> {
    // extension的基类类型
    public let type: Extension.Type
    // 是否允许使用默认实现
    // true: 如果容器注入了对应实现, 使用对应实现; 否则使用默认实现
    // false: 如果容器注入了对应实现, 使用对应实现; 否则API调用抛错
    public let defaultCanBeUsed: Bool
    
    public init(type: Extension.Type, defaultCanBeUsed: Bool) {
        self.type = type
        self.defaultCanBeUsed = defaultCanBeUsed
    }
}

// MARK: - async instance extension register
public extension OpenBasePlugin {

    typealias AsyncExtensionHandler<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult, Extension: OpenBaseExtension> = (
        _ params: Param,
        _ context: OpenAPIContext,
        _ extension: Extension,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void

    /**
     异步|实例方法, 出入参指定, 需要容器特定扩展

     使用方式:

     ```
     registerAsync(
         for: "\(APIName)",
         registerInfo: .init(
             pluginType: Self.self,
             paramsType: OpenPlugin"\(APIName)"Request.self,  /* 省略则用OpenAPIBaseParams */
             resultType: OpenPlugin"\(APIName)"Response.self  /* 省略则用OpenAPIBaseResult */
         ), extensionInfo: .init(
             type: OpenAPI"\(APIName)"Extension.self,
             defaultCanBeUsed: \(true or false))) { Self."\(APIName)"($0) }
     ```

     方法名声明:

     ```
     func \(FuntionName)(
        params: \(ParamsName),
        context: OpenAPIContext,
        apiExtension: \(ExtensionName),
        callback: @escaping (OpenAPIBaseResponse<\(ResultName)>) -> Void
     ```
     */
    func registerAsync<PluginType, Param, Result, Extension>(
        for apiName: String,
        registerInfo: OpenAPIRegisterInfo<PluginType, Param, Result>,
        extensionInfo: OpenAPIExtensionInfo<Extension>,
        handler: @escaping (
            _ this: PluginType
        ) -> AsyncExtensionHandler<Param, Result, Extension>
    ) where PluginType: OpenBasePlugin,
            Param: OpenAPIBaseParams,
            Result: OpenAPIBaseResult,
            Extension: OpenBaseExtension
    {
        registerInstanceAsyncHandler(for: apiName, pluginType: registerInfo.pluginType, paramsType: registerInfo.paramsType, resultType: registerInfo.resultType) { this, params, context, callback in
            
            guard let extensionResolver = this.extensionResolver else {
                throw OpenAPIError.noResolver(apiName, context)
            }
            
            let extensionImpl = try extensionResolver.resolve(with: extensionInfo, context: context)
            try handler(this)(params, context, extensionImpl, callback)
        }
    }
    
    // MARK: 无 params注册接口
    typealias AsyncExtensionHandlerNoParams<Result: OpenAPIBaseResult, Extension: OpenBaseExtension> = (
        _ context: OpenAPIContext,
        _ extension: Extension,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void
    
    /**
     异步|实例方法, 出入参指定, 需要容器特定扩展

     使用方式:

     ```
     registerAsync(
         for: "\(APIName)",
         registerInfo: .init(
             pluginType: Self.self,
             resultType: OpenPlugin"\(APIName)"Response.self /* 省略则用OpenAPIBaseResult */
         ), extensionInfo: .init(
             type: OpenAPI"\(APIName)"Extension.self,
             defaultCanBeUsed: \(true or false))) { Self."\(APIName)"($0) }
     ```

     方法名声明:

     ```
     func \(FuntionName)(
        context: OpenAPIContext,
        apiExtension: \(ExtensionName),
        callback: @escaping (OpenAPIBaseResponse<\(ResultName)>) -> Void
     ```
     */
    func registerAsync<PluginType, Result, Extension>(
       for apiName: String,
       registerInfo: OpenAPIRegisterInfo<PluginType, OpenAPIBaseParams, Result>,
       extensionInfo: OpenAPIExtensionInfo<Extension>,
       handler: @escaping (
           _ this: PluginType
       ) -> AsyncExtensionHandlerNoParams<Result, Extension>
    ) where PluginType: OpenBasePlugin,
           Result: OpenAPIBaseResult,
           Extension: OpenBaseExtension
    {
       registerInstanceAsyncHandler(for: apiName, pluginType: registerInfo.pluginType, paramsType: registerInfo.paramsType, resultType: registerInfo.resultType) { this, _, context, callback in
           
           guard let extensionResolver = this.extensionResolver else {
               throw OpenAPIError.noResolver(apiName, context)
           }
           
           let extensionImpl = try extensionResolver.resolve(with: extensionInfo, context: context)
           try handler(this)(context, extensionImpl, callback)
       }
    }
}

// MARK: - sync instance extension register
extension OpenBasePlugin {

    public typealias SyncExtensionHandler<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult, Extension: OpenBaseExtension> = (
        _ params: Param,
        _ context: OpenAPIContext,
        _ extension: Extension
    ) throws -> OpenAPIBaseResponse<Result>

    /**
     同步|实例方法, 出入参指定, 需要容器特定扩展

     使用方式:

     ```
     registerSync(
         for: "\(APIName)",
         registerInfo: .init(
             pluginType: Self.self,
             paramsType: OpenPlugin"\(APIName)"Request.self,
             resultType: OpenPlugin"\(APIName)"Response.self
         ), extensionInfo: .init(
             type: OpenAPI"\(APIName)"Extension.self,
             defaultCanBeUsed: \(true))) { Self."\(APIName)"($0) }
     ```

     方法名声明:

     ```
     func \(FuntionName)(
        params: \(ParamsName),
        context: OpenAPIContext,
        extension: \(ExtensionName)
     ) -> OpenAPIBaseResponse<\(ResultName)>
     ```
     */
    public func registerSync<PluginType, Param, Result, Extension>(
        for apiName: String,
        registerInfo: OpenAPIRegisterInfo<PluginType, Param, Result>,
        extensionInfo: OpenAPIExtensionInfo<Extension>,
        handler: @escaping (
            _ this: PluginType
        ) -> SyncExtensionHandler<Param, Result, Extension>
    ) where PluginType: OpenBasePlugin,
            Param: OpenAPIBaseParams,
            Result: OpenAPIBaseResult,
            Extension: OpenBaseExtension
    {
        registerInstanceSyncHandler(for: apiName, pluginType: registerInfo.pluginType, paramsType: registerInfo.paramsType, resultType: registerInfo.resultType) {
            (this, params, context) -> OpenAPIBaseResponse<Result> in
            
            guard let extensionResolver = this.extensionResolver else {
                throw OpenAPIError.noResolver(apiName, context)
            }
            
            let extensionImpl = try extensionResolver.resolve(with: extensionInfo, context: context)
            return try handler(this)(params, context, extensionImpl)
        }
    }
}

fileprivate extension OpenAPIError {
    static func noResolver(_ apiName: String, _ context: OpenAPIContext) -> OpenAPIError {
        let message = "Plugin: resolver is nil When call \(apiName) API"
        context.apiTrace.error(message)
        return OpenAPIError(errno: OpenAPICommonErrno.internalError)
            .setMonitorMessage(message)
    }
}

fileprivate extension ExtensionResolver {
    func resolve<Extension>(with info: OpenAPIExtensionInfo<Extension>, context: OpenAPIContext) throws -> Extension {
        guard info.defaultCanBeUsed else {
            return try resolve(info.type, arguments: context)
        }
        
        guard let result = try? resolve(info.type, arguments: context) else {
            return try info.type.init(extensionResolver: self, context: context)
        }
        
        return result
    }
}
