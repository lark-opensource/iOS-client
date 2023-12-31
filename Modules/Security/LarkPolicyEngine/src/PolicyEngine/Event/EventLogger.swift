//
//  EventLogger.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/8.
//

import Foundation
import LarkSnCService

final class EventLogger: EventDriver, Observer {

    let service: SnCService

    init(service: SnCService) {
        self.service = service
    }
    func receivedEvent(event: InnerEvent) {
        service.logger?.info("received event: \(event)")
    }

    func notify(event: Event) {
        service.logger?.info("post action: \(event)")
    }
}
