//
//  EventBusMiddleware.swift
//  AnimatedTabBar
//
//  Created by Miaoqi Wang on 2020/5/13.
//

import Foundation

struct EventBusCheckPopMiddleware: EventBusMiddlewareProtocol {
    let name: String = "EventBusCheckPopMiddleware"

    let priority: EventBusMiddlewarePriority = .medium

    weak var navigation: UINavigationController?

    init(navigation: UINavigationController?) {
        self.navigation = navigation
    }

    func excute(
        event: String,
        context: Any?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler,
        complete: @escaping () -> Void) {

        guard let context = context as? V3LoginEntity else {
            complete()
            return
        }

        SuiteLoginUtil.runOnMain {
            if self.checkPop(event: event, backFirst: context.backFirst) {
                successHandler()
            } else {
                complete()
            }
        }
    }

    func checkPop(event: String, backFirst: Bool?) -> Bool {
        guard let navigation = self.navigation else {
            return false
        }

        if backFirst ?? false {
            let popToVC = navigation.viewControllers.reversed().first { vc -> Bool in
                if let vc = vc as? V3ViewModelProtocol {
                    return vc.viewModel.step == event
                } else {
                    return false
                }
            }
            if let vc = popToVC {
                navigation.popToViewController(vc, animated: true)
                return true
            }
        }
        return false
    }
}

struct EventBusSaveStepInfoMiddleware: EventBusMiddlewareProtocol {
    let name: String = "EventBusSaveStepInfoMiddleware"

    let priority: EventBusMiddlewarePriority = .medium

    weak var stepInfoHelper: PassportStepInfoHelperProtocol?

    init(stepInfoHelper: PassportStepInfoHelperProtocol?) {
        self.stepInfoHelper = stepInfoHelper
    }

    func excute(
        event: String,
        context: Any?,
        successHandler: @escaping EventBusSuccessHandler,
        errorHandler: @escaping EventBusErrorHandler,
        complete: @escaping () -> Void) {

        guard let rawLoginContext = context as? V3RawLoginContext else {
            complete()
            return
        }

        if let stepInfo = rawLoginContext.stepInfo {
            stepInfoHelper?.stepInfo = stepInfo
            successHandler()
        }
        complete()
    }

}
