//
//  PageContext+Extensions.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/4.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkMessageBase
import LarkMessengerInterface
import TangramService
import LarkFoundation
import LarkExtensions
import LarkSDKInterface
import LarkUIKit

extension PageContext {
    public func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.dataSourceAPI?.filter(predicate) ?? []
    }

    public func getDisplayName(chatter: Chatter, chat: Chat, scene: GetChatterDisplayNameScene) -> String {
        guard chat.oncallId.isEmpty else { return chatter.name }
        return chatter.displayName(chatId: chat.id, chatType: chat.type, scene: scene)
    }

    //code_block_start tag CryptChat
    public func isBurned(message: Message) -> Bool {
        return (try? resolver.resolve(assert: MessageBurnService.self, cache: true).isBurned(message: message)) ?? false
    }
    //code_block_end

    public var maxCellWidth: CGFloat {
        return self.dataSourceAPI?.hostUIConfig.size.width ?? 0
    }

    public func isMe(_ chatterID: String) -> Bool {
        return self.currentChatterID == chatterID
    }

    public func isMe(_ chatterID: String, chat: Chat) -> Bool {
        let anonymousId = chat.anonymousId
        return self.currentChatterID == chatterID || (!anonymousId.isEmpty && anonymousId == chatterID)
    }
    // 获取是否拥有预览权限
    public func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?) {
        return (try? resolver.resolve(assert: ChatSecurityControlService.self, cache: true).checkPermissionPreview(anonymousId: chat.anonymousId, message: message)) ?? (true, nil)
    }
    // 获取是否拥有预览权限和接收权限
    public func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState {
        return (try? resolver.resolve(assert: ChatSecurityControlService.self, cache: true).checkPreviewAndReceiveAuthority(chat: chat, message: message)) ?? .allow
    }
    // 接收权限或预览权限被拒绝时弹窗
    public func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType) {
        let service = try? resolver.resolve(assert: ChatSecurityControlService.self, cache: true)
        let from = self.targetVC
        if let receiveAuthResult = receiveAuthResult,
           !receiveAuthResult.authorityAllowed {
            //优先对接收权限弹窗
            service?.alertForDynamicAuthority(event: .receive, result: receiveAuthResult, from: from)
            return
        }

        let event: SecurityControlEvent
        switch resourceType {
        case .file:
            event = .localFilePreview
        case .image:
            event = .localImagePreview
        case .video:
            event = .localVideoPreview
        }
        service?.authorityErrorHandler(event: event, authResult: previewAuthResult, from: from, errorMessage: nil, forceToAlert: true)
    }

    public func getRowLayoutDirection(_ chatterID: String, chat: Chat) -> FlexDirection {
        let flexDirection: FlexDirection
        if dataSourceAPI?.supportAvatarLeftRightLayout ?? false,
           isMe(chatterID, chat: chat) {
            flexDirection = .rowReverse
        } else {
            flexDirection = .row
        }
        return flexDirection
    }

    public func getSummerize(_ content: MergeForwardContent,
                             fontColor: UIColor,
                             urlPreviewProvider: ((String, [NSAttributedString.Key: Any], Message) -> (NSMutableAttributedString?, String?)?)?) -> NSAttributedString? {
        guard let summerizeRegistry = pageContainer.resolve(MetaModelSummerizeRegistry.self) else {
            return nil
        }

        let strs: [NSAttributedString] = content.messages.prefix(5).compactMap { (message) -> NSAttributedString? in
            guard let chatter = content.chatters[message.fromId] else {
                return nil
            }
            return summerizeRegistry.getSummerize(
                message: message,
                chatterName: chatter.name,
                fontColor: fontColor,
                urlPreviewProvider: { elementID, customAttributes in
                    return urlPreviewProvider?(elementID, customAttributes, message)
                }
            )
        }
        let str = (strs.reduce(NSMutableAttributedString(string: ""), { (a, b) in
            // 去除富文本里面的换行符
            let mutableAttributedString = NSMutableAttributedString(attributedString: b)
            mutableAttributedString.mutableString.replaceOccurrences(
                of: "\n",
                with: "",
                options: [],
                range: NSRange(location: 0, length: mutableAttributedString.length)
            )
            a.append(mutableAttributedString)
            a.append(NSAttributedString(string: "\n"))
            return a
        }) as NSAttributedString)
        return str.lf.trimmedAttributedString(
            set: .whitespacesAndNewlines,
            position: .trail
        )
    }
}
