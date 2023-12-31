//
//  PinListViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/16.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkMessageCore
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkSDKInterface
import AppReciableSDK
import LarkZoomable
import RustPB
import LarkSearchFilter
import TangramService

enum PinListStatus: Equatable {
    case all
    case search
}

enum PinListTableRefreshType: OuputTaskTypeInfo {
    case refreshTable(hasMore: Bool?, scrollTo: IndexPath?)
    case searching
    case loadMoreFail
    case searchFail
    func canMerge(type: PinListTableRefreshType) -> Bool {
        return false
    }
    func duration() -> Double {
        return 0
    }
    func isBarrier() -> Bool {
        return false
    }
}

private struct PinListSearchInfo {
    var text: String
    var filters: [SearchFilter]
    var offset: Int32
    var hasMore: Bool
    var moreToken: Any?
}

enum PinListInitState {
    case startInit
    case initFinish
    case none
}

final class PinListViewModel {
    var pinUIDataSource: [PinCellViewModel] = []
    var searchUIDataSource: [SearchPinListCellViewModel] = []
    public lazy var tableRefreshDriver: Driver<PinListTableRefreshType> = self.transRefreshPublish()
    public var initStateDriver: Driver<PinListInitState> {
        return initStateSubject.asDriver()
    }
    //pin列表初始数据二次回调回来前，不可以上拉加载更多
    public var getPinsLoadMoreEnableDriver: Driver<Bool> {
        return getPinsLoadMoreEnable.asDriver()
    }
    public var pinSettingDriver: Driver<PinSetting> {
        return pinSetting.asDriver()
    }
    public var subscribeSetting: RustPB.Settings_V1_PinSubscribeSetting {
        return pinSetting.value.subscribeSetting
    }
    private lazy var pinSetting: BehaviorRelay<PinSetting> = {
        var subscribeSetting = RustPB.Settings_V1_PinSubscribeSetting()
        subscribeSetting.isSubscribedPin = true
        subscribeSetting.notifyTimeHour = 20
        let setting = PinSetting(subscribeSetting: subscribeSetting)
        return BehaviorRelay<PinSetting>(value: setting)
    }()
    private(set) var getPinsLoadMoreEnable = BehaviorRelay<Bool>(value: false)
    private static let logger = Logger.log(PinListViewModel.self, category: "pin.newList.view.model")
    private var initStateSubject: BehaviorRelay<PinListInitState> = BehaviorRelay(value: .none)
    let dependency: PinListViewModelDependency
    private var pins: [PinCellViewModel] = []
    private var searchPins: [SearchPinListCellViewModel] = []
    private(set) var hadReadDic: [String: TimeInterval] = [:]
    private let requestCount: Int32 = 20
    private var timeCursor: Int64 = 0
    private var lastReadTime: Int64 = 0
    private var hasMorePins: Bool = false
    private var queueManager: QueueManager<PinListTableRefreshType> = QueueManager<PinListTableRefreshType>()
    private var tableRefreshPublish = PublishSubject<(PinListTableRefreshType, newDatas: [Any]?, state: PinListStatus)>()
    private let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()
    private var searchInfo: PinListSearchInfo?
    private(set) var status: PinListStatus = .all
    private var vmFactory: PinCellViewModelFactory
    private var cellConfig: PinCellConfig
    private var loadingMorePins: Bool = false
    private var cacheKey: String {
        return "pinList_\(chat.id)"
    }
    let chat: Chat
    private var messageIds: [String] {
        return self.pins.compactMap { (cellVM) -> String? in
            return (cellVM as? PinMessageCellViewModel)?.message.id
        }
    }
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    private var enterCostInfo: EnterPinCostInfo?

    init(chat: Chat, context: PinContext, dependency: PinListViewModelDependency, enterCostInfo: EnterPinCostInfo) {
        self.dependency = dependency
        self.chat = chat
        self.vmFactory = PinCellViewModelFactory(
            context: context,
            registery: PinMessageSubFactoryRegistery(
                context: context, defaultFactory: UnknownContentFactory(context: context)
            ),
            cellLifeCycleObseverRegister: PinCellLifeCycleObseverRegister()
        )
        self.cellConfig = PinCellConfig(showFromChat: false)
        self.enterCostInfo = enterCostInfo
    }

    func observePush() {
        self.dependency.deletePinPush
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messageId) in
                PinListViewModel.logger.info("reveive delete pin push", additionalData: ["messageId": messageId])
                if self?.removePins(messageIds: [messageId]) ?? false {
                    self?.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil), newDatas: self?.pins, state: .all)
                }
            }).disposed(by: self.disposeBag)

        self.dependency.is24HourTime
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (_) in
                self?.pins.forEach({ (cellVM) in
                    cellVM.calculateRenderer()
                })
                self?.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil), newDatas: self?.pins, state: .all)
            }).disposed(by: self.disposeBag)

        let chatId = chat.id
        // 当在列表中时 直接取消红点
        self.dependency.pinReadStatus
            .filter({ (status) -> Bool in
                return status.chatId == chatId && !status.hasRead
            }).flatMap({ [weak self] (_) -> Observable<Void> in
                PinListViewModel.logger.info("update pin read status when receive push", additionalData: ["chatId": chatId])
                return self?.dependency.pinAPI
                .updatePinReadStatus(chatId: chatId) ?? .empty()
            })
            .subscribe().disposed(by: self.disposeBag)
        self.dependency.messagePush
            .filter({ (message) -> Bool in
                return message.channel.id == chatId
            })
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (message) in
                guard let self = self else { return }
                PinListViewModel.logger.info("reveive channel message push",
                                                additionalData: ["messageId": message.id,
                                                                 "isPin": "\(message.pinChatter != nil)"])
                let isPin = (message.pinChatter != nil)
                // delete pined message.
                if (!isPin || message.isRecalled || message.isDeleted) && self.messageIds.contains(message.id) {
                    PinListViewModel.logger.info("delete pin", additionalData: ["messageId": message.id])
                    if self.removePins(messageIds: [message.id]) {
                        self.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil), newDatas: self.pins, state: .all)
                    }
                    return
                }
                // add new pin message.
                if isPin, !self.messageIds.contains(message.id), self.insert(message: message) {
                    self.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil), newDatas: self.pins, state: .all)
                }
                self.dependency.urlPreviewService.fetchMissingURLPreviews(messages: [message])
            }).disposed(by: self.disposeBag)
        self.dependency.inlinePreviewVM.subscribePush { [weak self] push in
            self?.queueManager.addDataProcess { [weak self] in
                guard let self = self else { return }
                if self.updateInlines(push: push) {
                    self.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil), newDatas: self.pins, state: .all)
                }
            }
        }
    }

    func fetchInitPins() {
        self.initStateSubject.accept(.startInit)
        let start = CACurrentMediaTime()
        var localFetchFail = false
        self.dependency.pinAPI
            .getPinListV2(chatId: self.chat.id, isFromServer: false, timestampCursor: 0, count: requestCount)
            .catchError { [weak self] error -> Observable<GetPinListResultV2> in
                guard let self = self else { return .empty() }
                localFetchFail = true
                Self.logger.error("fetchInitPins from local fail", additionalData: ["chatId": self.chat.id], error: error)
                return self.dependency.pinAPI.getPinListV2(chatId: self.chat.id, isFromServer: true, timestampCursor: 0, count: self.requestCount)
            }
            .observeOn(queueManager.dataScheduler)
            .flatMap({ [weak self] result -> Observable<GetPinListResultV2> in
                guard let self = self else { return .empty() }
                if localFetchFail {
                    //得到的就是catchError中转换的远端结果，直接抛出去
                    PinListViewModel.logger.info("fetchInitPins from server by catch local error", additionalData: ["chatId": self.chat.id])
                    return .just(result)
                } else {
                    PinListViewModel.logger.info("fetchInitPins from local", additionalData: ["chatId": self.chat.id])
                    //先处理本地结果
                    self.handleInitPins(result: result, start: start)
                    //再调用远端结果
                    return self.dependency.pinAPI.getPinListV2(chatId: self.chat.id, isFromServer: true, timestampCursor: 0, count: self.requestCount)
                }
            })
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                self?.handleInitPins(result: result, start: start)
            }, onError: { [weak self] (error) in
                PinListViewModel.logger.error("fetchInitPins from server fail", additionalData: ["chatId": self?.chat.id ?? ""], error: error)
                self?.initStateSubject.accept(.initFinish)
                if let enterCostInfo = self?.enterCostInfo {
                    let apiError = error.underlyingError as? APIError
                    AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                    scene: .Pin,
                                                                    event: .enterPin,
                                                                    errorType: .SDK,
                                                                    errorLevel: .Fatal,
                                                                    errorCode: Int(apiError?.code ?? -1),
                                                                    userAction: nil,
                                                                    page: PinListViewController.pageName,
                                                                    errorMessage: nil,
                                                                    extra: Extra(isNeedNet: true,
                                                                                 latencyDetail: [:],
                                                                                 metric: enterCostInfo.reciableMetric,
                                                                                 category: enterCostInfo.reciableCategory)))
                    self?.enterCostInfo = nil
                }
            }, onCompleted: { [weak self] in
                self?.getPinsLoadMoreEnable.accept(true)
                self?.observePush()
            }).disposed(by: self.disposeBag)
    }

    private func handleInitPins(result: GetPinListResultV2, start: CFTimeInterval) {
        self.enterCostInfo?.sdkCost = Int((CACurrentMediaTime() - start) * 1000)
        self.handleFetchedPins(result: result)
        self.publish(refreshType: .refreshTable(hasMore: self.hasMorePins, scrollTo: nil),
                     newDatas: self.pins,
                     state: .all)
        self.initStateSubject.accept(.initFinish)
        if let enterCostInfo = self.enterCostInfo {
            enterCostInfo.end = CACurrentMediaTime()
            AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                  scene: .Pin,
                                                                  event: .enterPin,
                                                                  cost: enterCostInfo.cost,
                                                                  page: PinListViewController.pageName,
                                                                  extra: Extra(isNeedNet: true,
                                                                               latencyDetail: enterCostInfo.reciableLatencyDetail,
                                                                               metric: enterCostInfo.reciableMetric,
                                                                               category: enterCostInfo.reciableCategory)))
            self.enterCostInfo = nil
        }
    }

    func searchPin(text: String, filters: [SearchFilter]) {
        //取消对上次搜索的监听
        self.searchDisposeBag = DisposeBag()
        self.searchInfo = PinListSearchInfo(text: text, filters: filters, offset: 0, hasMore: false)
        //退出搜索
        if text.isEmpty {
            self.status = .all
            queueManager.addDataProcess {
                self.publish(refreshType: .refreshTable(hasMore: self.hasMorePins, scrollTo: nil),
                             newDatas: self.pins,
                             state: .all)
            }
            return
        }
        self.status = .search
        self.publish(refreshType: .searching, state: .search)
        self.dependency.searchAPI
            .universalSearch(query: text,
                             scene: .rustScene(.searchPinMsgScene),
                             begin: 0,
                             end: requestCount,
                             moreToken: nil,
                             chatID: chat.id,
                             needSearchOuterTenant: true,
                             authPermissions: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.searchPins = response.results.map({ return SearchPinListCellViewModel(navigator: self.vmFactory.context.navigator, result: $0) })
                self.searchInfo = PinListSearchInfo(text: text, filters: filters, offset: Int32(response.results.count), hasMore: response.hasMore, moreToken: response.moreToken)
                self.publish(refreshType: .refreshTable(hasMore: response.hasMore, scrollTo: nil),
                             newDatas: self.searchPins,
                             state: .search)
            }, onError: { [weak self] (error) in
                PinListViewModel.logger.error("Pin搜索失败, rust返回结果异常", error: error)
                self?.publish(refreshType: .searchFail, state: .search)
            })
            .disposed(by: self.searchDisposeBag)
    }

    func loadMorePins(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
        switch self.status {
        case .all:
            self.loadMoreAllPins(finish: finish)
        case .search:
            self.loadMoreSearchPins()
        }
    }

    func loadSearchCache() -> Observable<(String, [SearchFilter])?> {
        return self.dependency.searchCache
            .getCacheData(key: cacheKey)
            .map { [weak self] (cacheData) -> (String, [SearchFilter])? in
                guard let self = self, let cacheData = cacheData, !cacheData.results.isEmpty else {
                    return nil
                }
                self.searchPins = cacheData.results.map { SearchPinListCellViewModel(navigator: self.vmFactory.context.navigator, result: $0) }
                self.status = .search
                self.searchInfo = PinListSearchInfo(text: cacheData.quary, filters: cacheData.filters, offset: 0, hasMore: false)
                let lastVisitIndex = cacheData.lastVisitIndex
                self.publish(refreshType: .refreshTable(hasMore: false, scrollTo: lastVisitIndex),
                             newDatas: self.searchPins,
                             state: .search)
                return (cacheData.quary, cacheData.filters)
            }
    }

    func saveSearchCache(visitedIndex: IndexPath) {
        guard let searchInfo = self.searchInfo else { return }
        self.dependency.searchCache
            .set(key: cacheKey,
                 quary: searchInfo.text,
                 filers: searchInfo.filters,
                 results: self.searchUIDataSource.map({ return $0.result }),
                 visitIndex: visitedIndex, showRequestColdTip: nil)
    }

    func onResize() {
        switch status {
        case .all:
            self.queueManager.addDataProcess { [weak self] in
                for cellVM in self?.pins ?? [] {
                    cellVM.onResize()
                }
                self?.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil),
                             newDatas: self?.pins ?? [],
                             state: .all)
            }
        case .search:
            break
        }
    }

    func needShowHighlight(source: PinMessageCellViewModel) -> Bool {
        //自己pin的不高亮
        if source.message.pinChatter?.id == self.dependency.currentChatterId {
            return false
        }
        if source.message.pinTimestamp < self.lastReadTime {
            return false
        }
        if self.hadReadDic[source.message.id] != nil {
            return false
        }
        self.hadReadDic[source.message.id] = CACurrentMediaTime()
        return true
    }

    func resetShowHighlightIfNeeded(source: PinMessageCellViewModel) {
        if source.message.pinTimestamp < self.lastReadTime {
            return
        }
        // 如果 cell 出现消失间隔小于 0.2s, 则判断为未出现在屏幕中
        if let time = self.hadReadDic[source.message.id], CACurrentMediaTime() - time < 0.2 {
            self.hadReadDic[source.message.id] = nil
        }
    }

    func pauseQueue() {
        self.queueManager.pauseQueue()
    }

    func resumeQueue() {
        self.queueManager.resumeQueue()
    }

    private func loadMoreAllPins(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
        guard !loadingMorePins else {
            finish?(.noWork)
            return
        }
        loadingMorePins = true
        self.dependency.pinAPI
            .getPinListV2(chatId: self.chat.id, isFromServer: true, timestampCursor: self.timeCursor, count: requestCount)
            .catchError({ [weak self] error -> Observable<GetPinListResultV2> in
                guard let self = self else { return .empty() }
                Self.logger.error("loadMoreAllPins from server fail \(self.chat.id)", error: error)
                return self.dependency.pinAPI.getPinListV2(chatId: self.chat.id,
                                                           isFromServer: false,
                                                           timestampCursor: self.timeCursor,
                                                           count: self.requestCount)
            })
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.timeCursor = result.pins.last?.message.pinTimestamp ?? 0
                self.removeDuplicate(newPins: result.pins)
                let newPins = self.transform(pins: result.pins)
                self.pins.append(contentsOf: newPins)
                self.hasMorePins = result.hasMore
                self.publish(refreshType: .refreshTable(hasMore: self.hasMorePins, scrollTo: nil),
                             newDatas: self.pins,
                             state: .all)
                self.loadingMorePins = false
                finish?(.success(sdkCost: Int64(result.sdkCost * 1000), valid: true))
            }, onError: { [weak self] (error) in
                PinListViewModel.logger.error("loadMoreAllPins fail \(self?.chat.id ?? "")", error: error)
                self?.publish(refreshType: .loadMoreFail, state: .all)
                self?.loadingMorePins = false
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }

    private func loadMoreSearchPins() {
        guard let searchInfo = self.searchInfo else { return }
        dependency.searchAPI
            .universalSearch(query: searchInfo.text,
                             scene: .rustScene(.searchPinMsgScene),
                             begin: searchInfo.offset,
                             end: searchInfo.offset + requestCount,
                             moreToken: searchInfo.moreToken,
                             chatID: chat.id,
                             needSearchOuterTenant: true,
                             authPermissions: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                self.searchPins.append(contentsOf: response.results.map({ return SearchPinListCellViewModel(navigator: self.vmFactory.context.navigator, result: $0) }))
                self.searchInfo?.offset += Int32(response.results.count)
                self.searchInfo?.hasMore = response.hasMore
                self.searchInfo?.moreToken = response.moreToken
                self.publish(refreshType: .refreshTable(hasMore: response.hasMore, scrollTo: nil),
                             newDatas: self.searchPins,
                             state: .search)
            }, onError: { [weak self] (error) in
                PinListViewModel.logger.error("Pin加载更多搜索结果失败", error: error)
                self?.publish(refreshType: .loadMoreFail, state: .search)
            })
            .disposed(by: self.searchDisposeBag)
    }

    private func removeDuplicate(newPins: [PinModel]) {
        let newMessageIds = newPins.map { (pinModel) -> String in
            return pinModel.message.id
        }
        let originMessaageIds = self.messageIds
        let needDeleteMessageIds = newMessageIds.filter { (id) -> Bool in
            return originMessaageIds.contains(id)
        }
        if !needDeleteMessageIds.isEmpty {
            PinListViewModel.logger.info("pin list need delete", additionalData: ["messageIds": "\(needDeleteMessageIds)"])
            self.removePins(messageIds: needDeleteMessageIds)
        }
    }

    private func insert(message: Message) -> Bool {
        var insertPinMessage: Bool = true
        if let first = self.pins.first as? PinMessageCellViewModel,
            message.pinTimestamp < first.message.pinTimestamp {
            insertPinMessage = false
        }
        if insertPinMessage {
            PinListViewModel.logger.info("add pin", additionalData: ["messageId": "\(message.id)"])
            let metaModel = PinMetaModel(message: message, chat: chat)
            let cellVM = self.vmFactory.create(with: metaModel,
                                               metaModelDependency: self.getCellDependency())
            self.pins.insert(cellVM, at: 0)
        }
        return insertPinMessage
    }

    private func handleFetchedPins(result: GetPinListResultV2) {
        var messageIdToCellVM: [String: PinMessageCellViewModel] = [:]
        self.pins.forEach { cellVM in
            if let messageVM = cellVM as? PinMessageCellViewModel {
                messageIdToCellVM[messageVM.message.id] = messageVM
            }
        }

        var newPins: [PinCellViewModel] = []
        result.pins.forEach { pinModel in
            guard self.shouldShowPin(pinModel) else {
                return
            }
            if let cellVM = messageIdToCellVM[pinModel.message.id] {
                newPins.append(cellVM)
                cellVM.update(metaModel: PinMetaModel(message: pinModel.message, chat: pinModel.chat),
                              metaModelDependency: self.getCellDependency())
            } else {
                newPins.append(contentsOf: self.transform(pins: [pinModel]))
            }
        }
        self.pins = newPins

        self.hasMorePins = result.hasMore
        self.timeCursor = result.pins.last?.message.pinTimestamp ?? 0
        if self.lastReadTime == 0 {
            self.lastReadTime = result.lastReadTime
        }
    }

    private func shouldShowPin(_ pin: PinModel) -> Bool {
        if pin.message.isDeleted || pin.message.isRecalled {
            return false
        }
        return true
    }

    private func transform(pins: [PinModel]) -> [PinCellViewModel] {
        return pins.filter({ (pinModel) -> Bool in
            return self.shouldShowPin(pinModel)
        }).map { (pinModel) -> PinCellViewModel in
            let metaModel = PinMetaModel(message: pinModel.message, chat: pinModel.chat)
            let cellVM = self.vmFactory.create(with: metaModel,
                                               metaModelDependency: self.getCellDependency())
            return cellVM
        }
    }

    private func transRefreshPublish() -> Driver<PinListTableRefreshType> {
        return tableRefreshPublish
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (refreshType, datas, state) -> Observable<PinListTableRefreshType> in
                return Observable.create({ [weak self] (obsever) -> Disposable in
                    self?.queueManager.addOutput(type: refreshType, task: { [weak self] in
                        guard let self = self else { return }
                        switch (state, self.status) {
                        //只有状态一致时，数据才被发射，否则丢弃
                        case (.all, .all):
                            if let datas = datas, let pins = datas as? [PinCellViewModel] {
                                self.pinUIDataSource = pins
                            }
                            obsever.onNext(refreshType)
                        case (.search, .search):
                            if let datas = datas, let searchPins = datas as? [SearchPinListCellViewModel] {
                                self.searchUIDataSource = searchPins
                            }
                            obsever.onNext(refreshType)
                        default:
                            break
                        }
                    })
                    return Disposables.create()
                })
            }.asDriver(onErrorRecover: { _ in Driver<(PinListTableRefreshType)>.empty() })
    }

    @discardableResult
    private func removePins(messageIds: [String]) -> Bool {
        var hasRemove = false
        messageIds.forEach { (messageId) in
            if let index = self.pins.firstIndex(where: { (cellVM) -> Bool in
                return (cellVM as? PinMessageCellViewModel)?.message.id == messageId
            }) {
                self.pins.remove(at: index)
                hasRemove = true
            }
        }
        return hasRemove
    }

    @discardableResult
    private func updatePins(messageIds: [String], doUpdate: (Message) -> Message?) -> Bool {
        var hasUpdate = false
        var messageIdsForLog: String = ""
        self.pins.forEach { cellVM in
            if let messageCellVM = (cellVM as? PinMessageCellViewModel),
               messageIds.contains(messageCellVM.message.id),
               let newMessage = doUpdate(messageCellVM.message) {
                messageCellVM.update(metaModel: PinMetaModel(message: newMessage, chat: messageCellVM.chat))
                hasUpdate = true
                messageIdsForLog += " \(messageCellVM.message.id)"
            }
        }
        Self.logger.info("updatePins: \(messageIdsForLog)")
        return hasUpdate
    }

    private func updateInlines(push: URLPreviewPush) -> Bool {
        let messageIds = push.inlinePreviewEntityPair.inlinePreviewEntities.keys
        guard !messageIds.isEmpty else { return false }
        var updatedSourceIDs = [String]()
        let needUpdate = updatePins(messageIds: Array(messageIds), doUpdate: { [weak self] message in
            guard let self = self else { return nil }
            updatedSourceIDs.append(message.id)
            if let body = self.dependency.inlinePreviewVM.getInlinePreviewBody(message: message, pair: push.inlinePreviewEntityPair) {
                let needUpate = self.dependency.inlinePreviewVM.update(message: message, body: body)
                return needUpate ? message : nil
            }
            return nil
        })
        // 只有SDK推送的数据才需要判断是否重新拉取；当updatedSourceIDs为空，表示当前没有使用到
        // 有时候长文类预览后端生成比较慢，forceServer拉取时可能拉不到，后续后端会给Push，重新触发拉取（needLoadIDs标识）
        if push.type == .sdk, !updatedSourceIDs.isEmpty, !push.needLoadIDs.isEmpty {
            var needLoadIDs = [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]()
            updatedSourceIDs.forEach { needLoadIDs[$0] = push.needLoadIDs[$0] }
            self.dependency.urlPreviewService.fetchNeedReloadURLPreviews(needLoadIDs: needLoadIDs)
        }
        return needUpdate
    }

    private func publish(refreshType: PinListTableRefreshType, newDatas: [Any]? = nil, state: PinListStatus) {
        self.tableRefreshPublish.onNext((refreshType, newDatas: newDatas, state: state))
    }

    private func getCellDependency() -> PinCellMetaModelDependencyImp {
        return PinCellMetaModelDependencyImp(
            contentPadding: 16,
            contentPreferMaxWidth: { [weak self] _ in
                guard let self = self else { return 0 }
                return self.hostUIConfig.size.width - 16 - 16
            },
            config: self.cellConfig
        )
    }
}

extension PinListViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
    }

    var scene: ContextScene {
        return .pin
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>
        (_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.pinUIDataSource
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    func pauseDataQueue(_ pause: Bool) {
        if pause {
            self.queueManager.pauseQueue()
        } else {
            self.queueManager.resumeQueue()
        }
    }

    func reloadTable() {
        self.queueManager.addDataProcess { [weak self] in
            self?.publish(refreshType: .refreshTable(hasMore: nil, scrollTo: nil), newDatas: self?.pins, state: .all)
        }
    }

    func reloadRow(by messageId: String, animation: UITableView.RowAnimation) {
    }

    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {
    }

    func deleteRow(by messageId: String) {
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
