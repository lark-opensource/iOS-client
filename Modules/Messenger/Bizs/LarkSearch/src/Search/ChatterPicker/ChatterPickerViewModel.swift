//
//  ChatterPickerViewModel.swift
//  LarkSearch
//
//  Created by qihongye on 2019/7/28.
//

import Foundation
import LarkContainer
import LarkCore
import LarkModel
import RxSwift
import RxCocoa
import Swinject
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import RustPB
import LarkBizTag

protocol GroupChatterPickWithSearchViewModel {
    var shouldShowTipView: Bool { get }
    var navibarTitle: String { get }
    var isInSearch: Bool { get }
    var canSearch: Driver<Bool> { get }
    var filterKey: String? { get }
    var cursor: String? { get }
    var statusVar: Driver<ChatChatterViewStatus> { get }
    var chatterSectionsData: [ChatChatterSection] { get }
    var selectedChatters: [Chatter] { get }
    func loadFirstScreen()
    func loadFilterData(matchText: String)
    func loadMoreData()
    func selectChatter(chatter: Chatter, select: Bool)
}

struct PickerItem {
    let letter: String
    var chatterIDs: [String]
}

final class ChatterPickerViewModel: GroupChatterPickWithSearchViewModel {
    private let chat: Chat
    private let tenantID: String
    private let currentChatterID: String
    private var pickInChatterIDs: [String]
    private var parseCache: [String: ChatChatterWapper] = [:]
    private let chatAPI: ChatAPI
    private let chatterAPI: ChatterAPI
    private let serverNTPTimeService: ServerNTPTimeService
    private let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()
    private let schedulerType: SerialDispatchQueueScheduler
    private let currentUserType: PassportUserType
    private let preSelectIDs: [String]?

    let navibarTitle: String

    private(set) var shouldShowTipView: Bool = false
    let searchEnabled: Bool
    let showChatChatters: Bool

    var isInSearch: Bool {
        !(filterKey ?? "").isEmpty
    }

    private var sections: [ChatChatterSection] = [] {
        didSet {
            let showSearch = searchEnabled && (sections.reduce(0, { $0 + $1.items.count }) > 7)
            _canSearchBehavior.onNext(showSearch)
        }
    }
    private var searchSections: [ChatChatterSection] = []
    var chatterSectionsData: [ChatChatterSection] {
        return isInSearch ? searchSections : sections
    }

    private(set) var filterKey: String?

    private(set) var cursor: String?

    private let _canSearchBehavior = BehaviorSubject<Bool>(value: false)
    var canSearch: Driver<Bool> {
        return _canSearchBehavior.asDriver(onErrorJustReturn: false)
    }

    private let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)
    var statusVar: Driver<ChatChatterViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }

    private(set) var selectedChatters: [Chatter] = []

    init(chat: Chat,
         tenantID: String,
         currentChatterID: String,
         pickInChatterIDs: [String] = [],
         searchEnabled: Bool = true,
         showChatChatters: Bool = true,
         chatAPI: ChatAPI,
         chatterAPI: ChatterAPI,
         serverNTPTimeService: ServerNTPTimeService,
         currentUserType: PassportUserType,
         navibarTitle: String,
         preSelectIDs: [String]? = nil
    ) {
        self.chat = chat
        self.tenantID = tenantID
        self.currentChatterID = currentChatterID
        self.pickInChatterIDs = pickInChatterIDs
        self.searchEnabled = searchEnabled
        self.showChatChatters = showChatChatters
        self.chatAPI = chatAPI
        self.chatterAPI = chatterAPI
        self.serverNTPTimeService = serverNTPTimeService
        self.currentUserType = currentUserType
        self.schedulerType = SerialDispatchQueueScheduler(internalSerialQueueName: "ChatterPickerViewModel")
        self.navibarTitle = navibarTitle
        self.preSelectIDs = preSelectIDs
    }

    func loadFirstScreen() {
        loadData(isFirst: true)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas) in
                guard let self = self else { return }

                self.sections = datas

                if self.isInSearch, datas.isEmpty {
                    self.statusBehavior.onNext(.viewStatus(.searchNoResult(self.filterKey ?? "")))
                } else if datas.isEmpty {
                    self.statusBehavior.onNext(.viewStatus(.empty))
                } else {
                    self.statusBehavior.onNext(.viewStatus(.display))
                }
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: disposeBag)
    }

    func loadFilterData(matchText: String) {
        filterKey = matchText
        searchDisposeBag = DisposeBag()

        if !isInSearch {
            statusBehavior.onNext(.viewStatus(.display))
            return
        }
        statusBehavior.onNext(.viewStatus(.loading))

        loadData()
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.searchSections = result
                self.statusBehavior.onNext(.viewStatus(result.isEmpty ? .searchNoResult(matchText) : .display))
                }, onError: { [weak self] (error) in
                    self?.statusBehavior.onNext(.error(error))
                }).disposed(by: searchDisposeBag)
    }

    func loadMoreData() {
        loadData()
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas) in
                guard let self = self else { return }
                // 由于分页且分组，所以数据需要merge而不是直接追加
                self.sections.merge(datas)
                self.statusBehavior.onNext(.viewStatus(.display))
            }, onError: { [weak self] _ in
                self?.statusBehavior.onNext(.viewStatus(.display))
            }).disposed(by: disposeBag)
    }

    func selectChatter(chatter: Chatter, select: Bool) {
        if select {
            selectedChatters.lf_appendIfNotContains(chatter)
        } else {
            selectedChatters.lf_remove(object: chatter)
        }
    }

    // 将ChatterIds格式统一，方便下一步处理
    private func formatChatterIDs(_ result: RustPB.Im_V1_GetChatChattersResponse) -> [PickerItem] {
        let ownerId = chat.ownerId
        if result.letterMaps.isEmpty {
            var item = PickerItem(letter: "", chatterIDs: [ownerId])
            let other = result.chatterIds.filter {
                $0 != ownerId
            }
            if !other.isEmpty {
                item.chatterIDs.append(contentsOf: other)
            }
            return [item]
        }
        return [PickerItem(letter: "", chatterIDs: [ownerId])]
            + result.letterMaps.compactMap({ (letterMap) -> PickerItem? in
            var chatterIds = letterMap.chatterIds
            chatterIds.removeAll { $0 == ownerId }
            return chatterIds.isEmpty
                ? nil
                : PickerItem(letter: letterMap.letter, chatterIDs: chatterIds)
        })
    }

    // 解析返回数据
    private func parseDatas(_ result: RustPB.Im_V1_GetChatChattersResponse, pickerItems: [PickerItem], isFirst: Bool) -> [ChatChatterSection] {
        guard let chatChatters = result.entity.chatChatters[chat.id]?.chatters else {
            return []
        }

        return pickerItems.compactMap { (pickerItem) -> ChatChatterSection? in
            let items = pickerItem.chatterIDs.compactMap { (id) -> ChatChatterWapper? in
                guard let pb = chatChatters[id] else {
                    return nil
                }
                return wrapper(Chatter.transform(pb: pb), isFirst: isFirst)
            }
            return items.isEmpty
                ? nil
                : ChatChatterSectionData(
                    title: pickerItem.letter,
                    indexKey: pickerItem.letter,
                    items: items,
                    sectionHeaderClass: ContactTableHeader.self
                )
        }
    }

    /// 包装成 ChatChatterItem
    private func wrapper(_ chatter: Chatter, isFirst: Bool) -> ChatChatterWapper? {
        if let item = parseCache[chatter.id] { return item }
        var item = ChatChatterWapper(
            chatter: chatter,
            itemName: itemName(for: chatter),
            itemTags: itemTags(for: chatter),
            itemCellClass: ChatChatterCell.self,
            descInlineProvider: nil,
            descUIConfig: nil
        )
//        item.isSelectedable = currentChatterID != chatter.id
        parseCache[chatter.id] = item
        if let preSelectIDs = preSelectIDs, isFirst, preSelectIDs.contains(where: { $0 == chatter.id }) {
            selectedChatters.lf_appendIfNotContains(chatter)
        }
        return item
    }

    // 获取显示名
    private func itemName(for chatter: Chatter) -> String {
        return chatter.displayName(
            chatId: chat.id,
            chatType: chat.type,
            scene: chat.oncallId.isEmpty ? .groupMemberList : .oncall)
    }

    // 获取Tag：外部、群主、负责人、机器人等
    private func itemTags(for chatter: Chatter) -> [TagDataItem]? {

        var result: [TagDataItem] = []

        /// 判断勿扰模式
        if serverNTPTimeService.afterThatServerTime(time: chatter.doNotDisturbEndTime) {
            result.append(TagDataItem(tagType: .doNotDisturb))
        }

        if chatter.id == chat.ownerId {
            result.append(TagDataItem(tagType: .groupOwner))
        }

        if chatter.type == .bot {
            result.append(TagDataItem(tagType: .robot))
        }

        /// 未注册
        if !chatter.isRegistered {
            result.append(TagDataItem(tagType: .unregistered))
        }
        if let items = chatter.tagData?.transform() {
            result.append(contentsOf: items)
        }
        result.append(contentsOf: chatter.eduTags.map({ tag in
            return TagDataItem(text: tag.title,
                               tagType: .customTitleTag,
                               frontColor: tag.style.textColor,
                               backColor: tag.style.backColor)
        }))
        return result
    }

    // load数据
    private func loadData(isFirst: Bool = false) -> Observable<[ChatChatterSection]> {
        if pickInChatterIDs.isEmpty, !showChatChatters {
            return .just([])
        }
        if !pickInChatterIDs.isEmpty {
            return chatterAPI.getChatters(ids: pickInChatterIDs).map { [weak self] (chatters) -> [ChatChatterSection] in
                guard let self = self else { return [] }
                let chatterWrappers = self.pickInChatterIDs
                    .compactMap({ chatters[$0] })
                    .compactMap({ self.wrapper($0, isFirst: isFirst) })
                guard !chatterWrappers.isEmpty else { return [] }
                return [
                    ChatChatterSectionData(
                        title: nil,
                        indexKey: nil,
                        items: chatterWrappers,
                        sectionHeaderClass: ContactTableHeader.self
                    )
                ]
            }
        }

        /// 大群SDK无法统计已经下发的人数，需要端上传入已经拉取的Chatter的数量；搜索时不需要
        let offset = isInSearch ? nil : sections.reduce(into: 0, { $0 += $1.items.count })
        return chatterAPI.getChatChatters(
            chatId: chat.id,
            filter: filterKey,
            cursor: cursor,
            limit: nil,
            condition: nil,
            forceRemote: true,
            offset: offset,
            fromScene: nil)
            .map { [weak self] (result) -> [ChatChatterSection] in
                guard let self = self else { return [] }
                if !self.isInSearch {
                    self.cursor = result.cursor
                }
                self.shouldShowTipView = result.showSearch
                return self.parseDatas(result, pickerItems: self.formatChatterIDs(result), isFirst: isFirst)
            }
    }
}
