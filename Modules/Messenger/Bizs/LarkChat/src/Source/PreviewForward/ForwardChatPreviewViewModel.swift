//
//  ForwardChatPreviewViewModel.swift
//  Lark
//
//  Created by Bytedance on 2022/9/8.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkCore
import RxCocoa
import RxSwift
import Swinject
import LarkMessageBase
import LarkMessageCore
import LarkMessengerInterface
import LarkSDKInterface
import LKCommonsLogging
import RustPB
import LarkAccountInterface
import LarkUIKit
import TangramService

enum PreviewStatus {
    case normal
    case error
    case empty
    case messageBurnMode
    case containBurnMessage
}

final class ForwardChatPreviewViewModel: AsyncDataProcessViewModel<MergeForwardTableRefreshType, [MergeForwardCellViewModel]>, HasAssets {
    static let logger = Logger.log(ForwardChatPreviewViewModel.self, category: "Business.PreviewForward")

    private let messageDatasource: MergeForwardMessagesDatasource
    private let disposeBag = DisposeBag()
    private(set) var inputMessages: [Message] = []

    let dependency: MergeForwardMessageDetailVMDependency
    let chatWrapper: ChatPushWrapper
    var chatModel: Chat {
        return chatWrapper.chat.value
    }
    let context: MergeForwardContext
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    var isUserInteractionEnabled: Bool {
        return self.context.mergeForwardType == .normal ? true : false
    }
    private var statusReplay: ReplaySubject<PreviewStatus> = ReplaySubject<PreviewStatus>.create(bufferSize: 1)
    public var status: Observable<PreviewStatus> {
        return statusReplay.asObserver()
    }

    init(
        dependency: MergeForwardMessageDetailVMDependency,
        context: MergeForwardContext,
        chatWrapper: ChatPushWrapper
    ) {
        self.dependency = dependency
        self.chatWrapper = chatWrapper
        self.context = context
        self.messageDatasource = MergeForwardMessagesDatasource(
            chat: {
                return chatWrapper.chat.value
            },
            vmFactory: ForwardChatPreviewCellViewModelFactory(
                context: context,
                registery: MergeForwardMessageSubFactoryRegistery(
                    context: context, defaultFactory: UnknownContentFactory(context: context)
                ),
                cellLifeCycleObseverRegister: MergeForwardCellLifeCycleObseverRegister()
            ),
            cellConfig: ChatCellConfig(hasStatus: false)
        )
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] message in
            return self?.getContentPreferMaxWidth(message) ?? 0
        }
    }

    func setupData() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else {
                return
            }
            self.messageDatasource.reset(messages: self.inputMessages, concurrent: self.concurrentHandler)
            var initInfo = InitMessagesInfo(hasHeader: false, hasFooter: false, scrollInfo: nil, initType: .lastedMessage)
            if !self.messageDatasource.cellViewModels.isEmpty {
                initInfo = InitMessagesInfo(hasHeader: false,
                                            hasFooter: false,
                                            scrollInfo: ScrollInfo(index: self.messageDatasource.cellViewModels.count - 1, tableScrollPosition: .bottom),
                                            initType: .lastedMessage)
            }
            self.tableRefreshPublish.onNext((.initMessages(initInfo), newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
    }
    func fetchInputMessage() {
        if chatModel.enableMessageBurn {
            // 开启阅后即焚模式时直接返回messageBurn信号，不再拉消息
            self.statusReplay.onNext(.messageBurnMode)
            return
        }
        self.dependency.fetchPreviewChatMessages(chatId: chatWrapper.chat.value.id)
            .debug("debug information")
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                if messages.contains(where: { $0.isOnTimeDel == true }) {
                    // 消息中包含阅后即焚消息
                    self.statusReplay.onNext(.containBurnMessage)
                    return
                }
                for message in messages {
                    message.pinTimestamp = 0
                    message.pinChatter = nil
                    message.isUrgent = false
                }
                self.inputMessages = messages
                self.setupData()
                self.getURLPreviews()
                self.statusReplay.onNext(self.inputMessages.isEmpty ? .empty : .normal)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("Forward.TargetPreview fetch chat message error: \(error)")
                self.statusReplay.onNext(.error)
            }).disposed(by: disposeBag)
    }
    func getURLPreviews() {
        let messages = self.inputMessages
        let pairMap = dependency.inlinePreviewVM.getMessagePreviewPair(messages: messages)
        if !pairMap.isEmpty {
            dependency.urlPreviewAPI?.getMessagePreviews(messagePreviewMap: pairMap, syncDataStrategy: .tryLocal)
                .observeOn(self.queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] inlinePair, _, _ in
                    guard let self = self else { return }
                    // 合并转发页面不支持卡片，暂时只更新Inline
                    self.updateInlinePreview(pair: inlinePair)
                    self.messageDatasource.reset(messages: messages, concurrent: self.concurrentHandler)
                    self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
                }, onError: { error in
                    Self.logger.error("getMessagePreviews failed", error: error)
                })
                .disposed(by: disposeBag)
        } else {
            Self.logger.info("empty pairMap")
        }
    }

    private func updateInlinePreview(pair: InlinePreviewEntityPair) {
        self.inputMessages.forEach { subMessage in
            if let body = self.dependency.inlinePreviewVM.getInlinePreviewBody(message: subMessage, pair: pair) {
                self.dependency.inlinePreviewVM.update(message: subMessage, body: body)
            }
        }
    }

    var messages: [Message] {
        return self.uiDataSource.compactMap { (cellVM) -> Message? in
            return (cellVM as? HasMessage)?.message
        }
    }

    func chatter(by chatterInfo: RustPB.Basic_V1_MergeForwardContent.ChatterInfo) -> Chatter {
        return Chatter(
            id: chatterInfo.id,
            isAnonymous: chatterInfo.isAnonymous,
            isFrozen: false,
            name: chatterInfo.name,
            localizedName: chatterInfo.name,
            enUsName: chatterInfo.name,
            namePinyin: "",
            alias: "",
            anotherName: "",
            nameWithAnotherName: chatterInfo.name,
            type: chatterInfo.type,
            avatarKey: chatterInfo.avatarKey,
            avatar: chatterInfo.avatar,
            updateTime: 0,
            creatorId: "",
            isResigned: false,
            isRegistered: true,
            description: Chatter.Description(),
            withBotTag: "",
            canJoinGroup: true,
            tenantId: "",
            workStatus: WorkStatus(),
            majorLanguage: "",
            profileEnabled: true,
            focusStatusList: [],
            chatExtra: nil,
            accessInfo: Chatter.AccessInfo(),
            email: "",
            doNotDisturbEndTime: 0,
            openAppId: "",
            acceptSmsPhoneUrgent: false
        )
    }

    func cellViewModel(by id: String) -> MergeForwardCellViewModel? {
        return self.uiDataSource.first { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.id == id || messageCellVM.message.cid == id
            }
            return false
        }
    }

    func findMessageIndexBy(id: String) -> IndexPath? {
        guard !id.isEmpty else {
            return nil
        }
        let index = self.uiDataSource.firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                return messageVM.message.id == id || messageVM.message.cid == id
            }
            return false
        }
        guard let row = index else { return nil }
        return IndexPath(row: row, section: 0)
    }

    func onResize() {
        self.queueManager.addDataProcess {
            self.messageDatasource.onResize()
            self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
    }

    public func isMeSend(_ id: String) -> Bool {
        return id == context.userID
    }

    public func checkPreviewPermission(message: Message) -> PermissionDisplayState {
        return self.dependency.chatSecurityControlService?.checkPreviewAndReceiveAuthority(chat: nil, message: message) ?? .allow
    }
}

extension ForwardChatPreviewViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
    }

    var scene: ContextScene {
        return .mergeForwardDetail
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.uiDataSource
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    func pauseDataQueue(_ pause: Bool) {
    }

    func reloadTable() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
    }

    func reloadRow(by messageId: String, animation: UITableView.RowAnimation = .fade) {
        self.reloadTable()
    }

    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {
    }

    func deleteRow(by messageId: String) {
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        let padding: CGFloat = message.showInThreadModeStyle ? self.messageDatasource.contentPadding * 2 : 0
        return ChatCellUIStaticVariable.maxCellContentWidth(
            hasStatusView: false,
            maxCellWidth: hostUIConfig.size.width
        ) - padding
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
