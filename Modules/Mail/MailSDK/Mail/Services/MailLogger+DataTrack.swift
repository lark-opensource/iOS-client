//
//  MailLogger+dataTrack.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/8/4.
//

import Foundation
import RustPB

/// 主要用于过滤敏感信息，同时减少log大小
protocol MailDataTrackLogable {
    var dataInfo: String { get }
}

/// 默认实现
extension MailDataTrackLogable {
    var dataInfo: String {
        return "\(self)"
    }
}

extension PushDispatcher.MailChangePush: MailDataTrackLogable {
    var dataInfo: String {
        var log = ""
        switch self {
        case .updateLabelsChange(let value):
            log = "updateLabelsChange- \(value.labels.map{ $0.id })"
        case .labelPropertyChange(let value):
            log = "labelPropertyChange- labelId: \(value.label.id)"
        default:
            log = "\(self)"
        }
        return log
    }
}

extension PushDispatcher.MailAccountPush: MailDataTrackLogable {
    var dataInfo: String {
        var log = ""
        switch self {
        case .accountChange(let change):
            log = "accountChange- account:{mailId:\(change.account.mailAccountID), userId:\(change.account.larkUserID)}; fromLocal:\(change.fromLocal)"
        case .shareAccountChange(let change):
            log = "shareAccountChange- account:{mailId:\(change.account.mailAccountID), userId:\(change.account.larkUserID)}; fetchAccountList:\(change.fetchAccountList); isCurrent:\(change.isCurrent); isBind:\(change.isBind)"
        default:
            log = "\(self)"
        }
        return log
    }
}

extension PushDispatcher.MailUnreadCountPush: MailDataTrackLogable {
    var dataInfo: String {
        var log = ""
        switch self {
        case .unreadThreadCount(let change):
            log = "unreadThreadCount- count:\(change.count); countMap:\(change.countMap)"
        }
        return log
    }
}

extension PushDispatcher.MigrationPush: MailDataTrackLogable {}

extension PushDispatcher.MailBatchChangePush: MailDataTrackLogable {}

extension PushDispatcher.MailSyncEventPush: MailDataTrackLogable {}

extension PushDispatcher.MailDownloadPush: MailDataTrackLogable {
    var dataInfo: String {
        var log = ""
        switch self {
        case .downloadPushChange(let change):
            if change.status != .inflight || change.status != .pending {
                log = "\(self)"
            }
        }
        return log
    }
}

extension PushDispatcher.MailUploadPush: MailDataTrackLogable {
    var dataInfo: String {
        var log = ""
        switch self {
        case .uploadPushChange(let change):
            if change.status != .inflight || change.status != .pending {
                log = "\(self)"
            }
        }
        return log
    }
}

extension PushDispatcher.MailMixSearchPush: MailDataTrackLogable {}

extension PushDispatcher.LarkEventPush: MailDataTrackLogable {}

