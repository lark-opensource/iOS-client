//
//  MailPush+filter.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/8/4.
//

import Foundation
import LarkSDKInterface

extension MailThreadChange: MailPushFilterAble {}

extension LarkMailMultiThreadsChange: MailPushFilterAble {}

extension MailLabelChange: MailPushFilterAble {}

extension MailLabelPropertyChange: MailPushFilterAble {}

// cacheInvalid 暂时不做此拦截，因为需要做的恢复事件较多，有成本。
//extension MailCacheInvalidChange: MailPushFilterAble {}

extension MailRefreshLabelThreadsChange: MailPushFilterAble {}

extension MailShareThreadChange: MailPushFilterAble {}

extension MailUnshareThreadChange: MailPushFilterAble {}

extension MailMigrationChange: MailPushFilterAble {
    func recoverWay() -> MailPushFilter.RecoverWayType {
        return .refreshMigration
    }
}

extension MailRecallChange: MailPushFilterAble {}

extension MailRecallDoneChange: MailPushFilterAble {}

extension MailOutboxSendStateChange: MailPushFilterAble {
    func recoverWay() -> MailPushFilter.RecoverWayType {
        return .refreshOutBox
    }
}
