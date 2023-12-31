//
//  TopStructureAdapter.swift
//  Lark
//
//  Created by liuwanlin on 2018/4/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkContainer
import LarkModel
import Swinject
import EENavigator
import UniverseDesignToast
import LarkAlertController
import LarkCore
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkGuide
import LarkNavigation
import LarkFeatureGating
import AnimatedTabBar
import LarkTab
import RustPB
import LarkSceneManager
import Homeric
import LKCommonsTracker
import ServerPB
import UniverseDesignDialog
import LKCommonsLogging
import LarkCoreLocation
import CoreLocation
import LarkSetting
import LarkNavigator
import LarkLocalizations
import AppReciableSDK

protocol CreateGroupCommon: AnyObject {
    var userResolver: UserResolver { get }
    var disposeBag: DisposeBag { get }
    // swiftlint:disable function_parameter_count
    func createGroup(
        name: String,
        desc: String,
        fromChatId: String,
        isCrypto: Bool,
        selectedChatIds: [String],
        selectedDepartmentIds: [String],
        selectedChatterIds: [String],
        selectedMessages: [Message],
        messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions],
        linkPageURL: String?,
        isPublic: Bool,
        isPrivateMode: Bool,
        chatMode: Chat.ChatMode
    ) throws -> Observable<CreateChatResult>
    // swiftlint:enable function_parameter_count
    func createDepartmentGroup(departmentId: String) throws -> Observable<Chat>

    func handleCreateGroupError(_ error: Error, from: UIViewController, source: CreateGroupFromWhere) throws
}

private enum CreateGroupSceneForAppReciable: String {
    case main_menu //主界面加号菜单建群
    case individual_chat //单聊同步建群
    case other
}

extension CreateGroupCommon {

    // swiftlint:disable function_parameter_count
    func createGroup(name: String,
                     desc: String,
                     fromChatId: String,
                     isCrypto: Bool,
                     selectedChatIds: [String],
                     selectedDepartmentIds: [String],
                     selectedChatterIds: [String],
                     selectedMessages: [Message],
                     messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions],
                     linkPageURL: String?,
                     isPublic: Bool,
                     isPrivateMode: Bool,
                     chatMode: Chat.ChatMode
        ) throws -> Observable<CreateChatResult> {
        if chatMode == .threadV2 {
            Tracer.trackCreateChannel(from: .chat)
        }
        return try self.userResolver.resolve(assert: ChatService.self)
            .createGroupChat(
                name: name,
                desc: desc,
                chatIds: selectedChatIds,
                departmentIds: selectedDepartmentIds,
                userIds: selectedChatterIds,
                fromChatId: fromChatId,
                messageIds: selectedMessages.map { $0.id },
                messageId2Permissions: messageId2Permissions,
                linkPageURL: linkPageURL,
                isCrypto: isCrypto,
                isPublic: isPublic,
                isPrivateMode: isPrivateMode,
                chatMode: chatMode
        )
    }
    // swiftlint:enable function_parameter_count

    func createDepartmentGroup(departmentId: String) throws -> Observable<Chat> {
        return try self.userResolver.resolve(assert: ChatService.self).createDepartmentGroupChat(departmentId: departmentId)
    }

    func handleCreateGroupError(_ error: Error, from: UIViewController, source: CreateGroupFromWhere) throws {
        guard let window = from.view.window else {
            assertionFailure("缺少Window")
            return
        }
        if let error = error.underlyingError as? APIError {
            switch error.type {
            case .chatMemberHadFull(let message):
                let textType: String
                switch source {
                case .plusMenu:
                    textType = "plus"
                case .internalToExternal:
                    textType = "from_inner_group"
                case .forward:
                    textType = "from_forward"
                case .p2pConfig:
                    textType = "from_p2p"
                default:
                    textType = "none"
                }
                Tracker.post(TeaEvent("im_chat_member_toplimit_view", params: [
                    "text_type": textType
                ]))

                let dialog = UDDialog()
                dialog.setContent(text: message)
                dialog.setTitle(text: BundleI18n.LarkContact.Lark_GroupLimit_GroupSizeExceedLimit_PopupTitle)
                dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_GroupLimit_GroupSizeExceedLimit_OKButton) {
                    Tracker.post(TeaEvent("im_chat_member_toplimit_click", params: [
                        "text_type": textType,
                        "click": "confirm",
                        "target": "none"
                    ]))
                }
                userResolver.navigator.present(dialog, from: from)
            case .createGroupFailed(let message),
                 .notInSameOrganization(let message),
                 .createGroupSigleLetterFailed(let message):
                UDToast.showFailure(with: message, on: window, error: error)
            case .noSecretChatPermission(let message):
                let alertController = LarkAlertController()
                alertController.setContent(text: message)
                alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Sure)

                userResolver.navigator.present(alertController, from: from)
            case .chatMemberHadFullForCertificationTenant(message: let message):
                 let alertController = LarkAlertController()
                 alertController.setContent(text: message)
                 alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_IKnow)
                userResolver.navigator.present(alertController, from: from)
            case .chatMemberHadFullForPay(message: let message):
                try self.userResolver.resolve(assert: UserAPI.self).isSuperAdministrator().asObservable()
                   .subscribe(onNext: { (isAdmin) in
                       Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_VIEW, params: [
                           "function_type": "chat_number_limit",
                           "admin_flag": isAdmin ? "true" : "false"
                       ]))
                   }).disposed(by: self.disposeBag)
                // link目前需要hardcode在端上
                let helpCenterHost = try self.userResolver.resolve(assert: UserGeneralSettings.self).helpDeskBizDomainConfig.helpCenterHost
                let host = helpCenterHost.isEmpty ? "www.feishu.cn" : helpCenterHost
                let lang = LanguageManager.currentLanguage.languageIdentifier
                let urlString = "https://\(host)/hc/\(lang)/articles/360034114413"
                let alertController = LarkAlertController()
                alertController.setContent(text: message)
                alertController.addCancelButton()
                alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Group_UplimitContactSalesButton(),
                                          dismissCompletion: {
                                            if let url = URL(string: urlString), let vc = from.fromViewController {
                                                self.userResolver.navigator.open(url, from: vc)
                                            }
                    guard let userAPI = try? self.userResolver.resolve(assert: UserAPI.self) else { return }
                    userAPI.isSuperAdministrator().asObservable()
                                                .subscribe(onNext: { (isAdmin) in
                                                    Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_CLICK, params: [
                                                        "function_type": "chat_number_limit",
                                                        "admin_flag": isAdmin ? "true" : "false"
                                                    ]))
                                                }).disposed(by: self.disposeBag)
                })
                userResolver.navigator.present(alertController, from: from)
            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                UDToast.showFailure(
                    with: BundleI18n.LarkContact.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                    on: window, error: error
                )
            default:
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_CreateGroupError, on: window, error: error)
            }
        } else {
            UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_CreateGroupError, on: window, error: error)
        }
    }
}

/// 目前用到的地方：
/// 1、单聊建群
/// 2、添加群成员&&有外部成员 -> 需要创建外部群
final class CreateGroupWithRecordHandler: UserTypedRouterHandler, CreateGroupCommon {
    private static let logger = Logger.log(CreateGroupWithRecordHandler.self, category: "IM.CreateGroup")

    private struct PickerResult {
        weak var controller: UIViewController?
        let chatterIds: [String]
        let chatIds: [String]
        let departmentIds: [String]
        let syncMessages: Bool
        let notFriendContacts: [AddExternalContactModel]
    }

    private struct CreateGroupContext {
        let pickerResult: PickerResult
        let createPrivateChat: Bool
    }

    private typealias MessagePickerResult = (messages: [Message], messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions])

    let disposeBag = DisposeBag()
    private lazy var chatAPI: ChatAPI? = {
        return try? userResolver.resolve(assert: ChatAPI.self)
    }()
    @ScopedInjectedLazy private var contactAPI: ContactAPI?

    private var currentChatterId: String {
        return userResolver.userID
    }

    //群上限管控fg
    lazy var imChatGroupMemberManageIsEnable = {
        userResolver.fg.staticFeatureGatingValue(with: "im.chat.group.member.manage")
    }()

    private struct P2PAuthResult {
        let createPrivateChat: Bool
    }

    private func checkP2pAuth(chat: Chat, vc: UIViewController) -> Observable<P2PAuthResult> {
        if !chat.isPrivateMode {
            return .just(P2PAuthResult(createPrivateChat: false))
        }
        let publish = PublishSubject<P2PAuthResult>()
        self.contactAPI?.fetchAuthChattersRequest(
            actionType: .privateChat,
            isFromServer: true,
            chattersAuthInfo: [currentChatterId: ""]
        )
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak vc, weak self] res in
            guard let vc = vc, let `self` = self else { return }
            guard res.authResult.deniedReasons[self.currentChatterId] != nil else {
                publish.onNext(P2PAuthResult(createPrivateChat: true))
                publish.onCompleted()
                return
            }
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkContact.Lark_IM_EncryptedChat_NoPermissionsToCreateEncryptedChat_CreateAnyway_Title)
            alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_IM_EncryptedChat_NoPermissionsToCreateEncryptedChat_CreateAnyway_CancelButton) {
                publish.onCompleted()
            }
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_IM_EncryptedChat_NoPermissionsToCreateEncryptedChat_CreateAnyway_CreateButton) {
                publish.onNext(P2PAuthResult(createPrivateChat: false))
                publish.onCompleted()
            }
            self.userResolver.navigator.present(alertController, from: vc)
        }, onError: { error in
            Self.logger.error("private mode auth fail \(error)")
        }).disposed(by: self.disposeBag)
        return publish
    }

    func handle(_ body: CreateGroupWithRecordBody, req: EENavigator.Request, res: Response) throws {
        guard let chat = try userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        let isMe = self.currentChatterId == chat.chatterId
        let ob: Observable<CreateGroupContext>
        switch body.type {
        case .p2P:
            guard let from = req.context.from()?.fromViewController else {
                assertionFailure("应该提供FromViewController")
                return
            }
            IMTracker.Group.Create.View(group: true, channel: false, history: true, transfer: false, source: "from_p2p")
            ob = self.checkP2pAuth(chat: chat, vc: from)
                .flatMap { [weak self, weak from] authResult -> Observable<CreateGroupContext> in
                    guard let self = self, let from = from else { return .empty() }
                    let createPrivateChat = authResult.createPrivateChat
                    return self.showPicker(chat, from: from, isMe: isMe, createPrivateChat: createPrivateChat)
                        .map { return CreateGroupContext(pickerResult: $0, createPrivateChat: createPrivateChat) }
                }
        case .group:
            guard let controller = body.pickerController else {
                assert(false, "应该提供PickerViewController")
                return
            }
            IMTracker.Group.Create.View(group: true, channel: false, history: true, transfer: false, source: "from_inner_group")
            ob = .just(
                CreateGroupContext(
                    pickerResult: PickerResult(
                        controller: controller,
                        chatterIds: body.selectedChatterIds,
                        chatIds: body.selectedChatIds,
                        departmentIds: body.selectedDepartmentIds,
                        syncMessages: body.syncMessage,
                        notFriendContacts: []
                    ),
                    createPrivateChat: false
                )
            )
        }
        ob.flatMap { [weak self] (context) -> Observable<(CreateGroupContext, MessagePickerResult)> in
            guard let self = self else { return .empty() }
            if self.imChatGroupMemberManageIsEnable {
                return self.newGetMessagePickerObserver(context, chat: chat, body: body, isMe: isMe)
            } else {
                return self.oldGetMessagePickerObserver(context, chat: chat, body: body, isMe: isMe)
            }
        }.subscribe(onNext: { [weak self] (context, resultB) in
            guard let self = self, let controller = context.pickerResult.controller else {
                assertionFailure("can not get controller")
                return
            }
            let resultA = context.pickerResult
            let selectedChatterIds: [String]
            if chat.type == .p2P {
                selectedChatterIds = Array(Set(resultA.chatterIds + [chat.chatterId]))
            } else {
                selectedChatterIds = resultA.chatterIds
            }

            Tracer.trackCreateGroupConfirmed(
                isP2P: chat.type == .p2P,
                isExternal: chat.isCrossTenant,
                isPublic: chat.isPublic,
                isThread: false,
                chatterNumbers: selectedChatterIds.count + Int(chat.userCount)
            )

            guard let ob = try? self.createGroup(
                name: "",
                desc: "",
                fromChatId: chat.id,
                isCrypto: chat.isCrypto,
                selectedChatIds: resultA.chatIds,
                selectedDepartmentIds: resultA.departmentIds,
                selectedChatterIds: selectedChatterIds,
                selectedMessages: resultB.messages,
                messageId2Permissions: resultB.messageId2Permissions,
                linkPageURL: nil,
                isPublic: false,
                isPrivateMode: context.createPrivateChat,
                chatMode: .default
            ) else { return }
            self.handleCreateGroup(ob.map { $0.chat },
                                    chatId: chat.id,
                                    rootVC: controller,
                                    fromType: body.type,
                                    notFriendContacts: resultA.notFriendContacts,
                                    selectedMessagesCount: resultB.messages.count,
                                    selectedMemeberCount: selectedChatterIds.count)

        }).disposed(by: disposeBag)

        res.end(resource: EmptyResource())
    }

    private func newGetMessagePickerObserver(_ context: CreateGroupContext, chat: Chat, body: CreateGroupWithRecordBody, isMe: Bool) -> Observable<(CreateGroupContext, MessagePickerResult)> {
        let result = context.pickerResult
        var pickEntities = [ServerPB_Chats_PickEntities]()
        if !result.chatIds.isEmpty {
            var pickEntity = ServerPB_Chats_PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = result.chatIds
            pickEntities.append(pickEntity)
        }
        if !result.chatterIds.isEmpty {
            var pickEntity = ServerPB_Chats_PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = result.chatterIds
            pickEntities.append(pickEntity)
        }
        if !result.departmentIds.isEmpty {
            var pickEntity = ServerPB_Chats_PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = result.departmentIds
            pickEntities.append(pickEntity)
        }
        let publish = PublishSubject<(CreateGroupContext, MessagePickerResult)>()
        self.chatAPI?.pullChangeGroupMemberAuthorization(pickEntities: pickEntities, chatMode: .default, fromChatId: Int64(chat.id))
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] res in
                guard let self = self, let controller = result.controller else {
                    assertionFailure("can not get controller")
                    publish.onCompleted()
                    return
                }
                if res.pass {
                    //  在和我的单聊需要特化处理只选1人
                    if isMe,
                       result.chatterIds.count == 1,
                       let chatterId = result.chatterIds.first {
                        let from = WindowTopMostFrom(vc: controller)
                        controller.dismiss(animated: true, completion: {
                            let chatBody = ChatControllerByChatterIdBody(
                                chatterId: chatterId,
                                isCrypto: false
                            )
                            self.userResolver.navigator.push(body: chatBody, from: from)
                        })
                        publish.onCompleted()
                    }

                    // code_next_line tag CryptChat
                    if result.syncMessages, !chat.isCrypto, chat.lastMessagePosition >= 0 {
                        guard let controller = result.controller as? UINavigationController else {
                            publish.onCompleted()
                            return
                        }
                        Tracer.trackSingleToGroupSelectMemberConfirm(result.chatterIds.count, false)
                        self.newSyncMessage(chatId: chat.id, controller: controller, onCancel: {
                            publish.onCompleted()
                        }, onFinish: { messages, messageId2Permissions in
                            if body.type == .p2P {
                                Tracer.trackSingleToGroupConfirm(syncMessage: true,
                                                                 selectedCount: messages.count,
                                                                 chatID: chat.id)
                                IMTracker.Group.Create.Click.Confirm(source: "from_p2p",
                                                                     chatType: chat.chatMode == .threadV2 ? "topic" : "group",
                                                                     public: chat.isPublic,
                                                                     isPrivateMode: false,
                                                                     isSycn: result.syncMessages,
                                                                     leaveAMessage: false)
                            } else {
                                IMTracker.Group.Create.Click.Confirm(source: "from_inner_group",
                                                                     chatType: chat.chatMode == .threadV2 ? "topic" : "group",
                                                                     public: chat.isPublic,
                                                                     isPrivateMode: false,
                                                                     isSycn: result.syncMessages,
                                                                     leaveAMessage: false)
                            }
                            publish.onNext((context, (messages, messageId2Permissions)))
                        })
                    } else {
                        Tracer.trackSingleToGroupSelectMemberConfirm(result.chatterIds.count, false)
                        if body.type == .p2P {
                            Tracer.trackSingleToGroupConfirm(syncMessage: false,
                                                             selectedCount: 0,
                                                             chatID: chat.id)
                            IMTracker.Group.Create.Click.Confirm(source: "from_p2p",
                                                                 chatType: chat.chatMode == .threadV2 ? "topic" : "group",
                                                                 public: chat.isPublic,
                                                                 isPrivateMode: false,
                                                                 isSycn: result.syncMessages,
                                                                 leaveAMessage: false)
                        } else {
                            IMTracker.Group.Create.Click.Confirm(source: "from_inner_group",
                                                                 chatType: chat.chatMode == .threadV2 ? "topic" : "group",
                                                                 public: chat.isPublic,
                                                                 isPrivateMode: false,
                                                                 isSycn: result.syncMessages,
                                                                 leaveAMessage: false)
                        }
                        publish.onNext((context, ([], [: ])))
                    }
                } else {
                    let textType: String
                    switch body.type {
                    case .group:
                        textType = "from_inner_group"
                    case .p2P:
                        textType = "from_p2p"
                    }
                    var trackParams: [AnyHashable: Any] = IMTracker.Param.chat(chat)
                    trackParams += ["text_type": textType]
                    Tracker.post(TeaEvent("im_chat_member_toplimit_view", params: trackParams))
                    let alertController = LarkAlertController()
                    alertController.setContent(text: res.msgDescription)
                    alertController.title = BundleI18n.LarkContact.Lark_GroupLimit_GroupSizeExceedLimit_PopupTitle
                    alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_GroupLimit_GroupSizeExceedLimit_OKButton) {
                        var trackParams: [AnyHashable: Any] = IMTracker.Param.chat(chat)
                        trackParams += [
                            "text_type": textType,
                            "click": "confirm",
                            "target": "none"
                        ]
                        Tracker.post(TeaEvent("im_chat_member_toplimit_click", params: trackParams))
                    }
                    self.userResolver.navigator.present(alertController, from: controller)
                    publish.onCompleted()
                }
            } onError: { error in
                if let controller = result.controller {
                    UDToast.showFailureIfNeeded(on: controller.view, error: error)
                }
                publish.onCompleted()
            }
        return publish.do()
    }

    private func oldGetMessagePickerObserver(_ context: CreateGroupContext, chat: Chat, body: CreateGroupWithRecordBody, isMe: Bool) -> Observable<(CreateGroupContext, MessagePickerResult)> {
        let result = context.pickerResult
        //  在和我的单聊需要特化处理只选1人
        if isMe,
           result.chatterIds.count == 1,
           let chatterId = result.chatterIds.first {
            guard let controller = result.controller else {
                assertionFailure("can not get controller")
                return .empty()
            }
            let from = WindowTopMostFrom(vc: controller)
            controller.dismiss(animated: true, completion: { [weak self] in
                guard let `self` = self else { return }
                let chatBody = ChatControllerByChatterIdBody(
                    chatterId: chatterId,
                    isCrypto: false
                )
                self.userResolver.navigator.push(body: chatBody, from: from)
            })
            return .empty()
        }

        // code_next_line tag CryptChat
        if result.syncMessages, !chat.isCrypto, chat.lastMessagePosition >= 0 {
            guard let controller = result.controller as? UINavigationController else { return .empty() }
            Tracer.trackSingleToGroupSelectMemberConfirm(result.chatterIds.count, false)
            return self.oldSyncMessage(chatId: chat.id, controller: controller)
                .map { (context, $0) }
                .do(onNext: { (_, resultB) in
                    if body.type == .p2P {
                        Tracer.trackSingleToGroupConfirm(syncMessage: true,
                                                         selectedCount: resultB.messages.count,
                                                         chatID: chat.id)
                        IMTracker.Group.Create.Click.Confirm(source: "from_p2p",
                                                             chatType: chat.chatMode == .threadV2 ? "topic" : "group",
                                                             public: chat.isPublic,
                                                             isPrivateMode: false,
                                                             isSycn: result.syncMessages,
                                                             leaveAMessage: false)
                    }
                })
        } else {
            Tracer.trackSingleToGroupSelectMemberConfirm(result.chatterIds.count, false)
            if body.type == .p2P {
                Tracer.trackSingleToGroupConfirm(syncMessage: false,
                                                 selectedCount: 0,
                                                 chatID: chat.id)
                IMTracker.Group.Create.Click.Confirm(source: "from_p2p",
                                                     chatType: chat.chatMode == .threadV2 ? "topic" : "group",
                                                     public: chat.isPublic,
                                                     isPrivateMode: false,
                                                     isSycn: result.syncMessages,
                                                     leaveAMessage: false)
            }
            return .just((context, ([], [: ])))
        }
    }

    private func handleCreateGroup(_ observable: Observable<Chat>?,
                                   chatId: String,
                                   rootVC: UIViewController,
                                   fromType: CreateGroupWithRecordBody.FromType,
                                   notFriendContacts: [AddExternalContactModel],
                                   selectedMessagesCount: Int,
                                   selectedMemeberCount: Int) {
            guard let observable = observable else { return }

            guard let window = rootVC.view.window else {
                assertionFailure("缺少Window")
                return
            }
            var create_group_scene: CreateGroupSceneForAppReciable = .other
            switch fromType {
            case .p2P:
                create_group_scene = .individual_chat
            default:
                break
            }
            let hud = UDToast.showLoading(with: BundleI18n.LarkContact.Lark_Legacy_CreatingGroup, on: window, disableUserInteraction: true)
            let start = Date()
            observable.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak rootVC, weak self] (chat) in
                    hud.remove()
                    guard let rootVC = rootVC, let `self` = self else { return }
                    let from = WindowTopMostFrom(vc: rootVC)
                    let cost = Int64(Date().timeIntervalSince(start) * 1000)
                    rootVC.dismiss(animated: true, completion: {
                        let createGroupWay: CreateGroupToChatInfo.CreateGroupWay
                        switch fromType {
                        case .group:
                            createGroupWay = .create_external_group
                            Tracer.trackCreateGroupSuccess(chat: chat, from: .internalToExternal)
                        case .p2P:
                            createGroupWay = .single_chat_to_group
                            Tracer.trackCreateGroupSuccess(chat: chat, from: .p2pConfig)
                        }
                        let createGroupToChatInfo = CreateGroupToChatInfo(way: createGroupWay,
                                                                          syncMessage: selectedMessagesCount == 0 ? false : true,
                                                                          messageCount: selectedMessagesCount,
                                                                          memberCount: selectedMemeberCount,
                                                                          cost: cost)
                        let body = ChatControllerByChatBody(chat: chat,
                                                            fromWhere: .profile,
                                                            extraInfo: [CreateGroupToChatInfo.key: createGroupToChatInfo])

                        var params = NaviParams()
                        params.switchTab = Tab.feed.url
                        let showAlert = {
                            self.presentAddContactAlert(chatId: chatId, isNotFriendContacts: notFriendContacts, from: from)
                        }
                        if Display.pad {
                            // iPad 多 scene 场景建群激活主 scene 建群
                            let context: [String: Any] = [
                                FeedSelection.contextKey: FeedSelection(feedId: chat.id,
                                                                        selectionType: .skipSame)
                            ]
                            if #available(iOS 13.0, *),
                               SceneManager.shared.supportsMultipleScenes,
                               let sceneInfo = from.fromViewController?.currentScene()?.sceneInfo,
                               !sceneInfo.isMainScene() {
                                SceneManager.shared.active(scene: Scene.mainScene(), from: rootVC) { [weak rootVC] (window, error) in
                                    if let window = window {
                                        self.userResolver.navigator.showDetail(body: body,
                                                                    naviParams: params,
                                                                    context: context,
                                                                    wrap: LkNavigationController.self,
                                                                    from: window) { (_, _) in
                                                                        showAlert()
                                        }
                                    } else if error != nil {
                                        if let rootVC = rootVC {
                                            UDToast.showTips(
                                                with: BundleI18n.LarkContact.Lark_Core_SplitScreenNotSupported,
                                                on: rootVC.view
                                            )
                                        }
                                    }
                                }
                            } else {
                                self.userResolver.navigator.showDetail(body: body,
                                                            naviParams: params,
                                                            context: context,
                                                            wrap: LkNavigationController.self,
                                                            from: from) { (_, _) in
                                                                showAlert()
                                }
                            }
                        } else {
                            self.userResolver.navigator.push(body: body, naviParams: params, from: from) { (_, _) in
                                showAlert()
                            }
                        }
                        AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                              scene: .Chat,
                                                                              eventable: CreateGroupEvent.createGroupChat,
                                                                              cost: Int(cost),
                                                                              page: nil,
                                                                              extra: Extra(isNeedNet: true,
                                                                                           category: ["create_group_scene": create_group_scene.rawValue])))
                    })
                }, onError: { [weak self, weak rootVC] (error) in
                    hud.remove()
                    guard let self = self else { return }
                    if let vc = rootVC {
                        try? self.handleCreateGroupError(error, from: vc, source: fromType == .p2P ? .p2pConfig : .internalToExternal)
                        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                        scene: .Chat,
                                                                        eventable: CreateGroupEvent.createGroupChat,
                                                                        errorType: .SDK,
                                                                        errorLevel: .Fatal,
                                                                        errorCode: (error as NSError).code,
                                                                        userAction: nil,
                                                                        page: nil,
                                                                        errorMessage: (error as NSError).description,
                                                                        extra: Extra(isNeedNet: true,
                                                                                     category: ["create_group_scene": create_group_scene.rawValue])))
                    }
                }).disposed(by: self.disposeBag)
    }

    private func presentAddContactAlert(chatId: String,
                                        isNotFriendContacts: [AddExternalContactModel],
                                        from: NavigatorFrom) {
        guard !isNotFriendContacts.isEmpty else { return }
        // 人数为1使用单人alert
        if isNotFriendContacts.count == 1 {
            let contact = isNotFriendContacts[0]
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chatId
            let addContactBody = AddContactApplicationAlertBody(userId: isNotFriendContacts[0].ID,
                                                                chatId: chatId,
                                                                source: source,
                                                                displayName: contact.name,
                                                                targetVC: from.fromViewController,
                                                                businessType: .groupConfirm)
            userResolver.navigator.present(body: addContactBody, from: from)
            return
        }
        // 人数大于1使用多人alert
        let dependecy = MSendContactApplicationDependecy(source: .chat)
        let addContactApplicationAlertBody = MAddContactApplicationAlertBody(
                                contacts: isNotFriendContacts,
                                source: .createGroup,
                                dependecy: dependecy,
                                businessType: .groupConfirm)
        userResolver.navigator.present(body: addContactApplicationAlertBody, from: from)
    }

    // 调用选人，并解析结果
    private func showPicker(_ chat: Chat, from: UIViewController, isMe: Bool, createPrivateChat: Bool) -> Observable<PickerResult> {
        let publish = PublishSubject<PickerResult>()
        let currentChatterId = currentChatterId

        var body = ChatterPickerBody()
        body.isCrossTenantChat = chat.isCrossTenant
        body.needSearchOuterTenant = !createPrivateChat
        body.source = .p2p
        body.checkInvitePermission = true
        if !chat.isCrypto {
            body.supportSelectGroup = true
            body.supportSelectOrganization = true
            body.checkGroupPermissionForInvite = true
            body.checkOrganizationPermissionForInvite = !userResolver.fg.staticFeatureGatingValue(with: "im.chat.depart_group_permission")
        }
        body.isCryptoModel = chat.isCrypto
        // code_next_line tag CryptChat
        if chat.isCrypto ||
            isMe ||
            (chat.isPrivateMode && !createPrivateChat) {
            body.toolbarClass = nil
        } else {
            body.toolbarClass = SyncMessageToolbar.self
            let resolver = self.resolver
            SyncMessageToolbar.guideService = { try? resolver.resolve(assert: GuideService.self) }
        }
        body.dataOptions = [.external]
        body.title = BundleI18n.LarkContact.Lark_Legacy_ConversationStartGroupChat
        body.supportCustomTitleView = true
        body.supportUnfoldSelected = true
        body.allowDisplaySureNumber = false
        body.forceSelectedChatterIds = [chat.chatterId, currentChatterId]
        body.selectedCallback = { controller, result in
            guard let controller = controller else { return }

            let notFriendContacts = result.chatterInfos
                .filter { $0.isNotFriend }
                .map { info in
                    AddExternalContactModel(
                        ID: info.ID,
                        name: info.name,
                        avatarKey: info.avatarKey
                    )
                }
            let isFriendContacts = result.chatterInfos.filter { !$0.isNotFriend }
            let chatterIDs = isFriendContacts.map { $0.ID }
//            chatAPI.pullChangeGroupMemberAuthorization(pickEntities: ,
//                                                       chatMode: ServerPB_Entities_Chat.ChatMode?,
//                                                       fromChatId: Int64?)
            publish.onNext(
                PickerResult(
                    controller: controller,
                    chatterIds: chatterIDs,
                    chatIds: result.chatInfos.map { $0.id },
                    departmentIds: result.departmentIds,
                    syncMessages: result.extra as? Bool ?? false,
                    notFriendContacts: notFriendContacts
                )
            )
        }
        body.cancelCallback = { publish.onCompleted() }

        userResolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        return publish
    }

    private func newSyncMessage(chatId: String, controller: UINavigationController,
                             onCancel: @escaping (() -> Void), onFinish: @escaping (([Message], [String: RustPB.Im_V1_CreateChatRequest.DocPermissions]) -> Void)) {
        var body = MessagePickerBody(chatId: chatId)
        body.cancel = { [weak controller] disappearReason in
            if disappearReason == .cancelBtnClick {
                controller?.popViewController(animated: true)
                onCancel()
            }
        }
        body.finish = { (messages, messageId2Permissions) in
            onFinish(messages, messageId2Permissions)
        }
        userResolver.navigator.push(body: body, from: controller)
    }

    private func oldSyncMessage(chatId: String, controller: UINavigationController) -> Observable<MessagePickerResult> {
        let publish = PublishSubject<MessagePickerResult>()
        var body = MessagePickerBody(chatId: chatId)
        body.cancel = { [weak controller] disappearReason in
            if disappearReason == .cancelBtnClick {
                controller?.popViewController(animated: true)
                publish.onCompleted()
            }
        }
        body.finish = { (messages, messageId2Permissions) in
            publish.onNext((messages, messageId2Permissions))
        }
        userResolver.navigator.push(body: body, from: controller)
        return publish

    }
}

/// 目前用到的地方：
/// 1、首页 -> 右上角创建群组
/// 2、转发 -> 创群
/// 3、广场 -> 创群
final class CreateGroupHandler: UserTypedRouterHandler, CreateGroupCommon {
    let disposeBag = DisposeBag()

    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    func handle(_ body: CreateGroupBody, req: EENavigator.Request, res: Response) throws {
        switch body.from {
        case .plusMenu:
            Tracer.trackOpenPickerView(.plus)
        case .forward:
            Tracer.trackOpenPickerView(.forward)
        default:
            break
        }
        var pickBody = CreateGroupPickBody()
        pickBody.from = body.from
        pickBody.isShowGroup = body.isShowGroup
        pickBody.canCreateSecretChat = body.canCreateSecretChat
        pickBody.canCreateThread = body.canCreateThread
        pickBody.canCreatePrivateChat = body.canCreatePrivateChat
        pickBody.needSearchOuterTenant = body.needSearchOuterTenant
        pickBody.forceSelectedChatterIds = [currentUserId]
        pickBody.targetPreview = userResolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "core.forward.target_preview"))

        pickBody.createConfirmButtonTitle = body.createConfirmButtonTitle
        pickBody.title = body.title
        pickBody.selectCallback = { [weak self] (context, result, vc) in
            guard let `self` = self else { return }
            switch result {
            case .department(let departmentId):
                guard let ob = try? self.createDepartmentGroup(departmentId: departmentId) else { return }
                self.createGroupBlock(body.createGroupBlock, from: body.from, observable: ob.map { CreateChatResult(chat: $0, pageLinkResult: nil) }, context: context, vc: vc, notFriendCotacts: [])
            case .pickEntities(let pickEntities):
                let notFriendCotacts = pickEntities.chatters
                    .filter { $0.isNotFriend }
                    .map { info in
                        AddExternalContactModel(
                            ID: info.ID,
                            name: info.name,
                            avatarKey: info.avatarKey
                        )
                    }
                let isFriendContacts = pickEntities.chatters.filter { !$0.isNotFriend }
                let chatterIDs = isFriendContacts.map { $0.ID }
                guard let ob = try? self.createGroup(
                    name: context?.name ?? "",
                    desc: context?.desc ?? "",
                    fromChatId: "",
                    isCrypto: context?.isCrypto ?? false,
                    selectedChatIds: pickEntities.chats,
                    selectedDepartmentIds: pickEntities.departments,
                    selectedChatterIds: chatterIDs,
                    selectedMessages: [],
                    messageId2Permissions: [:],
                    linkPageURL: body.linkPageURL,
                    isPublic: context?.isPublic ?? false,
                    isPrivateMode: context?.isPrivateMode ?? false,
                    chatMode: context?.chatMode ?? .default
                ) else { return }
                self.createGroupBlock(body.createGroupBlock, from: body.from, observable: ob, context: context, vc: vc, notFriendCotacts: notFriendCotacts)
            }
        }

        res.redirect(body: pickBody)
    }

    private func createGroupBlock(_ createGroupBlock: ((_: Chat?,
                                                        _: UIViewController,
                                                        _ cost: Int64,
                                                        _ notFriendContacts: [AddExternalContactModel],
                                                        _ pageLinkResult: Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void)?,
                                  from: CreateGroupFromWhere,
                                  observable: Observable<CreateChatResult>,
                                  context: CreateGroupContext?,
                                  vc: UIViewController,
                                  notFriendCotacts: [AddExternalContactModel]) {

        guard let window = vc.view.window else {
            assertionFailure("缺少Window")
            return
        }
        var create_group_scene: CreateGroupSceneForAppReciable = .other
        switch from {
        case .plusMenu:
            create_group_scene = .main_menu
        default:
            break
        }
        let hud = UDToast.showLoading(with: BundleI18n.LarkContact.Lark_Legacy_CreatingGroup, on: window, disableUserInteraction: true)
        let start = Date()
        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak vc] (result) in
                let chat = result.chat
                hud.remove()
                Tracer.trackCreateGroupSuccess(chat: chat, from: from)
                let cost = Int64(Date().timeIntervalSince(start) * 1000)
                if let vc = vc {
                    createGroupBlock?(chat, vc, cost, notFriendCotacts, result.pageLinkResult)
                }

                var modeType = "classic"
                if chat.isCrypto {
                    modeType = "secret"
                } else if chat.type == .topicGroup {
                    modeType = "topic"
                }
                Tracer.tarckCreateGroup(chatID: chat.id,
                                        isCustom: context?.name.isEmpty ?? false,
                                        isExternal: context?.isExternal ?? false,
                                        isPublic: context?.isPublic ?? false,
                                        modeType: modeType,
                                        count: context?.count ?? 0)
                AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                      scene: .Chat,
                                                                      eventable: CreateGroupEvent.createGroupChat,
                                                                      cost: Int(cost),
                                                                      page: nil,
                                                                      extra: Extra(isNeedNet: true,
                                                                                   category: ["create_group_scene": create_group_scene.rawValue])))
            }, onError: { [weak self, weak vc] (error) in
                hud.remove()
                guard let self = self else { return }
                if let vc = vc {
                    try? self.handleCreateGroupError(error, from: vc, source: from)
                }
                AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                scene: .Chat,
                                                                eventable: CreateGroupEvent.createGroupChat,
                                                                errorType: .SDK,
                                                                errorLevel: .Fatal,
                                                                errorCode: (error as NSError).code,
                                                                userAction: nil,
                                                                page: nil,
                                                                errorMessage: (error as NSError).description,
                                                                extra: Extra(isNeedNet: true,
                                                                             category: ["create_group_scene": create_group_scene.rawValue])))
            }).disposed(by: self.disposeBag)
    }
}

/// 目前用到的地方：
/// 1：联系人 -> 组织架构 -> 部门信息 -> 创建部门群
final class CreateDepartmentGroupHandler: UserTypedRouterHandler, CreateGroupCommon {
    let disposeBag = DisposeBag()

    func handle(_ body: CreateDepartmentGroupBody, req: EENavigator.Request, res: Response) throws {
        var hud: UDToast?
        if let window = req.from.fromViewController?.view.window {
            hud = UDToast.showLoading(with: BundleI18n.LarkContact.Lark_Legacy_CreatingGroup, on: window, disableUserInteraction: true)
        }
        try self.createDepartmentGroup(departmentId: body.departmentId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                hud?.remove()
                body.successCallBack?(chat)
            }, onError: { [weak self] (error) in
                hud?.remove()
                guard let `self` = self, let from = req.context.from()?.fromViewController else { return }
                try? self.handleCreateGroupError(error, from: from, source: .unknown)
            }).disposed(by: self.disposeBag)
        res.end(resource: EmptyResource())
    }
}

/// 面对面建群
final class CreateGroupWithFaceToFaceHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()

    func handle(_ body: CreateGroupWithFaceToFaceBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let faceToFaceApplicants = try userResolver.userPushCenter.observable(for: PushFaceToFaceApplicants.self)
        let authorization = try self.userResolver.resolve(assert: LocationAuthorization.self)
        let request = SingleLocationRequest(desiredAccuracy: 80.0,
                                            desiredServiceType: .aMap,
                                                    timeout: 5,
                                                    cacheTimeout: 10)
        let locationTask = try self.userResolver.resolve(assert: SingleLocationTask.self, argument: request)
        let viewModel = FaceToFaceCreateGroupViewModel(pushFaceToFaceApplicants: faceToFaceApplicants, authorization: authorization, locationTask: locationTask, resolver: userResolver)
        switch body.type {
        case .createGroup:
            Tracer.faceToFaceCreateChat()
        case .externalContact:
            Tracer.contactFaceToFaceCreateChat()
        }
        let vc = FaceToFaceCreateGroupViewController(viewModel: viewModel, fromType: body.type, resolver: userResolver)
        res.end(resource: vc)
    }
}

private enum CreateGroupEvent: ReciableEventable {
    case createGroupChat
    var eventKey: String {
        switch self {
        case .createGroupChat:
            return "create_group_chat"
        }
    }
}
