//
//  PushDispatcher.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/17.
//

import Foundation
import RxSwift
import RxRelay

/// 内部一些场景的数据传递可以用EventBus实例
public var EventBus: PushDispatcher {
    return PushDispatcher.shared
}

public final class PushDispatcher {
    public static let shared = PushDispatcher()

    // MAKR: internal observable
    @PushValue<MailChangePush> var mailChange

    @PushValue<MailAccountPush> var accountChange

    @PushValue<MailUnreadCountPush> var unreadCountChange

    @PushValue<MigrationPush> var migrationChange

    @PushValue<MailBatchChangePush> var batchChange

    @PushValue<MailSyncEventPush> var syncEventChange

    @PushValue<LarkEventPush> var larkEventChange

    @PushValue<MailDownloadPush> var downloadPushChange

    @PushValue<MailUploadPush> var uploadPushChange

    @PushValue<MailMixSearchPush> var mixSearchPushChange

    @PushValue<MailSearchContactPushChange> var searchContactChange
    
    @PushValue<MailAddressUpdatePushChange> var mailAddressUpdatePush
    
    @PushValue<MailAITaskStatusPushChange> var mailAITaskStatusPush
    
    @PushValue<MailFeedFromChange> var mailfeedChange
    
    @PushValue<MailFeedFollowStatusChange> var mailfollowStatusChange

    @PushValue<MailPreloadProgressPushChange> var mailPreloadProgressChange

    @PushValue<MailGroupMemberCountPush> var mailGroupMemberCountPush
    
    @PushValue<MailDownloadProgressPushChange> var downloadProgressPush
    
    @PushValue<MailCleanCachePushChange> var cleanCachePush

    @PushValue<MailIMAPMigrationStateChange> var mailIMAPMigrationStatePush

    // MARK: EventBus事件
    @PushValue<ThreadListEvent> var threadListEvent

    @PushValue<LarkMailEvent> public var larkmailEvent

    init() {

    }
}

// MARK: 用于接受来自LarkMail的推送
public extension PushDispatcher {
    func acceptMailChangePush(push: MailChangePush) {
        MailLogger.dataTrack(change: push)
        self.$mailChange.accept(push)
    }

    func acceptMailAccountPush(push: MailAccountPush) {
        MailLogger.dataTrack(change: push)
        if case .accountChange(let change) = push {
            if Store.settingData.checkPushValid(push: change) {
                self.$accountChange.accept(push)
            }
        } else {
            self.$accountChange.accept(push)
        } 
    }
    
    func acceptMailUnreadCountPush(push: MailUnreadCountPush) {
        MailLogger.dataTrack(change: push)
        self.$unreadCountChange.accept(push)
    }

    func acceptMailMigrationPush(push: MigrationPush) {
        MailLogger.dataTrack(change: push)
        self.$migrationChange.accept(push)
    }

    func acceptMailBatchChangePush(push: MailBatchChangePush) {
        MailLogger.dataTrack(change: push)
        self.$batchChange.accept(push)
    }

    func acceptMailSyncEventPush(push: MailSyncEventPush) {
        MailLogger.dataTrack(change: push)
        self.$syncEventChange.accept(push)
    }

    func acceptLarkEventPush(push: LarkEventPush) {
        MailLogger.dataTrack(change: push)
        self.$larkEventChange.accept(push)
    }

    func acceptMailDownloadChangePush(push: MailDownloadPush) {
        MailLogger.dataTrack(change: push)
        self.$downloadPushChange.accept(push)
    }

    func acceptMailUploadChangePush(push: MailUploadPush) {
        MailLogger.dataTrack(change: push)
        self.$uploadPushChange.accept(push)
    }

    func acceptMailMixSearchChangePush(push: MailMixSearchPush) {
        MailLogger.dataTrack(change: push)
        self.$mixSearchPushChange.accept(push)
    }

    func acceptMailSearchContactChangePush(push: MailSearchContactPushChange) {
        self.$searchContactChange.accept(push)
    }
    
    func acceptMailAddressUpdateChangePush(push: MailAddressUpdatePushChange) {
        self.$mailAddressUpdatePush.accept(push)
    }

    func acceptMailPreloadProgressChangePush(push: MailPreloadProgressPushChange) {
        self.$mailPreloadProgressChange.accept(push)
		}

    func acceptMailGroupMemberCountPush(push: MailGroupMemberCountPush) {
        self.$mailGroupMemberCountPush.accept(push)
    }
    
    func acceptMailAITaskStatusPush(push: MailAITaskStatusPushChange) {
        self.$mailAITaskStatusPush.accept(push)
    }
    func acceptMailDownloadProgressPush(push: MailDownloadProgressPushChange) {
        self.$downloadProgressPush.accept(push)
    }
    func acceptMailCleanCachePush(push: MailCleanCachePushChange) {
        self.$cleanCachePush.accept(push)
    }
    
    // current account imap migration state change
    func acceptIMAPMigrationStatePush(push: MailIMAPMigrationStateChange) {
        self.$mailIMAPMigrationStatePush.accept(push)
    }
    
    func acceptFeedChangePush(push: MailFeedFromChange) {
        self.$mailfeedChange.accept(push)
    }
    
    func acceptFollowStatusPush(push: MailFeedFollowStatusChange) {
        self.$mailfollowStatusChange.accept(push)
    }
}
