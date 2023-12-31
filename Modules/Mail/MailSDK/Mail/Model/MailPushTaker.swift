//
//  MailChangePushTaker.swift
//  MailSDK
//
//  Created by majx on 2019/8/11.
//

import Foundation
import RustPB

// MARK: - MailChange 对应结构体
public struct MailLabelChange {
    public let labels: [MailClientLabel]
    public init(labels: [MailClientLabel]) {
        self.labels = labels
    }
}

/// MailLabelPropertyChange.
public struct MailLabelPropertyChange {
    public let label: MailClientLabel
    public let isDelete: Bool
    public init(label: MailClientLabel, isDelete: Bool) {
        self.label = label
        self.isDelete = isDelete
    }
}

public struct MailThreadChange {
    public let labelIds: [String]
    public let threadId: String
    public init(labelIds: [String], threadId: String) {
        self.labelIds = labelIds
        self.threadId = threadId
    }
}

public struct MailMultiThreadsChange {
    public var label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>
    public var hasFilterThreads: Bool
    public var updateDelegation: Bool
    public init(label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>, hasFilterThreads: Bool, updateDelegation: Bool) {
        self.label2Threads = label2Threads
        self.hasFilterThreads = hasFilterThreads
        self.updateDelegation = updateDelegation
    }
}

public struct MailDraftChange {
    public let draftId: String
    public let action: Email_V1_DraftAction
    public init(draftId: String, action: Email_V1_DraftAction) {
        self.draftId = draftId
        self.action = action
    }
}

public struct MailOutboxSendStateChange {
    public let threadId: String
    public let messageId: String
    public let deliveryState: MailClientMessageDeliveryState
    public let count: Int32
    public let lastUpdateTime: Int64
    public init(threadId: String,
                messageId: String,
                deliveryState: MailClientMessageDeliveryState,
                count: Int32,
                lastUpdateTime: Int64) {
        self.threadId = threadId
        self.messageId = messageId
        self.deliveryState = deliveryState
        self.count = count
        self.lastUpdateTime = lastUpdateTime
    }
}

public struct MailCacheInvalidChange {
    public init() {

    }
}

/// MailRefreshLabelThreadsChange 最新协议不管参数
public struct MailRefreshLabelThreadsChange {
    public var labelIDs: [String]
    public init(labelIDs: [String]) {
        self.labelIDs = labelIDs
    }
}

public struct MailShareThreadChange {
    public var threadId: String
    public init(threadId: String) {
        self.threadId = threadId
    }
}

public struct MailUnshareThreadChange {
    public let threadId: String
    public let operatorUserID: String
    public init(threadId: String, operatorUserID: String) {
        self.threadId = threadId
        self.operatorUserID = operatorUserID
    }
}

public struct MailMigrationChange {
    public let stage: Int
    public let progressPct: Int
    public init(stage: Int, progressPct: Int) {
        self.stage = stage
        self.progressPct = progressPct
    }
}

public struct ShareMailPermissionChange {
    public let threadId: String
    public let permissionCode: MailPermissionCode
    public init(threadId: String, permissionCode: MailPermissionCode) {
        self.threadId = threadId
        self.permissionCode = permissionCode
    }
}

public struct MailAccountChange {
    public let account: MailAccount
    public let fromLocal: Bool
    public init(account: MailAccount, fromLocal: Bool) {
        self.account = account
        self.fromLocal = fromLocal
    }
}

public struct MailSharedAccountChange {
    public let account: MailAccount
    public let isBind: Bool
    public let isCurrent: Bool
    public let fetchAccountList: Bool

    public init(account: MailAccount, isBind: Bool, isCurrent: Bool, fetchAccountList: Bool) {
        self.account = account
        self.isBind = isBind
        self.isCurrent = isCurrent
        self.fetchAccountList = fetchAccountList
    }
}

public struct MailRecallDoneChange {
    public let messageId: String
    public let status: RecallStatus

    public init(messageId: String, status: RecallStatus) {
        self.messageId = messageId
        self.status = status
    }
}

public struct MailRecallChange {
    public let messageId: String
    public init(messageId: String) {
        self.messageId = messageId
    }
}

public struct MailUnreadThreadCountChange {
    public let count: Int64
    public let tabUnreadColor: UnreadCountColor

    public let countMap: [String: Int64]
    public let colorMap: [String: UnreadCountColor]

    public init(count: Int64,
                tabUnreadColor: UnreadCountColor,
                countMap: [String: Int64],
                colorMap: [String: UnreadCountColor]) {
        self.count = count
        self.tabUnreadColor = tabUnreadColor
        self.countMap = countMap
        self.colorMap = colorMap
    }
}

public struct MailBatchEndChange {
    public let code: Int32
    public let sessionID: String
    public let action: MailBatchChangesAction

    public init(sessionID: String,
                action: MailBatchChangesAction,
                code: Int32) {
        self.sessionID = sessionID
        self.action = action
        self.code = code
    }
}

public struct MailBatchResultChange {
    public let sessionID: String
    public let scene: MailBatchResultScene
    public let status: MailBatchResultStatus
    public let totalCount: Int32
    public let progress: Float

    public init(sessionID: String,
                scene: MailBatchResultScene,
                status: MailBatchResultStatus,
                totalCount: Int32,
                progress: Float) {
        self.sessionID = sessionID
        self.scene = scene
        self.status = status
        self.totalCount = totalCount
        self.progress = progress
    }
}

public struct MailSyncEventChange {
    public let syncEvent: MailSyncEvent

    public init(syncEvent: MailSyncEvent) {
        self.syncEvent = syncEvent
    }
}

public struct DynamicNetTypeChange {
    public let netStatus: DynamicNetStatus

    public init(netStatus: DynamicNetStatus) {
        self.netStatus = netStatus
    }
}

public struct MailDownloadPushChange {
    public let status: MailDownloadStatus
    public let key: String
    public var transferSize: Int64?
    public var totalSize: Int64?
    public var path: String?
    public var failedInfo: MailDownloadFailInfo?

    public init(status: MailDownloadStatus, key: String) {
        self.status = status
        self.key = key
    }
}

public struct MailUploadPushChange {
    public let status: MailUploadStatus
    public let key: String
    public let token: String
    public var transferSize: Int64?
    public var totalSize: Int64?

    public init(status: MailUploadStatus, key: String, token: String) {
        self.status = status
        self.key = key
        self.token = token
    }
}

public struct MailMixSearchPushChange {
    public let state: MailMixSearchState
    public let searchSession: String
    public let begin: Int64
    public var count: Int64

    public init(state: MailMixSearchState, searchSession: String, begin: Int64, count: Int64) {
        self.state = state
        self.searchSession = searchSession
        self.begin = begin
        self.count = count
    }
}

public struct MailSearchContactPushChange {
    let info: ContactSearchInfo
    let result: [Email_Client_V1_MailContactSearchResult]

    public init(response: Email_Client_V1_MailContactSearchResponse) {
        self.result = response.results
        self.info = ContactSearchInfo(total: response.total, hasMore: response.hasMore_p, fromLocal: response.fromLocal, searchSession: response.searchSession)
	}
}

public struct MailAddressUpdatePushChange {
    var addressNameList: [Email_Client_V1_AddressName] = []
    public init(response: Email_Client_V1_UpdateAddressNamePacket) {
        self.addressNameList = response.addressNameList
    }
}

public struct MailPreloadProgressPushChange {
    var status: Email_Client_V1_MailPreloadStatus
    var accountID: String
    var progress: Int64
    var errorCode: Email_Client_V1_MailPreloadError
    var preloadTs: Email_Client_V1_MailPreloadTimeStamp
    var isBannerClosed: Bool
    var needPush: Bool

    public init(status: Email_Client_V1_MailPreloadStatus, progress: Int64, errorCode: Email_Client_V1_MailPreloadError, preloadTs: Email_Client_V1_MailPreloadTimeStamp, isBannerClosed: Bool, needPush: Bool) {
        self.status = status
        self.accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        self.progress = progress
        self.errorCode = errorCode
        self.preloadTs = preloadTs
        self.isBannerClosed = isBannerClosed
        self.needPush = needPush
    }

    public init(response: Email_Client_V1_MailPreloadProgressPushResponse) {
        self.status = response.status
        self.accountID = response.accountID
        self.progress = response.progress
        self.errorCode = response.errorCode
        self.preloadTs = response.preloadTs
        self.isBannerClosed = false
        self.needPush = true
    }

    func preloadStatus() -> String {
        if errorCode == .diskFullError {
            return "disk_full"
        } else if errorCode == .networkError {
            return "network_error"
        } else if status == .running || status == .preparing {
            return "loading"
        } else if status == .stopped && progress == 100 {
            return "success"
        } else {
            return "unknown"
        }
		}
}

public struct MailGroupMemberCountPush {
    let sessionID: String
    let groupInfo: MailGroupMemberCountInfo
    let config: Email_Client_V1_RecipientCountLimitConfig
    
    public init(response: Email_Client_V1_MailGroupMemberCountPushResponse) {
        self.sessionID = response.sessionID
        self.groupInfo = response.groupInfo
        self.config = response.config
    }
}

public struct MailAITaskStatusPushChange {
    var taskStatus: Email_Client_V1_MailAITaskStatus
    public init(response: Email_Client_V1_MailAITaskStatusPushResponse) {
        self.taskStatus = response.mailAiTaskStatus

    }
}

public struct MailDownloadProgressPushChange {
    public enum FileType: Int {
        case image = 0
        case attach = 1
    }
    public let progressInfo: MailDownloadProgressInfo
    public let needSaveInMail: Bool // 需要存储在持久化缓存，业务侧管理
    public let fileType: FileType? // 用于区分是正文图片还是附件，0 图片，1 附件
    public let accountID: String // 当前mail账号id，用于区分缓存cache

    public init(push: Email_Client_V1_MailDownloadProcessPushResponse) {
        self.progressInfo = push.driveCallback
        self.needSaveInMail = push.needSaveInMail
        self.fileType = FileType(rawValue: Int(push.fileType))
        self.accountID = push.accountID
    }
}

public struct MailCleanCachePushChange {
    public let cleanType: MailCleanCacheType
    public let tokens: [String]
    public let accountID: String
    public init(cleanType: MailCleanCacheType,
                tokens: [String],
                accountID: String) {
        self.cleanType = cleanType
        self.tokens = tokens
        self.accountID = accountID
                }
}

// Feed进IM关注状态推送
public struct MailFeedFollowStatusChange {
    var followeeList: [Email_Client_V1_FolloweeInfo]
    public init(response: Email_Client_V1_MailFollowStatusChangeResponse) {
        self.followeeList = response.followeeList
    }
}

// Feed进IM邮件列表推送
public struct MailFeedFromChange {
    var fromResponse: Email_Client_V1_MailFromChangeResponse
    public init(response: Email_Client_V1_MailFromChangeResponse) {
        self.fromResponse = response
    }
}
public struct MailIMAPMigrationStateChange {
    let state: Email_Client_V1_IMAPMigrationState
    public init(response: Email_Client_V1_MailIMAPMigrationStatePushResponse) {
        self.state = response.state
    }
}
