//
//  SessionInvalidObserver.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/7/5.
//

import Foundation
import LarkSnCService

final class SessionInvalidObserver: EventDriver {

    let service: SnCService
    weak var delegate: SessionInvalidObserverDelegate?

    init(service: SnCService) {
        self.service = service
    }

    func receivedEvent(event: InnerEvent) {
        if event == .sessionInvalid {
            service.logger?.info("SessionInvalidObserver receivedEvent, sessionInvalid")
            delegate?.sessionInvalidAction()
        }
    }
}

protocol SessionInvalidObserverDelegate: AnyObject {
    func sessionInvalidAction()
}
