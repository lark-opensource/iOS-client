//
//  BadgeProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/6/24.
//

import Foundation
import MailSDK
import RxSwift
import LarkUIKit
import AnimatedTabBar
import LarkTab

class BadgeProvider {
    var progressSubject: PublishSubject<MailSDK.BadgeType> = PublishSubject<MailSDK.BadgeType>()

    static let `default` = BadgeProvider()

    static func transForm(_ origin: LarkTab.BadgeType) -> MailSDK.BadgeType {
        switch origin {
        case .none:
            return .none
        case .number(let count):
            return .number(count)
        case .dot(let count):
            return .dot(count)
        case .image(let image):
            return .image(image)
        }
    }
}

extension BadgeProvider: MailSDK.BadgeProxy {
    func getMailBadgeCount() -> Observable<MailSDK.BadgeType> {
        return progressSubject
    }
}
