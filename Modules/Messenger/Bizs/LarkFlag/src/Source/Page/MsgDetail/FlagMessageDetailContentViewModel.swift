//
//  FlagMessageDetailContentViewModel.swift
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

enum FlagMessageDetailTableRefreshType: OuputTaskTypeInfo {
    case refreshTable

    func canMerge(type: FlagMessageDetailTableRefreshType) -> Bool {
        return true
    }
    func duration() -> Double {
        return 0
    }
    func isBarrier() -> Bool {
        return false
    }
}

final class FlagMessageDetailContentViewModel: AsyncDataProcessViewModel<FlagMessageDetailTableRefreshType, [FlagMessageDetailCellViewModel]>, UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }

    static let logger = Logger.log(FlagMessageDetailContentViewModel.self, category: "Business.FlagMsg")

    private let messageDatasource: FlagMessageDetailDatasource
    private let disposeBag = DisposeBag()
    private(set) var messages: [Message]

    public let reason: String

    let dependency: FlagMessageDetailVMDependency
    let chatWrapper: ChatPushWrapper
    let context: FlagMessageDetailContext
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?

    init(
        dependency: FlagMessageDetailVMDependency,
        context: FlagMessageDetailContext,
        reason: String,
        chatWrapper: ChatPushWrapper,
        messages: [Message]
    ) {
        self.dependency = dependency
        self.chatWrapper = chatWrapper
        self.context = context
        self.reason = reason
        self.messages = messages
        self.messageDatasource = FlagMessageDetailDatasource(
            chat: {
                return chatWrapper.chat.value
            },
            vmFactory: FlagMessageDetailCellViewModelFactory(
                context: context,
                registery: FlagMessageDetailSubFactoryRegistery(
                    context: context, defaultFactory: UnknownContentFactory(context: context)
                ),
                cellLifeCycleObseverRegister: FlagMsgCellLifeCycleObseverRegister()
            ),
            cellConfig: FlagMessageDetailChatCellConfig.default
        )
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] _ in
            guard let self = self else { return 0 }
            return self.maxCellContentWidth(
                hasStatusView: true,
                maxCellWidth: self.hostUIConfig.size.width
            )
        }
    }

    func setupData() {
        self.queueManager.addDataProcess {
            self.messageDatasource.reset(messages: self.messages, concurrent: self.concurrentHandler)
            self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
    }

    func getURLPreviews() {
        var pairMap = [String: Im_V1_GetMessagePreviewsRequest.PreviewPair]()
        self.messages.forEach { subMessage in
            if !subMessage.urlPreviewHangPointMap.isEmpty {
                var pair = Im_V1_GetMessagePreviewsRequest.PreviewPair()
                pair.previewIds = subMessage.urlPreviewHangPointMap.map({ $0.value.previewID })
                pairMap[subMessage.id] = pair
            }
        }
        if !pairMap.isEmpty {
            dependency.getMessagePreviews(messagePreviewMap: pairMap)
                .observeOn(self.queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] inlinePair, urlPreviewPair, messageLinks in
                    guard let self = self, let inlinePair = inlinePair, let urlPreviewPair = urlPreviewPair else { return }
                    self.updateInlinePreview(pair: inlinePair)
                    self.updateURLPreview(pair: urlPreviewPair, messageLinks: messageLinks)
                    self.messageDatasource.reset(messages: self.messages, concurrent: self.concurrentHandler)
                    self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
                })
                .disposed(by: disposeBag)
        } else {
            Self.logger.info("empty pairMap, msgID = \(self.messages.map({ $0.id }))")
        }
    }

    private func updateInlinePreview(pair: InlinePreviewEntityPair) {
        self.messages.forEach { subMessage in
            guard let body = pair.inlinePreviewEntities[subMessage.id] else { return }
            if subMessage.type == .text, var subContent = subMessage.content as? TextContent {
                subContent.inlinePreviewEntities = body
                subMessage.content = subContent
            } else if subMessage.type == .post, var subContent = subMessage.content as? PostContent {
                subContent.inlinePreviewEntities = body
                subMessage.content = subContent
            }
        }
    }

    private func updateURLPreview(pair: URLPreviewEntityPair, messageLinks: [String: MessageLink]) {
        self.messages.forEach { subMessage in
            if let body = pair.urlPreviewEntities[subMessage.id], !body.isEmpty {
                let newEntities = body.filter({ subMessage.orderedPreviewIDs.contains($0.key) })
                if !newEntities.isEmpty {
                    subMessage.urlPreviewEntities += newEntities
                }
            }
            var newMessageLinks = [String: MessageLink]()
            subMessage.urlPreviewHangPointMap.values.forEach { hangPoint in
                newMessageLinks[hangPoint.previewID] = messageLinks[hangPoint.previewID]
            }
            if !newMessageLinks.isEmpty {
                subMessage.messageLinks += newMessageLinks
            }
        }
    }

    func onResize() {
        self.queueManager.addDataProcess {
            self.messageDatasource.onResize()
            self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.messageDatasource.cellViewModels, outOfQueue: false))
        }
    }

    public func isMeSend(_ id: String) -> Bool {
        return id == self.userResolver.userID
    }

    public func checkPreviewPermission(message: Message) -> PermissionDisplayState {
        return self.dependency.chatSecurityControlService?.checkPreviewAndReceiveAuthority(chat: nil, message: message) ?? .receiveLoading
    }
}

extension FlagMessageDetailContentViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
    }

    var scene: ContextScene {
        return .newChat
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

    func maxCellContentWidth(hasStatusView: Bool, maxCellWidth: CGFloat) -> CGFloat {
        let cellPadding: CGFloat = 16
        var bubbleLeft: CGFloat { 16 + 30.auto() + 6 } // left container width
        let maxBubbleWidth = maxCellWidth - bubbleLeft - cellPadding
        let messageStatusSize: CGFloat = StatusComponentLayoutConstraints.statusSize.width + StatusComponentLayoutConstraints.margin
        return maxBubbleWidth - (hasStatusView ? messageStatusSize : 0)
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
