//
//  ReadStatusViewModel.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/30.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkContainer
import LarkCore
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import LarkUIKit
import RustPB

// 从旧的逻辑搬过来的，从Message的RustPB.Basic_V1_RichText中读取被@的人
extension Message {
    var atChatterIds: [String] {
        switch self.type {
        case .text:
            if let richText = (self.content as? TextContent)?.richText {
                return richText.atIds.compactMap({ richText.elements[$0] }).map({ $0.property.at.userID })
            }
        case .post:
            if let richText = (self.content as? PostContent)?.richText {
                return richText.atIds.compactMap({ richText.elements[$0] }).map({ $0.property.at.userID })
            }
        @unknown default: return []
        }
        return []
    }
}

final class ReadStatusViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    fileprivate static let logger = Logger.log(ReadStatusViewModel.self, category: "ReadStatusViewModel")

    typealias SinglePageSectionData = (title: String, items: [ReadListCellViewModel])
    typealias SinglePageRichSectionData = (title: NSAttributedString, items: [ReadListCellViewModel])
    typealias ShowViewType = (showSearch: Bool, isSingleColumn: Bool, showLimited: Bool)

    private let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()

    private let currentChatterId: String
    private let pushCenter: PushNotificationCenter
    private let messageAPI: MessageAPI
    private let chatterAPI: ChatterAPI
    private let urgentAPI: UrgentAPI
    private var readCursor: String?
    private var unreadCursor: String?
    private var atUserIds: [String] = []
    private let displayNameScene: GetChatterDisplayNameScene

    private var isFirstLoaded: Bool = false
    private(set) var showType: ShowViewType = (false, false, false)

    let chat: Chat
    private(set) var message: Message
    let readStatusType: ReadStatusType
    let isDisplayPad: Bool = Display.pad

    var hasMoreRead: Bool { return !(readCursor?.isEmpty ?? true) }
    var hasMoreUnread: Bool { return !(unreadCursor?.isEmpty ?? true) }
    private(set) var readCount: Int = 0
    private(set) var unreadCount: Int = 0
    private(set) var readDataSource: [ReadListCellViewModel] = []
    private(set) var unreadDataSource: [ReadListCellViewModel] = []

    // 单页状态要把加急和@分出一个独立的Section
    private var atUsersDatas: [ReadListCellViewModel] = []
    private var normalDatas: [ReadListCellViewModel] = []
    private(set) var singlePageDataSource: [SinglePageSectionData] = []
    private(set) var singlePageRichDataSource: [SinglePageRichSectionData] = []

    // 搜索相关
    private(set) var searchDataSource: [ReadListCellViewModel] = []
    private var filterKey: String = ""
    private(set) var isInSearch: Bool = false

    private let isTypeDoubleLineVariable = BehaviorRelay<Bool?>(value: nil)
    var isTypeDoubleLineDriver: Driver<Bool?> {
        return isTypeDoubleLineVariable.asDriver()
    }

    // 单列双列、是否显示搜索框、是否显示底部提示条
    private let viewTypeBehavior = PublishSubject<ShowViewType>()
    var viewTypeDriver: Driver<ShowViewType> {
        return viewTypeBehavior.take(1).asDriver(onErrorRecover: { _ in .just((false, false, false)) })
    }

    // 数据刷新
    private let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)
    var statusVar: Driver<ChatChatterViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }

    init(userResolver: UserResolver,
        readStatusType: ReadStatusType,
        message: Message,
        currentChatterId: String,
        chat: Chat,
        pushCenter: PushNotificationCenter,
        messageAPI: MessageAPI,
        chatterAPI: ChatterAPI,
        urgentAPI: UrgentAPI) {
        self.userResolver = userResolver
        self.readStatusType = readStatusType
        self.message = message
        self.currentChatterId = currentChatterId
        self.pushCenter = pushCenter
        self.messageAPI = messageAPI
        self.chatterAPI = chatterAPI
        self.urgentAPI = urgentAPI
        self.chat = chat
        self.displayNameScene = chat.oncallId.isEmpty ? .readStatusList : .oncall
    }
}

private extension ReadStatusViewModel {

    /// 单页需要将@成员单独一个Section展示出来
    func formatSinglePageData(_ readItems: [ReadListCellViewModel],
                              _ unreadItems: [ReadListCellViewModel],
                              _ isAppend: Bool) {
        //过滤 加急 和 @
        let atRead = readItems.prefix(while: { $0.statusWeight > 0 })
        let atUnread = unreadItems.prefix(while: { $0.statusWeight > 0 })

        // 添加已读未读状态
        for item in atRead { item.isUnread = false }
        for item in atUnread { item.isUnread = true }

        atUsersDatas = (isAppend ? atUsersDatas : []) + atRead + atUnread
        normalDatas = (isAppend ? normalDatas : []) + readItems.suffix(readItems.count - atRead.count)

        let readCountTitle = "\(readCount)"
        let iPadRead = BundleI18n.LarkChat.Lark_Legacy_iPadRead
        let readTitle = readCountTitle + " " + iPadRead
        let readAttrText = NSMutableAttributedString(string: readTitle)

        let range = (readTitle as NSString).range(of: readCountTitle)
        readAttrText.addAttributes([.font: UIFont.systemFont(ofSize: 20, weight: .semibold)], range: range)
        readAttrText.addAttributes([.font: UIFont.systemFont(ofSize: 17)], range: (readTitle as NSString).range(of: iPadRead))
        let hugeGroupTitleAttrText = NSMutableAttributedString(string: BundleI18n.LarkChat.Lark_Group_HugeGroup_MsgReadList_Top_Title)

        if atUsersDatas.isEmpty {
            singlePageDataSource = [(BundleI18n.LarkChat.Lark_Legacy_ReadCount(readCount), normalDatas)]
            singlePageRichDataSource = [(readAttrText, normalDatas)]
        } else {
            singlePageDataSource = [(BundleI18n.LarkChat.Lark_Group_HugeGroup_MsgReadList_Top_Title, atUsersDatas),
                                    (BundleI18n.LarkChat.Lark_Legacy_ReadCount(readCount), normalDatas)]
            singlePageRichDataSource = [(hugeGroupTitleAttrText, atUsersDatas),
                                    (readAttrText, normalDatas)]
        }
    }

    func createCellViewModel(_ chatter: Chatter, isUnread: Bool = true) -> ReadListCellViewModel {

        let isAt = self.atUserIds.contains(chatter.id)
        let cellVM = ReadListCellViewModel(
            chatter: chatter,
            isUrgent: false,
            isAt: isAt,
            filterKey: filterKey
        ) { [weak self] (chatter) in
            return self?.getDisplayName(chatter: chatter) ?? ""
        }

        return cellVM
    }

    /// 将已读和未读解析成需要展示的样子，并根”isAppend“决定是追加还是替换数据
    ///
    /// - Parameters:
    ///   - readChatters: 已读Chatter
    ///   - unreadChatters: 未读Chatter
    ///   - isAppend: 是否追加
    func parseData(_ readChatters: [Chatter], _ unreadChatters: [Chatter], _ isAppend: Bool = false) {
        let currentChatterId = self.currentChatterId
        var readDataSource = readChatters.filter { currentChatterId != $0.id }.map({
            self.createCellViewModel($0, isUnread: false)
        })
        var unreadDataSource = unreadChatters.filter { currentChatterId != $0.id }.map({
            self.createCellViewModel($0)
        })

        // 在搜索状态下要合并已读已读未读成员列表
        if isInSearch {
            for item in unreadDataSource { item.isUnread = true }
            for item in readDataSource { item.isUnread = false }
            self.searchDataSource = unreadDataSource + readDataSource // 未读在前
            self.sortDataSource(&searchDataSource)
        } else {

            // 对数据排序
            self.sortDataSource(&readDataSource)
            self.sortDataSource(&unreadDataSource)

            // 单页展示时候，@和加急的人已读未读都要展示，且要展示已读未读标签
            if showType.isSingleColumn {
                formatSinglePageData(readDataSource, unreadDataSource, isAppend)
            } else {
                self.readDataSource = isAppend ? self.readDataSource + readDataSource : readDataSource
                self.unreadDataSource = isAppend ? self.unreadDataSource + unreadDataSource : unreadDataSource
            }
        }

        self.statusBehavior.onNext(.viewStatus(
            isInSearch && searchDataSource.isEmpty ?
                .searchNoResult(filterKey) :
                .display)
        )
    }

    /// 排序规则: urgent & at > urgent / at > none
    @discardableResult
    func sortDataSource(_ dataSource: inout [ReadListCellViewModel]) -> [ReadListCellViewModel] {
        let sortRule: (ReadListCellViewModel, ReadListCellViewModel) -> Bool = { (model1, model2) -> Bool in
            return model1.statusWeight > model2.statusWeight
        }
        dataSource.sort(by: sortRule)
        return dataSource
    }

    func getDisplayName(chatter: Chatter) -> String {
        return chatter.displayName(chatId: chat.id, chatType: chat.type, scene: displayNameScene)
    }
}

// MARK: - 普通的已读未读数据拉取
extension ReadStatusViewModel {

    /// 解析返回结果，获取已读和未读成员
    private func paseResult(_ result: RustPB.Im_V1_GetMessageReadStateResponse) -> (readChatters: [Chatter], unreadChatters: [Chatter]) {
        let chatters = result.entity.chatChatters[chat.id]?.chatters
        func getChatter(with id: String) -> Chatter? {
            guard let chatter = chatters?[id] ?? result.entity.chatters[id] else {
                ReadStatusViewModel.logger.error(
                    "read status view read chatter error",
                    additionalData: [
                        "chatID": chat.id,
                        "messageID": message.id,
                        "chatterID": id
                    ]
                )
                return nil
            }
            return Chatter.transform(pb: chatter)
        }
        let id = self.currentChatterId

        return (result.readState.readUserIds.filter { $0 != id }.compactMap { getChatter(with: $0) },
                result.readState.unreadUserIds.filter { $0 != id }.compactMap { getChatter(with: $0) })
    }

    private func loadNormalReadStatus() {
        ReadStatusViewModel.logger.info("start load normal read status, chatID: \(chat.id), messageID: \(message.id)")
        let chatID = self.chat.id
        let messageID = self.message.id
        messageAPI.getMessageReadStatus(
            messageId: messageID,
            listType: .all,
            query: nil,
            readCursor: nil,
            unreadCursor: nil,
            needUsers: true)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }

                self.showType = (result.readState.showSearchBox,
                                 result.readState.columnCount == 1,
                                 result.readState.showLimited)

                self.viewTypeBehavior.onNext(self.showType)

                self.isFirstLoaded = true
                self.readCursor = result.readCursor
                self.unreadCursor = result.unreadCursor

                self.readCount = Int(result.readState.readCount)
                self.unreadCount = Int(result.readState.unreadCount)
                self.atUserIds = result.readState.mentionUserIds
                self.syncMessageReadStuatus()

                let chatters = self.paseResult(result)
                self.parseData(chatters.readChatters, chatters.unreadChatters)
                ReadStatusViewModel.logger.info(
                    "read status did load;",
                    additionalData: [
                        "resultReadCount": "\(result.readState.readCount)",
                        "resultUnreadCount": "\(result.readState.unreadCount)",
                        "resultReadChattersCount": "\(chatters.readChatters.count)",
                        "resultUnreadChattersCount": "\(chatters.unreadChatters.count)"
                    ]
                )
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                ReadStatusViewModel.logger.error(
                    "get normal read status error",
                    additionalData: [
                        "chatID": chatID,
                        "messageID": messageID],
                    error: error
                )

                // 网络出错时添加一个默认样式
                self.viewTypeBehavior.onNext(self.showType)
                self.statusBehavior.onNext(.error(error))
            }).disposed(by: disposeBag)
    }

    // 读取第一屏数据，需要记录诸多状态
    func firstLoadReadStatus(showHud: Bool = true) {
        self.statusBehavior.onNext(.loading)

        if self.readStatusType == .urgent {
            self.loadUrgentReadStatus()
        } else {
            self.loadNormalReadStatus()
        }
    }

    // 拉取更多，需要记录是否还有更多
    func loadMore(_ listType: RustPB.Im_V1_GetMessageReadStateRequest.ListType) {
        let chatID = self.chat.id
        let messageID = self.message.id
        messageAPI.getMessageReadStatus(
            messageId: self.message.id,
            listType: listType,
            query: nil,
            readCursor: self.readCursor,
            unreadCursor: self.unreadCursor,
            needUsers: true)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }

                self.readCursor = result.readCursor
                self.unreadCursor = result.unreadCursor

                let chatters = self.paseResult(result)
                self.parseData(chatters.readChatters, chatters.unreadChatters, true)
                ReadStatusViewModel.logger.info(
                    "read status did load;",
                    additionalData: [
                        "resultReadCount": "\(result.readState.readCount)",
                        "resultUnreadCount": "\(result.readState.unreadCount)",
                        "resultReadChattersCount": "\(chatters.readChatters.count)",
                        "resultUnreadChattersCount": "\(chatters.unreadChatters.count)"
                    ]
                )
            }, onError: { [weak self] (error) in
                ReadStatusViewModel.logger.error(
                    "get more normal read status error",
                    additionalData: [
                        "chatID": chatID,
                        "messageID": messageID],
                    error: error
                )
                self?.statusBehavior.onNext(.viewStatus(.display))
            }).disposed(by: disposeBag)
    }

    // 搜索
    func filter(_ key: String) {
        guard isFirstLoaded else { return }

        self.filterKey = key
        self.searchDisposeBag = DisposeBag()
        if key.isEmpty {
            self.isInSearch = false
            self.statusBehavior.onNext(.viewStatus(.display))
        } else {
            self.isInSearch = true
            self.statusBehavior.onNext(.viewStatus(.loading))
        }

        messageAPI.getMessageReadStatus(
            messageId: self.message.id,
            listType: .all,
            query: key,
            readCursor: nil,
            unreadCursor: nil,
            needUsers: true)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                let chatters = self.paseResult(result)
                self.parseData(chatters.readChatters, chatters.unreadChatters)
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: searchDisposeBag)
    }
}

// MARK: - 加急已读状态ViewModel
private extension ReadStatusViewModel {

    /// 同步消息的加急状态
    ///
    /// - Parameter message: message
    /// - Returns: observable emit message with urgent status
    func syncMessageUrgent(_ message: Message) -> Observable<Message> {
        return urgentAPI.syncMessageUrgent(message: message)
    }

    func loadUrgentReadStatus() {
        let chatID = self.chat.id
        let messageID = self.message.id
        ReadStatusViewModel.logger.info("start load urgent read status, chatID: \(chatID), messageID: \(messageID)")
        syncMessageUrgent(message)
            .flatMap { [weak self] (message) -> Observable<([Chatter], [Chatter])> in

                guard let self = self else { return .just(([], [])) }

                self.message = message
                let chatterIds = message.ackUrgentChatterIds + message.unackUrgentChatterIds

                // 消息刷新后，拉取对应的群成员
                return self.chatterAPI.getChatChatters(ids: chatterIds, chatId: self.chat.id)
                    .map { (chatters) -> ([Chatter], [Chatter]) in
                        return (message.ackUrgentChatterIds.compactMap { chatters[$0] },
                                message.unackUrgentChatterIds.compactMap { chatters[$0] })
                    }
            }.subscribe(onNext: { [weak self] (readChatters, unreadChatters) in
                guard let self = self else { return }

                // 刷新ViewType
                self.showType = (false, false, false)
                self.viewTypeBehavior.onNext(self.showType)

                // 记录信息·
                self.isFirstLoaded = true
                self.atUserIds = self.message.atChatterIds

                self.readCount = readChatters.count
                self.unreadCount = unreadChatters.count
                self.parseData(readChatters, unreadChatters)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                ReadStatusViewModel.logger.error(
                    "get urgent read status error",
                    additionalData: [
                        "chatID": chatID,
                        "messageID": messageID],
                    error: error
                )

                self.viewTypeBehavior.onNext(self.showType)
                self.statusBehavior.onNext(.error(error))
            }).disposed(by: disposeBag)
    }
}

extension ReadStatusViewModel {
    // 反向刷新已读未读状态到Chat
    // 此处通过接口获得的数据中,Rust已经将自己从已读Count中去掉(做了-1)，
    // 但其他途径中msg携带的count没有处理，此处+1与外部数据保持一致
    func syncMessageReadStuatus() {
        let message = PushMessageReadstatus(
            channelId: self.chat.id,
            messageId: self.message.id,
            unreadCount: Int32(self.unreadCount),
            readCount: Int32(self.readCount + 1))
        self.pushCenter.post(message)
    }
}

extension ReadStatusViewModel {

    var title: String {
        switch readStatusType {
        case .message:
            return BundleI18n.LarkChat.Lark_Legacy_TitleActivityReadstate
        case .urgent:
            return BundleI18n.LarkChat.Lark_Chat_BuzzStatustitle
        }
    }

    var readWithoutCount: String {
        switch readStatusType {
        case .message:
            return BundleI18n.LarkChat.Lark_Legacy_ReadStatus
        case .urgent:
            return BundleI18n.LarkChat.Lark_Legacy_Confirmed
        }
    }

    var unreadWithoutCount: String {
        switch readStatusType {
        case .message:
            return BundleI18n.LarkChat.Lark_Legacy_TabNoRead
        case .urgent:
            return BundleI18n.LarkChat.Lark_Legacy_NotConfirmed
        }
    }

    var readTitleWithCount: String {
        switch readStatusType {
        case .message:
            if chat.isUserCountVisible {
                return BundleI18n.LarkChat.Lark_Legacy_ReadCount(readCount)
            } else {
                return BundleI18n.LarkChat.Lark_IM_HideMember_Read_Text
            }
        case .urgent:
            return BundleI18n.LarkChat.Lark_Chat_BuzzStatusConfirm(readCount)
        }
    }

    var unreadTitleWithCount: String {
        switch readStatusType {
        case .message:
            if chat.isUserCountVisible {
                return BundleI18n.LarkChat.Lark_Legacy_UnreadCount(unreadCount)
            } else {
                return BundleI18n.LarkChat.Lark_IM_HideMember_Unread_Text
            }
        case .urgent:
            return BundleI18n.LarkChat.Lark_Chat_BuzzStatusUnconfirm(unreadCount)
        }
    }

    var allRead: String {
        switch readStatusType {
        case .message, .urgent:
            return BundleI18n.LarkChat.Lark_Legacy_ReadStatusAllread
        }
    }

    var allunread: String {
        switch readStatusType {
        case .message, .urgent:
            return BundleI18n.LarkChat.Lark_Legacy_ReadStatusAllunread
        }
    }

}
