//
//  ChatNewPinCardListViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/23.
//

import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkModel
import LKCommonsLogging
import LarkMessageCore
import LarkSDKInterface
import RustPB
import ByteWebImage
import UniverseDesignActionPanel
import UniverseDesignToast
import UniverseDesignIcon
import EENavigator
import LarkMessengerInterface
import LarkCore
import LarkSetting
import LarkGuide

enum ChatPinCardsRefreshType: OuputTaskTypeInfo {
    case refreshTable(hasMore: Bool?)
    case pinsUpdate(indexPaths: [IndexPath])
    case scrollToTop

    func canMerge(type: ChatPinCardsRefreshType) -> Bool {
        return false
    }

    func duration() -> Double {
        return 0
    }

    func isBarrier() -> Bool {
        return false
    }

    var describ: String {
        switch self {
        case .refreshTable(let hasMore):
            return "refreshTable hasMore: \(String(describing: hasMore))"
        case .pinsUpdate(let indexPaths):
            return "pinsUpdate \(indexPaths)"
        case .scrollToTop:
            return "scrollToTop"
        }
    }
}

final class ChatNewPinCardListViewModel: AsyncDataProcessViewModel<ChatPinCardsRefreshType, [[ChatPinCardContainerCellAbility]]>, UserResolverWrapper,
                                         ChatOpenPinCardService, CommonScrollViewLoadMoreDelegate {
    var userResolver: UserResolver
    private let logger = Logger.log(ChatNewPinCardListViewModel.self, category: "Module.IM.ChatPin")

    lazy var pinPermissionBehaviorRelay: BehaviorRelay<ChatPinPermissionConfig.PermissionResult> = BehaviorRelay<ChatPinPermissionConfig.PermissionResult>(value: .success)
    var getPinsLoadMoreEnable = BehaviorRelay<Bool>(value: false)
    // pin 列表初始数据在服务端结果返回前，不可以上拉加载更多
    var getPinsLoadMoreEnableDriver: Driver<Bool> {
        return getPinsLoadMoreEnable.asDriver()
    }
    var availableMaxWidth: CGFloat = 0
    var chat: Chat {
        return self.chatBehaviorRelay.value
    }
    weak var targetVC: UIViewController?
    private let onboardingDisplayPublish: PublishSubject<Void>
        = PublishSubject<Void>()
    lazy var onboardingDisplayDriver: Driver<Void> = {
        return onboardingDisplayPublish.asDriver(onErrorJustReturn: ())
    }()

    private let pinAndTopNoticeViewModel: ChatPinAndTopNoticeViewModel
    static let onboardingIndex = 0
    static let topNoticeIndex = 1
    static let oldPinEntryIndex = 2
    static let stickPinCardIndex = 3
    static let unStickPinCardIndex = 4
    private var renderCellViewModels: [[ChatPinCardContainerCellAbility]] = [[], [], [], [], []]

    private let enableOldTip: Bool
    private let module: ChatPinCardModule
    let chatBehaviorRelay: BehaviorRelay<Chat>
    private let chatPushWrapper: ChatPushWrapper
    private var version: Int64?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy var securityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var guideService: NewGuideService?
    private let disposeBag = DisposeBag()
    private var nextPageToken: String = ""
    private var loadingMorePins: Bool = false
    private var userPushCenter: PushNotificationCenter? {
        return try? self.userResolver.userPushCenter
    }
    private let clientLogInfo: String = "\(Date().timeIntervalSince1970)"

    private lazy var topDataSource: ChatPinListDataSource = {
        return self.initDataSource({ $0.topPosition > $1.topPosition })
    }()

    private lazy var unTopDataSource: ChatPinListDataSource = {
        return self.initDataSource({ $0.position > $1.position })
    }()

    private func initDataSource(_ areInIncreasingOrder: @escaping (ChatPin, ChatPin) -> Bool) -> ChatPinListDataSource {
        let chatBehaviorRelay = self.chatBehaviorRelay
        let dataSource = ChatPinListDataSource(
            getChat: { return chatBehaviorRelay.value },
            cellVMTransformer: { [weak self] metaModel in
                guard let self = self else { return nil }
                if let cardVM = self.module.createCellViewModel(metaModel) {
                    let pinId = metaModel.pin.id
                    return ChatPinCardContainerCellViewModel(
                        metaModel: metaModel,
                        cellViewModel: cardVM,
                        getAvailableMaxWidth: { [weak self] in
                            return self?.availableMaxWidth ?? .zero
                        }, getTargetVC: { [weak self] in
                            return self?.targetVC
                        }, refreshHandler: { [weak self] in
                            self?.calculateSizeAndUpateView { pinID, _ in return pinID == pinId }
                        },
                        nav: self.userResolver.navigator,
                        featureGatingService: self.userResolver.fg
                    )
                }
                return nil
            },
            areInIncreasingOrder: areInIncreasingOrder,
            enableOldTip: enableOldTip
        )
        return dataSource
    }

    init(userResolver: UserResolver, module: ChatPinCardModule, chatPushWrapper: ChatPushWrapper, pinAndTopNoticeViewModel: ChatPinAndTopNoticeViewModel) {
        self.userResolver = userResolver
        self.module = module
        self.chatPushWrapper = chatPushWrapper
        self.chatBehaviorRelay = chatPushWrapper.chat
        self.pinAndTopNoticeViewModel = pinAndTopNoticeViewModel
        self.enableOldTip = userResolver.fg.dynamicFeatureGatingValue(with: ChatNewPinConfig.oldPinKey)
        super.init(uiDataSource: [])
    }

    func setup() {
        let metaModel = ChatPinCardMetaModel(chat: self.chatBehaviorRelay.value)
        self.module.handler(model: metaModel)
        self.module.modelDidChange(model: metaModel)
        self.chatBehaviorRelay
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] chat in
                self?.module.modelDidChange(model: ChatPinCardMetaModel(chat: chat))
            }.disposed(by: self.disposeBag)
        self.module.setup()

        self.chatBehaviorRelay
            .observeOn(MainScheduler.instance)
            .map { [weak self] chat -> ChatPinPermissionConfig.PermissionResult in
                guard let self = self else { return .success }
                return ChatPinPermissionConfig.checkPermission(chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg)
            }
            .bind(to: self.pinPermissionBehaviorRelay).disposed(by: disposeBag)

        self.fetchInitPins()

        self.pinAndTopNoticeViewModel.topNoticeBehaviorRelay
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] topNoticeModel in
                guard let self = self else { return }
                if let topNoticeModel = topNoticeModel {
                    self.renderCellViewModels[Self.topNoticeIndex] = [
                        ChatPinCardTopNoticeCellViewModel(
                            topNoticeModel: topNoticeModel,
                            currentChatterId: self.userResolver.userID,
                            fromChat: self.chat,
                            topNoticeService: try? self.userResolver.resolve(assert: ChatTopNoticeService.self),
                            nav: self.userResolver.navigator,
                            delegate: self
                        )
                    ]
                } else {
                    self.renderCellViewModels[Self.topNoticeIndex] = []
                }
                self.publish(refreshType: .refreshTable(hasMore: nil))
            }).disposed(by: self.disposeBag)
        self.pinAndTopNoticeViewModel.showOldPinEntryBehaviorRelay
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] show in
                guard let self = self else { return }
                if show {
                    self.renderCellViewModels[Self.oldPinEntryIndex] = [ChatPinCardOldPinCellViewModel()]
                } else {
                    self.renderCellViewModels[Self.oldPinEntryIndex] = []
                }
                self.publish(refreshType: .refreshTable(hasMore: nil))
            }).disposed(by: self.disposeBag)
        self.pinAndTopNoticeViewModel.startFetchAndObservePush()

        let onboardingKey: String = "im.chat.pin.onboard.card"
        if self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.pin.onboarding") {
            if self.guideService?.checkShouldShowGuide(key: onboardingKey) ?? false {
                IMTracker.Chat.Top.Onboarding.View(self.chat, isFromInfo: false)
                self.queueManager.addDataProcess { [weak self] in
                    guard let self = self else { return }
                    let cellVM = ChatPinOnboardingCellViewModel(
                        closeHandler: { [weak self] in
                            guard let self = self else { return }
                            self.queueManager.addDataProcess { [weak self] in
                                guard let self = self else { return }
                                self.renderCellViewModels[Self.onboardingIndex] = []
                                self.publish(refreshType: .refreshTable(hasMore: nil))
                            }
                            self.guideService?.didShowedGuide(guideKey: onboardingKey)
                            self.onboardingDisplayPublish.onNext(())
                            IMTracker.Chat.Sidebar.Click.closeOnboarding(self.chat)
                        },
                        refreshHandler: { [weak self] in
                            self?.queueManager.addDataProcess { [weak self] in
                                self?.publish(refreshType: .refreshTable(hasMore: nil))
                            }
                        }
                    )
                    self.renderCellViewModels[Self.onboardingIndex] = [cellVM]
                    self.publish(refreshType: .refreshTable(hasMore: nil))
                }
            } else {
                self.onboardingDisplayPublish.onNext(())
            }
        }
    }

    private func fetchInitPins() {
        var localFetchFail = false
        guard let chatId = Int64(self.chat.id) else { return }
        self.chatAPI?.getChatPin(chatId: chatId, count: 20, needPreview: true)
            .catchError { [weak self] error -> Observable<RustPB.Im_V1_GetUniversalChatPinsResponse> in
                guard let self = self else { return .empty() }
                localFetchFail = true
                self.logger.error("chatPinCardTrace get local fail chatId: \(chatId)", error: error)
                return self.chatAPI?.fetchChatPin(chatId: chatId, count: 20, pageToken: nil, needPreview: true, getTopPins: true) ?? .empty()
            }
            .observeOn(queueManager.dataScheduler)
            .flatMap { [weak self] result -> Observable<RustPB.Im_V1_GetUniversalChatPinsResponse> in
                guard let self = self else { return .empty() }
                if localFetchFail {
                    /// 本地拉取失败，这里返回的是远端的
                    return .just(result)
                } else if result.isLocalDataNewest {
                    /// 本地已经是最新的，不需要再拉远端
                    self.logger.info("chatPinCardTrace isLocalDataNewest chatId: \(chatId)")
                    return .just(result)
                } else {
                    /// 新处理本地数据，再拉远端
                    self.handleInitPins(response: result)
                    return self.chatAPI?.fetchChatPin(chatId: chatId, count: 20, pageToken: nil, needPreview: true, getTopPins: true) ?? .empty()
                }
            }
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                self?.handleInitPins(response: result)
            }, onError: { [weak self] error in
                self?.logger.error("chatPinCardTrace fetch pins from server fail", error: error)
            }, onCompleted: { [weak self] in
                self?.getPinsLoadMoreEnable.accept(true)
                self?.observePinPush()
            }).disposed(by: self.disposeBag)

    }

    private func observePinPush() {
        /// 监听 Pin 增量 Push
        guard let chatId = Int64(self.chat.id) else { return }
        self.userPushCenter?.observable(for: PushUniversalChatPinOperation.self)
            .filter { $0.push.chatID == chatId }
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let pinsPush = push.push
                let newVersion = pinsPush.meta.version
                self.logger.info("chatPinCardTrace handle operation push chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1) type: \(pinsPush.type)")
                guard self.checkNeedUpdate(newVersion) else { return }

                switch pinsPush.type {
                case .add:
                    self.mergePins(pinPbs: pinsPush.addedPins, pinsExtras: pinsPush.getPinsExtras())
                case .update:
                    self.mergePins(pinPbs: pinsPush.updatedPins, pinsExtras: pinsPush.getPinsExtras())
                case .delete:
                    if self.removePins(pinsPush.deletedPinIds) {
                        self.publish(refreshType: .refreshTable(hasMore: nil))
                    }
                case .stick:
                    let addTopPins = self.transform(pins: pinsPush.stickOperation.addTopPins, pinsExtras: pinsPush.getPinsExtras())
                    let removeTopPins = self.transform(pins: pinsPush.stickOperation.removeTopPins, pinsExtras: pinsPush.getPinsExtras())
                    var update: Bool = false
                    if self.transferPins(from: self.unTopDataSource, to: self.topDataSource, pins: addTopPins) {
                        update = true
                    }
                    if self.transferPins(from: self.topDataSource, to: self.unTopDataSource, pins: removeTopPins) {
                        update = true
                    }
                    if update {
                        self.publish(refreshType: .refreshTable(hasMore: nil))
                    }
                case .unstick:
                    let unstickPins = self.transform(pins: pinsPush.unstickPins, pinsExtras: pinsPush.getPinsExtras())
                    if self.transferPins(from: self.topDataSource, to: self.unTopDataSource, pins: unstickPins) {
                        self.publish(refreshType: .refreshTable(hasMore: nil))
                    }
                case .reorderV2:
                    var pinIDToPosDic: [Int64: Int64] = [:]
                    pinsPush.reorderV2Operation.reorderedChatPinPositionInfos.forEach {
                        pinIDToPosDic[$0.pinID] = $0.position
                    }
                    var update: Bool = false
                    if pinsPush.reorderV2Operation.hasReorderedPin {
                        let reorderedPins = self.transform(pins: [pinsPush.reorderV2Operation.reorderedPin], pinsExtras: pinsPush.getPinsExtras())
                        if self.unTopDataSource.merge(pins: reorderedPins) {
                            self.handleStickAndOldTip()
                            update = true
                        }
                    }
                    if self.unTopDataSource.update(doUpdate: { pinModel in
                        if let newPosition = pinIDToPosDic[pinModel.id] {
                            pinModel.position = newPosition
                            return pinModel
                        }
                        return nil
                    }) {
                        update = true
                    }

                    if update {
                        self.publish(refreshType: .refreshTable(hasMore: nil))
                    }
                case .reorderTop:
                    var pinIDToPosDic: [Int64: Int64] = [:]
                    pinsPush.reorderTopOperation.topChatPinPositionInfos.forEach {
                        pinIDToPosDic[$0.pinID] = $0.position
                    }
                    var update: Bool = false
                    if pinsPush.reorderTopOperation.hasReorderedPin {
                        let reorderedPins = self.transform(pins: [pinsPush.reorderTopOperation.reorderedPin], pinsExtras: pinsPush.getPinsExtras())
                        if self.topDataSource.merge(pins: reorderedPins) {
                            self.handleStickAndOldTip()
                            update = true
                        }
                    }
                    if self.topDataSource.update(doUpdate: { pinModel in
                        if let newPosition = pinIDToPosDic[pinModel.id] {
                            pinModel.topPosition = newPosition
                            return pinModel
                        }
                        return nil
                    }) {
                        update = true
                    }

                    if update {
                        self.publish(refreshType: .refreshTable(hasMore: nil))
                    }
                case .unknown, .reorder:
                    break
                @unknown default:
                    break
                }
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushStickChatPinToTop.self)
            .filter { $0.chatID == chatId }
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.response.meta.version
                self.logger.info("chatPinCardTrace handle local stickToTop push chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
                guard self.checkNeedUpdate(newVersion) else { return }

                let pinModels = self.transform(pins: Array(push.response.pins.values), pinsExtras: push.response.getPinsExtras())
                let addTopPins = pinModels.filter({ $0.isTop })
                let removeTopPins = pinModels.filter({ !$0.isTop })
                var update: Bool = false
                if self.transferPins(from: self.unTopDataSource, to: self.topDataSource, pins: addTopPins) {
                    update = true
                }
                if self.transferPins(from: self.topDataSource, to: self.unTopDataSource, pins: removeTopPins) {
                    update = true
                }
                if update {
                    self.publish(refreshType: .refreshTable(hasMore: nil))
                }
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushDeleteChatPinFormLocal.self)
            .filter { $0.chatId == chatId }
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.version
                self.logger.info("chatPinCardTrace handle local delete push chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
                guard self.checkNeedUpdate(newVersion) else { return }
                if self.removePins(push.deleteIds) {
                    self.publish(refreshType: .refreshTable(hasMore: nil))
                }
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushAddChatPinFormLocal.self)
            .filter { $0.chatId == chatId }
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.response.meta.version
                self.logger.info("chatPinCardTrace handle local add push chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
                guard self.checkNeedUpdate(newVersion) else { return }
                self.mergePins(pinPbs: push.response.pins, pinsExtras: push.response.getPinsExtras())
            }).disposed(by: self.disposeBag)

        self.userPushCenter?.observable(for: PushUpdateChatPinFormLocal.self)
            .filter { $0.chatId == chatId }
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let newVersion = push.response.meta.version
                self.logger.info("chatPinCardTrace handle local update push chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
                guard self.checkNeedUpdate(newVersion) else { return }
                self.mergePins(pinPbs: [push.response.pin], pinsExtras: push.response.getPinsExtras())
            }).disposed(by: self.disposeBag)
    }

    /// 判断 version 是否可以更新
    private func checkNeedUpdate(_ newVersion: Int64) -> Bool {
        self.logger.info("chatPinCardTrace checkNeedUpdate chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
        if let version = self.version, version >= newVersion { return false }
        self.version = newVersion
        return true
    }

    private func transferPins(from: ChatPinListDataSource, to: ChatPinListDataSource, pins: [ChatPin]) -> Bool {
        var update: Bool = false
        if from.removePins(pins.map { $0.id }) {
            update = true
        }
        if to.merge(pins: pins) {
            update = true
        }
        if update {
            self.handleStickAndOldTip()
        }
        return update
    }

    private func mergePins(pinPbs: [RustPB.Im_V1_UniversalChatPin], pinsExtras: UniversalChatPinsExtras) {
        let pinModels = self.transform(pins: pinPbs, pinsExtras: pinsExtras)
        var update: Bool = false
        if self.topDataSource.merge(pins: pinModels.filter { $0.isTop }) {
            update = true
        }
        if self.unTopDataSource.merge(pins: pinModels.filter { !$0.isTop }) {
            update = true
        }
        if update {
            self.handleStickAndOldTip()
            self.publish(refreshType: .refreshTable(hasMore: nil))
        }
    }

    @discardableResult
    private func removePins(_ pinIds: [Int64]) -> Bool {
        var hasRemove = false
        if self.topDataSource.removePins(pinIds) {
            hasRemove = true
        }
        if self.unTopDataSource.removePins(pinIds) {
            hasRemove = true
        }
        if hasRemove {
            self.handleStickAndOldTip()
        }
        return hasRemove
    }

    private func handleInitPins(response: RustPB.Im_V1_GetUniversalChatPinsResponse) {
        let newVersion = response.meta.version
        self.logger.info("chatPinCardTrace handle init pins chatId: \(self.chat.id) newVersion: \(newVersion) currentVersion: \(self.version ?? -1)")
        guard self.checkNeedUpdate(newVersion) else { return }

        let pinModels = self.transform(pins: response.topPins + response.pins, pinsExtras: response.getPinsExtras())
        self.topDataSource.reset(pins: pinModels.filter { $0.isTop })
        self.unTopDataSource.reset(pins: pinModels.filter { !$0.isTop })
        self.handleStickAndOldTip()
        self.nextPageToken = response.nextPageToken
        self.publish(refreshType: .refreshTable(hasMore: !self.nextPageToken.isEmpty))
    }

    private func handleStickAndOldTip() {
        let hasStickTip = self.topDataSource.hasStickTip()
        let oldTipIsFirst = self.unTopDataSource.checkOldTipIsFirst()
        let unTopDataSourceIsEmpty = self.unTopDataSource.cellVMTypes.isEmpty
        self.logger.info("""
            chatPinCardTrace handleStickAndOldTip chatId: \(self.chat.id)
            currentVersion: \(self.version ?? -1)
            hasStickTip: \(hasStickTip)
            oldTipIsFirst: \(oldTipIsFirst)
            unTopDataSourceIsEmpty: \(unTopDataSourceIsEmpty)
        """)

        if hasStickTip, (oldTipIsFirst || unTopDataSourceIsEmpty) {
            self.topDataSource.removeLast()
        }
    }

    private func publish(refreshType: ChatPinCardsRefreshType) {
        self.renderCellViewModels[Self.stickPinCardIndex] = self.topDataSource.cellVMTypes.map { $0.cellViewModel }
        self.renderCellViewModels[Self.unStickPinCardIndex] = self.unTopDataSource.cellVMTypes.map { $0.cellViewModel }
        self.tableRefreshPublish.onNext((refreshType, newDatas: self.renderCellViewModels, outOfQueue: true))
    }

    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            self.topDataSource.onResize()
            self.unTopDataSource.onResize()
            self.publish(refreshType: .refreshTable(hasMore: nil))
        }
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {}
    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {}
    func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {}
    func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard let chatId = Int64(self.chat.id) else { return }
        guard !loadingMorePins else {
            finish(.noWork)
            return
        }
        loadingMorePins = true
        self.chatAPI?.fetchChatPin(chatId: chatId, count: 20, pageToken: nextPageToken, needPreview: true, getTopPins: false)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.logger.info("chatPinCardTrace load more chatId: \(chatId) newVersion: \(response.meta.version) currentVersion: \(self.version ?? -1) \(response.nextPageToken.isEmpty)")
                let pinModels = self.transform(pins: response.topPins + response.pins, pinsExtras: response.getPinsExtras())
                self.topDataSource.merge(pins: pinModels.filter { $0.isTop })
                self.unTopDataSource.merge(pins: pinModels.filter { !$0.isTop })
                self.nextPageToken = response.nextPageToken
                let hasMorePins = !self.nextPageToken.isEmpty
                self.publish(refreshType: .refreshTable(hasMore: hasMorePins))
                self.loadingMorePins = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.logger.error("chatPinCardTrace load more pin fail chatId: \(chatId)", error: error)
                self?.loadingMorePins = false
                finish(.error)
            }).disposed(by: self.disposeBag)

    }

    // MARK: - ChatOpenPinCardService
    var targetViewController: UIViewController {
        return self.targetVC ?? UIViewController()
    }

    var contentAvailableMaxWidth: CGFloat {
        return self.availableMaxWidth - ChatPinListCardContainerCell.ContentExtraMargin
    }

    var headerAvailableMaxWidth: CGFloat {
        return self.availableMaxWidth - ChatPinListCardContainerCell.HeaderExtraMargin
    }

    func calculateSizeAndUpateView(shouldUpdate: @escaping (_ pinId: Int64, _ payload: ChatPinPayload?) -> Bool) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            var update: Bool = false
            var indexPaths: [IndexPath] = []
            if let item = self.topDataSource.calculateSize(shouldUpdate: shouldUpdate) {
                indexPaths.append(IndexPath(item: item, section: Self.stickPinCardIndex))
            }
            if let item = self.unTopDataSource.calculateSize(shouldUpdate: shouldUpdate) {
                indexPaths.append(IndexPath(item: item, section: Self.unStickPinCardIndex))
            }
            if !indexPaths.isEmpty {
                self.publish(refreshType: .pinsUpdate(indexPaths: indexPaths))
            }
        }
    }

    func refresh() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            self.topDataSource.layout()
            self.unTopDataSource.layout()
            self.publish(refreshType: .refreshTable(hasMore: nil))
        }
    }

    func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }

            let updatePaylodHandler: (ChatPin) -> ChatPin? = { pinModel in
                if let payload = pinModel.payload, let newnPayload = doUpdate(payload) {
                    pinModel.payload = newnPayload
                    return pinModel
                }
                return nil

            }
            var needUpdate = false
            if self.topDataSource.update(doUpdate: updatePaylodHandler) {
                needUpdate = true
            }
            if self.unTopDataSource.update(doUpdate: updatePaylodHandler) {
                needUpdate = true
            }
            completion?(needUpdate)
            if needUpdate {
                self.publish(refreshType: .refreshTable(hasMore: nil))
            }
        }
    }

    // MARK: - More Action
    func handleMoreAction(sourceView: UIView, actionItemTypes: [ChatPinActionItemType], pinModel: ChatPin) {
        guard let targetVC = self.targetVC else { return }

        let chat = self.chat
        var menuItemInfos: [FloatMenuItemInfo] = []
        actionItemTypes.forEach { actionItemType in
            var actionItem: ChatPinActionItem?
            switch actionItemType {
            case .commonType(let commonType):
                actionItem = self.getActionItem(commonType, pinModel: pinModel)
            case .item(let item):
                actionItem = item
            default:
                break
            }
            guard let actionItem = actionItem else {
                return
            }

            menuItemInfos.append(
                FloatMenuItemInfo(
                    icon: actionItem.image,
                    title: actionItem.title,
                    acionFunc: { actionItem.handler.handle(pin: pinModel, chat: chat) }
                )
            )
        }
        let menuVC = FloatMenuOperationController(pointView: sourceView,
                                                  bgMaskColor: UIColor.clear,
                                                  menuShadowType: .s5Down,
                                                  items: menuItemInfos)
        menuVC.modalPresentationStyle = .overFullScreen
        menuVC.animationBegin = { [weak self] in
            guard let self = self else { return }
            self.pauseDataQueue(true)
        }
        menuVC.animationEnd = { [weak self] in
            guard let self = self else { return }
            self.pauseDataQueue(false)
        }
        self.userResolver.navigator.present(menuVC, from: targetVC, animated: false)
    }

    func reorder(from: Int, to: Int, isTop: Bool) {
        let reorderDataSource: ChatPinListDataSource
        let reorderType: RustPB.Im_V1_ReorderChatPinRequest.ReorderType
        let reorderSection: Int
        if isTop {
            reorderDataSource = self.topDataSource
            reorderType = .top
            reorderSection = Self.stickPinCardIndex
        } else {
            reorderDataSource = self.unTopDataSource
            reorderType = .normal
            reorderSection = Self.unStickPinCardIndex
        }

        var sortUIDataSource = self.uiDataSource[reorderSection]
        guard let fromMetalModel = (sortUIDataSource[from] as? ChatPinCardContainerCellViewModel)?.metaModel,
              let toPinID = (sortUIDataSource[to] as? ChatPinCardContainerCellViewModel)?.metaModel.pin.id else {
            return
        }
        let fromPinID = fromMetalModel.pin.id
        let moveRequestIdentify: String = "ChatPinCard_MoveRequest"
        self.uiOutput(enable: false, indentify: moveRequestIdentify)
        self.logger.info("""
            chatPinCardTrace move chatId: \(self.chat.id)
            fromPinID: \(fromPinID)
            fromIndex: \(from)
            toPinID: \(toPinID)
            toIndex: \(to)
            clientLogInfo: \(self.clientLogInfo)
            isTop: \(isTop)
        """)
        IMTracker.Chat.Sidebar.Click.drag(self.chat, topId: fromMetalModel.pin.id, topType: IMTrackerChatPinType(type: fromMetalModel.pin.type), sourcePos: from, targetPos: to, isTop: isTop)
        let itemToMove = sortUIDataSource[from]
        sortUIDataSource.remove(at: from)
        sortUIDataSource.insert(itemToMove, at: to)
        self.uiDataSource[reorderSection] = sortUIDataSource
        var prevPinID: Int64?
        if to > 0, let cellVM = sortUIDataSource[to - 1] as? ChatPinCardContainerCellViewModel {
            prevPinID = cellVM.metaModel.pin.id
        }

        self.queueManager.addDataProcess { [weak self, weak reorderDataSource] in
            guard let self = self, let reorderDataSource = reorderDataSource else { return }
            if reorderDataSource.moveAfter(prevPinID, movedPinID: fromPinID) {
                self.publish(refreshType: .refreshTable(hasMore: nil))
            }
            DispatchQueue.main.async { [weak self] in
                self?.uiOutput(enable: true, indentify: moveRequestIdentify)
            }
        }

        self.queueManager.addDataProcess { [weak self, weak reorderDataSource] in
            guard let self = self, let chatAPI = self.chatAPI, let reorderDataSource = reorderDataSource else { return }
            let clientPinIDs: [Int64] = reorderDataSource.cellVMTypes.compactMap { $0.cardCellViewModel?.metaModel.pin.id }
            self.logger.info("""
                chatPinCardTrace begin reorder request chatId: \(self.chat.id)
                pinID: \(fromPinID)
                prevPinID: \(prevPinID ?? -1)
                clientLogInfo: \(self.clientLogInfo)
            """)
            chatAPI.reorderChatPin(
                chatID: Int64(self.chat.id) ?? 0,
                pinID: fromPinID,
                prevPinID: prevPinID,
                clientPinIDs: clientPinIDs,
                reorderType: reorderType,
                clientLogInfo: self.clientLogInfo
            ).observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self, weak reorderDataSource] response in
                guard let self = self, let reorderDataSource = reorderDataSource else { return }
                self.logger.info("chatPinCardTrace reorder success chatId: \(self.chat.id) pinID: \(fromPinID) prevPinID: \(prevPinID ?? -1) clientLogInfo: \(self.clientLogInfo) statusCode: \(response.statusCode.rawValue)")

                DispatchQueue.main.async {
                    if let targetVC = self.targetVC {
                        if case .success = response.statusCode {
                            UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_IM_SupperApp_PinSortingSaved_NoVersion_Toast, on: targetVC.view)
                        } else {
                            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_SuperApp_PinSortingFailToSave_Toast, on: targetVC.view)
                        }
                    }
                }

                guard self.checkNeedUpdate(response.meta.version) else { return }
                var pinIDToPosDic: [Int64: Int64] = [:]
                if isTop {
                    response.topChatPinPositionInfos.forEach {
                        pinIDToPosDic[$0.pinID] = $0.position
                    }
                } else {
                    response.chatPinPositionInfos.forEach {
                        pinIDToPosDic[$0.pinID] = $0.position
                    }
                }
                if reorderDataSource.update(doUpdate: { pinModel in
                    if let newPosition = pinIDToPosDic[pinModel.id] {
                        if isTop {
                            pinModel.topPosition = newPosition
                        } else {
                            pinModel.position = newPosition
                        }
                        return pinModel
                    }
                    return nil
                }) {
                    self.publish(refreshType: .refreshTable(hasMore: nil))
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("chatPinCardTrace reorder fail chatId: \(self.chat.id) pinID: \(fromPinID) prevPinID: \(prevPinID ?? -1) clientLogInfo: \(self.clientLogInfo)", error: error)
                DispatchQueue.main.async {
                    if let targetVC = self.targetVC {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_SuperApp_PinSortingFailToSave_Toast, on: targetVC.view, error: error)
                    }
                }
            }).disposed(by: self.disposeBag)
        }
    }

    func pauseDataQueue(_ pause: Bool) {
        if pause {
            self.logger.info("chatPinCardTrace chatId: \(self.chat.id) pauseQueue")
            self.pauseQueue()
        } else {
            self.logger.info("chatPinCardTrace chatId: \(self.chat.id) resumeQueue")
            self.resumeQueue()
        }
    }

    private func getActionItem(_ itemType: ChatPinActionCommonType, pinModel: ChatPin) -> ChatPinActionItem? {
        switch itemType {
        case .unPin:
            return ChatPinActionItem(title: BundleI18n.LarkChat.Lark_IM_NewPin_Remove_Button,
                                     image: UDIcon.getIconByKey(.unpinOutlined, size: CGSize(width: 20, height: 20)),
                                     handler: unPinCardActionHandler)
        case .stickToTop:
            if !ChatNewPinConfig.supportPinToTop(self.userResolver.fg) { return nil }
            if pinModel.isTop { return nil }
            if enableOldTip, pinModel.isOld { return nil }
            return ChatPinActionItem(title: BundleI18n.LarkChat.Lark_IM_SuperApp_Prioritize_Button,
                                     image: UDIcon.getIconByKey(.setTopOutlined, size: CGSize(width: 20, height: 20)),
                                     handler: stickToTopActionHandler)
        case .unSticktoTop:
            if !ChatNewPinConfig.supportPinToTop(self.userResolver.fg) { return nil }
            if !pinModel.isTop { return nil }
            return ChatPinActionItem(title: BundleI18n.LarkChat.Lark_IM_SuperApp_DontPrioritize_Button,
                                     image: UDIcon.getIconByKey(.setTopCancelOutlined, size: CGSize(width: 20, height: 20)),
                                     handler: unStickToTopActionHandler)
        @unknown default:
            return nil
        }
    }

    private lazy var stickToTopActionHandler: ChatPinActionHandler = {
        return StickToTopActionHandler(
            targetVC: targetVC,
            chatAPI: self.chatAPI,
            currentChatterId: self.userResolver.userID,
            nav: self.userResolver.navigator,
            featureGatingService: self.userResolver.fg,
            limitTopPin: { [weak self] in
                guard let self = self else { return false }
                let sectionIndex = Self.stickPinCardIndex
                guard sectionIndex < self.uiDataSource.count else {
                    return false
                }
                return self.uiDataSource[sectionIndex].compactMap { $0 as? HasChatPin }.count >= StickToTopActionHandler.maxCount
            }
        )
    }()

    private lazy var unStickToTopActionHandler: ChatPinActionHandler = {
        return UnStickToTopActionHandler(targetVC: targetVC,
                                         chatAPI: self.chatAPI,
                                         currentChatterId: self.userResolver.userID,
                                         nav: self.userResolver.navigator,
                                         featureGatingService: self.userResolver.fg)
    }()

    private lazy var unPinCardActionHandler: ChatPinActionHandler = {
        return UnPinCardActionHandler(targetVC: targetVC,
                                      chatAPI: self.chatAPI,
                                      currentChatterId: self.userResolver.userID,
                                      nav: self.userResolver.navigator,
                                      featureGatingService: self.userResolver.fg)
    }()

    // MARK: - ChatPin Transform
    private func transform(pins: [RustPB.Im_V1_UniversalChatPin], pinsExtras: UniversalChatPinsExtras) -> [ChatPin] {
        let pinModels: [ChatPin] = pins.map {
            let pinModel = ChatPin.transform(pb: $0)
            pinModel.payload = ChatPinCardModule.parse(pb: $0, extras: pinsExtras, context: self.module.context)
            pinModel.pinChatter = try? Chatter.transformChatChatter(
                entity: pinsExtras.entity,
                chatID: "\(pinModel.chatId)",
                id: "\(pinModel.chatterID)"
            )
            pinModel.topChatter = try? Chatter.transformChatChatter(
                entity: pinsExtras.entity,
                chatID: "\(pinModel.chatId)",
                id: "\(pinModel.topChatterID)"
            )
            return pinModel
        }
        self.module.handleAfterParse(pins: pinModels, extras: pinsExtras)
        return pinModels
    }
}

extension ChatNewPinCardListViewModel {
    func handleAddPin() {
        guard let targetVC = self.targetVC else { return }
        let permissionResult = self.pinPermissionBehaviorRelay.value
        switch permissionResult {
        case .success:
            let body = ChatAddPinBody(
                chat: self.chatBehaviorRelay.value,
                completion: { [weak self] in
                    self?.queueManager.addDataProcess { [weak self] in
                        self?.tableRefreshPublish.onNext((.scrollToTop, newDatas: nil, outOfQueue: true))
                    }
                }
            )
            self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: targetVC)
        case .failure(reason: let reason):
            UDToast.showTips(with: reason, on: targetVC.view)
        }
    }
}

extension ChatNewPinCardListViewModel: ChatPinCardTopNoticeCellViewModelDelegate {
    func getAvailableMaxWidth() -> CGFloat {
        return self.availableMaxWidth ?? .zero
    }
    func getTargetVC() -> UIViewController? {
        return self.targetVC
    }
    func menuShow() {
        self.pauseDataQueue(true)
    }
    func menuHide() {
        self.pauseDataQueue(false)
    }
}

protocol ChatPinCardContainerCellAbility {
    func getCellHeight() -> CGFloat
    func willDisplay()
    func didEndDisplay()
    func layout()
    func onResize()
    var identifier: String { get }

}

extension ChatPinCardContainerCellAbility {
    var identifier: String {
        return ""
    }
    func willDisplay() {}
    func didEndDisplay() {}
    func layout() {}
    func onResize() {}
}

extension RustPB.Im_V1_CreateUrlChatPinResponse {
    func getPinsExtras() -> UniversalChatPinsExtras {
        return UniversalChatPinsExtras(
            entity: entity,
            previewEntities: previewEntities,
            previewTemplates: previewTemplates,
            announcement: nil
        )
    }
}

extension RustPB.Im_V1_UpdateUrlChatPinResponse {
    func getPinsExtras() -> UniversalChatPinsExtras {
        return UniversalChatPinsExtras(
            entity: entity,
            previewEntities: previewEntities,
            previewTemplates: previewTemplates,
            announcement: nil
        )
    }
}

extension RustPB.Im_V1_StickChatPinToTopResponse {
    func getPinsExtras() -> UniversalChatPinsExtras {
        return UniversalChatPinsExtras(
            entity: entity,
            previewEntities: previewEntities,
            previewTemplates: previewTemplates,
            announcement: hasAnnouncement ? announcement : nil
        )
    }
}

struct ChatPinPermissionConfig {

    enum PermissionResult {
        case success
        case failure(reason: String)
    }

    static func checkPermission(_ chat: Chat, userID: String, featureGatingService: FeatureGatingService) -> PermissionResult {
        if chat.isFrozen {
            return .failure(reason: BundleI18n.LarkChat.Lark_IM_CantCompleteActionBecauseGrpDisbanded_Toast)
        }
        if ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: userID, featureGatingService: featureGatingService) {
            return .success
        } else {
            return .failure(reason: BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanManagePinnedItems_Toast)
        }
    }
}
