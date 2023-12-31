//
//  MergeForwardMessageDetailContentViewModel.swift
//  Lark
//
//  Created by zc09v on 2018/6/19.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
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

enum MergeForwardTableRefreshType: OuputTaskTypeInfo {
    case refreshTable
    case initMessages(InitMessagesInfo)
    case loadMoreOldMessages(hasHeader: Bool)
    case loadMoreNewMessages(hasFooter: Bool)

    func canMerge(type: MergeForwardTableRefreshType) -> Bool {
        switch (self, type) {
        case (.refreshTable, .refreshTable):
            return true
        default:
            return false
        }
    }
    func duration() -> Double {
        return 0
    }
    func isBarrier() -> Bool {
        return false
    }
}

final class MergeForwardMessageDetailContentViewModel: AsyncDataProcessViewModel<MergeForwardTableRefreshType, [MergeForwardCellViewModel]>, HasAssets {
    static let logger = Logger.log(MergeForwardMessageDetailContentViewModel.self, category: "Business.MergeForward")

    private let messageDatasource: MergeForwardMessagesDatasource
    private let disposeBag = DisposeBag()
    private(set) var inputMessages: [Message]

    private let pushHandlers: MergeForwardPushHandlersRegister
    let dependency: MergeForwardMessageDetailVMDependency
    let chatWrapper: ChatPushWrapper
    let context: MergeForwardContext
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    // 是否展示背景页面
    let isShowBgImageView: Bool
    let messageDatasourceService: MergeForwardMessageDetailDataSourceService?

    init(
        dependency: MergeForwardMessageDetailVMDependency,
        context: MergeForwardContext,
        chatWrapper: ChatPushWrapper,
        isShowBgImageView: Bool = false,
        pushHandler: MergeForwardPushHandlersRegister,
        inputMessages: [Message],
        messageDatasourceService: MergeForwardMessageDetailDataSourceService? = nil,
        registery: MessageSubFactoryRegistery<MergeForwardContext>? = nil
    ) {
        self.dependency = dependency
        self.chatWrapper = chatWrapper
        self.isShowBgImageView = isShowBgImageView
        self.context = context
        self.pushHandlers = pushHandler
        self.inputMessages = inputMessages
        self.messageDatasourceService = messageDatasourceService
        self.messageDatasource = MergeForwardMessagesDatasource(
            chat: {
                return chatWrapper.chat.value
            },
            vmFactory: MergeForwardCellViewModelFactory(
                context: context,
                registery: registery ?? MergeForwardMessageSubFactoryRegistery(
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

    var isUserInteractionEnabled: Bool {
        return self.context.mergeForwardType == .normal ? true : false
    }

    func setupData() {
        pushHandlers.startObserve(self)
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else {
                return
            }
            self.messageDatasource.reset(messages: self.inputMessages, concurrent: self.concurrentHandler)
            self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
        messageDatasourceService?.loadFirstScreenMessages()
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, hasMoreNew, hasMoreOld, _) in
                guard let self = self else { return }
                self.messageDatasource.reset(messages: messages, concurrent: self.concurrentHandler)
                self.tableRefreshPublish.onNext(
                    (
                        .initMessages(InitMessagesInfo(hasHeader: hasMoreOld, hasFooter: hasMoreNew, scrollInfo: nil, initType: .lastedMessage)),
                        newDatas: self.messageDatasource.cellViewModels,
                        outOfQueue: false
                    )
                )
            }).disposed(by: self.disposeBag)
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
                    if self.updateInlinePreview(pair: inlinePair) {
                        self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
                    }
                }, onError: { error in
                    Self.logger.error("getMessagePreviews failed, msgID = \(messages.map({ $0.id })), pairMap = \(pairMap)", error: error)
                })
                .disposed(by: disposeBag)
        } else {
            Self.logger.info("empty pairMap, msgID = \(messages.map({ $0.id }))")
        }
    }

    private func updateInlinePreview(pair: InlinePreviewEntityPair) -> Bool {
        let sourceIDs = Array(pair.inlinePreviewEntities.keys)
        return self.messageDatasource.update(messageIds: sourceIDs, doUpdate: { message in
            if let body = self.dependency.inlinePreviewVM.getInlinePreviewBody(message: message, pair: pair) {
                return self.dependency.inlinePreviewVM.update(message: message, body: body) ? message : nil
            }
            return nil
        })
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

extension MergeForwardMessageDetailContentViewModel: DataSourceAPI {
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
        self.reloadTable()
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
    func send(update: Bool) {
        if update {
            self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
    }
}
extension MergeForwardMessageDetailContentViewModel: HandlePushDataSourceAPI {
    func update(original: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(original: { (msg) -> Message? in
                return original(msg) as? Message
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }

    func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(messageIds: messageIds, doUpdate: { (msg) -> Message? in
                return doUpdate(msg) as? Message
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }
}

extension MergeForwardMessageDetailContentViewModel: MergeForwardMessageDetailTableViewDataSourceDelegate {
    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
        guard let messageDatasourceService = messageDatasourceService else {
            finish?(.noWork)
            return
        }
        messageDatasourceService.loadMoreNewMessages()
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, hasMore, sdkCost) in
                guard let self = self else {
                    finish?(.noWork)
                    return
                }
                let valid = self.messageDatasource.tailAppend(messages: messages, concurrent: self.concurrentHandler)
                self.tableRefreshPublish.onNext(
                    (
                        .loadMoreNewMessages(hasFooter: hasMore),
                        newDatas: self.messageDatasource.cellViewModels,
                        outOfQueue: false
                    )
                )
                finish?(.success(sdkCost: sdkCost, valid: valid))
            }, onError: { _ in
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
        guard let messageDatasourceService = messageDatasourceService else {
            finish?(.noWork)
            return
        }
        messageDatasourceService.loadMoreOldMessages()
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, hasMore, sdkCost) in
                guard let self = self else {
                    finish?(.noWork)
                    return
                }
                let valid = self.messageDatasource.headAppend(messages: messages, concurrent: self.concurrentHandler)
                self.tableRefreshPublish.onNext(
                    (
                        .loadMoreOldMessages(hasHeader: hasMore),
                        newDatas: self.messageDatasource.cellViewModels,
                        outOfQueue: false
                    )
                )
                finish?(.success(sdkCost: sdkCost, valid: valid))
            }, onError: { _ in
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }
}
