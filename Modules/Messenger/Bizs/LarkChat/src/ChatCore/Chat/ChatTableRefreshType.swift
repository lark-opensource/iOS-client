//
//  ChatTableRefreshType.swift
//  LarkChat
//
//  Created by zc09v on 2022/7/22.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageCore
import LarkMessageBase

struct InitMessagesInfo {
    let hasHeader: Bool
    let hasFooter: Bool
    let scrollInfo: ScrollInfo?
    let initType: MessageInitType
}

enum MessageInitType: Equatable {
    /// 上次离开时消息
    case recentLeftMessage
    /// 最近未读消息
    case lastedUnreadMessage
    /// 最远未读消息
    case oldestUnreadMessage
    /// 指定消息
    case specifiedMessages(position: Int32)
    /// 最新消息
    case lastedMessage
}

struct ScrollInfo {
    public let index: Int
    /// 传入nil使用默认策略：跳转middle，如果过长消息跳转top
    public let tableScrollPosition: UITableView.ScrollPosition?
    public let highlightPosition: Int32?
    public var needDuration: Bool
    public var customDurationTime: TimeInterval?
    public init(index: Int,
                tableScrollPosition: UITableView.ScrollPosition? = .top,
                highlightPosition: Int32? = nil,
                needDuration: Bool = true,
                customDurationTime: TimeInterval? = nil) {
        self.index = index
        self.tableScrollPosition = tableScrollPosition
        self.highlightPosition = highlightPosition
        self.needDuration = needDuration
        self.customDurationTime = customDurationTime
    }
}

enum ChatTableRefreshType: OuputTaskTypeInfo {
    case hasNewMessage(message: Message, hasFooter: Bool, withAnimation: Bool = true)
    case messageSendSuccess(message: Message, hasFooter: Bool)
    case messageSending(message: Message)
    case initMessages(InitMessagesInfo, needHighlight: Bool)
    case refreshMessages(hasHeader: Bool, hasFooter: Bool, scrollInfo: ScrollInfo?)
    case messagesUpdate(indexs: [Int], guarantLastCellVisible: Bool, animation: UITableView.RowAnimation)
    case loadMoreOldMessages(hasHeader: Bool)
    case loadMoreNewMessages(hasFooter: Bool)
    case updateHeaderView(hasHeader: Bool)
    case updateFooterView(hasFooter: Bool)
    case scrollTo(ScrollInfo)
    case startMultiSelect(startIndex: Int)
    case finishMultiSelect
    case refreshTable
    case refreshMissedMessage(anchorMessageId: String?) //刷新时保证指定消息位置不动，传消息id
    case highlight(position: Int32)
    case remain(hasFooter: Bool)
    case batchFetchSelectMessage(status: ChatBatchSelectMessageStatus)
    public func canMerge(type: ChatTableRefreshType) -> Bool {
        switch (self, type) {
        case (.updateHeaderView, .updateHeaderView),
             (.updateFooterView, .updateFooterView),
             (.refreshTable, .refreshTable),
             (.hasNewMessage, .hasNewMessage):
            return true
        default:
            return false
        }
    }

    public func duration() -> Double {
        // UI频控：降低刷新频率，和Android、PC对齐
        var duration: Double = 0.1
        switch self {
        case .hasNewMessage:
            duration = CommonTable.scrollToBottomAnimationDuration
        case .messageSending:
            duration = 0
        case .messagesUpdate(_, _, let animation) where animation == .none:
            duration = 0
        case .scrollTo(let scrollInfo):
            duration = scrollInfo.needDuration ? 0.1 : 0
        case .refreshMessages(_, _, let scrollInfo):
            duration = scrollInfo?.needDuration == true ? scrollInfo?.customDurationTime ?? 0.1 : 0.1
        default:
            break
        }
        return duration
    }

    public func isBarrier() -> Bool {
        switch self {
        case .messagesUpdate, .scrollTo:
            return true
        default:
            return false
        }
    }

    var describ: String {
        switch self {
        case .refreshTable:
            return "refreshTable"
        case .initMessages:
            return "initMessages"
        case .refreshMessages(hasHeader: let hasHeader, hasFooter: let hasFooter, _):
            return "refreshMessages \(hasHeader) \(hasFooter)"
        case .messagesUpdate:
            return "messagesUpdate"
        case .loadMoreOldMessages(hasHeader: let hasHeader):
            return "loadMoreOldMessages \(hasHeader)"
        case .loadMoreNewMessages(hasFooter: let hasFooter):
            return "loadMoreNewMessages \(hasFooter)"
        case .hasNewMessage(message: let message, hasFooter: let hasFooter, withAnimation: let withAnimation):
            return "hasNewMessage \(message.id) \(hasFooter) \(withAnimation)"
        case .updateHeaderView(hasHeader: let hasHeader):
            return "updateHeaderView \(hasHeader)"
        case .updateFooterView(hasFooter: let hasFooter):
            return "updateFooterView \(hasFooter)"
        case .scrollTo:
            return "scrollTo"
        case .startMultiSelect:
            return "startMultiSelect"
        case .finishMultiSelect:
            return "finishMultiSelect"
        case .messageSendSuccess(message: let message, hasFooter: let hasFooter):
            return "messageSendSuccess \(message.id) \(message.cid) \(hasFooter)"
        case .messageSending(let message):
            return "messageSending \(message.id) \(message.cid)"
        case .refreshMissedMessage(let anchorMessageId):
            return "refreshMissedMessage \(anchorMessageId ?? "")"
        case .highlight(position: let position):
            return "highlight \(position)"
        case .remain(let hasFooter):
            return "remain \(hasFooter)"
        case .batchFetchSelectMessage:
            return "batchFetchSelectMessage"
        }
    }
}
