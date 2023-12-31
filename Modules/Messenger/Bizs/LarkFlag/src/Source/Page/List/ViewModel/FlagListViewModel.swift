//
//  FlagListViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkContainer
import LKCommonsLogging
import LarkCore
import RxRelay
import LarkSDKInterface
import TangramService
import RustPB
import LarkAccountInterface
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkChat
import LarkStorage
import LarkUIKit
import SuiteAppConfig

typealias FlagCursor = Feed_V1_FeedCursor

final class FlagListViewModel: UserResolverWrapper {

    static let logger = Logger.log(FlagListViewModel.self, category: "flag.list.view.model")

    public enum State {
        case `default`
        case loading
        case noMore
    }

    // 数据刷新的类型
    public enum RefreshType {
        // 重新加载数据：简单的reloadData没有动画
        case reload
        // 删除数据：会有删除动画
        case delete
    }

    @ScopedInjectedLazy var chatSecurity: ChatSecurityControlService?

    @ScopedInjectedLazy var passportUserService: PassportUserService?

    public let userResolver: UserResolver

    public let disposeBag: DisposeBag = DisposeBag()

    public var cellViewModelFactory: FlagCellViewModelFactory

    public let dataDependency: FlagDataDependency

    public var datasource = BehaviorRelay<[FlagItem]>(value: [])

    public var state: State = .default

    public var sortingRule: Feed_V1_FlagSortingRule = .default

    public var refreshType: RefreshType = .reload
    // 总的标记数：监听服务端push，同步远端的标记数
    public var totalCount: Int = 0
    // 分页数
    public let countPerPage: Int = 20

    // 是否展示空态
    let showEmptyViewRelay = BehaviorRelay<Bool>(value: true)
    var showEmptyViewObservable: Observable<Bool> {
        return showEmptyViewRelay.asObservable().distinctUntilChanged()
    }
    // 是否展示‘置顶’入口
    var isShortCutOn: Bool {
        return AppConfigManager.shared.feature(for: "feed.shortcut").isOn
    }
    // 是否展示‘标签’入口
    var isLabelOn: Bool {
        return AppConfigManager.shared.feature(for: "label").isOn
    }
    // 本地缓存的已删除flags的辅助信息 [id: updatetime]
    public var removedFlags: [String: Double] = [:]
    // 总数据源容器: 其他地方也会调用，对外接口均内置互斥锁
    public let provider = FlagDataProvider()
    // 分页游标
    private var nextCursor: FlagCursor
    // 数据处理队列
    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "FlagListViewModelDataQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        return queue
    }()
    // 所有耗时的数据操作都放到队列里面
    fileprivate lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()
    // 消息卡片VM Factory
    var flagComponentVMFactory: FlagListMessageViewModelFactory
    var hostUIConfig: LarkMessageBase.HostUIConfig = HostUIConfig(size: .zero, safeAreaInsets: .zero)
    var componentDataSource: [FlagListMessageComponentViewModel] = []

    public init(userResolver: UserResolver,
                cellViewModelFactory: FlagCellViewModelFactory,
                dataDependency: FlagDataDependency,
                context: FlagListMessageContext) {
        self.userResolver = userResolver
        self.cellViewModelFactory = cellViewModelFactory
        self.flagComponentVMFactory = FlagListMessageViewModelFactory(context: context,
                                                                     registery: FlagListMessageSubFactoryRegistery(context: context, defaultFactory: UnknownContentFactory(context: context)))
        self.dataDependency = dataDependency
        // 首次拉取时候的游标
        self.nextCursor = FlagCursor()
        self.nextCursor.rankTime = Int64.max
        self.nextCursor.id = 0
        // 默认是按照标记时间排序
        self.sortingRule = .default
        let sortingRule = KVStores.Flag.global()[KVKeys.Flag.sortingRuleKey]
        // 按照消息的最新时间排序
        if sortingRule == 2 {
            self.sortingRule = .message
        }
        self.flagComponentVMFactory.getCellDependency = { [weak self] in
            return self?.getCellDependency() ?? FlagListMessageCellMetaModelDependencyImpl(
                contentPadding: 0,
                contentPreferMaxWidth: { _ in  0 }
            )
        }
        // 更新排序规则
        self.provider.setFlagSortingRole(self.sortingRule)
        setup()
        context.dataSourceAPI = self
    }

    private func setup() {
        subscribeEventHandlers()
    }

    private func subscribeEventHandlers() {
        // 监听Flag的Push
        self.dataDependency.pushFlagMessage
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (pushFlagMessage) in
                guard let `self` = self else { return }
                self.handleMessageFromPushFlag(pushFlagMessage: pushFlagMessage)
            })
            .disposed(by: self.disposeBag)
        // 监听is24HourTime的Push
        self.dataDependency.is24HourTime.distinctUntilChanged().asObservable()
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.handleIs24HourTime()
            }).disposed(by: disposeBag)
        // 监听Feed的Push
        self.dataDependency.pushFeedMessage
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (pushFeedMessage) in
                guard let `self` = self else { return }
                self.handleFeedFromPushFeed(pushFeedMessage: pushFeedMessage)
                self.handleUnReadCount(pushFeedMessage.filtersInfo)
            })
            .disposed(by: self.disposeBag)
        // 监听FeedFilterSettings的Push
        self.dataDependency.pushFeedFilterMessage
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (pushFeedFilterMessage) in
                guard let `self` = self else { return }
                self.handleFeedFilterMessage(pushFeedFilterMessage: pushFeedFilterMessage)
            })
            .disposed(by: self.disposeBag)
        // 监听InlinePreview的Push
        self.dataDependency.inlinePreviewVM.subscribePush { [weak self] push in
            self?.dataQueue.addOperation { [weak self] in
                guard let self = self else { return }
                self.handleMessageFromInlinePreviewPush(urlPreview: push)
            }
        }
        // 监听Cell选中的通知，iPad分屏需要选中状态
        self.dataDependency.observeSelect()
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] flagId in
                guard let self = self else { return }
                self.provider.resetSelectedState(flagId)
                self.updateFlags(flags: [])
            }).disposed(by: disposeBag)

        self.dataDependency.refreshObserver
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] in
                self?.fireFlagsRefresh(changedUniqueIds: [], refreshType: .reload)
            }).disposed(by: disposeBag)
    }

    // 挂起队列
    public func frozenDataQueue() {
        dataQueue.isSuspended = true
    }
    // 恢复队列
    public func resumeDataQueue() {
        dataQueue.isSuspended = false
    }

    // 重置分页游标
    public func resetCursor() {
        self.nextCursor.rankTime = Int64.max
        self.nextCursor.id = 0
        self.state = .default
    }

    @discardableResult
    func loadMore() -> Bool {
        if self.state != .default {
            FlagListViewModel.logger.error("LarkFlag: [LoadMore] get flags returned, state = \(self.state)")
            return false
        }
        self.state = .loading
        FlagListViewModel.logger.info("LarkFlag: [LoadMore] cursor = \(self.nextCursor.rankTime), sortingRule = \(self.sortingRule)")
        // 向RustSDK请求标记列表
        self.dataDependency.flagAPI?.getFlags(cursor: self.nextCursor, count: self.countPerPage, sortingRule: self.sortingRule)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                self.nextCursor = result.nextCursor
                if self.nextCursor.rankTime == 0, self.nextCursor.id == 0 {
                    // 如果rankTime和id都为0表示列表已经拉取完毕
                    self.state = .noMore
                } else {
                    // 还有没有拉完的数据下次滚动的时候继续触发数据拉取
                    self.state = .default
                }
                let updateIds = self.getFlagIdsBy(flags: result.flags)
                FlagListViewModel.logger.info("LarkFlag: [GetFlags] updateIds = \(updateIds), cursor.rankTime = \(result.nextCursor.rankTime), cursor.id = \(result.nextCursor.id)")
                let feedCards = result.flagFeeds.feedCards.map { feedEntityPreview in
                    feedEntityPreview.feedID
                }
                FlagListViewModel.logger.info("LarkFlag: [GetFlags] feedCards = \(feedCards)")
                var messages: [String] = []
                for (key, value) in result.flagMessages.entity.messages {
                    messages.append(key)
                }
                FlagListViewModel.logger.info("LarkFlag: [GetFlags] messages = \(messages)")
                self.updateFlags(flags: result.flags, flagFeeds: result.flagFeeds, flagMessages: result.flagMessages)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.state = .default
                FlagListViewModel.logger.error("LarkFlag: [GetFlags] Failed!!!", error: error)
            }).disposed(by: self.disposeBag)
        return true
    }

    func onResize() {
        componentDataSource.forEach({
            $0.onResize()
        })
    }

    func getCellDependency() -> FlagListMessageCellMetaModelDependencyImpl {
        return FlagListMessageCellMetaModelDependencyImpl(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] _ in
                guard let self = self else { return 0 }
                return self.hostUIConfig.size.width - 76 - 18
            }
        )
    }
}

extension FlagListViewModel: HasAssets {

    public func isMeSend(_ id: String) -> Bool {
        return self.userResolver.userID == id
    }

    public var messages: [Message] {
        return self.datasource.value.filter { flagItem in
            return flagItem.type == .message
        }.compactMap { flagItem in
            return flagItem.message
        }
    }

    public func checkPreviewPermission(message: Message) -> PermissionDisplayState {
        return self.chatSecurity?.checkPreviewAndReceiveAuthority(chat: nil, message: message) ?? .receiveLoading
    }
}

extension FlagListViewModel: DataSourceAPI {

    // 没有使用
    public func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>
    (_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.componentDataSource
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    public var scene: LarkMessageBase.ContextScene {
        return .pin
    }

    public func pauseDataQueue(_ pause: Bool) {
    }

    public func reloadTable() {
    }

    public func reloadRow(by messageId: String, animation: UITableView.RowAnimation) {
    }

    public func reloadRows(by messageIds: [String], doUpdate: @escaping (LarkModel.Message) -> LarkModel.Message?) {
    }

    public func deleteRow(by messageId: String) {
    }

    public func processMessageSelectedEnable(message: LarkModel.Message) -> Bool {
        return false
    }

    public func currentTopNotice() -> RxSwift.BehaviorSubject<LarkModel.ChatTopNotice?>? {
        return nil
    }

    public var traitCollection: UITraitCollection? {
        return nil
    }
}
