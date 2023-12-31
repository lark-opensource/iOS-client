//
//  EventBusManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/17.
//

import Foundation
import RxSwift
import RxRelay

class EventBusManager {
    static let shared = EventBusManager()

    @EventBusValue<(threadId: String?, messageId: String?, status: RecallStatus?)> var recallStateUpdate
}
