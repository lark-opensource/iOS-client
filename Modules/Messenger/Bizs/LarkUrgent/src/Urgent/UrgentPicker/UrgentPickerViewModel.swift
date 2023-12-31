//
//  UrgentPickerVM.swift
//  Action
//
//  Created by kongkaikai on 2019/2/24.
//

import Foundation
import LarkCore
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import ThreadSafeDataStructure
import RustPB
import LarkBizTag

final class UrgentPickerViewModel {
    private typealias ChatLimitInfo = RustPB.Im_V1_GetChatLimitInfoResponse
    private static let logger = Logger.log(
        UrgentPickerViewModel.self,
        category: "Module.IM.UrgentPickerViewModel")

    private var disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()
    private(set) var message: Message
    private(set) var chatId: String
    private(set) var chat: Chat
    private var tenantId: String
    private var currentChatterId: String
    private var displayNameScene: GetChatterDisplayNameScene
    private var chatType: Chat.TypeEnum?
    private var chatAPI: ChatAPI
    private var urgentAPI: UrgentAPI
    private var chatterAPI: ChatterAPI
    private var messageAPI: MessageAPI
    private var contactAPI: ContactAPI
    private var serverNTPTimeService: ServerNTPTimeService
    private var parseCache: SafeDictionary<String, UrgentChatterModel> = [:] + .readWriteLock
    private var cacheData: [UrgentChatterSectionData]?

    private var isFirstDataLoaded: Bool = false
    private let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)

    // 被权限管控的chatter
    var totalDenyChatters: [UrgentChatterModel] {
        var result: [UrgentChatterModel] = []
        let totalSection = self.datas.getImmutableCopy() + self.searchDatas.getImmutableCopy()
        var totalDenyChatterIds: String = ""
        for section in totalSection {
            for item in section.items where item.hitDenyReason != nil {
                result.append(item)
                totalDenyChatterIds += "\(item.id) "
            }
        }
        Self.logger.info("urgent picker totalDenyChatters \(self.chatId) \(totalDenyChatterIds)")
        return result
    }

    var isLargeGroup: Bool {
        return chatLimitInfo.isLargeGroup
    }
    var openSecurity: Bool {
        return chatLimitInfo.openSecurity
    }
    private var chatLimitInfo: ChatLimitInfo = ChatLimitInfo()

    // 未读用户
    private(set) var unreadChatters: [UrgentChatterModel] = [] {
        didSet {
            let ids = unreadChatters.map { $0.id }
            unreadChatterIdsSet = Set(ids)
        }
    }
    private(set) var unreadChatterIdsSet: Set<String> = []
    private var defaultSelectedIds: [String]?

    /// 默认被选中的人
    var getDefalutSelectedItems: ((_ items: [UrgentChatterModel]) -> Void)?
    // 是否处于全选未读模式(只有手动取消全选才能退出)
    var isSelecteAllUnreadMode = false
    // 全选未读后取消选择的人
    lazy var unselectedChatterIdsWhenAllSelectedUnread: [String] = []
    var unselectedChatterIdsWhenAllSelectedUnreadSet: Set<String> {
        Set<String>(unselectedChatterIdsWhenAllSelectedUnread)
    }
    // 全选未读后选择已读的人
    lazy var selectedReadChatterIdsWhenAllSelectedUnread: [String] = []
    var selectedReadChatterIdsWhenAllSelectedUnreadSet: Set<String> {
        Set<String>(selectedReadChatterIdsWhenAllSelectedUnread)
    }

    // 是否能全选未读
    var canAllSelectedUnread = false

    var tableViewModel: UrgentTableViewModel
    var statusVar: Driver<ChatChatterViewStatus> {
        return self.statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }

    private let schedulerType: SchedulerType
    var isInSearch: Bool {
        !(filterKey ?? "").isEmpty
    }
    // 全选未读场景 & 未全部拉取场景 下的总人数, 用来显示toolbar的总选择人数
    var allCountWhenAllSelectedUnreadAndNotFetchAll: Int64 = 0

    private(set) var filterKey: String?
    private(set) var cursor: String?

    private(set) var datas: SafeArray<UrgentChatterSectionData> = [] + .readWriteLock
    private(set) var searchDatas: SafeArray<UrgentChatterSectionData> = [] + .readWriteLock

    private(set) var authDeniedReasons: [String: UrgentChatterAuthDenyReason] = [:]
    var isFetchAll: Bool = false
    var groups: [UrgentConfrimChatterGroup] = []

    init(message: Message,
         chat: Chat,
         accountService: PassportUserService,
         chatAPI: ChatAPI,
         chatterAPI: ChatterAPI,
         messageAPI: MessageAPI,
         serverNTPTimeService: ServerNTPTimeService,
         urgentAPI: UrgentAPI,
         contactAPI: ContactAPI) {

        self.message = message
        self.chat = chat
        self.tableViewModel = UrgentTableViewModel()
        self.chatId = message.channel.id
        self.tenantId = accountService.userTenant.tenantID
        self.currentChatterId = accountService.user.userID
        self.chatAPI = chatAPI
        self.urgentAPI = urgentAPI
        self.messageAPI = messageAPI
        self.serverNTPTimeService = serverNTPTimeService
        self.chatterAPI = chatterAPI
        self.contactAPI = contactAPI

        self.tableViewModel.bottomTipMessage = BundleI18n.LarkUrgent.Lark_Group_HugeGroup_MemberList_Bottom

        self.displayNameScene = chat.oncallId.isEmpty ? .atOrUrgentPick : .oncall
        self.chatType = chat.type

        let queue = DispatchQueue.global()
        self.schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)

        if let atUserContent = message.content as? HasAtUsers {

            var defaultSelectedIdSet = atUserContent.atUserIdsSet
                .subtracting(atUserContent.atOuterIdsSet)
                .subtracting(message.readAtChatterIds)
                .union(message.unackUrgentChatterIds)
            defaultSelectedIdSet.remove(currentChatterId)

            self.defaultSelectedIds = Array(defaultSelectedIdSet)
        }
    }
}

// 对外暴露的Load方法
extension UrgentPickerViewModel {
    func removeSelectedReadChatterIdsWhenAllSelectedUnreadWith(_ item: UrgentChatterModel) {
        selectedReadChatterIdsWhenAllSelectedUnread.removeAll(where: { $0 == item.id })
        let newGroups = groups.map { group -> UrgentConfrimChatterGroup in
            var newGroup = group
            if newGroup.type == item.unSupportChatterType {
                newGroup.displayChatters.removeAll { $0.id == item.id }
                newGroup.allCount -= 1
            }
            return newGroup
        }
        self.groups = newGroups
    }

    func appendSelectedReadChatterIdsWhenAllSelectedUnreadWith(_ item: UrgentChatterModel) {
        selectedReadChatterIdsWhenAllSelectedUnread.append(item.id)
        let newGroups = groups.map { group -> UrgentConfrimChatterGroup in
            var newGroup = group
            if newGroup.type == item.unSupportChatterType {
                newGroup.displayChatters.append(item.chatter)
                newGroup.allCount += 1
            }
            return newGroup
        }
        self.groups = newGroups
    }

    func removeUnselectedChatterIdsWhenAllSelectedUnreadWith(_ item: UrgentChatterModel) {
        unselectedChatterIdsWhenAllSelectedUnread.removeAll(where: { $0 == item.id })
        let newGroups = groups.map { group -> UrgentConfrimChatterGroup in
            var newGroup = group
            if newGroup.type == item.unSupportChatterType {
                newGroup.displayChatters.append(item.chatter)
                newGroup.allCount += 1
            }
            return newGroup
        }
        self.groups = newGroups
    }

    func appendUnselectedChatterIdsWhenAllSelectedUnreadWith(_ item: UrgentChatterModel) {
        unselectedChatterIdsWhenAllSelectedUnread.append(item.id)
        let newGroups = groups.map { group -> UrgentConfrimChatterGroup in
            var newGroup = group
            if newGroup.type == item.unSupportChatterType {
                newGroup.displayChatters.removeAll { $0.id == item.id }
                newGroup.allCount -= 1
            }
            return newGroup
        }
        self.groups = newGroups
    }

    // 首次加载数据，需要加载默认选中的数据，所以单独拉出来处理
    func firstLoadData() {
        let limit = getChatLimit()

        Observable.zip(
            loadData(),
            loadDefaultSelectedItem(),
            limit)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas, defaultSeletedItems, _) in
                guard let self = self else { return }

                self.datas.replaceInnerData(by: datas)
                self.getDefalutSelectedItems?(defaultSeletedItems)
                self.selectedReadChatterIdsWhenAllSelectedUnread = defaultSeletedItems.filter { $0.isRead }.map { $0.id }

                self.statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
                self.isFirstDataLoaded = true
                self.unreadChatters = self.datas.reduce([], { partialResult, data in
                    return partialResult + data.items.filter({ !$0.isRead })
                }).flatMap { $0 }
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
                guard let self = self else { return }

                self.merge(datas)
                self.statusBehavior.onNext(.viewStatus(.display))
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
                self.searchDatas.replaceInnerData(by: result)
                self.statusBehavior.onNext(.viewStatus(result.isEmpty ? .searchNoResult(filterKey) : .display))
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: searchDisposeBag)
    }

    func removeChatters(with chatterIds: [String]) {
        self.chatAPI.deleteChatters(chatId: chatId, chatterIds: chatterIds, newOwnerId: nil)
            .subscribe(onNext: { [weak self] _ in
                self?.defaultSelectedIds = []
                self?.cursor = nil
                self?.filterKey = nil
                self?.firstLoadData()
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: disposeBag)
    }

    func pullSelectUrgentChattersRequest() -> Observable<[UrgentConfrimChatterGroup]> {
        return self.urgentAPI
            .pullSelectUrgentChattersRequest(messageId: message.id,
                                             selectType: isLargeGroup ? .allChatter : .allUnreadChatter,
                                             chatId: chatId,
                                             disableList: unselectedChatterIdsWhenAllSelectedUnread,
                                             additionalList: selectedReadChatterIdsWhenAllSelectedUnread)
            .flatMap { res -> Observable<[UrgentConfrimChatterGroup]> in
                let transfromer: (UrgentChatterRestrictGroup, UnSupportChatterType) -> UrgentConfrimChatterGroup = { (group, type) in
                    return UrgentConfrimChatterGroup(displayChatters: group.boundedChatters.map { Chatter.transform(pb: $0) }, allCount: Int(group.count), type: type)
                }
                return .just([transfromer(res.successGroup, .none),
                              transfromer(res.crossGroup, .crossGroup),
                              transfromer(res.emptyNameGroup, .emptyName),
                              transfromer(res.emptyPhoneGroup, .emptyPhone),
                              transfromer(res.externalNotFriendGroup, .externalNotFriend)])
            }
    }
}

// 数据加载和处理
private extension UrgentPickerViewModel {
    // 获取显示名
    func itemName(for chatter: Chatter) -> String {
        return chatter.displayName(
            chatId: self.chatId,
            chatType: self.chatType,
            scene: self.displayNameScene)
    }

    // 获取Tag：外部、群主、负责人、机器人等
    func itemTags(for chatter: Chatter) -> [TagDataItem]? {
        var result: [LarkBizTag.TagType] = []
        var tagDataItems: [TagDataItem] = []

        /// 判断勿扰模式
        if self.serverNTPTimeService.afterThatServerTime(time: chatter.doNotDisturbEndTime) {
            result.append(.doNotDisturb)
        }
        if let tagData = chatter.tagData, tagData.tagDataItems.isEmpty == false {
            tagDataItems.append(contentsOf: tagData.transform())
        }
        if !chatter.isRegistered { result.append(.unregistered) }
        tagDataItems.append(contentsOf: result.map({ type in
            return TagDataItem(tagType: type)
        }))

        return tagDataItems.isEmpty ? nil : tagDataItems
    }

    // 包装成 UrgentChatterModel
    func wapper(_ chatter: Chatter, urgentExtraInfo: UrgentExtraInfo? = nil) -> UrgentChatterModel? {
        guard chatter.type == .user else { return nil }

        if let item = self.parseCache[chatter.id] { return item }

        let item = UrgentChatterModel(
            chatter: chatter,
            itemName: chatter.displayName(
                chatId: self.chatId,
                chatType: self.chatType,
                scene: self.displayNameScene),
            itemTags: self.itemTags(for: chatter),
            isRead: urgentExtraInfo?.isRead ?? false,
            unSupportChatterType: urgentExtraInfo?.unSupportChatterType ?? .none,
            itemCellClass: UrgentChatterCell.self,
            authDenyReason: urgentExtraInfo?.authDenyReason ?? .pass)

        if urgentExtraInfo == nil {
            Self.logger.warn("urgent picker urgentExtraInfo is miss \(self.chatId) \(chatter.id)")
        }

        self.parseCache[chatter.id] = item

        return item
    }

    // 解析返回数据
    func paserDatas(_ result: RustPB.Im_V1_GetChatChattersResponse,
                    chatterIds: [[String: [String]]],
                    urgentExtraInfoMap: [String: UrgentExtraInfo]) -> [UrgentChatterSectionData] {
        guard let chatChatters = result.entity.chatChatters[chatId]?.chatters else { return [] }

        return chatterIds.compactMap { (section) -> UrgentChatterSectionData? in

            return section.compactMap { (key, chatterIds) -> UrgentChatterSectionData? in

                let items = chatterIds.compactMap({ (id) -> UrgentChatterModel? in
                    guard let pb = chatChatters[id] else { return nil }
                    return wapper(Chatter.transform(pb: pb), urgentExtraInfo: urgentExtraInfoMap[id])
                })

                return items.isEmpty ? nil :
                    UrgentChatterSectionData(
                        title: key,
                        indexKey: key,
                        items: items,
                        sectionHeaderClass: UrgentContactTableHeader.self)
            }.first
        }
    }

    func loadDefaultSelectedItem() -> Observable<[UrgentChatterModel]> {
        guard let defaultSelectedIds = defaultSelectedIds, !defaultSelectedIds.isEmpty else { return .just([]) }
        let chatId = self.chatId
        let extraInfo = self.urgentAPI.pullChattersUrgentInfoRequest(chatterIds: defaultSelectedIds,
                                                                     isSuperChat: self.chat.isSuper,
                                                                     messageId: self.message.id).map { res -> [String: UrgentExtraInfo] in
            var dic: [String: UrgentExtraInfo] = [:]
            res.chatterInfos.forEach { info in
                var denyReason: UrgentChatterAuthDenyReason = .pass
                if !info.authResult.isAllow {
                    Self.logger.info("urgent picker authResult isNotAllow \(chatId) \(info.chatterID) \(info.authResult.deniedReason.rawValue)")
                    denyReason = .reason(info.authResult.deniedReason)
                }
                dic[info.chatterID] = UrgentExtraInfo(isRead: info.readState == .read,
                                                      unSupportChatterType: UnSupportChatterType(rawValue: info.code.rawValue) ?? .none,
                                                      authDenyReason: denyReason)
            }
            return dic
        }

        let chatters = chatterAPI.getChatters(ids: defaultSelectedIds).map({ (map) -> [LarkModel.Chatter] in
            return Array(map.values)
        })

        return Observable.zip(chatters, extraInfo).asObservable().map { [weak self] res in
            res.0.compactMap { [weak self] in self?.wapper($0, urgentExtraInfo: res.1[$0.id]) }
        }
    }

    // 加载服务器限制
    func getChatLimit() -> Observable<Void> {
        return chatAPI.getChatLimitInfo(chatId: chatId)
            .map { [weak self] (info) -> Void in
                guard let self = self else { return () }
                self.canAllSelectedUnread = info.isUrgentAllSupport
                Self.logger.info("getChatLimit:  isUrgentAllSupport = \(info.isUrgentAllSupport)")
                return ()
            }
    }

    // 将ChatterIds格式统一，方便下一步处理
    /// return [索引: [成员]]
    func formatChatterIds(_ result: RustPB.Im_V1_GetChatChattersResponse) -> [[String: [String]]] {
        let chatterIds: [[String: [String]]]
        if result.letterMaps.isEmpty {
            /// 加急选人界面要去掉自己
            var ids = result.chatterIds
            ids.removeAll { $0 == self.currentChatterId }
            chatterIds = ids.isEmpty ? [] : [["": ids]]
        } else {
            chatterIds = result.letterMaps.compactMap({ (letterMap) -> [String: [String]]? in
                /// 加急选人界面要去掉自己
                var ids = letterMap.chatterIds
                ids.removeAll { $0 == self.currentChatterId }
                return ids.isEmpty ? nil : [letterMap.letter: ids]
            })
        }

        return chatterIds
    }

    // load数据
    func loadData() -> Observable<[UrgentChatterSectionData]> {
        /// 大群SDK无法统计已经下发的人数，需要端上传入已经拉取的Chatter的数量；搜索时不需要
        let offset = isInSearch ? nil : datas.reduce(into: 0, { $0 += $1.items.count })
        return getUrgentChatChatters(
            chatId: chatId,
            filter: filterKey,
            cursor: cursor,
            limit: 50,
            offset: offset
        ).map { [weak self] (res) -> [UrgentChatterSectionData] in
            guard let self = self else { return [] }
            let result = res.0
            let infoMap = res.1
            if !self.isInSearch {
                self.cursor = result.cursor
            }
            // 第一次加载决定isFetchAll的值
            if self.isFirstDataLoaded == false {
                self.isFetchAll = result.cursor.isEmpty
            }
            self.tableViewModel.shouldShowTipView = result.showSearch
            return self.paserDatas(result, chatterIds: self.formatChatterIds(result), urgentExtraInfoMap: infoMap)
        }
    }

    func getUrgentChatChatters(chatId: String,
                               filter: String?,
                               cursor: String?,
                               limit: Int?,
                               offset: Int?) -> Observable<(RustPB.Im_V1_GetChatChattersResponse, [String: UrgentExtraInfo])> {
        let getUrgentChatChattersRes = chatterAPI.getUrgentChatChatters(
            chatId: chatId,
            filter: filterKey,
            cursor: cursor,
            limit: limit,
            offset: offset
        )
        return getUrgentChatChattersRes.flatMap { [weak self] res -> Observable<(RustPB.Im_V1_GetChatChattersResponse, [String: UrgentExtraInfo])> in
            guard let self = self else { return .empty() }
            let ids = self.formatChatterIds(res).flatMap({ $0.values.flatMap({ $0 }) })
            // 根据ids再去拉取urgenInfo信息再一起返回
            let chatId = self.chatId
            let infoRes = self.urgentAPI.pullChattersUrgentInfoRequest(chatterIds: ids, isSuperChat: self.chat.isSuper, messageId: self.message.id).map { res -> [String: UrgentExtraInfo] in
                var dic: [String: UrgentExtraInfo] = [:]
                res.chatterInfos.forEach { info in
                    var denyReason: UrgentChatterAuthDenyReason = .pass
                    if !info.authResult.isAllow {
                        Self.logger.info("urgent picker authResult isNotAllow \(chatId) \(info.chatterID) \(info.authResult.deniedReason.rawValue)")
                        denyReason = .reason(info.authResult.deniedReason)
                    }
                    dic[info.chatterID] = UrgentExtraInfo(isRead: info.readState == .read,
                                                          unSupportChatterType: UnSupportChatterType(rawValue: info.code.rawValue) ?? .none,
                                                          authDenyReason: denyReason)
                }
                return dic
            }
            return Observable.zip(getUrgentChatChattersRes, infoRes).asObservable()
        }
    }

    // 由于分页且分组，所以数据需要merge而不是直接追加
    func merge(_ newDatas: [UrgentChatterSectionData]) {
        let keys = Set(datas.map { $0.indexKey }).intersection(newDatas.map { $0.indexKey })
        if keys.isEmpty {
            datas.append(contentsOf: newDatas)
        } else {
            var newDatas = newDatas
            for key in keys {
                if let oldIndex = datas.firstIndex(where: { $0.indexKey == key }),
                    let newIndex = newDatas.firstIndex(where: { $0.indexKey == key }) {
                    datas[oldIndex].items += newDatas[newIndex].items
                    newDatas.remove(at: newIndex)
                }
            }
            datas.append(contentsOf: newDatas)
        }
    }
}
