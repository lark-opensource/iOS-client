//
//  MailStatiticsAggregationHandler.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/5/8.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkFoundation

class MailStatiticsAggregationHandler: UserPushHandler, AccountBasePushHandler {
    let logger = Logger.log(MailStatiticsAggregationHandler.self, category: "Module.Mail")

    func process(push: RustPushPacket<MailStatisticsAggregationResponse>) throws {
        // if simulator ignore it. if you want to debug. delete it if you need
        if LarkFoundation.Utils.isSimulator {
            return
        }

        for item in push.body.statistics {
            if item.type == .slardar || item.type == .both {
                var params: [AnyHashable: Any] = [:].merging(item.slardarParam.params.stringParam) { (_, newValue) in newValue }
                params = params.merging(item.slardarParam.params.intParam) { (_, newValue) in newValue }
                #if DEBUG
                logger.debug("slardar statitics from rust with key:\(item.key), params:\(params)")
                #else
                Tracker.post(SlardarEvent(name: item.key, metric: params, category: [:], extra: [:]))
                #endif
            }
            if item.type == .tea || item.type == .both {
                var params: [AnyHashable: Any] = [:].merging(item.teaParam.params.stringParam) { (_, newValue) in newValue }
                params = params.merging(item.teaParam.params.intParam) { (_, newValue) in newValue }
                #if DEBUG
                logger.debug("tea statitics from rust with key:\(item.key), params:\(params)")
                #else
                Tracker.post(TeaEvent(item.key, params: params))
                #endif
            }
        }
    }
}
