//
//  GroupFreeBusyChatterControllerVM.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/7/30.
//

import Foundation
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import RustPB
import LarkBizTag
import LarkTag
import LarkContainer

public final class GroupFreeBusyChatterControllerVM {
    let userResolver: UserResolver
    public typealias ChatterFliter = (_ chatter: Chatter) -> Bool

    /// 追加自定义Tag
    public typealias AppendTagProvider = (_ chatter: Chatter) -> [LarkBizTag.TagType]?

    private var disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()

    public var defaultSelectedIds: [String]?
    public private(set) var chatId: String

    private var currentChatterId: String { userResolver.userID }
    private var chat: Chat
    private var chatAPI: ChatAPI
    private var chatterAPI: ChatterAPI
    private var serverNTPTimeService: ServerNTPTimeService
    private var parseCache: [String: ChatChatterWapper] = [: ]
    private var isOwner: Bool { chat.ownerId == currentChatterId }
    private let chatterFliter: ChatterFliter
    private let appendTagProvider: AppendTagProvider?
    private var isOwnerSelectable: Bool

    var datas: [ChatChatterSection] = []
    var searchDatas: [ChatChatterSection] = []

    private var isFirstDataLoaded: Bool = false
    private(set) var shouldShowTipView: Bool = false

    var onLoadDefaultSelectedItems: ((_ items: [ChatChatterItem]) -> Void)?

    var isInSearch: Bool {
        !(filterKey ?? "").isEmpty
    }

    var filterKey: String?
    var cursor: String?

    private let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)
    public var statusVar: Driver<ChatChatterViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }

    private let schedulerType: SchedulerType
    let selectCallBack: ([String]) -> Void

    public init(userResolver: UserResolver,
                chat: Chat,
                selectedChatterIds: [String],
                chatAPI: ChatAPI,
                chatterAPI: ChatterAPI,
                serverNTPTimeService: ServerNTPTimeService,
                chatterFliter: ChatterFliter? = nil,
                appendTagProvider: AppendTagProvider? = nil,
                isOwnerSelectable: Bool = false,
                selectCallBack: @escaping ([String]) -> Void
    ) {
        self.userResolver = userResolver
        self.chat = chat
        self.chatId = chat.id
        self.defaultSelectedIds = selectedChatterIds
        self.chatAPI = chatAPI
        self.chatterAPI = chatterAPI
        self.serverNTPTimeService = serverNTPTimeService
        self.chatterFliter = chatterFliter ?? { _ in true }
        self.appendTagProvider = appendTagProvider
        self.isOwnerSelectable = isOwnerSelectable
        self.selectCallBack = selectCallBack
        let queue = DispatchQueue.global()
        schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)
    }
}

// 对外暴露的Load方法
extension GroupFreeBusyChatterControllerVM {

    // 首次加载数据，需要加载默认选中的数据，所以单独拉出来处理
    func firstLoadData() {
        loadData()
            .flatMap { [weak self] (result) -> Observable<([ChatChatterSection], [ChatChatterItem])> in
                guard let self = self else { return .empty() }
                return self.loadDefaultSelectedItem().map { (result, $0) }
            }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas, defaultSeletedItems) in
                guard let self = self else { return }

                self.datas = datas
                self.onLoadDefaultSelectedItems?(defaultSeletedItems)

                self.statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))

                self.isFirstDataLoaded = true
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: disposeBag)
    }

    // 上啦加载更多
    func loadMoreData() {
        guard isFirstDataLoaded else { return }

        loadData()
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas) in
                self?.merge(datas)
                self?.statusBehavior.onNext(.viewStatus(.display))
            }, onError: { [weak self] _ in
                self?.statusBehavior.onNext(.viewStatus(.display))
            }).disposed(by: disposeBag)
    }

    // 搜索接口
    func loadFilterData(_ key: String) {
        guard isFirstDataLoaded else { return }

        filterKey = key
        searchDisposeBag = DisposeBag()

        if isInSearch {
            statusBehavior.onNext(.viewStatus(.loading))
        } else {
            statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
            return
        }

        loadData()
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self, let filterKey = self.filterKey else { return }
                self.searchDatas = result
                self.statusBehavior.onNext(.viewStatus(result.isEmpty ? .searchNoResult(filterKey) : .display))
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: searchDisposeBag)
    }

}

// 数据加载和处理
private extension GroupFreeBusyChatterControllerVM {
    // 获取显示名
    func itemName(for chatter: Chatter) -> String {
        return chatter.displayName(
            chatId: chatId,
            chatType: chat.type,
            scene: chat.oncallId.isEmpty ? .groupMemberList : .oncall)
    }

    // 获取Tag：外部、群主、负责人、机器人等
    func itemTags(for chatter: Chatter) -> [TagDataItem]? {
        var result: [LarkBizTag.TagType] = appendTagProvider?(chatter) ?? []
        var tagDataItems: [TagDataItem] = []

        chatter.tagData?.tagDataItems.forEach { item in
            let isExternal = item.respTagType == .relationTagExternal
            if isExternal {
                result.append(.external)
            } else {
                let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                         tagType: item.respTagType.transform(),
                                                         priority: Int(item.priority))
                tagDataItems.append(tagDataItem)
            }
        }

        /// 判断勿扰模式
        if self.serverNTPTimeService.afterThatServerTime(time: chatter.doNotDisturbEndTime) {
            result.append(.doNotDisturb)
        }

        if chatter.id == chat.ownerId {
            result.append(.groupOwner)
        }

        if chatter.type == .bot {
            result.append(.robot)
        }

        /// 未注册
        if !chatter.isRegistered {
            result.append(.unregistered)
        }
        tagDataItems.append(contentsOf: chatter.eduTags.map({ tag in
            return TagDataItem(text: tag.title,
                               tagType: .customTitleTag,
                               frontColor: tag.style.textColor,
                               backColor: tag.style.backColor)
        }))
        tagDataItems.append(contentsOf: result.map({ type in
            let defaultInfo = Tag.defaultTagInfo(for: type.convert())
            return TagDataItem(text: defaultInfo.title, image: defaultInfo.image, tagType: type)
        }))

        return tagDataItems.isEmpty ? nil : tagDataItems
    }

    /// 包装成 ChatChatterItem
    func wrapper(_ chatter: Chatter) -> ChatChatterWapper? {
        guard chatter.type == .user, chatterFliter(chatter) else { return nil }
        if let item = parseCache[chatter.id] { return item }
        var item = ChatChatterWapper(
            chatter: chatter,
            itemName: self.itemName(for: chatter),
            itemTags: self.itemTags(for: chatter),
            itemCellClass: GroupFreeBusyChatterCell.self)
        item.isSelectedable = currentChatterId != chatter.id || isOwnerSelectable
        parseCache[chatter.id] = item
        return item
    }

    // 解析返回数据
    func paserDatas(_ result: RustPB.Im_V1_GetChatChattersResponse, chatterIds: [[String: [String]]]) -> [ChatChatterSection] {
        guard let chatChatters = result.entity.chatChatters[chatId]?.chatters else { return [] }

        return chatterIds.compactMap { (section) -> ChatChatterSection? in

            return section.compactMap { (key, chatterIds) -> ChatChatterSection? in

                let items = chatterIds.compactMap({ (id) -> ChatChatterWapper? in
                    guard let pb = chatChatters[id] else { return nil }
                    if pb.type != .user { return nil }
                    return wrapper(Chatter.transform(pb: pb))
                })

                return items.isEmpty ? nil :
                    ChatChatterSectionData(
                        title: key,
                        indexKey: key,
                        items: items,
                        sectionHeaderClass: ContactTableHeader.self)
            }.first
        }
    }

    func loadDefaultSelectedItem() -> Observable<[ChatChatterItem]> {
        guard let defaultSelectedIds = defaultSelectedIds, !defaultSelectedIds.isEmpty else { return .just([]) }

        return chatterAPI.getChatters(ids: defaultSelectedIds).map({ [weak self] (map) -> [ChatChatterItem] in
            guard let self = self else { return [] }
            return map.values.compactMap { self.wrapper($0) }
        })
    }

    // load数据
    func loadData(isFirst: Bool = false) -> Observable<[ChatChatterSection]> {
        /// 大群SDK无法统计已经下发的人数，需要端上传入已经拉取的Chatter的数量；搜索时不需要
        let offset = isInSearch ? nil : datas.reduce(into: 0, { $0 += $1.items.count })
        return chatterAPI.getChatChatters(
            chatId: chatId,
            filter: filterKey,
            cursor: cursor,
            limit: nil,
            condition: nil,
            forceRemote: !isFirst,
            offset: offset,
            fromScene: nil
        ).subscribeOn(schedulerType)
        .map { [weak self] (result) -> [ChatChatterSection] in
            guard let self = self else { return [] }

            if !self.isInSearch {
                self.cursor = result.cursor
            }
            self.shouldShowTipView = result.showSearch

            let formatedChatterIDs = isFirst ?
                result.formatedChatterIDs(.swapOwnerToFirst(self.chat.ownerId)) :
                result.formatedChatterIDs(.normal)

            return self.paserDatas(result, chatterIds: formatedChatterIDs)
        }
    }

    // 由于分页且分组，所以数据需要merge而不是直接追加
    func merge(_ newDatas: [ChatChatterSection]) {
        datas.merge(newDatas)
    }
}
