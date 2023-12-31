//
//  CacheUpdateEvent.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import LarkSnCService

final class CacheUpdateEvent: EventDriver {

    private let service: SnCService
    weak var delegate: ProviderDelegate?
    private static let postDelayTime = 5
    var lastEventTimestamp: TimeInterval = 0

    init(service: SnCService) {
        self.service = service
    }

    func receivedEvent(event: InnerEvent) {
        if [.policyUpdate, .subjectFactorUpdate, .timerEvent].contains(event) {
            let currentTimestamp = Date().timeIntervalSince1970
            guard currentTimestamp - lastEventTimestamp > TimeInterval(CacheUpdateEvent.postDelayTime) else {
                return
            }
            lastEventTimestamp = currentTimestamp
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(CacheUpdateEvent.postDelayTime)) {
                self.service.logger?.info("CacheUpdateEvent postEvent: decisionContextChanged")
                self.delegate?.postOuterEvent(event: .decisionContextChanged)
            }
        }
    }
}
