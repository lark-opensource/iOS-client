//
//  PushDispatcher+innerEvent.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/9/15.
//

import Foundation

// 一些仅MailSDK内部使用的event。不public
extension PushDispatcher {
    enum ActionSource {
        case messageList
        case other // 默认other
    }
    // 一些内部自定义的数据传递
    enum ThreadListEvent {
        case didReloadListData(labelId: String, datas: [MailThreadListCellViewModel])
        case didReloadListDataOnlyFromMessageList(labelId: String, datas: [MailThreadListCellViewModel]) // 读信页独享。TODO：暂时没有好的办法。
        case resetThreadsCache(labelId: String)
        case updateLabelsCellVM(labels: [MailFilterLabelCellModel])
        case reloadLabelMenu
        case markRecalledThread(threadId: String?)
        case needUpdateOutbox
        case didFailedOutboxCountRefreshed(Int)
        case needUpdateThreadList(label: String, removeThreadId: String?)
        case needLoadMoreThreadIfNeeded(label: String, timestamp: Int64?, source: ActionSource)

    }

    public enum LarkMailEvent {
        case unreadCountRecover(count: Int64, color: UnreadCountColor)
    }
}
