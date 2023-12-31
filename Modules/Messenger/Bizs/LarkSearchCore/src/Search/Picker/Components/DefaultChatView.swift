//
//  DefaultChatView.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/14.
//

import Foundation
import UIKit
import RxSwift
import LarkFeatureGating
import LarkMessengerInterface
import LarkOpenFeed
import LKCommonsLogging
import LarkModel
import UniverseDesignToast
import LarkKeyCommandKit
import Homeric
import LarkUIKit
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkAccountInterface
import EENavigator
import LarkSetting
import LKCommonsTracker

// TODO: 默认页实现放出去, 暂时放在picker组件里
typealias ForwardItemFilter = (ForwardItem) -> Bool
public final class DefaultChatView: UIView, UITableViewDelegate, UITableViewDataSource, TableViewKeyboardHandlerDelegate, ForwardItemDataConvertable, UserResolverWrapper {

    public var userResolver: LarkContainer.UserResolver
    static let logger = Logger.log(DefaultChatView.self, category: "DefaultChatView")
    static let loggerKey = "Forward.View: "
    weak var selectionDataSource: SelectionDataSource?
    let tableView: UITableView
    private lazy var headerStackView = UIStackView()
    var recentForwardView: RecentForwardView?
    private var skeletonView: ForwardSkeletonTableView?
    var recentForwardDatas: [RecentForwardCellData] = []
    var keyboardHandler: TableViewKeyboardHandler?
    var preWidth: CGFloat = 0
    var remoteDataLoaded = false
    weak var fromVC: UIViewController?
    let bag = DisposeBag()

    @ScopedInjectedLazy var serviceContainer: PickerServiceContainer?
    lazy var searchAPI: SearchAPI? = { self.serviceContainer?.searchAPI }()
    lazy var contactAPI: ContactAPI? = { self.serviceContainer?.contactAPI }()
    lazy var userService: PassportUserService? = { self.serviceContainer?.userService }()

    private lazy var forwardFgEnable: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: "foward.quickswitcher.v118")
    }()
    /// 近期访问是否需要和最近转发去重
    private lazy var listNoRepeat: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: "core.forward.list_no_repeat")
    }()
    /// 近期访问是否开启多端同步
    private lazy var isRemoteSyncFG: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: "messenger.message.duoduan_sync")
    }()
    /// 近期访问是否开启多端同步
    private lazy var isNewPermissionFG: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: "lark.forward.use_new_deny_reason")
    }()

    let filter: ForwardItemFilter?
    // 老逻辑生成最近转发过滤参数时用到该属性
    let filterParameters: ForwardFilterParameters?
    // 转发多端同步设计参数
    let includeConfigs: IncludeConfigs
    let enableConfigs: IncludeConfigs
    let canForwardToTopic: Bool
    let shouldShowRecentForward: Bool
    let canForwardToMsgThread: Bool
    let targetPreview: Bool
    lazy var dataProvider = { ForwardDataProvider(searchAPI: self.searchAPI, contactAPI: self.contactAPI, userService: self.userService) }()
    // 最近转发过滤参数
    var recentForwardRequestParameter = RecentForwardFilterParameter()

    lazy var feedSyncDispatchService = self.serviceContainer?.feedSyncDispatchService
    public var forwardInitTime: CFTimeInterval = CACurrentMediaTime()
    private let scene: String?
    deinit {
        Self.logger.info("\(Self.loggerKey) deinit")
    }

    init(resolver: LarkContainer.UserResolver,
         frame: CGRect,
         customView: UIView?,
         selection: SelectionDataSource,
         canForwardToTopic: Bool,
         scene: String?,
         canForwardToMsgThread: Bool,
         shouldShowRecentForward: Bool,
         filter: ForwardItemFilter?,
         filterParameters: ForwardFilterParameters? = nil,
         includeConfigs: IncludeConfigs? = nil,
         enableConfigs: IncludeConfigs? = nil,
         fromVC: UIViewController? = nil,
         targetPreview: Bool = false,
         isInForwardComponent: Bool) {
        self.userResolver = resolver
        tableView = UITableView(frame: CGRect(origin: .zero, size: frame.size), style: .plain)
        selectionDataSource = selection
        self.filter = filter
        self.filterParameters = filterParameters
        //兜底策略，如果为nil将展示所有targets
        self.includeConfigs = includeConfigs ?? [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig()
        ]
        self.enableConfigs = enableConfigs ?? [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig(),
            ForwardThreadEnabledEntityConfig()
        ]
        self.canForwardToTopic = canForwardToTopic
        self.canForwardToMsgThread = canForwardToMsgThread
        self.scene = scene
        self.fromVC = fromVC
        self.targetPreview = targetPreview
        self.shouldShowRecentForward = shouldShowRecentForward
        super.init(frame: frame)
        if isInForwardComponent {
            self.recentForwardRequestParameter = self.generateRecentForwardRequestParameter(filterConfigs: self.includeConfigs, disabledConfigs: self.enableConfigs)
        } else {
            self.recentForwardRequestParameter = self.generateRecentForwardRequestParameter(currentUid: userResolver.userID, filter: filter, filterParameters: filterParameters)
            self.recentForwardRequestParameter.includeMyAi = self.includeConfigs.contains(where: { $0.type == .myAi })
        }

        self.backgroundColor = UIColor.ud.bgBody

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 68
        tableView.separatorColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.register(ForwardChatTableCell.self, forCellReuseIdentifier: "ForwardChatTableCell")
        tableView.delegate = self
        tableView.dataSource = self
        headerStackView = UIStackView()
        headerStackView.axis = .vertical
        headerStackView.spacing = 0
        headerStackView.distribution = .equalSpacing
        tableView.tableHeaderView = headerStackView
        if SearchFeatureGatingKey.forwardLoacalDataOptimized.isUserEnabled(userResolver: self.userResolver) {
            loadData()
        }
        headerStackView.snp.makeConstraints {
            $0.width.equalTo(tableView)
        }
        if let customView = customView {
            tableView.tableHeaderView = headerStackView
            // 如果customView是frame设置的，需要更新为约束
            if customView.translatesAutoresizingMaskIntoConstraints {
                customView.snp.makeConstraints {
                    $0.height.equalTo(customView.bounds.height)
                }
            }
            headerStackView.addArrangedSubview(customView)
            headerStackView.layoutIfNeeded()
            tableView.tableHeaderView = headerStackView
        }
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        #endif

        self.addSubview(tableView)
        self.skeletonView = ForwardSkeletonTableView()
        if let skeletonView = self.skeletonView {
            addSubview(skeletonView)
            skeletonView.snp.makeConstraints {
               $0.edges.equalTo(UIEdgeInsets.zero)
            }
        }

        // tableview keyboard
        keyboardHandler = TableViewKeyboardHandler(options: [.allowCellFocused(focused: Display.pad)])
        keyboardHandler?.delegate = self
        Self.logger.info("\(Self.loggerKey) forward request parameter: \(self.recentForwardRequestParameter)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var loaded = false // lazy load when appear on window
    public override func willMove(toWindow newWindow: UIWindow?) {
        guard !loaded, newWindow != nil else { return }
        // loaded用来保证willMovetoWindow里的逻辑只执行一次
        loaded = true
        if !SearchFeatureGatingKey.forwardLoacalDataOptimized.isUserEnabled(userResolver: self.userResolver) {
            loadData()
        }
        // FIXME: 是否有动态切换的选项?
        let tableView = self.tableView
        selectionDataSource?.isMultipleChangeObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] isMulti in
            guard let self = self else { return }
            self.recentForwardDatas.forEach({
                $0.isMutiple = isMulti
            })
            self.recentForwardView?.updateUI(cellDatas: self.recentForwardDatas)
            tableView.reloadData()
            }).disposed(by: bag)
        selectionDataSource?.selectedChangeObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] dataSource in
            guard let self = self else { return }
            self.recentForwardDatas.forEach({
                $0.isSelected = dataSource.state(for: $0.item, from: nil).selected
            })
            self.recentForwardView?.updateUI(cellDatas: self.recentForwardDatas)
            tableView.reloadData()
            }).disposed(by: bag)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // update recentForwardView if needed
        if preWidth != self.bounds.size.width {
            self.preWidth = self.bounds.size.width
            self.recentForwardView?.setNeedsLayout()
            self.recentForwardView?.layoutIfNeeded()
            self.recentForwardView?.updateUI(cellDatas: self.recentForwardDatas)
        }
    }

    // MARK: Model
    static let maxDataCount = 40
    static let minShowDataCount = 3
    var sections: [ForwardSectionData] = []

    func includeRecentForward() -> Bool {
        return self.shouldShowRecentForward
        return self.shouldShowRecentForward
    }

    func getRecentVisitAndRecentForwardOb(strategy: Basic_V1_SyncDataStrategy, recentVisitLimit: Int32 = 60) -> Observable<([ForwardItem], [ForwardItem])> {
        return Observable.combineLatest(self.loadForwardItems(isFromLocal: false, strategy: strategy, limit: recentVisitLimit),
                                        self.loadRecentForwardItem(strategy: strategy))
    }

    func dataAvailable(recentVisitItems: [ForwardItem], leastCount: Int) -> Bool {
        // 最近访问本地缓存大于x，且远端数据未加载过，才用本地缓存先上屏
        return recentVisitItems.count >= leastCount
    }

    func filterRecentVisitItem(recentVisit: [ForwardItem], recentForward: [ForwardItem]) -> ([ForwardItem], [ForwardItem]) {
        let result = ForwardViewModel.filterForwardItems(recentForwardItems: recentForward, recentViewItems: recentVisit,
                                                         noRepeat: self.listNoRepeat)
        let recentVisitItems = result.recentViewItems.enumerated().map {
            var i = $1; i.index = $0 ; return i
        }
        let recentForwardItems = result.recentForwardItems.enumerated().map {
            var i = $1; i.index = $0 + 1 ; return i
        }
        Self.logger.info("\(Self.loggerKey) display recent visit view \(recentVisitItems.count) items: \(recentVisitItems.map { $0.log })")
        Self.logger.info("\(Self.loggerKey) display recent forward \(recentForwardItems.count) items: \(recentForwardItems.map { $0.log })")
        return (recentVisitItems, recentForwardItems)
    }

    // nolint: long_function 加载方法,内部有方法拆分,转发Q4会统一重构
    func loadData() {
        // TODO: 外部有其他依赖直接复用了ForwardViewModel
        Self.logger.info("\(Self.loggerKey) loadData")
        struct Context {
            var resolver: UserResolver
            var sections: [ForwardSectionData] = []

            func makeItem(chat: Chat) -> ForwardItem {
                makeItem(chat: chat,
                         id: chat.isPrivateMode ? chat.id : (chat.chatterId.isEmpty ? chat.id : chat.chatterId),
                         name: chat.displayName,
                         // FIXME: unknown的type是不是过滤掉？
                         type: chat.isPrivateMode ? .chat : (chat.chatterId.isEmpty ? .chat : ForwardItemType(rawValue: chat.chatter?.type.rawValue ?? 0) ?? .unknown),
                         isCrossTenant: chat.isCrossTenant,
                         isCrossWithKa: chat.isCrossWithKa,
                         tagData: chat.tagData
                )
            }
            func makeItem(chat: Chat, id: String, name: String, type: ForwardItemType,
                          isCrossTenant: Bool, isCrossWithKa: Bool, channelID: String? = nil, tagData: Basic_V1_TagData? = nil
            ) -> ForwardItem {
                let userService = try? resolver.resolve(assert: PassportUserService.self)
                var item = ForwardItem(
                    avatarKey: chat.avatarKey,
                    name: name,
                    subtitle: chat.chatter?.department ?? "",
                    description: chat.description,
                    descriptionType: chat.chatter?.description_p.type ?? .onDefault,
                    localizeName: chat.localizedName,
                    id: id,
                    chatId: chat.id,
                    type: type,
                    isCrossTenant: isCrossTenant,
                    isCrossWithKa: isCrossWithKa,
                    // code_next_line tag CryptChat
                    isCrypto: chat.isCrypto,
                    isThread: chat.chatMode == .threadV2 || type.isThread,
                    isPrivate: chat.isPrivateMode,
                    channelID: channelID,
                    doNotDisturbEndTime: chat.chatter?.doNotDisturbEndTime ?? 0,
                    hasInvitePermission: true,
                    userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                    enableThreadMiniIcon: false,
                    isOfficialOncall: chat.isOfficialOncall,
                    tags: chat.tags,
                    customStatus: chat.chatter?.focusStatusList.topActive,
                    tagData: tagData
                )
                item.chatUserCount = chat.userCount
                DefaultChatView.logger.info("\(DefaultChatView.loggerKey) init forwardItem with id:\(id), chatId:\(chat.id), type:\(type)")
                item.source = .recentChat
                return item
            }
        }
        var context = Context(resolver: self.userResolver)
        var counter = 0
        let reload = { [weak self] in
            guard let self = self else { return }
            if self.isNewPermissionFG {
                self.reload(items: context.sections)
                return
            }
            counter += 1
            let sections = context.sections
            // 获取需要去查询权限的外部联系人，dic[key: value] key是chatterId，valus是chatID
            var authDic: [String: String] = [:]
            // 过滤出没有外部联系人的items
            let items = sections.map({ (data) -> ForwardSectionData in
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
            self.reload(items: items)
            // 如果没有鉴权的用户直接结束
            guard !authDic.isEmpty else {
                return
            }
            // 批量查询外部联系人的权限
            self.contactAPI?.fetchAuthChattersRequest(
                actionType: .shareMessageSelectUser, isFromServer: true, chattersAuthInfo: authDic
            ).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, capture = counter] (res) in // 异步排重
                    guard let `self` = self, capture == counter else { return }
                    let sections = sections.map { (data) -> ForwardSectionData in
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
                    self.reload(items: sections)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    self.reload(items: sections)
                    Self.logger.error("\(Self.loggerKey) fetchAuthChattersRequest error, error = \(error)")
                }).disposed(by: self.bag)

        }

        func reloadForwardViews(recentVisit: [ForwardItem], recentForward: [ForwardItem], dataGetCost: CFTimeInterval, isLocal: Bool) {
            let topSection = ForwardSectionData(title: BundleI18n.LarkSearchCore.Lark_IM_RecentVisit_Title,
                                                dataSource: recentVisit,
                                                canFold: false,
                                                shouldFold: false,
                                                tag: "recent")
            if let index = context.sections.firstIndex(where: { $0.tag == "recent" }) {
                // 如果最近访问数据已经存在，则用本次的新数据来替换老数据
                context.sections[index] = topSection
            } else {
                // 如果最近访问数据为空，则直接append本次数据
                context.sections.append(topSection)
            }

            // update UI after async load
            reload()
            if self.includeRecentForward() {
                self.loadRecentForwardViewData(items: recentForward)
            }
            let dataGetCost = Int((dataGetCost) * 1000)
            let dataUiCost = Int((CACurrentMediaTime() - self.forwardInitTime) * 1000)
            // 首屏上报埋点
            Tracker.post(TeaEvent("forward_data_time_profiler",
                                  params: [
                                    "data_get_cost": dataGetCost,
                                    "data_ui_cost": dataUiCost,
                                    "data_isLocal": isLocal ? "true" : "false",
                                    "data_optimization_fg": "true"
                                  ]))
            Self.logger.info("\(Self.loggerKey) dataGetCost: \(dataGetCost) dataUiCost: \(dataUiCost), isLocalData: \(isLocal)")
        }

        // 置顶数据
        func loadStickItems() {
            // NOTE: 这是一个同步方法
            let stickItems = feedSyncDispatchService?
            .allShortcutChats
            .sorted { $0.lastMessagePosition > $1.lastMessagePosition }
            .prefix(Self.maxDataCount)
            .map { (chat) -> ForwardItem in context.makeItem(chat: chat) }
            .filter {
                // 外租户也由filter过滤
                // code_next_line tag CryptChat
                !$0.isCrypto && (self.filter?($0) ?? true)
            } ?? []
            let stickSection = ForwardSectionData(title: BundleI18n.LarkSearchCore.Lark_Legacy_TableQuickswitcher,
                                                  dataSource: stickItems,
                                                  canFold: stickItems.count > Self.minShowDataCount,
                                                  shouldFold: true,
                                                  tag: "top")
            context.sections.append(stickSection)
        }

        // 加载最近聊天数据 包括帖子
        func asyncLoadTopItems() {
            Self.logger.info("\(Self.loggerKey) sync: \(isRemoteSyncFG), list: true")
            let requestTime = CACurrentMediaTime()
            var remoteResponseTime = CACurrentMediaTime()
            var localResponseTime = CACurrentMediaTime()
            if SearchFeatureGatingKey.forwardLoacalDataOptimized.isUserEnabled(userResolver: self.userResolver) {
                Self.logger.info("optimized InitToQuestCost: \(requestTime - self.forwardInitTime)")
                self.getRecentVisitAndRecentForwardOb(strategy: .local, recentVisitLimit: 10)
                    .map { [weak self] (recentVisit, recentForward) in
                        localResponseTime = CACurrentMediaTime()
                        let data = self?.filterRecentVisitItem(recentVisit: recentVisit, recentForward: recentForward)
                        return data ?? ([], [])
                    }
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (recentVisit, recentForward) in
                        // local数据大于等于3，且远端未刷新过
                        guard let self,
                              self.dataAvailable(recentVisitItems: recentVisit, leastCount: 3),
                              !self.remoteDataLoaded
                        else { return }
                        self.skeletonView?.removeFromSuperview()
                        reloadForwardViews(recentVisit: recentVisit,
                                           recentForward: recentForward,
                                           dataGetCost: localResponseTime - requestTime,
                                           isLocal: true)
                    }, onError: { [weak self] error in
                        self?.skeletonView?.removeFromSuperview()
                        Self.logger.error("\(Self.loggerKey) loadTopItems error", error: error)
                    }).disposed(by: bag)

                self.getRecentVisitAndRecentForwardOb(strategy: .forceServer)
                    .map { [weak self] (recentVisit, recentForward) in
                        remoteResponseTime = CACurrentMediaTime()
                        let data = self?.filterRecentVisitItem(recentVisit: recentVisit, recentForward: recentForward)
                        return data ?? ([], [])
                    }
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (recentVisit, recentForward) in
                        // 远端数据大于等于1才刷新
                        guard let self,
                              self.dataAvailable(recentVisitItems: recentVisit, leastCount: 1)
                        else {
                            return
                        }
                        self.skeletonView?.removeFromSuperview()
                        self.remoteDataLoaded = true
                        reloadForwardViews(recentVisit: recentVisit,
                                           recentForward: recentForward,
                                           dataGetCost: remoteResponseTime - requestTime,
                                           isLocal: false)
                    }, onError: { [weak self] error in
                        self?.skeletonView?.removeFromSuperview()
                        Self.logger.error("\(Self.loggerKey) loadTopItems error", error: error)
                    }).disposed(by: bag)
                return
            }
            let fetchListRequest: Observable<[ForwardItem]> = {
                if isRemoteSyncFG { return self.loadForwardItems(isFromLocal: false) }
                return self.loadForwardItems(isFromLocal: true)
            }()
            Observable.combineLatest(fetchListRequest, loadRecentForwardItem())
                .map { [weak self] (topItems, recentItems) in
                    remoteResponseTime = CACurrentMediaTime()
                    let result = ForwardViewModel.filterForwardItems(recentForwardItems: recentItems, recentViewItems: topItems,
                                                                     noRepeat: self?.listNoRepeat)
                    let recentViewItems = result.recentViewItems.enumerated().map {
                        var i = $1; i.index = $0 ; return i
                    }
                    let recentForwardItems = result.recentForwardItems.enumerated().map {
                        var i = $1; i.index = $0 + 1 ; return i
                    }
                    Self.logger.info("\(Self.loggerKey) display recent view \(recentViewItems.count) items: \(recentViewItems.map { $0.log })")
                    Self.logger.info("\(Self.loggerKey) display recent forward \(recentForwardItems.count) items: \(recentForwardItems.map { $0.log })")
                    return (recentViewItems, recentForwardItems)
                }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (topItems, recentItems) in
                guard let self = self else { return }
                self.skeletonView?.removeFromSuperview()
                let topSection = ForwardSectionData(title: BundleI18n.LarkSearchCore.Lark_IM_RecentVisit_Title,
                                                    dataSource: topItems,
                                                    canFold: false,
                                                    shouldFold: false,
                                                    tag: "recent")
                context.sections.append(topSection)
                // update UI after async load
                reload()
                if self.includeRecentForward() {
                    self.loadRecentForwardViewData(items: recentItems)
                }
                let dataGetCost = Int((remoteResponseTime - requestTime) * 1000)
                let dataUiCost = Int((CACurrentMediaTime() - self.forwardInitTime) * 1000)
                Tracker.post(TeaEvent("forward_data_time_profiler",
                                      params: [
                                        "data_get_cost": dataGetCost,
                                        "data_ui_cost": dataUiCost,
                                        "data_isLocal": "false",
                                        "data_optimization_fg": "false"
                                      ]))
                Self.logger.info("\(Self.loggerKey) remote dataGetCost: \(dataGetCost) remote dataUiCost: \(dataUiCost) InitToQuestCost: \(requestTime - self.forwardInitTime)")
            }, onError: { (error) in
                self.skeletonView?.removeFromSuperview()
                Self.logger.error("\(Self.loggerKey) loadTopItems error", error: error)
            }).disposed(by: bag)
        }
        func loadFeedForwardItem() -> Observable<[ForwardItem]> {
            guard let feedSyncDispatchService else { return .never() }
            return feedSyncDispatchService.topInboxData(by: Self.maxDataCount, containMsgThread: self.canForwardToMsgThread)
            .retry(2) // 没有手动重试，加一次自动重试
            .map { [weak self] (info) in
                guard let self = self else { return [] }
                var topItems = info.forwardMessages.filter { (_, message) -> Bool in
                    // 对于不能转发到帖子的需要将帖子筛选掉
                    return !(self.canForwardToTopic == false && message != nil)
                }.map { (chat, message) in
                    var name = ""
                    var ID = ""
                    var type: ForwardItemType = .chat
                    var channelID: String?
                    // 对于帖子消息，不应该显示外部标签，因此默认为false
                    var isCrossTenant = false
                    var isCrossWithKa = false
                    if let message = message {
                        // threadMessage
                        let msgThreadName = info.msgThreadMap[message.id]
                        name = msgThreadName ?? (self.serviceContainer?.messageModelService?.messageSummerize(message) ?? "")
                        ID = message.id
                        type = msgThreadName != nil ? .replyThreadMessage : .threadMessage
                        channelID = message.channel.id
                    } else {
                        let tmpChatterType = ForwardItemType(rawValue: chat.chatter?.type.rawValue ?? 0) ?? .unknown
                        name = chat.displayWithAnotherName
                        ID = chat.chatterId.isEmpty ? chat.id : chat.chatterId
                        type = chat.chatterId.isEmpty ? .chat : tmpChatterType
                        isCrossTenant = chat.isCrossTenant
                        isCrossWithKa = chat.isCrossWithKa
                    }
                    if chat.isPrivateMode {
                        ID = chat.id
                        type = .chat
                    }
                    Self.logger.info("isPrivate: \(chat.isPrivateMode), ID: \(ID), chat.id: \(chat.id), chatterID: \(chat.chatterId), type: \(type)")
                    return context.makeItem(chat: chat, id: ID, name: name, type: type, isCrossTenant: isCrossTenant, isCrossWithKa: isCrossWithKa, channelID: channelID, tagData: chat.tagData)
                }.filter {
                    // code_next_line tag CryptChat
                    !$0.isCrypto && (self.filter?($0) ?? true)
                }
                topItems = topItems.enumerated().map {
                    var item = $1
                    item.index = $0
                    return item
                }
                return topItems
            }
        }
        if forwardFgEnable {
            loadStickItems()
        }
        asyncLoadTopItems()
        reload()
    }
    // enable-lint: long_function

    private func loadForwardItems(isFromLocal: Bool, strategy: Basic_V1_SyncDataStrategy = .forceServer, limit: Int32 = 60) -> Observable<[ForwardItem]> {
        return dataProvider.loadForwardItems(isFromLocal: isFromLocal, includeConfigs: includeConfigs, strategy: strategy, limit: limit)
            .map { [weak self] res -> [ForwardItem] in
                guard let self = self else { return [] }
                let items = res.filter {
                    // code_next_line tag CryptChat
                    if !isFromLocal { return true }
                    return !$0.isCrypto && (self.filter?($0) ?? true)
                }
                return items.map {
                    var i = $0
                    i.source = .recentChat
                    return i
                }
            }
    }

    private func loadRecentForwardItem(strategy: Basic_V1_SyncDataStrategy = .forceServer) -> Observable<[ForwardItem]> {
        guard includeRecentForward() else {
            return .just([])
        }
        return dataProvider.loadRecentForwardItem(filter: recentForwardRequestParameter, strategy: strategy)
    }

    func reload(items: [ForwardSectionData]) {
        assert(Thread.isMainThread, "should occur on main thread!")
        self.sections = items
        self.tableView.reloadData()
    }

    func loadRecentForwardViewData(items: [ForwardItem]) {
        guard includeRecentForward() else { return }
        if items.isEmpty { return }
        if self.recentForwardView.isNil {
            let recentView = RecentForwardView(frame: CGRect(x: 0, y: 0, width: frame.width, height: Self.recentForwardViewHeight))
            recentView.snp.makeConstraints {
                $0.height.equalTo(Self.recentForwardViewHeight)
            }
            headerStackView.addArrangedSubview(recentView)
            headerStackView.layoutIfNeeded()
            self.recentForwardView = recentView
            tableView.tableHeaderView = headerStackView
            if #unavailable(iOS 12) {
                headerStackView.snp.makeConstraints {
                    $0.top.leading.trailing.equalToSuperview()
                }
            }
        }
        var cellDatas: [RecentForwardCellData] = []
        for i in 0 ..< min(5, items.count) {
            let option = items[i]
            let item = RecentForwardCellData(item: option)
            item.isMutiple = self.selectionDataSource?.isMultiple ?? false
            if let state = self.selectionDataSource?.state(for: option, from: nil) {
                item.isSelected = state.selected
            }
            item.tapEvent = { [weak self] in
                guard let self = self else { return }
                let indexPath = IndexPath(row: 0, section: 0)
                self.selectionDataSource?.toggle(option: option,
                                                 from: PickerSelectedFromInfo(sender: self, container: self.tableView, indexPath: indexPath, tag: "recent"),
                                           at: i,
                                           event: Homeric.PUBLIC_PICKER_SELECT_CLICK,
                                           target: Homeric.PUBLIC_PICKER_SELECT_VIEW,
                                           scene: self.scene)
            }
            cellDatas.append(item)
        }
        self.recentForwardDatas = cellDatas
        self.recentForwardView?.updateUI(cellDatas: cellDatas)
    }

    // MARK: TableView
    static let headerViewHeight: CGFloat = 26
    static let recentForwardViewHeight: CGFloat = 131
    static let footerViewHeight: CGFloat = 32
    public func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        let count = section.dataSource.count
        if section.canFold, section.shouldFold {
            return min(count, Self.minShowDataCount)
        }
        return count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = self.sections[indexPath.section]
        let model = section.dataSource[indexPath.row]
        let lastRow = section.dataSource.count == indexPath.row + 1
        if let selectionDataSource = self.selectionDataSource,
           let cell = model.reuseCell(in: tableView, resolver: self.userResolver, selectionDataSource: selectionDataSource, isLastRow: lastRow, targetPreview: targetPreview) {
            cell.section = indexPath.section
            cell.row = indexPath.row
            cell.delegate = self
            return cell
        }
        assertionFailure()
        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard let model = model(at: indexPath), let selectionDataSource = self.selectionDataSource else { return }
        selectionDataSource.toggle(option: model,
                                   from: PickerSelectedFromInfo(sender: self, container: tableView, indexPath: indexPath, tag: sections[indexPath.section].tag),
                                   at: tableView.absolutePosition(at: indexPath),
                                   event: Homeric.PUBLIC_PICKER_SELECT_CLICK,
                                   target: Homeric.PUBLIC_PICKER_SELECT_VIEW,
                                   scene: self.scene)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (sections.count == 1 && sections[0].title.isEmpty) || sections[section].dataSource.isEmpty {
            return nil
        }
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody

        let headerLabel = UILabel()
        headerLabel.textColor = UIColor.ud.textCaption
        headerLabel.textAlignment = .left
        headerLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        headerLabel.text = sections[section].title
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(17)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        if section != 0 { headerView.lu.addTopBorder() }

        return headerView
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (sections.count == 1 && sections[section].title.isEmpty) || sections[section].dataSource.isEmpty {
            return .leastNormalMagnitude
        } else {
            return Self.headerViewHeight
        }
    }
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard sections[section].canFold else { return nil }

        let footerView = UIView()
        footerView.backgroundColor = UIColor.ud.bgBody
        let warpperView = UIView()

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        footerView.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.top.left.right.equalToSuperview()
        }

        let footerLabel = UILabel()
        footerLabel.text = sections[section].shouldFold ? BundleI18n.LarkSearchCore.Lark_Legacy_ItemShowMore : BundleI18n.LarkSearchCore.Lark_Legacy_ItemShowLess
        footerLabel.textColor = UIColor.ud.textPlaceholder
        footerLabel.textAlignment = .center
        footerLabel.font = UIFont.systemFont(ofSize: 12)

        warpperView.addSubview(footerLabel)
        footerLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(7)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        let image = sections[section].shouldFold ? Resources.LarkSearchCore.Picker.table_fold : BundleResources.LarkSearchCore.Picker.table_unfold
        let footerImageView = UIImageView(image: image)
        warpperView.addSubview(footerImageView)
        footerImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(12)
            make.centerY.equalTo(footerLabel)
            make.left.equalTo(footerLabel.snp.right).offset(4)
            make.right.equalToSuperview()
        }

        footerView.addSubview(warpperView)
        warpperView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        footerView.tag = section
        footerView.lu.addTapGestureRecognizer(action: #selector(tapFooterView(_:)),
                                              target: self,
                                              touchNumber: 1)
        return footerView
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].canFold {
            return Self.footerViewHeight
        } else {
            return .leastNormalMagnitude
        }
    }
    @objc
    private func tapFooterView(_ sender: UIGestureRecognizer) {
        guard let section = sender.view?.tag, section < sections.count else { return }
        sections[section].shouldFold.toggle()
        tableView.reloadSections(IndexSet(integer: section), with: .none)
    }

    func model(at: IndexPath) -> ForwardItem? {
        if at.section < sections.count, case let section = sections[at.section],
           at.row < section.dataSource.count {
            return section.dataSource[at.row]
        }
        return nil
    }
    // MARK: KeyBinding
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }
    // TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

}

public struct ForwardSectionData {
    let title: String
    var dataSource: [ForwardItem]
    let canFold: Bool
    var shouldFold: Bool // if true, section should appear as fold
    var tag: String // 统计用的section区分字段
}

extension ForwardItem {
    func reuseCell(in tableView: UITableView,
                   resolver: LarkContainer.UserResolver,
                   selectionDataSource: SelectionDataSource,
                   isLastRow: Bool = false,
                   targetPreview: Bool = false,
                   isShowDepartmentTail: Bool = false) -> ForwardChatTableCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ForwardChatTableCell") as? ForwardChatTableCell else { return nil }
        cell.isDepartmentInfoTail = isShowDepartmentTail
        let state = selectionDataSource.state(for: self, from: tableView)
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        let serverNTPTimeService = try? resolver.resolve(assert: ServerNTPTimeService.self)

        cell.personInfoView.bottomSeperator.isHidden = isLastRow
        cell.setContent(resolver: resolver,
                        model: self,
                        currentTenantId: userService?.userTenant.tenantID ?? "",
                        isSelected: state.selected,
                        hideCheckBox: !selectionDataSource.isMultiple,
                        enable: !state.disabled && self.hasInvitePermission,
                        animated: false,
                        checkInDoNotDisturb: serverNTPTimeService?.afterThatServerTime(time:) ?? { _ in false },
                        targetPreview: targetPreview && TargetPreviewUtils.canTargetPreview(forwardItem: self))
        return cell
    }

    func reuseWikiCell(in tableView: UITableView,
                       resolver: UserResolver,
                       selectionDataSource: SelectionDataSource,
                       pickType: UniversalPickerType,
                       isLastRow: Bool = false) -> WikiPickerTableCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "wikiPickerTableCell") as? WikiPickerTableCell else { return nil }

        let state = selectionDataSource.state(for: self, from: tableView)
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        let serverNTPTimeService = try? resolver.resolve(assert: ServerNTPTimeService.self)

        cell.personInfoView.bottomSeperator.isHidden = isLastRow
        cell.setContent(model: self,
                        pickType: pickType,
                        currentTenantId: userService?.userTenant.tenantID ?? "",
                        isSelected: state.selected,
                        hideCheckBox: !selectionDataSource.isMultiple,
                        enable: !state.disabled && self.hasInvitePermission,
                        animated: false,
                        checkInDoNotDisturb: serverNTPTimeService?.afterThatServerTime(time:) ?? { _ in false })
        return cell
    }

    public func reuseChatCell(in tableView: UITableView, resolver: UserResolver, selectionDataSource: SelectionDataSource, isLastRow: Bool = false) -> ChatPickerTableCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatPickerTableCell") as? ChatPickerTableCell else { return nil }
        let state = selectionDataSource.state(for: self, from: tableView)
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        let serverNTPTimeService = try? resolver.resolve(assert: ServerNTPTimeService.self)
        cell.resolver = resolver
        cell.personInfoView.bottomSeperator.isHidden = isLastRow
        cell.setContent(model: self,
                        currentTenantId: userService?.userTenant.tenantID ?? "",
                        isSelected: state.selected,
                        hideCheckBox: !selectionDataSource.isMultiple,
                        enable: !state.disabled && self.hasInvitePermission,
                        animated: false,
                        checkInDoNotDisturb: serverNTPTimeService?.afterThatServerTime(time:) ?? { _ in false })
        return cell
    }

    public func reuseFilterCell(in tableView: UITableView,
                                resolver: UserResolver,
                                selectionDataSource: SelectionDataSource,
                                pickType: UniversalPickerType,
                                isLastRow: Bool = false) -> FilterSelectionCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FilterSelectionCell") as? FilterSelectionCell else { return nil }
        let state = selectionDataSource.state(for: self, from: tableView)
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        cell.setContent(model: self,
                        pickerType: pickType,
                        currentTenantId: userService?.userTenant.tenantID ?? "",
                        hideCheckBox: !selectionDataSource.isMultiple,
                        enabled: !state.disabled,
                        isSelected: state.selected)
        return cell
    }
}

extension DefaultChatView: TargetInfoTapDelegate {
    public func presentPreviewViewController(section: Int?, row: Int?) {
        guard let fromVC = self.fromVC,
              let section = section,
              let row = row,
              section < sections.count,
              row < sections[section].dataSource.count
        else { return }
        let item = sections[section].dataSource[row]
        let chatId = item.chatId ?? ""
        //未开启过会话的单聊，chatID为空时，需传入uid
        let userId = chatId.isEmpty ? item.id : ""
        if !TargetPreviewUtils.canTargetPreview(forwardItem: item) {
            if let window = fromVC.view.window {
                UDToast.showTips(with: BundleI18n.LarkSearchCore.Lark_IM_UnableToPreviewContent_Toast, on: window)
            }
        } else if TargetPreviewUtils.isThreadGroup(forwardItem: item) {
            //话题群
            let threadChatPreviewBody = ThreadPreviewByIDBody(chatID: chatId)
            userResolver.navigator.present(body: threadChatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        } else {
            //会话
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chatId, userId: userId, title: item.name)
            userResolver.navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        }
        SearchTrackUtil.trackPickerSelectClick(scene: self.scene, clickType: .chatDetail(target: "none"))
    }
}
