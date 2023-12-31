//
//  ChatInfoViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/29.
//

import LarkActionSheet
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LarkContainer
import LarkFoundation
import LarkTag
import EENavigator
import LarkCore
import AppContainer
import UniverseDesignToast
import LarkBadge
import LarkAlertController
import LarkReleaseConfig
import LarkSDKInterface
import LarkAccountInterface
import LarkKAFeatureSwitch
import LarkMessengerInterface
import LarkFeatureSwitch
import LKCommonsLogging
import LarkFeatureGating
import SuiteAppConfig
import LarkOpenChat
import RustPB

/// 新版设置页代码导读文档: https://bytedance.feishu.cn/docs/doccnwg9Ae1FcFHza0JAWmmsIcb#KDwoKq
final class ChatInfoViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(ChatInfoViewModel.self, category: "Module.IM.ChatInfo")

    private(set) var disposeBag = DisposeBag()
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()
    private var pushCenter: PushNotificationCenter

    private let schedulerType: SchedulerType
    var reloadData: Driver<CommonDatasource> { return _reloadData.asDriver(onErrorJustReturn: []) }
    private var _reloadData = PublishSubject<CommonDatasource>()

    // 更新cell高度
    var updateHeight: Driver<Void> { return _updateHeight.asDriver(onErrorJustReturn: ()) }
    private(set) var _updateHeight = PublishSubject<Void>()
    private let hideFeedSetting: Bool
    let hasModifyAccess: Bool

    var chat: LarkModel.Chat
    private var chatSubject = PublishSubject<Chat>()
    private var chatPushWrapper: ChatPushWrapper
    private var chatOb: Observable<Chat> {
        chatSubject.asObservable()
    }
    private var currentChatterInChatSubject = PublishSubject<Chatter>()
    var currentChatterInChatob: Observable<Chatter> {
        currentChatterInChatSubject.asObservable()
    }

    weak var targetVC: ChatInfoControllerAbility?
    var chatSettingType: P2PChatSettingBody.ChatSettingType

    // 群分享时，默认选中item
    var defaultSelected: ShareChatViaLinkType {
        return .card
    }
    var chatCanBeShared: Bool {
        return chat.chatCanBeShared(currentUserId: currentUserId)
    }

    // 可感知耗时&错误相关属性
    var firstScreenReadyDriver: Driver<Void> {
        return _firstScreenReadyPublisher.take(1).asDriver(onErrorJustReturn: ())
    }
    private var _firstScreenReadyPublisher = PublishSubject<Void>()
    private var firstScreenReadyState = FirstScreenReadyState() {
        didSet {
            if firstScreenReadyState.isFinish() {
                _firstScreenReadyPublisher.onNext(())
            }
        }
    }
    private let action: EnterChatSettingAction
    var errorObserver: Observable<Error> {
        return _errorPublisher.asObservable()
    }
    private var _errorPublisher = PublishSubject<Error>()

    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?

    // 所有的模块vms
    private lazy var muduleViewModels: [ChatSettingModuleViewModel] = {
        return [
            actionModuleViewModel,
            infoModuleViewModel,
            linkedPagesModuleViewModel,
            appsModuleViewModel,
            searchModuleViewModel,
            configModuleViewModel,
            restrictedModeModuleViewModel
        ].compactMap({ $0 as? ChatSettingModuleViewModel })
    }()
    /// chatSettingModule
    private(set) lazy var chatSettingModule: ChatSettingModule = ChatSettingModule(context: self.chatSettingContext)
    let chatSettingContext: ChatSettingContext

    // 行为模块vm
    private lazy var actionModuleViewModel: ChatSettingActionModuleViewModel = {
        let vm = ChatSettingActionModuleViewModel(resolver: self.userResolver,
                                                  chat: chat,
                                                  hasModifyAccess: hasModifyAccess,
                                                  schedulerType: schedulerType,
                                                  pushChat: self.chatOb,
                                                  currentChatterInChatOb: currentChatterInChatob,
                                                  pushCenter: pushCenter,
                                                  targetVC: targetVC)
        return vm
    }()
    // 信息模块vm
    private lazy var infoModuleViewModel: ChatSettingInfoModuleViewModel = {
        let vm = ChatSettingInfoModuleViewModel(resolver: self.userResolver,
                                                chat: chat,
                                                pushChat: self.chatOb,
                                                schedulerType: schedulerType,
                                                hasModifyAccess: self.hasModifyAccess,
                                                targetVC: targetVC)
        return vm
    }()

    // 应用模块vm
    private lazy var appsModuleViewModel: ChatSettingAppsModuleViewModel = {
        let vm = ChatSettingAppsModuleViewModel(resolver: self.userResolver,
                                                chat: chat,
                                                pushCenter: pushCenter,
                                                chatPushWrapper: self.chatPushWrapper,
                                                moduleFatoryTypes: chatSettingModule.functionFactoryTypes(),
                                                targetVC: targetVC)
        return vm
    }()
    // 搜索模块vm
    private lazy var searchModuleViewModel: ChatSettingSearchModuleViewModel = {
        let vm = ChatSettingSearchModuleViewModel(userResolver: self.userResolver,
                                                  chat: chat,
                                                  pushCenter: pushCenter,
                                                  chatPushWrapper: chatPushWrapper,
                                                  factoryTypes: chatSettingModule.searchFactoryTypes(),
                                                  targetVC: targetVC)
        return vm
    }()
    // 配置模块vm
    private lazy var configModuleViewModel: ChatSettingConfigModuleViewModel = {
        let vm = ChatSettingConfigModuleViewModel(resolver: self.userResolver,
                                                  chat: chat,
                                                  pushChat: self.chatOb,
                                                  hasModifyAccess: hasModifyAccess,
                                                  schedulerType: schedulerType,
                                                  currentChatterInChatOb: currentChatterInChatob,
                                                  pushCenter: pushCenter,
                                                  hideFeedSetting: hideFeedSetting,
                                                  chatSettingType: chatSettingType,
                                                  targetVC: targetVC)
        return vm
    }()

    // 消息权限管理
    private lazy var restrictedModeModuleViewModel: RestrictedModeModuleViewModel = {
        let vm = RestrictedModeModuleViewModel(resolver: self.userResolver,
                                               chatPushWrapper: chatPushWrapper,
                                               targetVC: targetVC)
        return vm
    }()

    // 群关联页面
    private lazy var linkedPagesModuleViewModel: ChatSettingLinkedPagesModuleViewModel = {
        let vm = ChatSettingLinkedPagesModuleViewModel(resolver: self.userResolver,
                                                       chat: chat,
                                                       pushChat: self.chatOb,
                                                       targetVC: targetVC)
        return vm
    }()

    let naviBarTitle: String
    init(resolver: UserResolver,
         pushCenter: PushNotificationCenter,
         chatPushWrapper: ChatPushWrapper,
         chat: Chat,
         hasModifyAccess: Bool,
         hideFeedSetting: Bool,
         chatSettingType: P2PChatSettingBody.ChatSettingType,
         chatSettingContext: ChatSettingContext,
         action: EnterChatSettingAction,
         businessModuleViewModels: [ChatSettingModuleViewModel] = []
    ) {
        self.userResolver = resolver
        self.pushCenter = pushCenter
        self.chatPushWrapper = chatPushWrapper
        self.hasModifyAccess = hasModifyAccess
        self.hideFeedSetting = hideFeedSetting
        self.chatSettingType = chatSettingType
        self.chatSettingContext = chatSettingContext
        let queue = DispatchQueue(label: "chatInfoQueue", qos: .utility)
        schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)
        self.action = action
        self.chat = chat
        self.naviBarTitle = BundleI18n.LarkChatSetting.Lark_Legacy_MessageSetting
    }

    func startLoadData() {
        // 模块vms初始化items
        self.muduleViewModels.forEach { (vm) in
            vm.structItems()
        }
        // 发射初始化信号
        _reloadData.onNext(structureItems())

        // 监听改变信号
        DispatchQueue.global().async {
            self.startToObserve()
        }
    }

    // MARK: - make datasoure
    func structureItems() -> CommonDatasource {
        let items = self.muduleViewModels.flatMap { (vm) -> [CommonCellItemProtocol] in
            return vm.items
        }
        let moduleItems = self.chatSettingModule.items()
        let allItems = items + moduleItems
        var itemDic = [String: [CommonCellItemProtocol]]()
        allItems.forEach { (item) in
            var itemsArray = itemDic[item.type.rawValue] ?? []
            itemsArray.append(item)
            itemDic[item.type.rawValue] = itemsArray
        }
        // 根据模块布局cell
        return layoutItemsWithDic(itemDic)
    }

    private func startToObserve() {
        let chatId = self.chat.id
        let currentUserId = self.currentUserId

        // 模块vms开始监听数据变化
        self.muduleViewModels.forEach { (vm) in
            vm.startToObserve()
        }

        // 监听所有module的Push 刷新UI
        // 100毫秒debounce过滤掉高频信号刷新
        Observable.merge(self.muduleViewModels.map({ $0.reloadObservable }))
            .debounce(.milliseconds(100), scheduler: schedulerType)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self._reloadData.onNext(self.structureItems())
            }, onError: { [weak self] (error) in
                self?._errorPublisher.onNext(error)
            }).disposed(by: self.disposeBag)

        // 监听chat 变化
        pushCenter.observable(for: PushChat.self)
            .filter { $0.chat.id == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) -> Void in
                self?.chat = push.chat
                self?.chatSettingModule.modelDidChange(model: ChatSettingMetaModel(chat: push.chat))
                self?.targetVC?.updateRightItems()
                self?.chatSubject.onNext(push.chat)
            }).disposed(by: self.disposeBag)

        // 可感知耗时事件监听
        self.infoModuleViewModel.firstScreenGroupMemberReadyOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.firstScreenReadyState.groupMemberReady = true
            }).disposed(by: self.disposeBag)

        // 可感知错误事件监听
        self.infoModuleViewModel.errorObserver
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?._errorPublisher.onNext(error)
            }).disposed(by: self.disposeBag)

        // 拉取server chat
        chatAPI?.fetchChat(by: chatId, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                if let chat = chat {
                    self?.chat = chat
                    self?.chatSubject.onNext(chat)
                    self?.firstScreenReadyState.chatReady = true
                } else {
                    Self.logger.error("Get local chat error", additionalData: ["chatId": chatId])
                }
            }).disposed(by: self.disposeBag)

        if chat.type != .p2P {
            // 获取当前用户角色
            chatterAPI?.fetchChatChatters(ids: [currentUserId], chatId: chatId)
                .map { $0[currentUserId] }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatter) -> Void in
                    if let chatter = chatter {
                        self?.currentChatterInChatSubject.onNext(chatter)
                        self?.firstScreenReadyState.chatChatterReady = true
                    } else {
                        Self.logger.error("Get local chatter error", additionalData: ["chatId": chatId])
                    }
                }, onError: { [weak self] (error) in
                    self?._errorPublisher.onNext(error)
                }).disposed(by: self.disposeBag)
        }
    }

    func refresh() {
        self._reloadData.onNext(self.structureItems())
    }

    func viewDidLoadTask() {
        NewChatSettingTracker.imChatSettingView(chat: chat,
                                                myUserId: currentUserId,
                                                isOwner: currentUserId == chat.ownerId,
                                                isAdmin: chat.isGroupAdmin,
                                                extra: ["action": action.rawValue])
    }
}

 // MARK: 工具方法
extension ChatInfoViewModel {
    func layoutItemsWithDic(_ itemsDic: [String: [CommonCellItemProtocol]]) -> CommonDatasource {
        let layout = LarkOpenChat.settingTableLayout
        let allItems = layout.sections.map { section -> CommonSectionModel in
            let rows = section.rows.compactMap { identify -> [CommonCellItemProtocol]? in
                return itemsDic[identify]
            }.flatMap { $0 }
            return CommonSectionModel(title: section.headerTitle, items: rows)
        }

        return allItems.compactMap { (section) -> CommonSectionModel? in
            let newItems = section.items.compactMap { $0 }
            return newItems.isEmpty ? nil : section
        }
    }
}

// MARK: 业务逻辑
extension ChatInfoViewModel {
    func fetchP2PChatterAuthAndHandle(title: String? = nil,
                                      content: String? = nil,
                                      businessType: AddContactBusinessType,
                                      handler: @escaping () -> Void) {
        self.infoModuleViewModel.fetchP2PChatterAuthAndHandle(title: title,
                                                              content: content,
                                                              businessType: businessType,
                                                              handler: handler
        )
    }

    func configModuleViewModules(showAlert: ((_ title: String, _ message: String) -> Void)?) {
        self.configModuleViewModel.showAlert = showAlert
    }

    // 配置开放的module
    func setupOpenModule() {
        chatSettingModule.handler(model: ChatSettingMetaModel(chat: chat))
        chatSettingModule.createItems(model: ChatSettingMetaModel(chat: chat))
    }
}

protocol ChatSettingModuleViewModel {
    var items: [CommonCellItemProtocol] { get }
    var reloadObservable: Observable<Void> { get }
    func structItems()
    func startToObserve()
}

typealias PushLocalLeaveGroupHandler = (_ channelId: String, _ status: LocalLeaveGroupStatus) -> Void
