//
//  FolderContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/21.
//

import LarkCore
import LarkModel
import LarkContainer
import LarkMessageBase
import LarkMessengerInterface
import LarkUIKit
import LarkSceneManager

public final class FolderContentActionHandler<C: PageContext>: FileAndFolderContentActionHandler<C> {
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
        self.context.fileUtilService?.onFolderMessageClicked(message: message,
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

    // 是否有预览权限
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
        IMTracker.Chat.Main.Click.Msg.Folder(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        guard !chat.isCrypto else {
            assertionFailure("not support folder")
            return
        }
        var localChat: Chat?
        if context.downloadFileScene == .todo || useLocalChat {
            localChat = chat
        }

        let scene: FileSourceScene
        switch self.context.scene {
        case .mergeForwardDetail:
            scene = .mergeForward
        case .pin:
            scene = .pin
        default:
            scene = .chat
        }

        func pushVC() {
            let body = FolderManagementBody(
                message: message,
                messageId: nil,
                scene: scene,
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
        if let myAiPageService = try? context.userResolver.resolve(type: MyAIPageService.self),
           let fromVC = context.targetVC {
            myAiPageService.onMessageFolderTapped(fromVC: fromVC,
                                                  message: message,
                                                  scene: scene,
                                                  downloadFileScene: context.downloadFileScene) {
                pushVC()
            }
        } else {
            pushVC()
        }
    }
}
