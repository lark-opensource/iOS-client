//
//  PushDispatcher+Changelog.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/9/24.
//

import Foundation

// MARK: 来自Rust的changelog
extension PushDispatcher {
    // MARK: 邮件changelog
    public enum MailChangePush {
        case threadChange(MailThreadChange)
        case multiThreadsChange(MailMultiThreadsChange)
        case updateLabelsChange(MailLabelChange)
        case labelPropertyChange(MailLabelPropertyChange)
        case cacheInvalidChange(MailCacheInvalidChange)
        case refreshThreadChange(MailRefreshLabelThreadsChange)
        case shareThreadChange(MailShareThreadChange)
        case unshareThreadChange(MailUnshareThreadChange)
        case mailMigrationChange(MailMigrationChange)
        case recalledChange(MailRecallChange)
        case recallDoneChange(MailRecallDoneChange)
        case sharePermissonChange(ShareMailPermissionChange)
        case outboxBoxSendStateChange(MailOutboxSendStateChange)
        case draftChange(MailDraftChange)
    }

    // MARK: 账号相关push
    public enum MailAccountPush {
        case unknow /// useless
        case accountChange(MailAccountChange)
        case shareAccountChange(MailSharedAccountChange)
        case currentAccountChange
    }
    
    // MARK: thread unread count
    public enum MailUnreadCountPush {
        case unreadThreadCount(MailUnreadThreadCountChange)
    }

    public enum MigrationPush {
        case migrationChange(MailMigrationChange)
    }

    public enum MailSyncEventPush {
        case syncEventChange(MailSyncEventChange)
    }

    // MARK: 不知道是啥
    public enum MailBatchChangePush {
        case batchEndChange(MailBatchEndChange)
        case batchResultChange(MailBatchResultChange)
    }

    public enum MailDownloadPush {
        case downloadPushChange(MailDownloadPushChange)
    }

    public enum MailUploadPush {
        case uploadPushChange(MailUploadPushChange)
    }

    public enum MailMixSearchPush {
        case mixSearchPushChange(MailMixSearchPushChange)
    }
    public enum MailAddressPush {
        case mailAddressChange(MailAddressUpdatePushChange)
    }
    public enum MailAITaskStatusPush {
        case mailAITaskStatusChange(MailAITaskStatusPushChange)
    }
    
    public enum MailDownloadProgressPush {
        case progressChange(MailDownloadPushChange)
    }
    // MARK: FeedPush
    public enum MailFeedFromPush {
        case mailFeedFromChange(MailFeedFromChange)
    }
    
    public enum MailFeedFollowStatusPush {
        case mailFeedFollowStatusChange(MailFeedFollowStatusChange)
    }
    
}
