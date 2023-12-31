//
//  LarkInterface+Feed.swift
//  LarkInterface
//
//  Created by Yuguo on 2018/6/20.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import RxCocoa
import RxSwift
import RustPB

/// Feed Selection Infos
/// * feedId: the selection feed`s id, nil represent no selection
/// * peak: move feed to top in feed list
public struct FeedSelection {
    static public let contextKey: String = "kFeedSelection"

    public let feedId: String?
    public var parendId: String?
    public let selectionType: FeedSelectionType?
    public let peak: Bool
    public var filterTabType: Feed_V1_FeedFilter.TypeEnum?
    public var extra: [String: Any]?

    public init(feedId: String? = nil,
                selectionType: FeedSelectionType? = nil,
                needSyncSelectInList: Bool = false,
                peak: Bool = false,
                showDetail: Bool = false,
                row: Int? = nil) {
        self.feedId = feedId
        self.selectionType = selectionType
        self.peak = peak
    }
}

public enum FeedSelectionType {
    /// should skip the same last feed
    case skipSame
    /// locally make in feed list
    case syncSelect
}

// UIViewController 实现该协议处理 iPad Feed Selection 问题
public protocol FeedSelectionInfoProvider {
    func getFeedIdForSelected() -> String?
}

public protocol FeedSyncDispatchService: AnyObject {
    // 转发到帖子时需要message+message对应chat
    typealias ForwardMessage = (chat: Chat, message: Message?)
    var dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
    var inboxFeedsReadyDriver: Driver<Bool> { get }
    var allShortcutChats: [Chat] { get }
    func fetchAllShortcutChats() -> Observable<[Chat]>
    /// chatType 为 nil 时表示全部
    func topInboxChats(by count: Int, chatType: [Chat.ChatMode]?, needChatBox: Bool) -> Observable<[Chat]>
    func currentAllStaffChatId() -> String?
    func topInboxData(by count: Int) -> Observable<[ForwardMessage]>
    func topInboxData(by count: Int, containMsgThread: Bool) -> Observable<(forwardMessages: [ForwardMessage], msgThreadMap: [String: String])>

}

public protocol FeedSyncDispatchServiceForDoc: AnyObject {
    func isFeedCardShortcut(feedId: String) -> Bool
}
