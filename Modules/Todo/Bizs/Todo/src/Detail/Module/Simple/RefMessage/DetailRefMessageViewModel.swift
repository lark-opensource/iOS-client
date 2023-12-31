//
//  DetailRefMessageViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/2/3.
//

import RxSwift
import RxCocoa
import LarkContainer
import ThreadSafeDataStructure
import RustPB
import TodoInterface

/// Detail - RefMessage - ViewModel

final class DetailRefMessageViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let rxViewData = BehaviorRelay<DetailRefMessageViewDataType?>(value: nil)
    var messageDetail: (entity: Basic_V1_Entity, messageId: String)? {
        guard let viewData = rxViewData.value as? MessageData else {
            return nil
        }
        return (viewData.entity, viewData.messageId)
    }

    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    @ScopedInjectedLazy private var messengerDependency: MessengerDependency?

    private let store: DetailModuleStore

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() {
        store.rxInitialized().subscribe(onSuccess: { [weak self] _ in
            guard let self = self else { return }
            let state = self.store.state
            // 目前对 refResource 的支持状态：
            //  - 只支持一个
            //  - 只支持 message
            guard let rState = state.refResourceStates.first else {
                return
            }
            if state.scene.isForCreating {
                if case .untransformed(let resourceSource) = rState {
                    switch resourceSource {
                    case .message(let messageIds, let chatId, let needsMerge):
                        self.transformToResource(fromMessageIds: messageIds, chatId: chatId, needsMerge: needsMerge)
                    case .thread(let threadId):
                        self.transformToResource(fromThreadId: threadId)
                    }
                }
            } else {
                if case .normal(let resourceId) = rState {
                    self.loadRefResource(byId: resourceId)
                }
            }
        }).disposed(by: disposeBag)
    }

    private func updateRefResourceState(_ refSourceState: DetailModuleState.RefResourceState) {
        assert(Thread.isMainThread)
        var refResourceStates = store.state.refResourceStates
        guard !refResourceStates.isEmpty else {
            assertionFailure()
            return
        }
        refResourceStates[0] = refSourceState
        store.dispatch(.updateRefResources(refResourceStates))
    }

}

// MARK: ViewData

extension DetailRefMessageViewModel {

    private struct MessageData: DetailRefMessageViewDataType {
        var title: String
        var content: AttrText
        var isDeletable: Bool
        var entity: Basic_V1_Entity
        var messageId: String
        var resourceId: String
    }

    private func updateMessageData(with resource: Rust.RefResource?) {
        guard let resource = resource,
              case .msg(let msgResource) = resource.resource,
              let message = msgResource.entity.messages[msgResource.msgID],
              let messDep = messengerDependency else {
            rxViewData.accept(nil)
            return
        }
        let (title, content) = messDep.getMergedMessageDisplayInfo(entity: msgResource.entity, message: message)
        rxViewData.accept(
            MessageData(
                title: title,
                content: content,
                isDeletable: store.state.permissions.refMessage.isEditable,
                entity: msgResource.entity,
                messageId: msgResource.msgID,
                resourceId: resource.id
            )
        )
    }

}

// MARK: ViewAction

extension DetailRefMessageViewModel {

    func deleteResource() {
        var state = store.state
        guard let rState = state.refResourceStates.first,
              case .normal(let resourceId) = rState else {
            return
        }
        updateRefResourceState(.deleted(id: resourceId))
        rxViewData.accept(nil)
    }

}

// MARK: Resource

extension DetailRefMessageViewModel {

    private func transformToResource(fromMessageIds messageIds: [String], chatId: String, needsMerge: Bool) {
        Detail.logger.info("will transformToResource. messageIds: \(messageIds), chatId: \(chatId)")
        operateApi?.mergeMessagesAsResources(withMessageIds: messageIds, chatId: chatId, needsMerge: needsMerge)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] resource in
                    Detail.logger.info("transformToResource succeed. resourceId: \(resource.id)")
                    guard let self = self else { return }
                    self.updateRefResourceState(.normal(id: resource.id))
                    self.updateMessageData(with: resource)
                },
                onError: { err in
                    Detail.logger.error("transformToResource failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func transformToResource(fromThreadId threadId: String) {
        Detail.logger.info("will transformToResource. threadId: \(threadId)")
        operateApi?.transformThreadAsResources(withThreadId: threadId)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] tuple in
                    Detail.logger.info("transformToResource succeed. resourceId: \(tuple.resourceId)")
                    guard let self = self else { return }
                    self.updateRefResourceState(.normal(id: tuple.resourceId))
                    self.updateMessageData(with: tuple.resource)
                },
                onError: { err in
                    Detail.logger.error("transformToResource failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadRefResource(byId resourceId: String) {
        Detail.logger.info("will loadRefResource. resourceId: \(resourceId)")
        fetchApi?.getTodoRefResources(byIds: [resourceId])
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] resources in
                    Detail.logger.info("loadRefResource succeed")
                    guard let self = self else { return }
                    self.updateMessageData(with: resources.first)
                },
                onError: { err in
                    Detail.logger.error("loadRefResource failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

}
