//
//  MailRiskEvent.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/6/22.
//

import Foundation

public final class MailRiskEvent {
    static let ChannelKey = "channel"

    public enum Channel: String {
        case tab = "tab"
        case bot = "bot"
        case notification = "notification"
        case approval = "approval"
        case forwardCard = "forwardCard"
    }

    public static func enterMail(channel: Channel) {
        let _ = Store
            .fetcher?
            .markMailRiskEvent(riskEvent: .accessLarkMail, params: [ChannelKey: channel.rawValue])
            .subscribe(onNext: { _ in
                MailLogger.debug("MailRiskEvent markMailRiskEvent channel:\(channel) success")
        }, onError: { err in
            MailLogger.error("MailRiskEvent markMailRiskEvent channel:\(channel) fail err: \(err)")
        })
    }
}
