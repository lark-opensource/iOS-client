//
//  EventBus.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/18.
//
import Foundation
import LKCommonsLogging

typealias EventBusErrorHandler = (_ error: EventBusError) -> Void
typealias EventBusSuccessHandler = () -> Void
typealias Event = String

enum EventBusError: Error, CustomStringConvertible, LocalizedError {
    case castContextFail
    case noHandler
    case invalidParams
    case internalError(V3LoginError)
    case invalidEvent

    public var description: String {
        switch self {
        case .castContextFail:
            return "EventBusError.castContextFail"
        case .noHandler:
            return "EventBusError.noHandler"
        case .invalidParams:
            return "EventBusError.invalidParams"
        case .internalError(let err):
            return "EventBusError.internalError: \(err)"
        case .invalidEvent:
            return "EventBusError.invalidEvent"
        }
    }

    var errorDescription: String? {
        switch self {
        case let .internalError(loginError):
            return loginError.localizedDescription
        case .castContextFail, .noHandler, .invalidParams:
            return I18N.Lark_Passport_BadServerData
        case .invalidEvent:
            return nil
        }
    }
}

class EventBus {

    private typealias HandlerKey = String
    private typealias Handler = (_ event: Event, _ context: Any?, _ successHandler: @escaping EventBusSuccessHandler, _ errorHanlder: @escaping EventBusErrorHandler) -> Void

    private var handlers: [HandlerKey: [Handler]] = [:]

    static let logger = Logger.plog(EventBus.self, category: "SuiteLogin.EventBus")

    private var middlewares: [EventBusMiddlewareProtocol] = []

    func post(
        event: Event,
        context: Any? = nil,
        successHandler: @escaping EventBusSuccessHandler,
        errorHanlder: @escaping EventBusErrorHandler) {
        let key = event
        let items = handlers[key] ?? []

        if items.isEmpty {
            EventBus.logger.error("n_action EventBus: error no handler for event: [\(event)]")
            errorHanlder(EventBusError.noHandler)
        } else {
            items.forEach {
                $0(event, context, {
                    EventBus.logger.info("n_action EventBus: handled event with success: [\(event)]", method: .local)
                    successHandler()
                }, { err in
                    EventBus.logger.error("n_action EventBus: handled event with error: [\(event)] \(err)")
                    errorHanlder(err)
                })
            }
        }
    }

    func register<Context: Any>(
        event: Event,
        queue: DispatchQueue = DispatchQueue.main,
        handler: EventBusHandler<Context>) {

        let handlerWrapper: Handler = { [weak self] event, context, successHandler, errorHanlder in
            guard let self = self else {
                EventBus.logger.error("self is nil")
                return
            }
            guard let ctx = context as? Context else {
                    queue.async {
                        EventBus.logger.error("n_action EventBus: handle event: [\(event)] error context type: \(type(of: context)), \(Context.self)")
                        errorHanlder(EventBusError.castContextFail)
                    }
                    return
            }

            self.excuteMiddleware(event: event, context: context, successHandler: successHandler, errorHandler: errorHanlder) {
                queue.async {
                    EventBus.logger.info("n_action EventBus: handle event: [\(event)]", method: .local)
                    handler.handle(event: event,
                                   context: ctx,
                                   successHandler: successHandler,
                                   errorHandler: errorHanlder)
                }
            }
        }

        let key = event
        var items = handlers[key] ?? []
        if !items.isEmpty {
            EventBus.logger.error("n_action multi register for event: \(key)")
        }
        items.append(handlerWrapper)

        handlers[key] = items
    }

    func removeHandler(for key: String) {
        handlers.removeValue(forKey: key)
    }

    func canHandle(event: Event) -> Bool {
        return (handlers[event] ?? []).count > 0
    }
}

// MARK: - middleware

extension EventBus {

    func registerMiddleware(_ middleware: EventBusMiddlewareProtocol) {
        middlewares.removeAll { (mdw) -> Bool in
            mdw.name == middleware.name
        }
        middlewares.append(middleware)
        middlewares.sort { $0.priority.rawValue > $1.priority.rawValue }
    }

    private func excuteMiddleware(
        event: Event,
        context: Any?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler,
        complete: @escaping () -> Void) {
        innerExcuteMiddleware(
            index: 0,
            event: event,
            context: context,
            successHandler: successHandler,
            errorHandler: errorHandler,
            complete: complete)
    }

    private func innerExcuteMiddleware(
        index: Int,
        event: Event,
        context: Any?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler,
        complete: @escaping () -> Void) {
        guard index < middlewares.count else {
            complete()
            return
        }
        let middleware = middlewares[index]
        middleware.excute(
            event: event,
            context: context,
            successHandler: successHandler,
            errorHandler: errorHandler) { [weak self] in
                self?.innerExcuteMiddleware(
                    index: index + 1,
                    event: event,
                    context: context,
                    successHandler: successHandler,
                    errorHandler: errorHandler,
                    complete: complete
                )
        }
    }
}

enum EventBusMiddlewarePriority: Int {
    case high = 1000
    case medium = 500
    case low = 0
}

protocol EventBusMiddlewareProtocol {
    // used to identity different middleware
    var name: String { get }
    // affect excute order, higher first
    var priority: EventBusMiddlewarePriority { get }

    func excute(
        event: String,
        context: Any?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler,
        complete: @escaping () -> Void)
}

protocol PassportStepInfoHelperProtocol: class {
    var stepInfo: [String: Any] { get set }
}

//保存stepInfo
extension ExternalEventBus: PassportStepInfoHelperProtocol {
    struct helper {
        static var stepInfo: [String: Any] = [:]
    }
    var stepInfo: [String: Any] {
        get {
            helper.stepInfo
        }
        set {
            helper.stepInfo = newValue
        }
    }
}
