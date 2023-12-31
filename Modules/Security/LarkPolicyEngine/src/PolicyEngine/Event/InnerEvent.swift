//
//  Event.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/10/13.
//

import Foundation
import LarkSnCService

public enum InnerEvent: Equatable {
    case initCompletion
    case timerEvent
    case sessionInvalid
    case subjectFactorUpdate
    case policyUpdate
    case networkChanged
    case becomeActive
}

protocol EventDriver: AnyObject {
    func receivedEvent(event: InnerEvent)
}

extension WeakManager where T == EventDriver {
    func sendEvent(event: InnerEvent) {
        PolicyEngineQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.weakObjects.forEach {
                ($0.value as? T)?.receivedEvent(event: event)
            }
        }
    }
}
