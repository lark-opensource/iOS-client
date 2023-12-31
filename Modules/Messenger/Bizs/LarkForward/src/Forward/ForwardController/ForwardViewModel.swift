//
//  ForwardVIewModel.swift
//  LarkForward
//
//  Created by 姚启灏 on 2018/11/26.
//

import Foundation
import Homeric
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging
import LKCommonsTracker
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import LarkFeatureGating
import LarkSearchCore
import LarkContainer
import LarkFocusInterface
import LarkOpenFeed
import LarkBizTag
import RustPB

public struct ForwardSectionData {
    let title: String
    var dataSource: [ForwardItem]
    let showFooterView: Bool // footerView是否有展开折叠按钮
    let isSearchResult: Bool
    var isFold: Bool // isFold = False时，限制的展示条数。和实际状态是反的
}

public struct ForwardSelectRecordInfo {

    public enum ResultType: String {
        case top, recent, search, mention
    }

    public let id: String
    public let offset: Int32
    public let resultType: ResultType

    public init(id: String, offset: Int32, resultType: ResultType) {
        self.id = id
        self.offset = offset
        self.resultType = resultType
    }
}

// nolint: duplicated_code,magic_number -- v1转发代码，历史代码全量下线后可删除
public final class ForwardViewModel {
    static let minShowDataCount = 3
    static let maxDataCount = 40

    static let logger = Logger.log(ForwardViewModel.self, category: "Module.IM.Message")

    var searchVM: SearchSimpleVM<ForwardItem>! = nil

    private let feedSyncDispatchService: FeedSyncDispatchService
    private let serverNTPTimeService: ServerNTPTimeService
    private let disposeBag = DisposeBag()
    private let enableThreadMiniIconFg: Bool
    private let enableDocCustomIconFg: Bool
    private lazy var forwardFgEnable: Bool = {
        self.provider.userResolver.fg.staticFeatureGatingValue(with: "foward.quickswitcher.v118")
    }()
    private let modelService: ModelService
    // 控制 搜索/最近聊天 是否过滤掉帖子 true:不过滤
    private var canForwardToTopic: Bool? = false

    let provider: ForwardAlertProvider
    let currentTenantId: String
    let userTypeObservable: Observable<PassportUserType>

    /// 勿扰模式检查
    lazy var checkInDoNotDisturb: ((Int64) -> Bool) = { [weak self] time -> Bool in
        guard let `self` = self else { return false }
        return self.serverNTPTimeService.afterThatServerTime(time: time)
    }

    private var defaultItems: [ForwardSectionData] = []

    private var dataSourceVariable = BehaviorRelay<[ForwardSectionData]>(value: [])
    var dataSourceDriver: Driver<[ForwardSectionData]> {
        return dataSourceVariable.asDriver()
    }

    private var isLoadingViewShowVariable = BehaviorRelay<Bool>(value: false)
    var isloadingViewShowDriver: Driver<Bool> {
        return isLoadingViewShowVariable.asDriver()
    }

    private var selectItemsVariable = BehaviorRelay<[ForwardItem]>(value: [])
    var selectItemsDriver: Driver<[ForwardItem]> {
        return selectItemsVariable.asDriver()
    }

    private var hasMoreVariable = BehaviorRelay<Bool>(value: false)
    var hasMoreDriver: Driver<Bool> {
        return hasMoreVariable.asDriver()
    }

    private var showNoResultView = BehaviorRelay<Bool>(value: false)
    var showNoResultViewDriver: Driver<Bool> {
        return showNoResultView.asDriver()
    }

    private var filter: ForwardDataFilter? {
        return provider.getFilter()
    }

    var maxSelectCount: Int {
        return provider.maxSelectCount
    }

    var isSupportMultiSelectMode: Bool {
        return provider.isSupportMultiSelectMode
    }

    var isShowCreatChatView: Bool {
        return provider.shouldCreateGroup
    }

    private var needExternalTagObservable: Observable<Bool>?

    public init(
         feedSyncDispatchService: FeedSyncDispatchService,
         currentTenantId: String,
         provider: ForwardAlertProvider,
         enableThreadMiniIconFg: Bool,
         enableDocCustomIconFg: Bool,
         serverNTPTimeService: ServerNTPTimeService,
         modelService: ModelService,
         canForwardToTopic: Bool? = false,
         userTypeObservable: Observable<PassportUserType>) {
        self.feedSyncDispatchService = feedSyncDispatchService
        self.currentTenantId = currentTenantId
        self.provider = provider
        self.serverNTPTimeService = serverNTPTimeService
        self.modelService = modelService
        self.canForwardToTopic = canForwardToTopic
        self.userTypeObservable = userTypeObservable
        self.enableThreadMiniIconFg = enableThreadMiniIconFg
        self.enableDocCustomIconFg = enableDocCustomIconFg

        self.searchVM = makeSearchVM()
        bindSearchVM()
    }

    func makeSearchVM() -> SearchSimpleVM<ForwardItem> {
        var maker = RustSearchSourceMaker(resolver: self.provider.userResolver, scene: .rustScene(.transmitMessages))
        maker.needSearchOuterTenant = provider.needSearchOuterTenant
        maker.authPermissions = [.createP2PChat]
        let source = maker.makeAndReturnProtocol()

        let list = SearchListVM(
            source: source, pageCount: 20, compactMap: { [weak self](result: SearchItem) -> ForwardItem? in
                guard let result = result as? SearchResultType else {
                    assertionFailure("unreachable code!!")
                    return nil
                }
                return self?.compactMap(result: result)
            })
        return SearchSimpleVM(result: list)
    }

    func compactMap(result: SearchResultType) -> ForwardItem? {
        // before filter
        if canForwardToTopic == false, case .thread = result.meta {
            return nil
        }

        // map
        var type = ForwardItemType.unknown
        var id = ""
        var description = ""
        var flag = Chatter.DescriptionType.onDefault
        var isCrossTenant = false
        var isCrossWithKa = false
        var isThread = false
        var doNotDisturbEndTime: Int64 = 0
        var hasInvitePermission: Bool = true
        var isOfficialOncall: Bool = false
        var channelID: String?
        var chatId = ""
        var chatUserCount = 0 as Int32
        var customStatus: ChatterFocusStatus?
        var tagData: Basic_V1_TagData?

        switch result.meta {
        case .chatter(let chatter):
            id = chatter.id
            type = ForwardItemType(rawValue: chatter.type.rawValue) ?? .unknown
            description = chatter.description_p
            flag = chatter.descriptionFlag
            isCrossTenant = (chatter.tenantID != self.currentTenantId)
            doNotDisturbEndTime = chatter.doNotDisturbEndTime
            customStatus = chatter.customStatus.topActive
            let searchActionType: SearchActionType = .createP2PChat
            var forwardSearchDeniedReason: SearchDeniedReason = .unknownReason
            // 有deniedReason直接判断deniedReason，没有的情况下判断deniedPermissions
            if let searchDeniedReason = chatter.deniedReason[Int32(searchActionType.rawValue)] {
                forwardSearchDeniedReason = searchDeniedReason
            } else if !chatter.deniedPermissions.isEmpty {
                forwardSearchDeniedReason = .sameTenantDeny
            }
            // 统一通过deniedReason判断OU权限(sameTenantDeny)和外部联系人的的权限（block）
            hasInvitePermission = !(forwardSearchDeniedReason == .sameTenantDeny || forwardSearchDeniedReason == .blocked)
            tagData = chatter.relationTag.toBasicTagData()
        case .chat(let chat):
            id = chat.id
            chatId = chat.id
            type = .chat
            isCrossTenant = chat.isCrossTenant
            isCrossWithKa = chat.isCrossWithKa
            isThread = chat.chatMode == .threadV2
            isOfficialOncall = chat.isOfficialOncall
            chatUserCount = chat.userCountWithBackup
            tagData = chat.relationTag.toBasicTagData()
        case .thread(let thread):
            id = thread.id
            type = .threadMessage
            channelID = thread.channel.id
            isThread = true
        default:
            break
        }

        var avatarKey = result.avatarKey
        if enableDocCustomIconFg,
           let icon = result.icon,
           icon.type == .image {
            avatarKey = icon.value
        }
        var item = ForwardItem(
            avatarKey: avatarKey,
            name: result.title.string,
            subtitle: result.summary.string,
            description: description,
            descriptionType: flag,
            localizeName: result.title.string,
            id: id,
            chatId: chatId,
            type: type,
            isCrossTenant: isCrossTenant,
            isCrossWithKa: isCrossWithKa,
            isCrypto: false,
            isThread: isThread,
            channelID: channelID,
            doNotDisturbEndTime: doNotDisturbEndTime,
            hasInvitePermission: hasInvitePermission,
            userTypeObservable: self.userTypeObservable,
            enableThreadMiniIcon: enableThreadMiniIconFg,
            isOfficialOncall: isOfficialOncall,
            tags: result.tags,
            attributedTitle: nil,
            attributedSubtitle: nil,
            customStatus: customStatus,
            tagData: tagData)
        item.chatUserCount = chatUserCount
        Self.logger.info("init forwardItem with id:\(id), chatId:\(chatId), type:\(type)")
        // after filter
        return self.filter?(item) != false ? item : nil
    }

    func bindSearchVM() {
        searchVM?.result.stateObservable.subscribe(onNext: { [weak self](change) in
            self?.on(change: change)
        }).disposed(by: disposeBag)
    }

    typealias ListVM = SearchListVM<ForwardItem>

    private var listState: SearchListStateCases? // 仅用于回调记录，回调是在单线程上的

    func on(change: ListVM.StateChange) {
        func accept(results: [ForwardItem]) {
            dataSourceVariable.accept([ForwardSectionData(
                title: "",
                dataSource: results,
                showFooterView: false,
                isSearchResult: true,
                isFold: false)])
        }
        if change.state.state != .empty { // empty切换到defaultItems控制的source, 忽略listvm的
            if let results = change.newValue(keyPath: \.results) { accept(results: results) }
        }
        cases: if let cases = change.newValue(keyPath: \.state) {
            if let old = listState {
                if old == cases { break cases } // cases相同不做处理
                switch old {
                case .empty:
                    // 恢复list绑定，如果这次变化没有对应的变化通知的话
                    if !change.hasChange(keyPath: \ListVM.State.results) { accept(results: change.state.results) }
                case .reloading: isLoadingViewShowVariable.accept(false)
                default: break
                }
            }
            listState = cases
            switch cases {
            case .empty:
                showNoResultView.accept(false)
                showDefaultPage()
            case .reloading:
                showNoResultView.accept(false)
                isLoadingViewShowVariable.accept(true)
            case .loadingMore: break // 没有loadingMore对应的通知，是UI主动发起的
            case .normal:
                switch change.event {
                case .success(req: let req, appending: _):
                    showNoResultView.accept(change.state.results.isEmpty)
                    // VC依赖这个通知来结束loadMore的状态，所以加载结束后总是通知，而不仅仅是变的时候
                    hasMoreVariable.accept(change.state.hasMore)
                    SearchTrackUtil.track(requestTimeInterval: -req.startTime.timeIntervalSinceNow,
                                          query: req.query, status: change.state.results.isEmpty ? "NO" : "YES",
                                          location: searchLocation)
                case .fail(req: let req, error: _):
                    hasMoreVariable.accept(false)
                    SearchTrackUtil.track(requestTimeInterval: -req.startTime.timeIntervalSinceNow,
                                          query: req.query, status: "fail", location: searchLocation)
                default: break
                }
            @unknown default: break
            }
        }
    }

    // 展示并更新default页内容
    func showDefaultPage() {
        // 获取需要去查询权限的外部联系人，dic[key: value] key是chatterId，valus是chatID
        var authDic: [String: String] = [:]
        // 过滤出没有外部联系人的items
        let items = defaultItems.map({ (data) -> ForwardSectionData in
            var data = data
            data.dataSource = data.dataSource.filter({ (item) -> Bool in
                if item.isCrossTenant, item.type == .user, !(item.chatId?.isEmpty ?? true) {
                    authDic[item.id] = item.chatId
                    return false
                }
                return true
            })
            return data
        })
        // 根据过滤的数据先初始化list
        self.dataSourceVariable.accept(items)
        self.hasMoreVariable.accept(false)
        // 如果没有鉴权的用户直接结束
        guard !authDic.isEmpty else {
            return
        }
        // 批量查询外部联系人的权限
        try? self.provider.userResolver.resolve(assert: ContactAPI.self).fetchAuthChattersRequest(actionType: .shareMessageSelectUser,
                                            isFromServer: true,
                                            chattersAuthInfo: authDic)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self else { return }
                self.defaultItems = self.defaultItems.map { (data) -> ForwardSectionData in
                    var newData = data
                    let dataSource = data.dataSource.map { (item) -> ForwardItem in
                        guard let deniedReason = res.authResult.deniedReasons[item.id] else {
                            return item
                        }
                        var item = item
                        // 如果block则没有权限
                        if item.isCrossTenant,
                           item.type == .user,
                           deniedReason == .blocked {
                            item.hasInvitePermission = false
                        } else {
                            switch deniedReason {
                            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                                item.hasInvitePermission = false
                            @unknown default: break
                            }
                        }
                        return item
                    }
                    newData.dataSource = dataSource
                    return newData
                }
                self.dataSourceVariable.accept(self.defaultItems)
                self.hasMoreVariable.accept(false)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.dataSourceVariable.accept(self.defaultItems)
                self.hasMoreVariable.accept(false)
                Self.logger.error("fetchAuthChattersRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    let searchLocation = "choose"

    func loadDefaultData() {
        let enableThreadMiniIconFg = self.enableThreadMiniIconFg
        if forwardFgEnable {
            // 置顶数据
            let stickItems = self.feedSyncDispatchService
                .allShortcutChats
                .sorted { $0.lastMessagePosition > $1.lastMessagePosition }
                .enumerated()
                .filter({ (index, _) -> Bool in
                    return index < ForwardViewModel.maxDataCount
                })
                .map({ [weak self] (_, chat) -> ForwardItem in
                    let chatterType: ForwardItemType = ForwardItemType(rawValue: chat.chatter?.type.rawValue ?? 0) ?? .unknown
                    var item = ForwardItem(avatarKey: chat.avatarKey,
                                       name: chat.displayWithAnotherName,
                                       subtitle: chat.chatter?.department ?? "",
                                       description: chat.description,
                                       descriptionType: chat.chatter?.description_p.type ?? .onDefault,
                                       localizeName: chat.localizedName,
                                       id: chat.chatterId.isEmpty ? chat.id : chat.chatterId,
                                       chatId: chat.id,
                                       type: chat.chatterId.isEmpty ? .chat : chatterType,
                                       isCrossTenant: chat.isCrossTenant,
                                       isCrossWithKa: chat.isCrossWithKa,
                                       // code_next_line tag CryptChat
                                       isCrypto: chat.isCrypto,
                                       isThread: chat.chatMode == .threadV2,
                                       doNotDisturbEndTime: chat.chatter?.doNotDisturbEndTime ?? 0,
                                       hasInvitePermission: true,
                                       userTypeObservable: self?.userTypeObservable,
                                       enableThreadMiniIcon: enableThreadMiniIconFg,
                                       isOfficialOncall: chat.isOfficialOncall,
                                       tags: chat.tags,
                                       customStatus: chat.chatter?.focusStatusList.topActive,
                                           tagData: chat.tagData)
                    Self.logger.info("init forwardItem with id:\(chat.chatterId.isEmpty ? chat.id : chat.chatterId), chatId:\(chat.id), type:\(chat.chatterId.isEmpty ? .chat : chatterType)")
                    item.chatUserCount = chat.userCount
                    return item
                }).filter({
                    // code_next_line tag CryptChat
                    (self.filter?($0) ?? true) && !$0.isCrypto
                }).filter { (item) -> Bool in
                    /// 过滤外租户 item
                    return self.provider.needSearchOuterTenant || !item.isCrossTenant
                }
            let stickSection = ForwardSectionData(title: BundleI18n.LarkForward.Lark_Legacy_TableQuickswitcher,
                                                  dataSource: stickItems,
                                                  showFooterView: stickItems.count > ForwardViewModel.minShowDataCount,
                                                  isSearchResult: false,
                                                  isFold: false)
            defaultItems.append(stickSection)
        }

        // 加载最近聊天数据 包括帖子
        loadTopItems()
    }

    // 加载最近聊天数据 包括帖子
    private func loadTopItems() {
        self.feedSyncDispatchService.topInboxData(by: ForwardViewModel.maxDataCount)
            .subscribe(onNext: { [weak self] (forwardMessages) in
                guard let self = self else { return }
                let topItems = forwardMessages.filter({ (_, message) -> Bool in
                    // 对于不能转发到帖子的需要将帖子筛选掉 chat的message == nil
                    if self.canForwardToTopic == false && message != nil {
                        return false
                    }
                    return true
                })
                .map { [weak self] (chat, message) in
                    var name = ""
                    var ID = ""
                    var type: ForwardItemType = .chat
                    var channelID: String?
                    // 对于帖子消息，不应该显示外部标签，因此默认为false
                    var isCrossTenant = false
                    var isCrossWithKa = false
                    if let message = message {
                        // threadMessage
                        name = self?.modelService.messageSummerize(message) ?? ""
                        ID = message.id
                        type = .threadMessage
                        channelID = message.channel.id
                    } else {
                        let tmpChatterType = ForwardItemType(rawValue: chat.chatter?.type.rawValue ?? 0) ?? .unknown
                        name = chat.displayWithAnotherName
                        ID = chat.chatterId.isEmpty ? chat.id : chat.chatterId
                        type = chat.chatterId.isEmpty ? .chat : tmpChatterType
                        isCrossTenant = chat.isCrossTenant
                        isCrossWithKa = chat.isCrossWithKa
                    }
                    var item = ForwardItem(
                        avatarKey: chat.avatarKey,
                        name: name,
                        subtitle: chat.chatter?.department ?? "",
                        description: chat.description,
                        descriptionType: chat.chatter?.description_p.type ?? .onDefault,
                        localizeName: chat.localizedName,
                        id: ID,
                        chatId: chat.id,
                        type: type,
                        isCrossTenant: isCrossTenant,
                        isCrossWithKa: isCrossWithKa,
                        // code_next_line tag CryptChat
                        isCrypto: chat.isCrypto,
                        isThread: chat.chatMode == .threadV2,
                        channelID: channelID,
                        doNotDisturbEndTime: chat.chatter?.doNotDisturbEndTime ?? 0,
                        hasInvitePermission: true,
                        userTypeObservable: self?.userTypeObservable,
                        enableThreadMiniIcon: self?.enableThreadMiniIconFg ?? false,
                        isOfficialOncall: chat.isOfficialOncall,
                        tags: chat.tags,
                        customStatus: chat.chatter?.focusStatusList.topActive,
                        tagData: chat.tagData)
                    Self.logger.info("init forwardItem with id:\(ID), chatId:\(chat.id), type:\(type)")
                    item.chatUserCount = chat.userCount
                    return item
                }.filter({
                    // code_next_line tag CryptChat
                    (self.filter?($0) ?? true) && !$0.isCrypto
                }).filter { (item) -> Bool in
                    /// 过滤外租户 item
                    self.provider.needSearchOuterTenant || !item.isCrossTenant
                }
                let topSection = ForwardSectionData(title: BundleI18n.LarkForward.Lark_Legacy_TableRecentchats,
                                                    dataSource: topItems,
                                                    showFooterView: false,
                                                    isSearchResult: false,
                                                    isFold: false)
                self.defaultItems.append(topSection)

                if self.searchVM?.result.state.state == .empty {
                    self.showDefaultPage()
                }
        }, onError: { (error) in
                ForwardViewModel.logger.error("loadTopItems error", error: error)
            })
        .disposed(by: disposeBag)
    }

    func matchText(text: String) {
        self.searchVM?.query.text.accept(text)
    }

    func loadMoreData() {
        self.searchVM?.result.loadMore()
    }

    func addSelectItem(item: ForwardItem) {
        var temp = self.selectItemsVariable.value
        temp.append(item)
        self.selectItemsVariable.accept(temp)
    }

    func removeSelectItem(item: ForwardItem) {
        var temp = self.selectItemsVariable.value
        temp.removeAll { (forwarditem) -> Bool in
            forwarditem.id == item.id
        }
        self.selectItemsVariable.accept(temp)
    }

    func removeAllSelectItem() {
        self.selectItemsVariable.accept([])
    }

    func changeSectionFlod() {
        var temp = self.dataSourceVariable.value
        temp[0].isFold.toggle()
        self.dataSourceVariable.accept(temp)
        Tracer.trackTapFlod(isFlod: self.dataSourceVariable.value[0].isFold)
    }

    func trackAction(isMultiSelectMode: Bool,
                     selectRecordInfo: [ForwardSelectRecordInfo],
                     chatIds: [String]) {
        var chatId = ""
        if !isMultiSelectMode {
            if let data = selectRecordInfo.first {
                if !chatIds.isEmpty, let selectedChatId = chatIds.first {
                    chatId = selectedChatId
                }
                if let content = provider.content as? OpenShareContentAlertContent {
                    Tracer.trackSingleClick(location: data.resultType.rawValue, position: Int(data.offset), chatId: chatId, source: content.sourceAppName)
                } else {
                    Tracer.trackSingleClick(location: data.resultType.rawValue, position: Int(data.offset), chatId: chatId)
                }
            }
        } else {
            selectRecordInfo.enumerated().forEach { (index, info) in
                if chatIds.count > index {
                    chatId = chatIds[index]
                }
                if let content = provider.content as? OpenShareContentAlertContent {
                    Tracer.trackMultiClick(location: info.resultType.rawValue, position: Int(info.offset), chatId: chatId, source: content.sourceAppName)
                } else {
                    Tracer.trackMultiClick(location: info.resultType.rawValue, position: Int(info.offset), chatId: chatId)
                }
            }
        }
    }
}
