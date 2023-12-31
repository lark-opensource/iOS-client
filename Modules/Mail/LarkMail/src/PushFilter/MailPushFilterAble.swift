//
//  MailPushFilterAble.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/8/4.
//

import Foundation
import LarkContainer
import RxSwift
import LarkFeatureGating

protocol MailPushFilterAble {
    /// 当前是否需要拦截
    func shouldBlock() -> Bool

    /// 标记回到MailTab时的恢复操作，默认刷新列表
    func recoverWay() -> MailPushFilter.RecoverWayType
}

extension MailPushFilterAble {
    func shouldBlock() -> Bool {
        return !MailPushFilter.shared.isInMailPage
    }

    func recoverWay() -> MailPushFilter.RecoverWayType {
        return .refreshThreadList
    }
}
