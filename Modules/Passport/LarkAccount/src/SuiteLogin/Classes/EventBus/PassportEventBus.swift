//
//  PassportEventBus.swift
//  AnimatedTabBar
//
//  Created by Miaoqi Wang on 2020/5/14.
//

import Foundation
import ECOProbeMeta
import LKCommonsLogging
import LarkContainer

protocol PassportEventBusProtocol {
    func post(
        event: String,
        context: Any?,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler)

    func register<Context: Any>(event: String, queue: DispatchQueue, handler: EventBusHandler<Context>)
}

extension PassportEventBusProtocol {
   func register<Context: Any>(event: Event, handler: EventBusHandler<Context>) {
       register(event: event, queue: DispatchQueue.main, handler: handler)
   }
}

class PassportEventBus<Step: RawRepresentable & PassportStepInfoProtocol>: EventBus where Step.RawValue == String {
    func post(
        step: Step,
        rawContext: V3RawLoginContext?,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler) {
        let stepInfo = rawContext?.stepInfo ?? [:]
        let serverInfo = step.pageInfo(with: stepInfo)
        let context = V3LoginContext(
            serverInfo: serverInfo,
            additionalInfo: rawContext?.additionalInfo,
            vcHandler: rawContext?.vcHandler,
            backFirst: rawContext?.backFirst,
            context: rawContext?.context
        )
        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_step_action_run,
                              categoryValueMap: [ProbeConst.stepName: step.rawValue],
                              context: context.context ?? UniContextCreator.create(.unknown))
        post(event: step.rawValue, context: context, successHandler: success, errorHanlder: error)
    }

    func register<Context>(step: Step, handler: EventBusHandler<Context>) {
        register(event: step.rawValue, handler: handler)
    }
}

/// passport 外部业务可以注册的 eventBus
class ExternalEventBus: EventBus{

    static let shared = ExternalEventBus()

    func post(
        step: Event,
        rawContext: V3RawLoginContext?,
        success: @escaping EventBusSuccessHandler,
        error: @escaping EventBusErrorHandler) {
        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_step_action_run,
                              categoryValueMap: [ProbeConst.stepName: step],
                              context: rawContext?.context ?? UniContextCreator.create(.unknown))
        post(event: step, context: rawContext, successHandler: success, errorHanlder: error)
    }

    func register<Context>(step: Event, handler: EventBusHandler<Context>) {
        register(event: step, handler: handler)
    }

    override init() {
        super.init()
        self.registerMiddleware(EventBusSaveStepInfoMiddleware(stepInfoHelper: self))
    }
}

extension PassportEventBus: PassportEventBusProtocol {

    func post(event: String, context: Any?, success: @escaping EventBusSuccessHandler, error: @escaping EventBusErrorHandler) {
        if let rawLoginContext = context as? V3RawLoginContext {
            if let step = Step(rawValue: event) {
                post(step: step, rawContext: rawLoginContext, success: success, error: error)
            } else if ExternalEventBus.shared.canHandle(event: event) {
                ExternalEventBus.shared.post(event: event, context: context, success: success, error: error)
            } else {
                EventBus.logger.error("invalid params for step: [\(event)]")
                error(.invalidEvent)
            }
        } else {
            post(event: event, context: context, successHandler: success, errorHanlder: error)
        }
    }
}

extension ExternalEventBus: PassportEventBusProtocol {

    func post(event: String, context: Any?, success: @escaping EventBusSuccessHandler, error: @escaping EventBusErrorHandler) {
        if let rawLoginContext = context as? V3RawLoginContext {
            post(step: event, rawContext: rawLoginContext, success: success, error: error)
        } else {
            post(event: event, context: context, successHandler: success, errorHanlder: error)
        }
    }
}

class LoginPassportEventBus: PassportEventBus<PassportStep> {
    static let shared = LoginPassportEventBus()

    @Provider var eventRegistry: PassportEventRegistry // user:checked (global-resolve)

    override init() {
        super.init()

        if PassportSwitch.shared.enableLazySetupEventRegister {
            // 初始化设置 event bus
            eventRegistry.setupEventRegister(eventBus: self)
        }
    }
}

extension UserResolver {
    var passportEventBus: ScopedLoginEventBus {
        ScopedLoginEventBus(eventBus: LoginPassportEventBus.shared, userResolver: self)
    }
}

class ScopedEventBus<Step: RawRepresentable & PassportStepInfoProtocol>: EventBus, PassportEventBusProtocol where Step.RawValue == String {

    func post(step: Step, rawContext: V3RawLoginContext?, success: @escaping EventBusSuccessHandler, error: @escaping EventBusErrorHandler) {
        let stepInfo = rawContext?.stepInfo ?? [:]
        let serverInfo = step.pageInfo(with: stepInfo)
        let scopedContext = ScopedEventBusContext(userResolver: userResolver,
                                                  serverInfo: serverInfo,
                                                  additionalInfo: rawContext?.additionalInfo,
                                                  vcHandler: rawContext?.vcHandler,
                                                  backFirst: rawContext?.backFirst,
                                                  context: rawContext?.context)
        if canHandle(event: step.rawValue) {
            EventBus.logger.info("n_action_scoped_event_bus: can handle: [\(step.rawValue)]")
            post(event: step.rawValue, context: scopedContext, successHandler: success, errorHanlder: error)
        } else {
            EventBus.logger.info("n_action_scoped_event_bus: cannot handle: [\(step.rawValue)]")
            eventBus.post(event: step.rawValue, context: rawContext, success: success, error: error)
        }
    }

    func post(event: String, context: Any?, success: @escaping EventBusSuccessHandler, error: @escaping EventBusErrorHandler) {
        if let rawLoginContext = context as? V3RawLoginContext {
            if let step = Step(rawValue: event) {
                EventBus.logger.info("n_action_scoped_event_bus: post step: [\(event)]")
                post(step: step, rawContext: rawLoginContext, success: success, error: error)
            } else if ExternalEventBus.shared.canHandle(event: event) {
                EventBus.logger.info("n_action_scoped_event_bus: post external step: [\(event)]")
                ExternalEventBus.shared.post(event: event, context: context, success: success, error: error)
            } else {
                EventBus.logger.error("n_action_scoped_event_bus: scoped invalid params for step: [\(event)]")
                error(.invalidEvent)
            }
        } else {
            EventBus.logger.error("n_action_scoped_event_bus: not raw context for step: [\(event)]")
            post(event: event, context: context, successHandler: success, errorHanlder: error)
        }
    }

    func register<Context>(step: PassportStep, handler: EventBusHandler<Context>) {
        register(event: step.rawValue, handler: handler)
    }

    let eventBus: PassportEventBusProtocol
    let userResolver: UserResolver

    init(eventBus: PassportEventBusProtocol, userResolver: UserResolver) {
        self.eventBus = eventBus
        self.userResolver = userResolver
        super.init()
    }
}

class ScopedLoginEventBus: ScopedEventBus<PassportStep> {
    override init(eventBus: PassportEventBusProtocol, userResolver: UserResolver) {
        super.init(eventBus: eventBus, userResolver: userResolver)
        do {
            let registry = try userResolver.resolve(assert: PassportEventRegistry.self)
            registry.setupUserEventRegister(eventBus: self)
        } catch {
            #if DEBUG || ALPHA
                fatalError("ScopedEventBus resolve PassportEventRegistry with error: \(error)")
            #endif
        }
    }
}
