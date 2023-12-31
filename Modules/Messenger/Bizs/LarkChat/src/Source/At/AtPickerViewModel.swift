//
//  AtPickerViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/3.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import RxSwift
import LarkTag
import RxCocoa
import LKCommonsLogging
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import ThreadSafeDataStructure
import RustPB
import LarkBizTag
import LarkContainer
import LarkAIInfra

final class AtPickerViewModel {
    let userResolver: UserResolver
    static let logger = Logger.log(AtPickerViewModel.self, category: "AtPickerViewModel")
    private var disposeBag = DisposeBag()

    private(set) var chatId: String
    /// 整体是否允许at all
    private(set) var allowAtAll: Bool
    private(set) var allowSideIndex: Bool
    private(set) var chat: Chat
    /// 是否允许MyAi
    var allowMyAi: Bool = false
    let showChatUserCount: Bool

    private var chatType: Chat.TypeEnum
    private var displayNameScene: GetChatterDisplayNameScene

    private var chatterAPI: ChatterAPI
    private var parseCache: [String: AtPickerItem] = [: ]
    private var isFirstDataLoaded: Bool = false
    private var outChatChatterIds: [String] = []
    private let serverNTPTimeService: ServerNTPTimeService
    private var atOuterText: String?
    private var aiService: MyAIService

    private let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)
    var statusVar: Driver<ChatChatterViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }

    var shouldShowTipView: Bool = false
    var shouldShowIndex: Bool = true
    var showDepartment: Bool = false
    var selectedItems: [AtPickerItem] = []

    var datas: [ChatChatterSection] = [] {
        didSet { _reloadData.onNext(()) }
    }
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private(set) var filterKey: String = ""
    private var searchStartCache: SafeDictionary<String, Double> = [:] + .readWriteLock

    /// On data ready callback, (Swift.Result<Bool, Error>) -> Void
    var onDataReady: ((Swift.Result<Bool, Error>) -> Void)?

    /// - Parameter allowSideIndex: if false, do not allow at all, otherwise let the viewModel decide if at all available
    init(userResolver: UserResolver,
         chat: Chat,
         atOuterText: String? = BundleI18n.LarkChat.Lark_Chat_AtNonChatMemberDescription,
         allowAtAll: Bool,
         allowSideIndex: Bool
    ) throws {
        self.userResolver = userResolver
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.serverNTPTimeService = try userResolver.resolve(assert: ServerNTPTimeService.self)
        self.aiService = try userResolver.resolve(assert: MyAIService.self)

        self.chat = chat
        self.chatId = chat.id
        self.atOuterText = atOuterText
        self.allowSideIndex = allowSideIndex
        self.showChatUserCount = chat.isUserCountVisible

        self.chatType = chat.type
        self.displayNameScene = chat.oncallId.isEmpty ? .atOrUrgentPick : .oncall
        let isAdmin = chat.isGroupAdmin
        self.allowAtAll = allowAtAll &&
            chat.type != .p2P &&
            (chat.atAllPermission == .allMembers || chat.ownerId == userResolver.userID || isAdmin)

    }

    private func checkShouldTrack(_ isSuccess: Bool) {
        guard let start = searchStartCache.removeValue(forKey: filterKey) else { return }
        ChatTracker.trackMentionExternalUserSearchTime(
            Int((CACurrentMediaTime() - start) * 1000),
            isSuccess: isSuccess
        )
    }

    func loadChatter() {
        let chatID = self.chatId
        // 获取基础信息
        chatterAPI.fetchAtListWithLocalOrRemote(chatId: chatID, query: filterKey)
            .subscribe(onNext: { [weak self] (result, isRemote) in
                guard let `self` = self else { return }
                self.shouldShowTipView = result.showSearch
                self.shouldShowIndex = self.allowSideIndex && !self.shouldShowTipView
                self.onLoadData(result, isRemote)
                self.onDataReady?(.success(isRemote))
            }, onError: { [weak self] (error) in
                AtPickerViewModel.logger.error(
                    "fetch at list error",
                    additionalData: ["chatID": chatID],
                    error: error)
                self?.statusBehavior.onNext(.error(error))
                self?.checkShouldTrack(false)
                self?.onDataReady?(.failure(error))
            }).disposed(by: disposeBag)
    }

    func loadChatterRemoteDepartmentInfo(chatterIds: [Int64]) {
        // 获取部门信息
        let requestID = UUID().uuidString
        chatterAPI.fetchAtListRemoteDepartmentInfo(chatterIds: chatterIds,
                                                   requestID: requestID).subscribe(onNext: { [weak self] (result, responseID) in
            guard let self = self else { return }
            Self.logger.info("department data count is \(result.chatterIDToSensitiveInfo.count)")
            if requestID == responseID {
                var tempData = self.datas
                result.chatterIDToSensitiveInfo.forEach { element in
                    tempData.updateDepartmentName(element.value.departmentName, String(element.key))
                }
                self.datas = tempData
                self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .searchNoResult(self.filterKey) : .display))
            }
        }, onError: { [weak self] (error) in
            AtPickerViewModel.logger.error(
                "fetch at list department error",
                additionalData: ["chatID": self?.chatId ?? ""],
                error: error)
        }).disposed(by: disposeBag)
    }

    func filterChatter(_ key: String) {
        guard isFirstDataLoaded else { return }

        filterKey = key
        disposeBag = DisposeBag()

        if filterKey.isEmpty {
            searchStartCache.removeAll()
        }
        statusBehavior.onNext(.viewStatus(.loading))
        loadChatter()
        searchStartCache[key] = CACurrentMediaTime()
    }

    func deselected(_ item: AtPickerItem, isTableEvent: Bool = true) {
        selectedItems.removeAll(where: { $0.itemId == item.itemId })

        // if event not trigged by table, reload table
        if !isTableEvent {
            _reloadData.onNext(())
        }
    }

    func selected(_ item: AtPickerItem, isTableEvent: Bool = true) {
        selectedItems.append(item)

        // if event not trigged by table, reload table
        if !isTableEvent {
            _reloadData.onNext(())
        }
    }

    /// return true if item is selected
    func isItemSelected(_ item: ChatChatterItem) -> Bool {
        return selectedItems.contains(where: { $0.itemId == item.itemId })
    }

    var isMyAiEnable: Bool {
        if !allowMyAi { return false }
        let isAiEnable = self.aiService.enable.value && !aiService.needOnboarding.value
        Self.logger.info("[Mention]{check ai enable} - ai: \(isAiEnable), chat: \(allowMyAi)")
        return isAiEnable
    }

    var aiEntity: MyAIInfo {
        return self.aiService.info.value
    }
}

// MARK: - parse data result
private extension AtPickerViewModel {

    func itemTags(for chatter: Chatter) -> [TagDataItem]? {
        var result: [TagDataItem] = []
        if let items = chatter.tagData?.transform() {
            result.append(contentsOf: items)
        }
        /// 对方处于勿扰模式
        if self.serverNTPTimeService
            .afterThatServerTime(time: chatter.doNotDisturbEndTime) {
            result.append(TagDataItem(tagType: .doNotDisturb))
        }
        if chatter.workStatus.status == .onLeave { result.append(TagDataItem(tagType: .onLeave)) }
        if chatter.type == .bot { result.append(TagDataItem(tagType: .robot)) }
        if !chatter.isRegistered { result.append(TagDataItem(tagType: .unregistered)) }
        result.append(contentsOf: chatter.eduTags.map({ tag in
            return TagDataItem(text: tag.title,
                               tagType: .customTitleTag,
                               frontColor: tag.style.textColor,
                               backColor: tag.style.backColor)
        }))
        return result
    }

    // 将 chatter 包装成 ChatChatterItem 以便后续的选择打点等操作
    func wrap(_ chatter: Chatter, location: Int, eventTag: String? = nil, isWanted: Bool = false, departmentNameDic: [String: String] = [:]) -> ChatChatterItem {

        // 由于打点需要针对每个 chatter 独立打点，所以将信息与 item 绑定
        let trackExtension = AtPickerItemTrackExtension(
            location: location,
            tag: eventTag,
            isQuery: !filterKey.isEmpty,
            isWanted: isWanted)

        if var item = parseCache[chatter.id] {
            item.trackExtension = trackExtension
            item.itemDepartment = departmentNameDic[chatter.id]
            return item
        }

        let isOuter = outChatChatterIds.contains(chatter.id)

        var item = AtPickerItem(
            chatter: chatter,
            itemName: chatter.displayName(chatId: chatId, chatType: chatType, scene: displayNameScene),
            itemTags: itemTags(for: chatter),
            itemCellClass: showDepartment ? ChatChatterProfileCell.self : ChatChatterCell.self,
            itemDepartment: departmentNameDic[chatter.id],
            isOuter: isOuter,
            trackExtension: trackExtension
        )
        item.supportShowDepartment = showDepartment && chatter.type == .user
        item.needDisplayDepartment = item.supportShowDepartment

        parseCache[chatter.id] = item

        return item
    }

    func onLoadData(_ data: RustPB.Im_V1_GetMentionChatChattersResponse, _ isRemote: Bool) {
        Self.logger.info("API data: wantedMentionIds count is \(data.wantedMentionIds.count), " +
                         "inChatChatterIds count is \(data.inChatChatterIds.count), " +
                         "outChatAtChatters count is: \(data.outChatChatterIds.count)")

        let getChatters: ([String]) -> [Chatter] = {
            $0.compactMap({ (chatterId) -> Chatter? in

                // 因为有群外的人，所以优先取群成员，取不到则尝试取‘entity.chatters’
                if let pb = data.entity.chatChatters[self.chatId]?.chatters[chatterId] ??
                    data.entity.chatters[chatterId] {
                    return Chatter.transform(pb: pb)
                }
                Self.logger.info("can`t find chatter in entity")
                return nil
            })
        }

        self.outChatChatterIds = data.outChatChatterIds

        // 可能@的人,屏蔽MyAi
        let wantedAtChatters: [Chatter] = getChatters(data.wantedMentionIds).filter { $0.type != .ai }
        let inChatAtChatters: [Chatter] = getChatters(data.inChatChatterIds).filter { $0.type != .ai }
        let outChatAtChatters: [Chatter] = getChatters(data.outChatChatterIds).filter { $0.type != .ai }
        let departmentNameDic = data.entity.chatterIDToSensitiveInfo.reduce(into: [String: String]()) { result, element in
            return result[String(element.key)] = element.value.departmentName
        }

        if filterKey.isEmpty {
            parseChatters(
                inChatAtChatters,
                wantedAtChatters: wantedAtChatters,
                wantedMentionTags: data.wantedMentionTags)
        } else {
            parseChatters(
                inChatAtChatters,
                outChatAtChatters: outChatAtChatters,
                departmentNameDic: departmentNameDic)
            // remote Chatters数据返回时，根据相应chatterIds请求remote部门数据
            if isRemote {
                let chatterIds = [data.inChatChatterIds, data.outChatChatterIds]
                    .flatMap { $0 }
                    .compactMap { Int64($0) }
                self.loadChatterRemoteDepartmentInfo(chatterIds: chatterIds)
            }
        }
    }

    /// 解析普通显示数据
    func parseChatters(
        _ chatters: [Chatter],
        wantedAtChatters: [Chatter],
        wantedMentionTags: [String: String]
    ) {
        var datas = [ChatChatterSection]()

        // 记录当前起始Index, 从1开始
        var offset: Int = 1

        if !wantedAtChatters.isEmpty {
            let wantedAtSection = ChatChatterSectionData(
                title: BundleI18n.LarkChat.Lark_Legacy_ProbabilityAtPersonHint,
                indexKey: "@",
                items: wantedAtChatters.enumerated().map { (index, chatter) in
                    wrap(chatter, location: offset + index, eventTag: wantedMentionTags[chatter.id], isWanted: true)
                },
                sectionHeaderClass: GrayTableHeader.self)
            datas.append(wantedAtSection)

            datas.append(ChatChatterSectionData(
                title: BundleI18n.LarkChat.Lark_Legacy_AllMember,
                indexKey: "",
                items: [],
                sectionHeaderClass: GrayTableHeader.self))
            offset = wantedAtChatters.count
        }

        datas.append(contentsOf: chatters.lf_sorted(
            by: { $0.sortIndexName < $1.sortIndexName },
            getIndexKey: { $0.sortIndexName })
            .map { (sortedSesstion) in
                let session = ChatChatterSectionData(
                    title: sortedSesstion.key,
                    items: sortedSesstion.elements.enumerated().map { (index, chatter) in
                        wrap(chatter, location: offset + index)
                    },
                    sectionHeaderClass: ContactTableHeader.self)
                offset += session.items.count
                return session
            }
        )
        // 话题小组没有“全部成员”需要过滤掉
        if chat.type == .topicGroup {
            self.datas = datas.filter { !$0.items.isEmpty }
        } else {
            self.datas = datas
        }
        let itemsCount = self.datas.reduce("") { result, section in
            result + "\(section.items.count), "
        }
        Self.logger.info("UI data is \(itemsCount)")
        statusBehavior.onNext(.viewStatus(.display))
        isFirstDataLoaded = true
    }

    /// 解析搜索显示数据
    func parseChatters(_ chatters: [Chatter], outChatAtChatters: [Chatter], departmentNameDic: [String: String] = [:]) {
        var datas: [ChatChatterSection] = []

        // 记录当前起始Index, 从1开始
        var offset: Int = 1

        if !chatters.isEmpty {
            datas.append(
                ChatChatterSectionData(
                    title: BundleI18n.LarkChat.Lark_Chat_AtChatMember,
                    indexKey: "",
                    items: chatters.enumerated().map { (index, chatter) in
                        wrap(chatter, location: offset + index, departmentNameDic: departmentNameDic)
                    },
                    sectionHeaderClass: GrayTableHeader.self)
            )
            offset = chatters.count
        }

        if !outChatAtChatters.isEmpty {
            // 当且仅当群内成员为空，且有群外的人时才添加“AtNoResultItem”
            if chatters.isEmpty {
                datas.append(
                    ChatChatterSectionData(
                        title: BundleI18n.LarkChat.Lark_Chat_AtChatMember,
                        indexKey: "",
                        items: [AtNoResultItem()],
                        sectionHeaderClass: GrayTableHeader.self)
                )
            }
            datas.append(
                AtPickerOutChatSection(
                    title: BundleI18n.LarkChat.Lark_Chat_AtNonChatMember,
                    subTitle: atOuterText,
                    indexKey: "",
                    items: outChatAtChatters.enumerated().map { (index, chatter) in
                        wrap(chatter, location: offset + index, departmentNameDic: departmentNameDic)
                    },
                    sectionHeaderClass: GrayTableHeader.self))

            checkShouldTrack(true)
        }

        self.datas = datas
        statusBehavior.onNext(.viewStatus(datas.isEmpty ? .searchNoResult(filterKey) : .display))
    }
}
