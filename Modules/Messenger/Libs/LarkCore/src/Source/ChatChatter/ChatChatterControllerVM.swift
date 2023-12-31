//
//  ChatterControllerVM.swift
//  LarkCore
//
//  Created by kongkaikai on 2019/5/28.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkTag
import RxCocoa
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import UniverseDesignDialog
import LarkContainer
import EENavigator
import LarkFeatureGating
import RustPB
import TangramService
import LarkListItem
import LarkBizTag
import LarkSetting
import ThreadSafeDataStructure

public class ChatChatterOrderDataSource {
    public class OrderData {
        public var cursor: Int
        public var index: Int
        public var isLoaded: Bool = false
        public var preLoaded: Bool = false
        public var nextLoaded: Bool = false

        public init(index: Int, cursor: Int) {
            self.index = index
            self.cursor = cursor
        }
    }

    public struct LetterData {
        public var letter: String
        public var count: Int

        public init(letter: String, count: Int) {
            self.letter = letter
            self.count = count
        }
    }

    private let lock = NSLock()

    // 群成员字母表
    public var letterArray: [LetterData] {
        get { _letterArray.getImmutableCopy() }
        set { _letterArray.safeWrite { map in
            map = newValue
        } }
    }
    private var _letterArray: SafeArray<LetterData> = [] + .readWriteLock

    // 群成员排序
    public var orderHashArray: [OrderData] {
        get { _orderHashArray.getImmutableCopy() }
        set { _orderHashArray.safeWrite { map in
            map = newValue
        } }
    }
    private var _orderHashArray: SafeArray<OrderData> = [] + .readWriteLock

    // 列表数据相关
    // 列表数据相关
    public var datas: [ChatChatterSection] {
        get { _datas.value }
        set { _datas.value = newValue }
    }
    private var _datas: SafeAtomic<[ChatChatterSection]> = [] + .readWriteLock

    public var wrapperCallBack: ((Chatter) -> ChatChatterWapper?)?

    public var orderID: String?
    public var orderCount: Int = 100
    private var preNextCursor: Int = -1
    private var lastNextCursor: Int = -1

    public init() {}

    public func updateOrderDatas(_ result: RustPB.Im_V1_GetOrderedChatChattersResponse,
                                 cursor: Int?,
                                 scene: RustPB.Im_V1_GetOrderedChatChattersRequest.Scene,
                                 chatId: String,
                                 ownerId: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard let chatChatters = result.entity.chatChatters[chatId]?.chatters else { return }
        if scene == .listFirstScreen {
            self.orderID = result.uid
            self.datas = []
            var newHashArry: [OrderData] = []
            var newLetterDatas: [LetterData] = []
            var postion = 0
            for data in result.occupancyData.letterData {
                let letter = data.letter
                let count = data.chatterIds.count
                var showHeader = true
                newLetterDatas.append(LetterData(letter: letter, count: count))
                var items: [ChatChatterItem] = []
                data.chatterIds.forEach { chatterId in
                    if !ownerId.isEmpty, String(chatterId) == ownerId {
                        showHeader = false
                    }
                    let cursorData = OrderData(index: postion, cursor: Int(chatterId))
                    items.append(ChatChatterDefaultItem(itemId: String(chatterId)))
                    newHashArry.append(cursorData)
                    postion += 1
                }

                self.datas.append(ChatChatterSectionData(title: letter,
                                                         indexKey: letter,
                                                         items: items,
                                                         showHeader: showHeader,
                                                         sectionHeaderClass: ContactTableHeader.self))
            }
            self.orderHashArray = newHashArry
            self.letterArray = newLetterDatas
        }

        let res = result.intervalData
        let chatterCount = res.chatterIds.count
        var chatterIndex = 0

        switch scene {
        case .previewFirstScreen, .listFirstScreen:
            break
        case .nextPage:
            guard let currentData = self.orderHashArray.first(where: {
                return $0.cursor == cursor
            }) else { return }
            chatterIndex = currentData.index
        case .previousPage:
            guard let currentData = self.orderHashArray.first(where: {
                return $0.cursor == cursor
            }) else { return }
            chatterIndex = currentData.index - chatterCount + 1 > 0 ? currentData.index - chatterCount + 1 : 0
        @unknown default:
            break
        }

        var newSection: [ChatChatterSection] = self.datas
        for (index, id) in res.chatterIds.enumerated() {
            if let indexPath = self.getIndexPathBy(chatterIndex + index),
               newSection[indexPath.section].items[indexPath.row] as? ChatChatterDefaultItem != nil,
               let pb = chatChatters[String(id)],
               let item = self.wrapperCallBack?(Chatter.transform(pb: pb)) {
                newSection[indexPath.section].items[indexPath.row] = item
                self.orderHashArray[chatterIndex + index].isLoaded = true
            }
        }
        self.datas = newSection
    }

    public func getCursorAndSceneBy(_ loader: ChatterControllerVM.DataLoader = .none, isCheck: Bool = false) -> [(Int?, RustPB.Im_V1_GetOrderedChatChattersRequest.Scene)] {
        switch loader {
        case .none:
            return []
        case .firstScreen:
            return [(nil, .listFirstScreen)]
        case .up(let indexPath):
            guard let index = self.getIndexBy(indexPath), !self.orderHashArray[index].preLoaded else {
                return []
            }

            var newIndex: Int?
            var startIndex = index - self.orderCount / 2 > 0 ? index - self.orderCount / 2 : 0
            for item in orderHashArray[startIndex...index].reversed() {
                if !item.isLoaded {
                    newIndex = item.index
                    break
                }
            }

            guard let loadIndex = newIndex else { return [] }
            if !isCheck {
                self.orderHashArray[startIndex].nextLoaded = true
                self.orderHashArray[index].preLoaded = true
                startIndex = loadIndex - self.orderCount + 1 > 0 ? loadIndex - self.orderCount + 1 : 0
                orderHashArray[startIndex...loadIndex].forEach { item in
                    item.isLoaded = true
                }
            }
            return [(orderHashArray[loadIndex].cursor, .previousPage)]
        case .down(let indexPath):
            guard let index = self.getIndexBy(indexPath), !self.orderHashArray[index].nextLoaded else {
                return []
            }

            var newIndex: Int?
            var endIndex = index + self.orderCount / 2 < self.orderHashArray.count ? index + self.orderCount / 2 : self.orderHashArray.count - 1
            for item in orderHashArray[index...endIndex] {
                if !item.isLoaded {
                    newIndex = item.index
                    break
                }
            }
            guard let loadIndex = newIndex else { return [] }
            if !isCheck {
                self.orderHashArray[index].nextLoaded = true
                self.orderHashArray[endIndex].preLoaded = true
                endIndex = loadIndex + self.orderCount - 1 < self.orderHashArray.count ? loadIndex + self.orderCount - 1 : self.orderHashArray.count - 1
                orderHashArray[loadIndex...endIndex].forEach { item in
                    item.isLoaded = true
                }
            }
            return [(orderHashArray[loadIndex].cursor, .nextPage)]
        case .upAndDown(let indexPath):
            var result = self.getCursorAndSceneBy(.up(indexPath: indexPath), isCheck: isCheck)
            result.append(contentsOf: self.getCursorAndSceneBy(.down(indexPath: indexPath), isCheck: isCheck))
            return result
        }
    }

    public func updateDatas(datas: [ChatChatterSection]) {
        lock.lock()
        defer {
            lock.unlock()
        }

        self.datas = datas
    }

    public func updateDepartmentName(_ newDepartmentName: String, _ chatterId: String) {
        lock.lock()
        defer {
            lock.unlock()
        }

        self.datas.updateDepartmentName(newDepartmentName, chatterId)
    }

    public func removeChatters(with chatterIds: [String]) {
        var indexPaths: [IndexPath] = []
        self.datas.enumerated().forEach { (section, data) in
            data.items.enumerated().forEach { (index, item) in
                if chatterIds.contains(where: {
                    $0 == item.itemId
                }) {
                    indexPaths.append(IndexPath(row: index, section: section))
                }
            }
        }

        orderHashArray = self.orderHashArray.filter({ data in
            return !chatterIds.contains {
                return String(data.cursor) == $0
            }
        }).enumerated().map({ (index, data) -> OrderData in
            data.index = index
            return data
        })

        // 更新字母表
        indexPaths.forEach { indexPath in
            guard indexPath.section < self.letterArray.count else { return }
            let count = self.letterArray[indexPath.section].count - 1
            if count < 1 {
                self.letterArray.remove(at: indexPath.section)
                self.datas.remove(at: indexPath.section)
            } else {
                self.letterArray[indexPath.section].count = count
            }
        }

        var newDatas = datas
        chatterIds.forEach { (userId) in
            newDatas = newDatas.map { (section) -> ChatChatterSection in
                var newSection = section
                let items = section.items.filter { (item) -> Bool in
                    item.itemId != userId
                }
                newSection.items = items
                return newSection
            }.filter({ section in
                return !section.items.isEmpty
            })
        }
        self.datas = newDatas
    }

    private func getOrderDataBy(_ indexPath: IndexPath) -> OrderData? {
        guard let index = getIndexBy(indexPath),
              index < self.orderHashArray.count else { return nil }
        return self.orderHashArray[index]
    }

    private func getIndexBy(_ indexPath: IndexPath) -> Int? {
        var index = 0
        self.letterArray.enumerated().forEach { (letterIndex, letterData) in
            if letterIndex < indexPath.section {
                index += letterData.count
            } else if letterIndex == indexPath.section {
                index += indexPath.row
            }
        }

        guard index < self.orderHashArray.count else {
            return nil
        }
        return index
    }

    private func getIndexPathBy(_ index: Int) -> IndexPath? {
        guard index < self.orderHashArray.count else { return nil }
        var row = index
        var section = 0

        while (row >= self.letterArray[section].count) && (section < self.letterArray.count) {
            row -= self.letterArray[section].count
            section += 1
        }

        return IndexPath(row: row, section: section)
    }
}

// 群设置页viewModel
public final class ChatChatterControllerVM: ChatterControllerVM, ExportChatMembersAbility {
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chat.isGroupAdmin
    }

    // 删除前需要确认
    public var confirmBeforeDeleteCallback: (([ChatChatterItem]) -> Void)?
    private var cursor: String?

    private var orderDataSource: ChatChatterOrderDataSource?

    private let pushChat: Observable<PushChat>
    private let pushChatChatter: Observable<PushChatChatter>
    private let pushChatChatterTag: Observable<PushChatChatterTag>
    private let pushChatChatterListDepartmentName: Observable<PushChatChatterListDepartmentName>?
    public let chatAPI: ChatAPI
    public let currentUserType: AccountUserType

    /// 追加自定义Tag
    public typealias AppendTagProvider = (_ chatter: Chatter) -> [LarkBizTag.TagType]?
    public let appendTagProvider: AppendTagProvider?
    public let serverNTPTimeService: ServerNTPTimeService
    public let tenantId: String
    public let isThread: Bool
    public let chatterAPI: ChatterAPI

    public typealias ChatterFliter = (_ chatter: Chatter) -> Bool
    private let chatterFliter: ChatterFliter
    private let isOwnerSelectable: Bool
    public let useLeanCell: Bool
    public let isAbleToSearch: Bool
    // 群成员列表场景
    public let supportShowDepartment: Bool
    public let currentChatterId: String
    public var isOwner: Bool {
        chat.ownerId == currentChatterId
    }

    public var currentUserId: String {
        return self.currentChatterId
    }

    public private(set) override var sortType: ChatterSortType {
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

    public var isSupportAlphabetical: Bool {
        // imChatMemberListFg：当前租户是否开启了FG
        let key = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.imChatMemberList.rawValue)
        // canBeSortedAlphabetically： 群是否支持首字母排序
        return userResolver.fg.dynamicFeatureGatingValue(with: key) && chat.canBeSortedAlphabetically && !chat.isSuper && isDefaultSupportAlphabetical
    }

    public private(set) var canExportMembers: Bool = false

    private let isDefaultSupportAlphabetical: Bool

    // 是否为默认首字母排序
    private var isDefaultAlphabetical: Bool {
        let key = FeatureGatingManager.Key(stringLiteral: FeatureGatingKey.memberListDefaultAlphabetical.rawValue)
        return userResolver.fg.dynamicFeatureGatingValue(with: key)
    }

    let inlineService: MessageTextToInlineService?
    lazy var descUIConfig: StatusLabel.UIConfig = {
        return .init(linkColor: UIColor.ud.textPlaceholder,
                     activeLinkBackgroundColor: UIColor.ud.textPlaceholder,
                     textColor: UIColor.ud.textPlaceholder,
                     font: UIFont.systemFont(ofSize: 12),
                     backgroundColor: UIColor.clear)
    }()
    public var needDisplayDepartment: Bool?
    public internal(set) var chat: Chat
    public init(userResolver: UserResolver,
                chat: Chat,
                chatterFliter: ChatterFliter? = nil,
                appendTagProvider: AppendTagProvider? = nil,
                isOwnerSelectable: Bool = false,
                showSelectedView: Bool = true,
                maxSelectModel: (Int, String)? = nil,
                pushChatChatterListDepartmentName: Observable<PushChatChatterListDepartmentName>? = nil,
                useLeanCell: Bool = false,
                isAbleToSearch: Bool = true,
                isDefaultSupportAlphabetical: Bool = true,
                supportShowDepartment: Bool = false
    ) throws {
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        let user = passportUserService.user

        self.chat = chat
        self.tenantId = user.tenant.tenantID
        self.serverNTPTimeService = try userResolver.resolve(assert: ServerNTPTimeService.self)
        self.appendTagProvider = appendTagProvider
        self.currentUserType = .init(user.type)
        self.chatterFliter = chatterFliter ?? { _ in true }
        self.pushChat = try userResolver.userPushCenter.observable(for: PushChat.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.pushChatChatter = try userResolver.userPushCenter.observable(for: PushChatChatter.self)
        self.pushChatChatterTag = try userResolver.userPushCenter.observable(for: PushChatChatterTag.self)
        self.isDefaultSupportAlphabetical = isDefaultSupportAlphabetical
        self.pushChatChatterListDepartmentName = pushChatChatterListDepartmentName
        let isThread = (chat.chatMode == .threadV2)
        self.isThread = isThread
        self.isOwnerSelectable = isOwnerSelectable
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.currentChatterId = user.userID
        self.inlineService = try? MessageTextToInlineService(userResolver: userResolver)
        self.useLeanCell = useLeanCell
        self.isAbleToSearch = isAbleToSearch
        self.supportShowDepartment = supportShowDepartment
        let searchPlaceHolder = isThread ? BundleI18n.LarkCore.Lark_Groups_AssignNewCircleOwnerSearchPlaceholder : BundleI18n.LarkCore.Lark_Group_SearchGroupMember
        super.init(userResolver: userResolver,
                   id: chat.id,
                   searchPlaceHolder: searchPlaceHolder,
                   maxSelectModel: maxSelectModel,
                   showSelectedView: showSelectedView)

        self.isSortedAlphabetically = self.isDefaultAlphabetical
        self.initOrderDataSource()
        self.fetchData()
        observeData()
    }

    private func initOrderDataSource() {
        self.orderDataSource = ChatChatterOrderDataSource()
        self.orderDataSource?.wrapperCallBack = { [weak self] (chatter) in
            guard let self = self else { return nil}
            return self.wrapper(chatter)
        }
    }

    private func fetchData() {
        self.fetchExportMembersPermission(fg: self.userResolver.fg)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
            self?.canExportMembers = result
        }).disposed(by: self.disposeBag)
    }

    // tag的处理方法
    // 获取Tag：外部、群主、负责人、机器人等
    private func itemTags(for chatter: Chatter) -> [TagDataItem]? {
        var result: [LarkBizTag.TagType] = appendTagProvider?(chatter) ?? []
        var tagDataItems: [TagDataItem] = []

        if chatter.isSpecialFocus {
            result.append(.specialFocus)
        }
        // 这里如果包含了暂停使用的标签 不在展示请假的标签
        if chatter.tenantId == tenantId,
            chatter.workStatus.status == .onLeave {
            result.append(.onLeave)
        } else if self.serverNTPTimeService.afterThatServerTime(time: chatter.doNotDisturbEndTime) { // 判断勿扰模式
            result.append(.doNotDisturb)
        }

        /// 未注册
        if !chatter.isRegistered {
            result.append(.unregistered)
        } else if chatter.isFrozen {
            result.append(.isFrozen)
            /// 如果出现暂停使用标签的时候 需要移除请假的标签
            result.removeAll { (tagType) -> Bool in
                tagType == .onLeave
            }
        }

        // 群主
        if chatter.id == chat.ownerId {
            result.append(.groupOwner)
        } else if chatter.chatExtra?.tagInfos.tags.contains(where: { $0.tagType == .adminUser }) ?? false {
            // 群管理员
            result.append(.groupAdmin)
        }

        chatter.tagData?.tagDataItems.forEach { item in
            let isExternal = item.respTagType == .relationTagExternal
            if isExternal {
                tagDataItems.append(TagDataItem(tagType: .external,
                                                priority: 0
                                               ))
            } else {
                let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                         tagType: item.respTagType.transform(),
                                                         priority: Int(item.priority))
                tagDataItems.append(tagDataItem)
            }
        }

        if chatter.type == .bot {
            result.append(.robot)
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

    // MARK: 需要Override的方法
    public override func removeChatterBySelectedItems(_ selectedItems: [ChatChatterItem]) {
        tryRemoveChatters(selectedItems)
    }

    public override func loadDefaultSelectedItem(defaultSelectedIds: [String]) -> Observable<[ChatChatterItem]> {
        guard !defaultSelectedIds.isEmpty else { return .just([]) }
        return chatterAPI.getChatters(ids: defaultSelectedIds).map({ [weak self] (map) -> [ChatChatterItem] in
            guard let self = self else { return [] }
            return defaultSelectedIds.compactMap { id in
                if let value = map[id] {
                    return self.wrapper(value)
                }
                return nil
            }
        })
    }

    // load数据
    public override func loadData(_ loader: ChatterControllerVM.DataLoader = .none) -> Observable<[ChatChatterSection]> {
        if self.sortType == .alphabetical, !isInSearch {
            guard let orderDataSource = self.orderDataSource else {
                return .just(datas)
            }

            let cursorAndScenes = orderDataSource.getCursorAndSceneBy(loader)
            var result: Observable<[ChatChatterSection]> = .just(datas)
            for (cursor, scene) in cursorAndScenes {
                result = result.flatMap({ [weak self] (_) -> Observable<[ChatChatterSection]> in
                    guard let self = self else { return .just([]) }
                    return self.chatterAPI.getOrderChatChatters(chatId: self.chat.id,
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
                            orderDataSource.updateOrderDatas(result, cursor: cursor, scene: scene, chatId: self.chat.id, ownerId: self.chat.ownerId)
                            return orderDataSource.datas
                        }
                })
            }
            return result
        }

        /// 大群SDK无法统计已经下发的人数，需要端上传入已经拉取的Chatter的数量；搜索时不需要
        let isFirst = loader == .firstScreen
        let offset = isInSearch ? nil : (isFirst ? 0 : datas.reduce(into: 0, { $0 += $1.items.count }))
        return chatterAPI.getChatChatters(
            chatId: chat.id,
            filter: filterKey,
            cursor: cursor,
            limit: 20,
            condition: nil,
            forceRemote: !isFirst,
            offset: offset,
            fromScene: supportShowDepartment ? (isFirst ? .firstGetChatChatterList : .getChatChatterList) : .unknownScene
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

    public override func loadMoreData(_ loader: ChatterControllerVM.DataLoader = .none) {
        if self.sortType == .alphabetical, self.orderDataSource?.getCursorAndSceneBy(loader, isCheck: true).isEmpty ?? false {
            return
        }
        super.loadMoreData(loader)
    }

    public override func loadFirstScreenData() {
        self.chatterAPI
            .getUserBehaviorPermissions()
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (res) in
                let key = Behavior_V1_GetUserBehaviorPermissionsRequest.Behavior.displayDepartment.rawValue
                self?.needDisplayDepartment = res.behaviorResult[Int32(key)]?.hasPermission_p
                self?.superLoadFirstScreenData()
            }, onError: { [weak self] (_) in
                self?.superLoadFirstScreenData()
            }).disposed(by: disposeBag)
    }

    private func superLoadFirstScreenData() {
        super.loadFirstScreenData()
    }

    // 是否还有更多数据
    public override func hasMoreData() -> Bool {
        if self.sortType == .alphabetical {
            return false
        }
        if let cursor = cursor, !cursor.isEmpty {
            return true
        }
        return false
    }

    public override func clearOrderedChatChatters() {
        guard self.sortType == .alphabetical else {
            return
        }
        self.chatAPI
            .clearOrderedChatChatters(chatId: chat.id, uid: self.orderDataSource?.orderID ?? "")
            .subscribe(onNext: {
                ChatterControllerVM.logger.info("clearOrderedChatChatters")
            }).disposed(by: self.disposeBag)
    }

    public func updateSortType(_ sortType: ChatterSortType) {
        self.sortType = sortType
        switch sortType {
        case .alphabetical:
            self.initOrderDataSource()
        case .joinTime:
            break
        }
        self.filterKey = nil
        self.datas = []
        self.defaultSelectedIds = []
        self.cursor = nil
        loadFirstScreenData()
    }

    // 监听push数据
    private func observeData() {
        let chatId = self.chat.id
        // 监听群主改变，重新拉取首屏数据
        pushChat
            .observeOn(schedulerType)
            .filter { [weak self] push in
                return push.chat.id == chatId && push.chat.ownerId != self?.chat.ownerId ?? ""
            }
            .subscribe(onNext: { [weak self] push in
                self?.chat = push.chat
                self?.defaultSelectedIds = []
                self?.cursor = nil
                self?.filterKey = nil
                self?.datas = []
                self?.loadFirstScreenData()
            }).disposed(by: disposeBag)

        pushChatChatter
            .filter { $0.chatId == chatId }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let items = push.chatters.compactMap { (chatter) -> ChatChatterWapper? in
                    self.wrapper(chatter)
                }
                switch push.type {
                // 添加操作：虽然是添加，由于添加操作sdk和server均会当前客户端发送push(避免服务端push过慢)
                // 因此为了避免重复，这里先尝试替换，否则再去直接追加到最后一个
                case .append:
                    if self.sortType != .alphabetical {
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
                }
                self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .display))
            }).disposed(by: disposeBag)

        pushChatChatterListDepartmentName?
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

        pushChatChatterTag
            .filter { $0.chatId == chatId }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                push.chattersMap.forEach { (element) in
                    guard let adminUser = self.wrapper(element.value) else { return }
                    self.updateDataFromNewChatter(adminUser)
                }
                self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .update))
            }).disposed(by: disposeBag)

        chatterAPI.pushFocusChatter
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] msg in
                self?.processPushFocusChatter(msg)
            }).disposed(by: disposeBag)
    }

    // 处理星标联系人的push
    private func processPushFocusChatter(_ msg: PushFocusChatterMessage) {
        let addChatterIds = msg.addChatters.map { $0.id }
        let datas = self.datas.map { (section) -> ChatChatterSection in
            var newSection = section
            // 根据新的tags进行merge操作
            let items = section.items.map { (originItem) -> ChatChatterItem in
                guard let item = originItem as? ChatChatterWapper else { return originItem }
                var newTags = item.itemTags
                // 1. 尝试添加specialFocus tag
                if addChatterIds.contains(where: { $0 == item.itemId }) {
                    let tagDataItem = LarkBizTag.TagDataItem(tagType: .specialFocus)
                    newTags?.append(tagDataItem)
                }
                // 2. 尝试删除specialFocus tag
                if msg.deleteChatterIds.contains(where: { $0 == item.itemId }) {
                    newTags?.removeAll(where: { $0.tagType == .specialFocus })
                }
                // 3. 根据newTags生成新的数据源
                var wapper = ChatChatterWapper(chatter: item.chatter,
                                               itemName: item.itemName,
                                               itemMedalKey: item.itemMedalKey,
                                               itemTags: newTags,
                                               itemCellClass: item.itemCellClass,
                                               itemDepartment: item.itemDepartment,
                                               itemTimeZoneId: item.itemTimeZoneId,
                                               descInlineProvider: item.descInlineProvider,
                                               descUIConfig: item.descUIConfig)
                wapper.needDisplayDepartment = item.needDisplayDepartment
                wapper.supportShowDepartment = item.supportShowDepartment
                return wapper
            }
            newSection.items = items
            return newSection
        }
        self.datas = datas
        self.orderDataSource?.datas = datas
        self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .update))
    }

    private func findChatChatter(_ id: String) -> Chatter? {
        for section in datas {
            for item in section.items where item.itemId == id {
                guard let chatterWrapper = item as? ChatChatterWapper else { return nil }
                return chatterWrapper.chatter
            }
        }
        return nil
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
        self.orderDataSource?.datas = datas
        // 如果没有在当前list则追加到当前section的最后一个
        if !isInCurrentList, !self.datas.isEmpty, self.sortType != .alphabetical {
            let lastIndex = self.datas.count - 1
            self.datas[lastIndex].items.append(new)
        }
    }

    // 解析返回数据
    func paserDatas(_ result: RustPB.Im_V1_GetChatChattersResponse, chatterIds: [[String: [String]]]) -> [ChatChatterSection] {
        guard let chatChatters = result.entity.chatChatters[chat.id]?.chatters else { return [] }

        return chatterIds.compactMap { (section) -> ChatChatterSection? in
            return section.compactMap { (key, chatterIds) -> ChatChatterSection? in

                let items = chatterIds.compactMap({ (id) -> ChatChatterWapper? in
                    guard let pb = chatChatters[id] else { return nil }
                    // 过滤掉非群主的机器人
                    if pb.type == .bot, pb.id != chat.ownerId { return nil }
                    return wrapper(Chatter.transform(pb: pb))
                })

                return items.isEmpty ? nil :
                    ChatChatterSectionData(
                        title: key,
                        indexKey: key,
                        items: items,
                        sectionHeaderClass: ContactTableHeader.self
                    )
            }.first
        }
    }

    private func tryRemoveChatters(_ selectedItems: [ChatChatterItem]) {
        if let confirmBeforeDeleteCallback = self.confirmBeforeDeleteCallback {
            confirmBeforeDeleteCallback(selectedItems)
        } else {
            removeChatters(selectedItems)
        }
    }

    public func removeChatters(_ selectedItems: [ChatChatterItem]) {
       removeChatters(with: selectedItems.map { $0.itemId }) { [weak self] error in
           guard let `self` = self else { return }
           self.delegate?.onRemoveEnd(error)
           if let error = error, let window = self.targetVC?.view.window {
               if let error = error.underlyingError as? APIError {
                   switch error.type {
                   case .noSecretChatPermission(let message):
                       UDToast.showFailure(with: message, on: window, error: error)
                   case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                       UDToast.showFailure(
                           with: BundleI18n.LarkCore
                               .Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                           on: window,
                           error: error
                       )
                   default:
                       UDToast.showFailure(
                           with: BundleI18n.LarkCore.Lark_Legacy_GroupDeleteMemberFailTip,
                           on: window,
                           error: error
                       )
                   }
                   return
               }
               UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_GroupDeleteMemberFailTip, on: window, error: error)
           }
       }
    }

    private func removeChatters(with chatterIds: [String], onFinish: ((Error?) -> Void)? = nil) {
        let chatId = chat.id
        self.chatAPI.deleteChatters(chatId: chatId, chatterIds: chatterIds, newOwnerId: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                onFinish?(nil)
                if let window = self.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkCore.Lark_Legacy_RemovedSuccessfully, on: window)
                }
            }, onError: { (error) in
                onFinish?(error)
                ChatterControllerVM.logger.error(
                    "remove chat chatter error",
                    additionalData: [
                        "chatID": chatId,
                        "chatterIds": chatterIds.joined(separator: ",")
                    ],
                    error: error)
            }).disposed(by: disposeBag)
    }

    // 左滑items组装
    public override func structureActionItems(tapTask: @escaping () -> Void,
                                       indexPath: IndexPath) -> [UIContextualAction]? {
        guard delegate?.canLeftSlide() ?? false, !useLeanCell else { return nil }
        let chat = self.chat
        let isOwner = self.isOwner
        let isAdmin = self.isGroupAdmin
        let myUserId = self.currentChatterId
        // 删除item
        let delete = UIContextualAction(style: .destructive,
                                        title: BundleI18n.LarkCore.Lark_Groups_DeleteMember) { [weak self] (_, _, completionHandler) in
            tapTask()
            CoreTracker.imGroupMemberClick(chat: chat, myUserId: myUserId, isOwner: isOwner, isAdmin: isAdmin, clickEvent: .deleteGroupMembers, target: "im_group_confirm_view")
            completionHandler(false)
            self?.delete(indexPath: indexPath)
        }

        // 设置为群主 item
        let assignGroupOwner = UIContextualAction(style: .destructive,
                                                  title: BundleI18n.LarkCore.Lark_Legacy_AssignGroupOwner) { [weak self] (_, _, completionHandler) in
            tapTask()
            CoreTracker.imGroupMemberClick(chat: chat, myUserId: myUserId, isOwner: isOwner, isAdmin: isAdmin, clickEvent: .transferOwner, target: "none")
            completionHandler(false)
            self?.assignGroupOwner(indexPath: indexPath)
        }
        assignGroupOwner.backgroundColor = UIColor.ud.N600

        // 设置为群管理员 item
        let assignGroupAdmin = UIContextualAction(style: .destructive,
                                                  title: BundleI18n.LarkCore.Lark_Legacy_AssignGroupAdmin) { [weak self] (_, _, completionHandler) in
            tapTask()
            CoreTracker.imGroupMemberClick(chat: chat, myUserId: myUserId, isOwner: isOwner, isAdmin: isAdmin, clickEvent: .assignAdmin, target: "none")
            completionHandler(false)
            self?.assignGroupAdmin(indexPath: indexPath)
        }
        assignGroupAdmin.backgroundColor = UIColor.ud.colorfulYellow

        // 移除群管理员 item
        let removeGroupAdmin = UIContextualAction(style: .destructive,
                                                  title: BundleI18n.LarkCore.Lark_Legacy_RemoveGroupAdmins) { [weak self] (_, _, completionHandler) in
            tapTask()
            CoreTracker.imGroupMemberClick(chat: chat, myUserId: myUserId, isOwner: isOwner, isAdmin: isAdmin, clickEvent: .deleteGroupMembers, target: "im_group_confirm_view")
            completionHandler(false)
            self?.removeGroupAdmin(indexPath: indexPath)
        }
        removeGroupAdmin.backgroundColor = UIColor.ud.colorfulYellow

        let actions = [canShowDelete(indexPath: indexPath) ? delete : nil,
                       canShowAssignGroupAdmin(indexPath: indexPath) ? assignGroupAdmin : nil,
                       canShowRemoveGroupAdmin(indexPath: indexPath) ? removeGroupAdmin : nil,
                       canShowAssignGroupOwner(indexPath: indexPath) ? assignGroupOwner : nil].compactMap({ $0 })
        return actions
    }

    private func canShowDelete(indexPath: IndexPath) -> Bool {
        guard let cell = delegate?.getCellByIndexPath(indexPath),
            let item = cell.item else { return false }
        let selectedIsMe = item.itemId == currentChatterId
        let selectedIsOwner = item.itemId == chat.ownerId
        let selectedIsAdmin = item.itemTags?.contains(where: { $0.tagType == .groupAdmin }) ?? false
        let deletePermission = isOwner || isGroupAdmin
        guard deletePermission, !selectedIsMe, !selectedIsOwner else {
            return false
        }
        // 群管理员无法删除群管理员
        if isGroupAdmin, selectedIsAdmin { return false }
        return true
    }

    private func canShowAssignGroupOwner(indexPath: IndexPath) -> Bool {
        guard let cell = delegate?.getCellByIndexPath(indexPath),
            let item = cell.item else { return false }
        let selectedIsMe = item.itemId == currentChatterId
        let selectedIsOwner = item.itemId == chat.ownerId
        guard isOwner, !selectedIsMe, !selectedIsOwner else {
            return false
        }
        return true
    }

    private func canShowAssignGroupAdmin(indexPath: IndexPath) -> Bool {
        guard !chat.isCrypto, let cell = delegate?.getCellByIndexPath(indexPath),
              let item = cell.item else { return false }
        let selectedIsMe = item.itemId == currentChatterId
        let selectedIsOwner = item.itemId == chat.ownerId
        let selectedIsAdmin = item.itemTags?.contains(where: { $0.tagType == .groupAdmin }) ?? false
        guard isOwner, !selectedIsAdmin, !selectedIsMe, !selectedIsOwner else {
            return false
        }
        return true
    }

    private func canShowRemoveGroupAdmin(indexPath: IndexPath) -> Bool {
        guard !chat.isCrypto, let cell = delegate?.getCellByIndexPath(indexPath),
              let item = cell.item else { return false }
        let selectedIsMe = item.itemId == currentChatterId
        let selectedIsOwner = item.itemId == chat.ownerId
        let selectedIsAdmin = item.itemTags?.contains(where: { $0.tagType == .groupAdmin }) ?? false
        guard isOwner, selectedIsAdmin, !selectedIsMe, !selectedIsOwner else {
            return false
        }
        return true
    }

    private func delete(indexPath: IndexPath) {
        guard let cell = delegate?.getCellByIndexPath(indexPath),
            let item = cell.item else { return }
        let chat = self.chat
        let myUserId = self.currentChatterId
        let isOwner = self.isOwner
        let isAdmin = self.isGroupAdmin
        CoreTracker.imGroupConfirmView(chat: chat,
                                       myUserId: myUserId,
                                       isOwner: isOwner,
                                       isAdmin: isAdmin,
                                       confirmType: "delete_group_members")
        tryRemoveChatters([item])
    }

    // 设置为群主
    private func assignGroupOwner(indexPath: IndexPath) {
        guard let cell = self.delegate?.getCellByIndexPath(indexPath),
            let item = cell.item else { return }
        let chat = self.chat
        let myUserId = self.currentChatterId
        let isOwner = self.isOwner
        let isAdmin = self.isGroupAdmin
        CoreTracker.imGroupConfirmView(chat: chat,
                                       myUserId: myUserId,
                                       isOwner: isOwner,
                                       isAdmin: isAdmin,
                                       confirmType: "transfer_owner")
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkCore.Lark_Legacy_AssignGroupOwner)
        dialog.setContent(text: BundleI18n.LarkCore.Lark_Legacy_ChatGroupInfoTransferSure(item.itemName))
        dialog.addSecondaryButton(text: BundleI18n.LarkCore.Lark_Legacy_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.LarkCore.Lark_Legacy_LarkConfirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            CoreTracker.imGroupConfirmClick(chat: chat,
                                            myUserId: myUserId,
                                            isOwner: isOwner,
                                            isAdmin: isAdmin,
                                            confirmType: "transfer_owner")
            self.assignGroupOwner(newOwnerId: item.itemId)
        })
        if let vc = targetVC {
            userResolver.navigator.present(dialog, from: vc)
        }
    }

    // 设置为群管理员
    private func assignGroupAdmin(indexPath: IndexPath) {
        guard let cell = self.delegate?.getCellByIndexPath(indexPath),
            let item = cell.item else { return }
        self.patchGroupAdmin(toAddUserIds: [item.itemId])
    }

    // 移除群管理员
    private func removeGroupAdmin(indexPath: IndexPath) {
        guard let cell = self.delegate?.getCellByIndexPath(indexPath),
            let item = cell.item else { return }
        self.patchGroupAdmin(toDeleteUserIds: [item.itemId])
    }

    // 群管理员更新接口
    private func patchGroupAdmin(toAddUserIds: [String] = [],
                                 toDeleteUserIds: [String] = []) {
        let chatId = chat.id
        self.chatAPI.patchChatAdminUsers(chatId: chatId,
                                         toAddUserIds: toAddUserIds,
                                         toDeleteUserIds: toDeleteUserIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let window = self?.targetVC?.currentWindow() {
                    UDToast.showTips(with: BundleI18n.LarkCore.Lark_NewSettings_SetSuccessfully, on: window)
                }
            }, onError: { [weak self] (error) in
                if let window = self?.targetVC?.currentWindow() {
                    UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_GroupAdminAddFailedToast, on: window, error: error)
                }
                ChatterControllerVM.logger.error(
                    "remove chat chatter error",
                    additionalData: [
                        "chatID": chatId,
                        "toAddUserIds": toAddUserIds.joined(separator: ","),
                        "toDeleteUserIds": toDeleteUserIds.joined(separator: ",")
                    ],
                    error: error)
            }).disposed(by: disposeBag)
    }

    // 转让群主接口
    private func assignGroupOwner(newOwnerId: String) {
        let chatId = self.chat.id
        self.chatAPI.transferGroupOwner(chatId: chatId, ownerId: newOwnerId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let window = self?.targetVC?.currentWindow() {
                    UDToast.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_ChangeOwnerSuccess, on: window)
                }
            }, onError: { [weak self] (error) in
                if let error = error.underlyingError as? APIError, let window = self?.targetVC?.currentWindow() {
                    switch error.type {
                    case .transferGroupOwnerFailed(let message):
                        UDToast.showFailure(with: message, on: window, error: error)
                    default:
                        if !error.displayMessage.isEmpty {
                            UDToast.showFailure(with: error.displayMessage, on: window)
                        } else {
                            UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_ChangeOwnerFailed, on: window, error: error)
                        }
                    }
                }
                Self.logger.error(
                    "transfer group owner failed!",
                    additionalData: ["chatId": chatId, "newOwnerId": newOwnerId],
                    error: error
                )
            })
            .disposed(by: self.disposeBag)
    }
}

// MARK: 数据加载和处理
extension ChatChatterControllerVM {
    /// 包装成 ChatChatterItem
    func wrapper(_ chatter: Chatter) -> ChatChatterWapper? {
        guard chatterFliter(chatter) else { return nil }

        // 获取显示名
        func itemName(for chatter: Chatter) -> String {
            return chatter.displayName(
                chatId: chat.id,
                chatType: chat.type,
                scene: chat.oncallId.isEmpty ? .groupMemberList : .oncall)
        }

        var item = ChatChatterWapper(
            chatter: chatter,
            itemName: itemName(for: chatter),
            itemMedalKey: chatter.medalKey,
            itemTags: self.itemTags(for: chatter),
            itemCellClass: useLeanCell ? ChatChatterLeanCell.self : ChatChatterCell.self,
            itemDepartment: chatter.chatChatterListDepartmentName,
            itemTimeZoneId: chatter.timeZoneID,
            descInlineProvider: { [weak self] completion in
                guard let self = self, !chatter.description_p.text.isEmpty else { return }
                let paragraphStyle = NSMutableParagraphStyle()
                // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
                paragraphStyle.lineBreakMode = .byWordWrapping
                var attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: self.descUIConfig.linkColor,
                    .font: self.descUIConfig.font,
                    .paragraphStyle: paragraphStyle,
                    MessageInlineViewModel.iconColorKey: self.descUIConfig.linkColor,
                    MessageInlineViewModel.tagTypeKey: TangramService.TagType.normal
                ]
                let startTime = CACurrentMediaTime()
                self.inlineService?.replaceWithInlineTryBuffer(
                    sourceID: chatter.id,
                    sourceText: chatter.description_p.text,
                    type: .personalSig,
                    attributes: attributes,
                    completion: { [weak self] result, sourceID, _, sourceType in
                        if result.urlRangeMap.isEmpty, result.textUrlRangeMap.isEmpty { return }
                        completion(sourceID, result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap)
                        self?.inlineService?.trackURLInlineRender(sourceID: chatter.id,
                                                                 sourceText: chatter.description_p.text,
                                                                 type: .personalSig,
                                                                 sourceType: sourceType,
                                                                 scene: "chatter_list",
                                                                 startTime: startTime,
                                                                 endTime: CACurrentMediaTime())
                    }
                )
            },
            descUIConfig: descUIConfig)
        item.needDisplayDepartment = self.needDisplayDepartment
        item.supportShowDepartment = self.supportShowDepartment
        let chatterIsAdmin = chatter.chatExtra?.tagInfos.tags.contains(where: { $0.tagType == .adminUser }) ?? false
        // 只有非群主才能使管理员进入不可选择态
        let adminCanUnSelected = chatterIsAdmin && !isOwner
        if !isOwnerSelectable && (currentChatterId == chatter.id || chatter.id == chat.ownerId || adminCanUnSelected) {
            item.isSelectedable = false
        }
        return item
    }
}
