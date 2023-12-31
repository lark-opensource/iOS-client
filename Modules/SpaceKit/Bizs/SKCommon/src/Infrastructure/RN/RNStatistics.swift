//
//  RNStatistics.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/22.
//

import SKFoundation
import SwiftyJSON
import LarkSetting

final class RNStatistics: RNMessageDelegate {
    init() {
    }

    func startListen() {
        DocsLogger.info("RNStatistics startListen")
        RNManager.manager.registerRnEvent(eventNames: [.rnStatistics], handler: self)
    }

    func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard eventName == .rnStatistics else {
            DocsLogger.info("\(eventName) is not rnStatistics")
            return
        }
        let json = JSON(data)
        guard let event = json["data"]["event_name"].string,
            let params = json["data"]["data"].dictionaryObject else {
                DocsLogger.info("rnStatistics invalid params")
                return
        }
        if json["data"]["noPrefix"].boolValue { // 不会加上docs_前缀
            DocsTracker.newLog(event: event, parameters: params)
        } else {
            DocsTracker.log(event: event, parameters: params)
        }
        
    }
}
@objcMembers
public final class RNFGHelper: NSObject {
    public class func featureGatingValue(key: String) -> Bool {
        let value = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
        DocsLogger.info("rn call fg, key is:\(key) value is:\(value)")
        return value
    }
}
