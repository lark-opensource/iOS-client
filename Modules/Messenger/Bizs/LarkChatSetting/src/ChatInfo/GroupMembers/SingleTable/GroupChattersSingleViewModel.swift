//
//  GroupChattersSingleViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/30.
//

import Foundation
import RxSwift
import RxCocoa
import LarkTag
import LarkCore
import LarkModel
import LKCommonsLogging
import LarkAccountInterface
import LarkMessengerInterface
import ThreadSafeDataStructure
import LarkFeatureGating
import RustPB
import LarkBizTag
import LarkSetting
import LarkContainer

final class GroupChattersSingleViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    private var orderDataSource: ChatChatterOrderDataSource?

    // 群成员首字母排序
    private(set) var sortType: ChatterSortType {
        get {
            if self.isSupportAlphabetical && isSortedAlphabetically {
                return .alphabetical
            } else {
                return .joinTime
            }
        }
        set {
            self.isSortedAlphabetically = newValue == .alphabetical
        }
    }

    private var isFinishedLoading = true

    private var isSortedAlphabetically: Bool = false

    var isSupportAlphabetical: Bool {
        // imChatMemberListFg：当前租户是否开启了FG
        let key = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.imChatMemberList.rawValue)
        // canBeSortedAlphabetically： 群是否支持首字母排序
        return userResolver.fg.dynamicFeatureGatingValue(with: key) &&
        chat.canBeSortedAlphabetically &&
        condition == .noLimit && !chat.isSuper
    }

    // 是否为默认首字母排序
    private var isDefaultAlphabetical: Bool {
        let key = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.memberListDefaultAlphabetical.rawValue)
        return userResolver.fg.dynamicFeatureGatingValue(with: key)
    }

    private let semaphore = DispatchSemaphore(value: 1)

    private let logger = Logger.log(
        GroupChattersSingleViewModel.self,
        category: "Module.IM.GroupChattersSingleViewModel")

    private let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()

    private let schedulerType: SchedulerType

    private var ownerID: String { return dependency.ownerID }
    private var tenantID: String { return dependency.tenantID }
    private var currentChatterID: String { return dependency.currentChatterID }
    private var currentUserType: AccountUserType { return dependency.currentUserType }

    private var chatID: String { return dependency.chatID }
    private var chat: Chat { return dependency.chat }

    private var parseCache: [String: ChatChatterWapper] = [:]
    private var isFirstDataLoaded: Bool = false
    private(set) var isInSearch: Bool = false

    private(set) var condition: RustPB.Im_V1_GetChatChattersRequest.Condition = .unknown
    private(set) var supportShowDepartment: Bool

    let dependency: GroupChattersSingleDependencyProtocol
    var datas: [ChatChatterSection] {
        get { _datas.value }
        set { _datas.value = newValue }
    }
    private var _datas: SafeAtomic<[ChatChatterSection]> = [] + .readWriteLock
    var searchDatas: [ChatChatterSection] = []

    var filterKey: String?
    var cursor: String?

    private let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)
    var statusVar: Driver<ChatChatterViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }
    public var needDisplayDepartment: Bool?

    init(userResolver: UserResolver,
         dependency: GroupChattersSingleDependencyProtocol,
         condition: RustPB.Im_V1_GetChatChattersRequest.Condition,
         supportShowDepartment: Bool = false
    ) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.condition = condition
        self.supportShowDepartment = supportShowDepartment

        let queue = DispatchQueue.global()
        schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)

        self.isSortedAlphabetically = self.isDefaultAlphabetical

        dependency.removeChatters.subscribe(onNext: { [weak self] (chatterIDs) in
            self?.removeChatters(by: chatterIDs)
        }).disposed(by: disposeBag)
        self.initOrderDataSource()
    }

    private func initOrderDataSource() {
        self.orderDataSource = ChatChatterOrderDataSource()
        self.orderDataSource?.wrapperCallBack = { [weak self] (chatter) in
            return self?.wrapper(chatter)
        }
    }

    private func removeChatters(by chatterIDs: [String]) {
        for index in datas.indices {
            datas[index].items.removeAll { chatterIDs.contains($0.itemId) }
        }
        datas.removeAll(where: { $0.items.isEmpty })
        statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
    }
}

// 对外暴露的Load方法
extension GroupChattersSingleViewModel {
    // 首次加载数据，需要加载默认选中的数据，所以单独拉出来处理
    func firstLoadData() {
        self.dependency.chatterAPI
            .getUserBehaviorPermissions()
            .flatMap { [weak self] (result) -> Observable<[ChatChatterSection]> in
                guard let self = self else { return .just([]) }
                let key = Behavior_V1_GetUserBehaviorPermissionsRequest.Behavior.displayDepartment.rawValue
                self.needDisplayDepartment = result.behaviorResult[Int32(key)]?.hasPermission_p
                return self.loadData(.firstScreen)
            }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas) in
                guard let self = self else { return }

                self.datas = datas

                // 如果在搜索中，则保存结果，忽略UI刷新
                if self.isInSearch { return }

                let status: ChatChatterBaseTable.Status = datas.isEmpty ? .empty : .display

                self.statusBehavior.onNext(.viewStatus(status))
            }, onError: { [weak self] (error) in
                self?.logger.error(
                    "first load chat chatter error",
                    additionalData: ["chatID": self?.chatID ?? ""],
                    error: error)
                self?.statusBehavior.onNext(.error(error))
            }, onDisposed: { [weak self] in
                self?.isFirstDataLoaded = true
            }).disposed(by: disposeBag)
    }

    private func updateDataFromNewChatter(_ new: ChatChatterWapper) {
        // 尝试寻找并且替换
        var isInCurrentList = false
        let datas = self.datas.map { (section) -> ChatChatterSection in
            var newSection = section
            let items = section.items.map { (item) -> ChatChatterItem in
                if item.itemId == new.itemId {
                    isInCurrentList = true
                    return new
                }
                return item
            }
            newSection.items = items
            return newSection
        }
        self.datas = datas
        // 如果没有在当前list则追加到当前section的最后一个
        if !isInCurrentList, !self.datas.isEmpty {
            let lastIndex = self.datas.count - 1
            self.datas[lastIndex].items.append(new)
        }
    }

    func observeData() {
        let chatId = self.chat.id
        dependency.pushChatChatter
            .filter { $0.chatId == chatId }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let items = push.chatters.compactMap { (chatter) -> ChatChatterWapper? in
                    self.wrapper(chatter)
                }
                switch push.type {
                    // 添加操作：直接追加到最后一个
                case .append:
                    if self.sortType != .alphabetical {
                        let lastIndex = self.datas.count - 1
                        if self.datas.count > lastIndex {
                            self.datas[lastIndex].items.append(contentsOf: items)
                        }
                        items.forEach { (newChatter) in
                            self.updateDataFromNewChatter(newChatter)
                        }
                    } else {
                        return
                    }
                    // 删除操作：则去当前list查找，如果有则替换，否则依赖sdk处理, 端上不用处理
                case .delete:
                    if self.sortType == .alphabetical, let orderDataSource = self.orderDataSource {
                        let ids = push.chatters.map {
                            return $0.id
                        }

                        self.orderDataSource?.removeChatters(with: ids)
                        self.datas = orderDataSource.datas
                        self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .update))
                        return
                    }
                    push.chatters.forEach { (user) in
                        let datas = self.datas.map { (section) -> ChatChatterSection in
                            var newSection = section
                            let items = section.items.filter { (item) -> Bool in
                                item.itemId != user.id
                            }
                            newSection.items = items
                            return newSection
                        }
                        self.datas = datas
                    }
                default:
                    break
                }
                self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .display))
            }).disposed(by: disposeBag)

        dependency.pushChatChatterListDepartmentName?
            .filter { $0.chatId == chatId }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] push in
                guard let self = self, self.needDisplayDepartment == true else { return }
                //根据chatID去找当前数据源的item，更新department信息，刷新ui
                push.chatterIDToDepartmentName.forEach { element in
                    self.datas.updateDepartmentName(element.value, element.key)
                    self.orderDataSource?.updateDepartmentName(element.value, element.key)
                }
                self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .update))
            }).disposed(by: disposeBag)

        dependency.pushChatAdmin
            .filter { $0.chatId == chatId }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let adminUsers = push.adminUsers.compactMap { (chatter) -> ChatChatterWapper? in
                    self.wrapper(chatter)
                }
                adminUsers.forEach { (adminUser) in
                    // 尝试寻找并且替换
                    var isInCurrentList = false
                    let datas = self.datas.map { (section) -> ChatChatterSection in
                        var newSection = section
                        let items = section.items.map { (item) -> ChatChatterItem in
                            if item.itemId == adminUser.itemId {
                                isInCurrentList = true
                                return adminUser
                            }
                            return item
                        }
                        newSection.items = items
                        return newSection
                    }
                    self.datas = datas
                    // 如果没有在当前list则追加到当前section的最后一个
                    if !isInCurrentList, !self.datas.isEmpty {
                        let lastIndex = self.datas.count - 1
                        self.datas[lastIndex].items.append(adminUser)
                    }
                }
                self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .update))
            }).disposed(by: disposeBag)
    }

    func clearOrderedChatChatters() {
        guard self.sortType == .alphabetical else {
            return
        }
        self.dependency.chatAPI
            .clearOrderedChatChatters(chatId: chat.id, uid: self.orderDataSource?.orderID ?? "")
            .subscribe(onNext: { [weak self] in
                self?.logger.info("clearOrderedChatChatters")
            }).disposed(by: self.disposeBag)
    }

    func updateSortType(_ sortType: ChatterSortType) {
        self.sortType = sortType
        switch sortType {
        case .alphabetical:
            self.initOrderDataSource()
        case .joinTime:
            break
        default:
            break
        }
        self.filterKey = nil
        self.datas = []
        self.cursor = nil
        firstLoadData()
    }

    // 上啦加载更多
    func loadMoreData(_ loader: ChatterControllerVM.DataLoader = .none) {
        if self.sortType == .alphabetical, self.orderDataSource?.getCursorAndSceneBy(loader, isCheck: true).isEmpty ?? false {
            return
        }
        guard isFirstDataLoaded else { return }
        loadData(loader)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas) in
                guard let self = self else { return }

                if self.sortType == .alphabetical {
                    self.datas = datas
                    self.statusBehavior.onNext(.viewStatus(.update))
                    return
                }

                // 由于分页且分组，所以数据需要merge而不是直接追加
                self.datas.merge(datas)
                self.statusBehavior.onNext(.viewStatus(.display))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }

                self.logger.error(
                    "load more chat chatter error",
                    additionalData: ["chatID": self.chatID],
                    error: error)
                self.statusBehavior.onNext(.viewStatus(.display))
            }).disposed(by: disposeBag)
    }

    // 搜索接口
    func loadFilterData(_ key: String) {
        guard isFirstDataLoaded else { return }

        filterKey = key
        isInSearch = !key.isEmpty

        // 取消上次搜索
        searchDisposeBag = DisposeBag()

        if isInSearch {
            statusBehavior.onNext(.viewStatus(.loading))
        } else {
            statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
            return
        }

        loadData(.none)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.searchDatas = result
                self.statusBehavior.onNext(
                    .viewStatus(result.isEmpty ? .searchNoResult(key) : .display)
                )
            }, onError: { [weak self] (error) in
                self?.logger.error(
                    "load filter chat chatter error",
                    additionalData: [
                        "chatID": self?.chatID ?? "",
                        "filterKey": key
                    ],
                    error: error)
                self?.statusBehavior.onNext(.viewStatus(.searchNoResult(key)))
            }).disposed(by: searchDisposeBag)
    }
}

// 数据加载和处理
private extension GroupChattersSingleViewModel {
    /// 获取显示名
    func itemName(for chatter: Chatter) -> String {
        return chatter.displayName(chatId: chatID, chatType: chat.type, scene: .groupMemberList)
    }

    /// 获取Tag：外部、群主、负责人、机器人等
    func itemTags(for chatter: Chatter) -> [TagDataItem]? {
        var result: [LarkBizTag.TagType] = []
        var tagDataItems: [TagDataItem] = []

        chatter.tagData?.tagDataItems.forEach { item in
            let isExternal = item.respTagType == .relationTagExternal
            if isExternal {
                tagDataItems.append(TagDataItem(tagType: .external,
                                                priority: Int(item.priority)
                                               ))
            } else {
                let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                         tagType: item.respTagType.transform(),
                                                         priority: Int(item.priority))
                tagDataItems.append(tagDataItem)
            }
        }

        /// 判断勿扰模式
        if self.dependency.serverNTPTimeService.afterThatServerTime(time: chatter.doNotDisturbEndTime) {
            result.append(.doNotDisturb)
        }

        /// 群主
        if chatter.id == chat.ownerId {
            result.append(.groupOwner)
        } else if chatter.chatExtra?.tagInfos.tags.contains(where: { $0.tagType == .adminUser }) ?? false {
            // 群管理员
            result.append(.groupAdmin)
        }

        /// 机器人
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
            return TagDataItem(tagType: type)
        }))

        return tagDataItems.isEmpty ? nil : tagDataItems
    }

    /// 包装成 ChatChatterItem
    func wrapper(_ chatter: Chatter) -> ChatChatterWapper? {
        if let item = parseCache[chatter.id] { return item }
        var item = ChatChatterWapper(
            chatter: chatter,
            itemName: self.itemName(for: chatter),
            itemMedalKey: chatter.medalKey,
            itemTags: self.itemTags(for: chatter),
            itemCellClass: ChatChatterCell.self,
            itemDepartment: chatter.chatChatterListDepartmentName,
            descInlineProvider: nil,
            descUIConfig: nil)
        item.needDisplayDepartment = self.needDisplayDepartment
        item.supportShowDepartment = self.supportShowDepartment

        item.isSelectedable = currentChatterID != chatter.id || dependency.isOwnerSelectable
        parseCache[chatter.id] = item
        return item
    }

    /// 解析返回数据
    func paserDatas(_ result: RustPB.Im_V1_GetChatChattersResponse, chatterIds: [[String: [String]]]) -> [ChatChatterSection] {
        // chatchatter 包含更多信息
        let chatChatters = result.entity.chatChatters[chatID]?.chatters ?? [:]
        let entityChatters = result.entity.chatters

        return chatterIds.compactMap { (section) -> ChatChatterSection? in
            return section.compactMap { (key, chatterIds) -> ChatChatterSection? in
                let items = chatterIds.compactMap { (id) -> ChatChatterWapper? in
                    guard let pb = chatChatters[id] ?? entityChatters[id] else { return nil }
                    // 过滤掉非群主的机器人
                    if pb.type == .bot, pb.id != chat.ownerId { return nil }
                    return wrapper(
                        Chatter.transform(pb: pb))
                }

                return items.isEmpty ?
                    nil :
                    ChatChatterSectionData(
                        title: key,
                        indexKey: key,
                        items: items,
                        sectionHeaderClass: ContactTableHeader.self
                    )
            }.first
        }
    }

    /// load数据并格式化
    func loadData(_ loader: ChatterControllerVM.DataLoader = .none) -> Observable<[ChatChatterSection]> {
        if self.sortType == .alphabetical, !isInSearch {
            guard let orderDataSource = self.orderDataSource else {
                return .just(datas)
            }

            let cursorAndScenes = orderDataSource.getCursorAndSceneBy(loader)
            var result: Observable<[ChatChatterSection]> = .just(datas)
            for (cursor, scene) in cursorAndScenes {
                result = result.flatMap({ [weak self] (_) -> Observable<[ChatChatterSection]> in
                    guard let self = self else { return .just([]) }
                    return self.dependency.chatterAPI.getOrderChatChatters(chatId: self.chat.id,
                                                                scene: scene,
                                                                cursor: cursor,
                                                                count: orderDataSource.orderCount,
                                                                uid: orderDataSource.orderID)
                        .subscribeOn(self.schedulerType)
                        .map { [weak self] (result) -> [ChatChatterSection] in
                            guard let self = self,
                                  let orderDataSource = self.orderDataSource else {
                                return []
                            }
                            orderDataSource.updateOrderDatas(result, cursor: cursor, scene: scene, chatId: self.chat.id, ownerId: self.ownerID)
                            return orderDataSource.datas
                        }
                })
            }
            return result
        }

        /// 大群SDK无法统计已经下发的人数，需要端上传入已经拉取的Chatter的数量；搜索时不需要
        let isFirst = loader == .firstScreen
        let offset = isInSearch ? nil : (isFirst ? 0 : datas.reduce(into: 0, { $0 += $1.items.count }))
        let forceRemote = loader == .none || loader == .firstScreen
        return self.dependency.chatterAPI.getChatChatters(
            chatId: self.chatID,
            filter: self.filterKey,
            cursor: self.cursor,
            limit: nil,
            condition: self.condition,
            forceRemote: forceRemote,
            offset: offset,
            fromScene: supportShowDepartment ? (isFirst ? .firstGetChatChatterList : .getChatChatterList) : .unknownScene
        ).subscribeOn(schedulerType)
        .map { [weak self] (result) -> [ChatChatterSection] in
            guard let self = self else { return [] }

            if !self.isInSearch {
                self.cursor = result.cursor
            }

            let formatedChatterIDs = isFirst ?
                result.formatedChatterIDs(.swapOwnerToFirst(self.ownerID)) :
                result.formatedChatterIDs(.normal)
            return self.paserDatas(result, chatterIds: formatedChatterIDs)
        }
    }
}
