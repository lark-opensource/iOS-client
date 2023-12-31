//
//  OpenEventManager.swift
//  LarkOpenPluginManager
//
//  Created by yi on 2021/7/18.
//

import Foundation
import LKCommonsLogging
import ECOProbe

// 消息处理
final class OpenEventManagerHandler<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult>: NSObject {
    fileprivate var handleWork: OpenBasePlugin.AsyncHandler<Param, Result>

    required init(handleWork: @escaping OpenBasePlugin.AsyncHandler<Param, Result>) {
        self.handleWork = handleWork
    }

    let logger = Logger.log(OpenEventManagerHandler.self, category: "OpenPlatform")

    func handle(
        event: String,
        data: Param,
        apiContext: OpenAPIContext,
        successHandler: @escaping OpenEventManagerSuccessHandler<Result>,
        errorHandler: @escaping OpenEventManagerErrorHandler
    ) throws {
        let callback: (OpenAPIBaseResponse<Result>) -> Void = { response in
            switch response {
            case let .success(data: data):
                successHandler(data)
            case let .failure(error: error):
                errorHandler(error)
            default:
                errorHandler(
                    OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                )
            }
        }
        try handleWork(data, apiContext, callback)
    }
}

typealias OpenEventManagerErrorHandler = (_ error: OpenAPIError) -> Void

typealias OpenEventManagerSuccessHandler<Result: OpenAPIBaseResult> = (Result?) -> Void

typealias OpenEvent = String

// 多播事件管理
final class OpenEventManager {

    private typealias HandlerKey = String
    private typealias Handler = (
        _ event: OpenEvent,
        _ context: Any?,
        _ apiContext: OpenAPIContext,
        _ successHandler: @escaping OpenEventManagerSuccessHandler<OpenAPIBaseResult>,
        _ errorHanlder: @escaping OpenEventManagerErrorHandler
    ) throws -> Void

    private var handlers: [HandlerKey: [Handler]] = [:]

    static let logger = Logger.log(OpenEventManager.self, category: "OpenPlatform.EventManager")

    // 发送多播消息
    func post<Result: OpenAPIBaseResult>(
        event: OpenEvent,
        data: Any? = nil,
        apiContext: OpenAPIContext,
        successHandler: @escaping OpenEventManagerSuccessHandler<Result>,
        errorHanlder: @escaping OpenEventManagerErrorHandler
    ) throws {
        let key = event
        let items = handlers[key] ?? []

        if items.isEmpty {
            OpenEventManager.logger.error("EventManager: error no handler for event: [\(event)]")
            errorHanlder(
                OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
            )
        } else {
            items.forEach {
                /// 多播需要保证部分失败，其他 event 还要发出去，因此在此处统一 catch，非框架预期的 error 使用 callback 跑抛出。
                /// 后续需要考虑的事情:
                /// 1. 多播的 callback 方式，是每个单独 callback, 还是聚合后 callback
                /// 2. 单独 callback 是否有生命周期冲突的问题
                do {
                    try $0(event, data, apiContext, { result in
                        OpenEventManager.logger.info("EventManager: handled event with sucess: [\(event)]")
                        successHandler(result as? Result)
                    }, { err in
                        OpenEventManager.logger.error("EventManager: handled event with error: [\(event)] \(err)")
                        errorHanlder(err)
                    })
                } catch {
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknownException)
                        .setErrno(OpenAPICommonErrno.unhandledException)
                        .setError(error)
                    errorHanlder(apiError)
                }
            }
        }
    }

    // 注册多播消息
    func register<Param: OpenAPIBaseParams, Result: OpenAPIBaseResult>(
        event: OpenEvent,
        handler: OpenEventManagerHandler<Param, Result>
    ) {

        let handlerWrapper: Handler = { event, data, apiContext, successHandler, errorHandler in
            guard let data = data as? Param else {
                OpenEventManager.logger.error("EventManager: handle event: [\(event)] error data type: \(type(of: data)), \(Param.self)")
                errorHandler(
                    OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                )
                return
            }

            OpenEventManager.logger.info("EventManager: handle event: [\(event)]")
            try handler.handle(
                event: event,
                data: data,
                apiContext: apiContext,
                successHandler: successHandler,
                errorHandler: errorHandler
            )
        }

        let key = event
        var items = handlers[key] ?? []
        if !items.isEmpty {
            OpenEventManager.logger.info("multi register for event: \(key)")
        }
        items.append(handlerWrapper)

        handlers[key] = items
    }

    // 移除多播消息
    func removeHandler(for key: String) {
        handlers.removeValue(forKey: key)
    }
}
