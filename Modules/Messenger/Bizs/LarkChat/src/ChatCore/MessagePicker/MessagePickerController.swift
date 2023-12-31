//
//  MessagePickerController.swift
//  LarkChat
//
//  Created by liuwanlin on 2019/7/10.
//

import UIKit
import Foundation
import SnapKit
import LarkModel
import RxSwift
import RustPB
import ServerPB
import UniverseDesignToast
import LarkFeatureGating
import LarkSDKInterface
import LarkContainer
import LarkMessageBase
import LarkMessengerInterface

typealias ChatMessagePickerCancelHandler = ((MessagePickerCancelReason) -> Void)?
typealias ChatMessagePickerFinishHandler = (([LarkModel.Message], [String: RustPB.Im_V1_CreateChatRequest.DocPermissions]) -> Void)?

final class ChatMessagePickerAbility: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var docAPI: DocAPI?
    @ScopedInjectedLazy private var messageAPI: MessageAPI?

    private let finish: ChatMessagePickerFinishHandler
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver, finish: ChatMessagePickerFinishHandler) {
        self.userResolver = userResolver
        self.finish = finish
    }

    private func getDocToMessageIds(_ messagesWithDocs: [LarkModel.Message]) -> [RustPB.Basic_V1_Doc: [String]] {
        var docToMessageIds: [RustPB.Basic_V1_Doc: [String]] = [:]
        messagesWithDocs.forEach { (message) in
            message.docs?.forEach({ (arg) in
                let (_, doc) = arg
                if docToMessageIds[doc] == nil {
                    docToMessageIds[doc] = [message.id]
                } else {
                    var messageIds = docToMessageIds[doc]
                    messageIds?.append(message.id)
                    docToMessageIds[doc] = messageIds
                }
            })
        }
        return docToMessageIds
    }

    func finishSelectMessage(selectedMessageContexts: [ChatSelectedMessageContext],
                             targetVC: UIViewController,
                             ignoreDocAuth: Bool) {
        var hud: UDToast?

        let selectedMessagesObservable: Observable<[LarkModel.Message]> = Observable.create { [weak self, weak targetVC] (observer) -> Disposable in
            guard let self = self, let targetVC = targetVC else { return Disposables.create() }

            var selectedInMemory: [LarkModel.Message] = [] /// 记录在内存中的选中消息
            var selectedNotInMemory: [String] = [] /// 记录未在内存中的选中消息
            selectedMessageContexts.forEach { (context) in
                if let message = context.message {
                    selectedInMemory.append(message)
                    return
                }
                selectedNotInMemory.append(context.id)
            }
            /// 所选消息都在内存中
            if selectedNotInMemory.isEmpty {
                observer.onNext(selectedInMemory)
                observer.onCompleted()
                return Disposables.create()
            }

            let completionHanler = {
                observer.onNext(selectedInMemory)
                observer.onCompleted()
            }
            /// 尝试去获取不在内存中的消息
            hud = UDToast.showLoading(on: targetVC.view, disableUserInteraction: true)
            self.messageAPI?
                .fetchMessagesMap(ids: selectedNotInMemory, needTryLocal: true)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { messagesMap in
                    observer.onNext(selectedInMemory + Array(messagesMap.values))
                    observer.onCompleted()
                }, onError: { _ in
                    completionHanler()
                }, onCompleted: {
                    completionHanler()
                }, onDisposed: {
                    completionHanler()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }

        if ignoreDocAuth {
            skipPermissionAuth(selectedMessagesObservable: selectedMessagesObservable,
                                     targetVC: targetVC,
                                     hud: hud)
            return
        }

        docPermissionAuthWithURLPreview(selectedMessagesObservable: selectedMessagesObservable,
                                        targetVC: targetVC,
                                        hud: hud)
    }

    private func skipPermissionAuth(selectedMessagesObservable: Observable<[LarkModel.Message]>,
                                          targetVC: UIViewController,
                                          hud: UDToast?) {
        selectedMessagesObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedMessages in
                self?.finish?(selectedMessages, [:])
            }).disposed(by: self.disposeBag)
    }

    private func docPermissionAuthWithURLPreview(selectedMessagesObservable: Observable<[LarkModel.Message]>,
                                                 targetVC: UIViewController,
                                                 hud: UDToast?) {
        var hud = hud
        selectedMessagesObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak targetVC] selectedMessages in
                guard let self = self, let targetVC = targetVC else { return }
                // 为了兼容旧消息，需要同时判断docEntity数据
                let messagesWithDoc = selectedMessages.filter({ $0.isIncludeDocURL || $0.docs != nil })
                let messageIDs = messagesWithDoc.map({ $0.id })
                if messageIDs.isEmpty {
                    hud?.remove()
                    self.finish?(selectedMessages, [:])
                    return
                }
                if hud == nil {
                    hud = UDToast.showLoading(on: targetVC.view, disableUserInteraction: true)
                }
                self.docAPI?.pullMessageDocPermissions(messageIds: messageIDs)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self, weak targetVC] response  in
                        guard let self = self, let targetVC = targetVC else { return }
                        if response.docPerms.isEmpty {
                            ChatMessagePickerController.logger.error("pullMessageDocPermissions with empty perms",
                                                                     additionalData: [ "messageIds": messageIDs.joined(separator: ",")])
                        }
                        hud?.remove()
                        let docCellProps = response.docPerms.compactMap { self.transformToPermCellVM(docInfo: $0) }
                        if docCellProps.isEmpty {
                            self.finish?(selectedMessages, [:])
                            return
                        }
                        let permissionVCModel = DocsPermissionVCModel(docPermissions: docCellProps)
                        let docPermissionVC = DocsPermissionViewController(props: permissionVCModel)
                        docPermissionVC.show(
                            rootVC: targetVC.navigationController ?? UIViewController(),
                            isHeightHalf: false,
                            selectedCompletion: { [weak self] (permissionMap) in
                                self?.finish?(selectedMessages, permissionMap)
                            }
                        )
                    }, onError: { [weak targetVC] error in
                        guard let targetVC = targetVC else { return }
                        hud?.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_DocsPermissionLoadFail,
                                         on: targetVC.view,
                                         error: error)
                    })
                    .disposed(by: self.disposeBag)
            }).disposed(by: self.disposeBag)
    }

    private func transformToPermCellVM(docInfo: ServerPB_Messages_PullMessageDocPermsResponse.DocPerm) -> DocsPermissionCellModel? {
        var maxPermission: Basic_V1_DocPermission.Permission?
        if let permission = docInfo.permissions.first(where: { $0.permCode == Int32(UpdateDocPermissionRequest.Permission.edit.rawValue) }) {
            maxPermission = Basic_V1_DocPermission.Permission()
            if permission.hasPermCode {
                maxPermission?.code = permission.permCode
            }
            if permission.hasPermName {
                maxPermission?.name = permission.permName
            }
        } else if let permission = docInfo.permissions.first(where: { $0.permCode == Int32(UpdateDocPermissionRequest.Permission.read.rawValue) }) {
            maxPermission = Basic_V1_DocPermission.Permission()
            if permission.hasPermCode {
                maxPermission?.code = permission.permCode
            }
            if permission.hasPermName {
                maxPermission?.name = permission.permName
            }
        }
        if let maxPerm = maxPermission {
            var doc = Basic_V1_Doc()
            if docInfo.hasDocTitle {
                doc.name = docInfo.docTitle
            }
            if docInfo.hasDocType {
                doc.type = docInfo.docTypeToPB
            }
            if docInfo.hasDocURL {
                doc.url = docInfo.docURL
            }
            if docInfo.hasOwnerName {
                doc.ownerName = docInfo.ownerName
            }
            return DocsPermissionCellModel(messageIds: docInfo.messageIds, doc: doc, permission: maxPerm)
        }
        return nil
    }
}

extension ServerPB_Messages_PullMessageDocPermsResponse.DocPerm {
    var docTypeToPB: Basic_V1_Doc.TypeEnum {
        switch docType {
        case .unknownDocType: return .unknown
        case .doc: return .doc
        case .sheet: return .sheet
        case .bitable: return .bitable
        case .mindnote: return .mindnote
        case .file: return .file
        case .slide: return .slide
        case .wiki: return .wiki
        case .docx: return .docx
        case .folder: return .folder
        case .catalog: return .catalog
        case .slides: return .slides
        case .shortcut: return .unknown
        @unknown default: return .unknown
        }
    }
}

final class ChatMessagePickerController: ChatMessagesViewController {
    var cancel: ChatMessagePickerCancelHandler = nil
    var finish: ChatMessagePickerFinishHandler = nil
    var ignoreDocAuth: Bool = false

    override func generateBottomLayout() -> BottomLayout {
        return MessagePickerBottomLayout(userResolver: self.userResolver,
                                         containerViewController: self,
                                         cancel: self.cancel,
                                         finish: self.finish,
                                         ignoreDocAuth: self.ignoreDocAuth,
                                         pickedMessages: self.chatMessageViewModel.pickedMessages)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.cancel?(.viewWillDisappear)
        super.viewWillDisappear(animated)
    }
}
