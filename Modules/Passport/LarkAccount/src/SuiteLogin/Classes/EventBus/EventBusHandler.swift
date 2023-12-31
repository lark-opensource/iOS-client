//
//  EventBusHandler.swift
//  AnimatedTabBar
//
//  Created by Miaoqi Wang on 2020/5/13.
//

import Foundation
import LarkContainer
import LKCommonsLogging

private protocol EventBusHandlerWorkProtocol {
    associatedtype HandlerType

    var handleWork: HandlerType { get set }

    init(handleWork: HandlerType)
}

// general base
class EventBusHandler<Context: Any> {

    let logger = Logger.plog(EventBusHandler.self, category: "SuiteLogin")

    func handle(event: String,
                context: Context?,
                successHandler: @escaping EventBusSuccessHandler,
                errorHandler: @escaping EventBusErrorHandler) {
        assertionFailure("need be override")
    }
}

struct ServerInfoHandleArgs<Server: ServerInfo> {
    var event: Event
    var serverInfo: Server
    var additional: Codable?
    var vcHandler: EventBusVCHandler?
    var successHandler: EventBusSuccessHandler
    var errorHandler: EventBusErrorHandler
    var context: UniContextProtocol
}

/// must have server info handler
class ServerInfoEventBusHandler<Server: ServerInfo>: EventBusHandler<V3LoginEntity>, EventBusHandlerWorkProtocol {

    typealias HandlerType = (ServerInfoHandleArgs<Server>) -> Void

    fileprivate var handleWork: HandlerType

    required init(handleWork: @escaping HandlerType) {
        self.handleWork = handleWork
    }

    override func handle(
        event: String,
        context: V3LoginEntity?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler
    ) {

        guard let server = context?.serverInfo as? Server else {
            errorHandler(.invalidParams)
            logger.error("EventBus: cannot handle event [\(event)] because serverInfo \(type(of: context?.serverInfo)) - \(Server.self)")
            return
        }
        let args = ServerInfoHandleArgs<Server>(
            event: event,
            serverInfo: server,
            additional: context?.additionalInfo,
            vcHandler: context?.vcHandler,
            successHandler: successHandler,
            errorHandler: errorHandler,
            context: context?.context ?? UniContext.placeholder
        )
        handleWork(args)
    }
}

struct AdditionalInfoHandleArgs<Additional: Codable> {
    var event: Event
    var serverInfo: Codable?
    var additional: Additional
    var vcHandler: EventBusVCHandler?
    var successHandler: EventBusSuccessHandler
    var errorHandler: EventBusErrorHandler
    var context: UniContextProtocol
}

/// must have additional info handler
class AdditionalInfoEventBusHandler<Additional: Codable>: EventBusHandler<V3LoginEntity>, EventBusHandlerWorkProtocol {

    typealias HandlerType = (AdditionalInfoHandleArgs<Additional>) -> Void

    fileprivate var handleWork: HandlerType

    required init(handleWork: @escaping HandlerType) {
        self.handleWork = handleWork
    }

    override func handle(
        event: String,
        context: V3LoginEntity?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler
    ) {

        guard let additional: Additional = context?.additionalInfo as? Additional else {
            errorHandler(.invalidParams)
            logger.error("EventBus: cannot handle event [\(event)] because serverInfo \(type(of: context?.additionalInfo)) - \(Additional.self)")
            return
        }

        let serverInfo = context?.serverInfo
        let vcHandler = context?.vcHandler
        let args = AdditionalInfoHandleArgs<Additional>(
            event: event,
            serverInfo: serverInfo,
            additional: additional,
            vcHandler: vcHandler,
            successHandler: successHandler,
            errorHandler: errorHandler,
            context: context?.context ?? UniContext.placeholder
        )
        handleWork(args)
    }
}

struct CommonHandlerArgs<Context: Any> {
    let event: String
    let eventBusContext: Context?
    let context: UniContextProtocol
    let successHandler: EventBusSuccessHandler
    let errorHandler: EventBusErrorHandler
}

/// handler for not specific context
class CommonEventBusHandler: EventBusHandler<V3LoginEntity>, EventBusHandlerWorkProtocol {

    typealias HandlerType = (CommonHandlerArgs<V3LoginEntity>) -> Void

    fileprivate var handleWork: HandlerType

    required init(handleWork: @escaping HandlerType) {
        self.handleWork = handleWork
    }

    override func handle(
        event: String,
        context: V3LoginEntity?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler
    ) {

        let args = CommonHandlerArgs<V3LoginEntity>(
            event: event,
            eventBusContext: context,
            context: context?.context ?? UniContext.placeholder,
            successHandler: successHandler,
            errorHandler: errorHandler
        )
        handleWork(args)
    }
}

struct ExternalHandlerArgs<Context: Any> {
    let event: String
    let stepInfo: Context?
    let context: UniContextProtocol
    let successHandler: EventBusSuccessHandler
    let errorHandler: EventBusErrorHandler
}

class ExternalEventBusHandler: EventBusHandler<V3RawLoginContext>, EventBusHandlerWorkProtocol {

    typealias HandlerType = (ExternalHandlerArgs<[String: Any]>) -> Void

    fileprivate var handleWork: HandlerType

    required init(handleWork: @escaping HandlerType) {
        self.handleWork = handleWork
    }

    override func handle(
        event: String,
        context: V3RawLoginContext?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler
    ) {

        let args = ExternalHandlerArgs<[String: Any]>(
            event: event,
            stepInfo: context?.stepInfo,
            context: context?.context ?? UniContext.placeholder,
            successHandler: successHandler,
            errorHandler: errorHandler
        )
        handleWork(args)
    }
}

struct ScopedEventBusContext {
    let serverInfo: Codable?
    let additionalInfo: Codable?
    let vcHandler: EventBusVCHandler?
    let backFirst: Bool?
    let context: UniContextProtocol?
    let userResolver: UserResolver

    init(userResolver: UserResolver, serverInfo: Codable? = nil, additionalInfo: Codable? = nil, vcHandler: EventBusVCHandler? = nil, backFirst: Bool? = nil, context: UniContextProtocol? = nil) {
        self.serverInfo = serverInfo
        self.additionalInfo = additionalInfo
        self.vcHandler = vcHandler
        self.backFirst = backFirst
        self.context = context
        self.userResolver = userResolver
    }
}

struct ScopedServerInfoHandleArgs<Server: ServerInfo> {
    let event: Event
    let serverInfo: Server
    let additional: Codable?
    let vcHandler: EventBusVCHandler?
    let successHandler: EventBusSuccessHandler
    let errorHandler: EventBusErrorHandler
    let context: UniContextProtocol
    let userResolver: UserResolver
}

/// 用户态服务端返回 Step 处理
class ScopedServerInfoEventBusHandler<Server: ServerInfo>: EventBusHandler<ScopedEventBusContext>, EventBusHandlerWorkProtocol {

    typealias HandlerType = (ScopedServerInfoHandleArgs<Server>) -> Void

    fileprivate var handleWork: HandlerType

    required init(handleWork: @escaping HandlerType) {
        self.handleWork = handleWork
    }

    override func handle(
        event: String,
        context: ScopedEventBusContext?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler
    ) {
        // UserScope
        guard let userResolver = context?.userResolver else {
            errorHandler(.invalidParams)
            logger.error("ScopedEventBus: cannot handle event [\(event)] because user resolver not found")
            return
        }
        guard let server = context?.serverInfo as? Server else {
            errorHandler(.invalidParams)
            logger.error("ScopedEventBus: cannot handle event [\(event)] because serverInfo \(type(of: context?.serverInfo)) - \(Server.self)")
            return
        }
        let args = ScopedServerInfoHandleArgs<Server>(
            event: event,
            serverInfo: server,
            additional: context?.additionalInfo,
            vcHandler: context?.vcHandler,
            successHandler: successHandler,
            errorHandler: errorHandler,
            context: context?.context ?? UniContext.placeholder,
            userResolver: userResolver
        )
        handleWork(args)
    }
}
