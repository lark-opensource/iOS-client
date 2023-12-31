//
//  FileContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/21.
//

import LarkCore
import LarkModel
import LarkContainer
import LarkMessageBase
import LarkMessengerInterface

public final class FileContentActionHandler<C: PageContext>: FileAndFolderContentActionHandler<C> {
    @PageContext.InjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?

    public override func tapAction(
        chat: Chat,
        message: Message,
        isLan: Bool,
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        useLocalChat: Bool,
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool,
        canSaveToDrive: Bool,
        canOfficeClick: Bool
    ) {
        let permissionPreview = context.checkPermissionPreview(chat: chat, message: message)
        if !permissionPreview.0 || !dynamicAuthorityEnum.authorityAllowed {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .file)
            return
        }
        guard let window = self.context.targetVC?.view.window else { return }
        if !canOfficeClick, let content = message.content as? FileContent, isOfficeFile(fileName: content.name) {
            return
        }
        self.context.fileUtilService?.onFileMessageClicked(message: message,
                                                           chat: chat,
                                                           window: window,
                                                           downloadFileScene: self.context.downloadFileScene) { [weak self] in
            self?.open(
                chat: chat,
                message: message,
                useLocalChat: useLocalChat,
                canViewInChat: canViewInChat,
                canForward: canForward,
                canSearch: canSearch,
                canSaveToDrive: canSaveToDrive,
                canOfficeClick: canOfficeClick
            )
        }
    }

    public override func open(
        chat: Chat,
        message: Message,
        useLocalChat: Bool,
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool,
        canSaveToDrive: Bool,
        canOfficeClick: Bool
    ) {
        guard let content = message.content as? FileContent else { return }
        IMTracker.Chat.Main.Click.Msg.File(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        self.chatSecurityAuditService?.auditEvent(.chatPreviewfile(chatId: chat.id,
                                                                   chatType: chat.type,
                                                                   fileId: content.key,
                                                                   fileName: content.name,
                                                                   fileType: (content.name as NSString).pathExtension),
                                                  isSecretChat: false)
        let fileBrowseScene: FileSourceScene = (self.context.scene == .mergeForwardDetail || self.context.scene == .threadPostForwardDetail) ? .mergeForward : .chat
        var localChat: Chat?
        if context.downloadFileScene == .todo || useLocalChat {
            localChat = chat
        }
        func pushVC() {
            let body = MessageFileBrowseBody(
                message: message,
                scene: fileBrowseScene,
                downloadFileScene: context.downloadFileScene,
                chatFromTodo: localChat,
                useLocalChat: useLocalChat,
                canFileClick: canOfficeClick ? nil : { [weak self] fileName in
                    guard let self = self else { return true }
                    return !self.isOfficeFile(fileName: fileName)
                },
                canViewInChat: canViewInChat,
                canForward: canForward,
                canSearch: canSearch,
                canSaveToDrive: canSaveToDrive
            )
            context.navigator(type: .push, body: body, params: nil)
        }
        if let myAiPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self),
           let fromVC = context.pageAPI {
            myAiPageService.onMessageFileTapped(fromVC: fromVC,
                                                message: message,
                                                scene: fileBrowseScene,
                                                downloadFileScene: context.downloadFileScene) {
                pushVC()
            }
        } else {
            pushVC()
        }
    }
}
