//
//  ChatKeyboardContext.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2021/12/24.
//

import UIKit
import Foundation
import Swinject
import LarkModel
import RustPB
import RxSwift
import LarkOpenIM
import LarkContainer

public final class ChatKeyboardContext: BaseModuleContext {
    public var disableMyAI: Bool

    public init(parent: Container, store: Store, userStorage: UserStorage, compatibleMode: Bool = false, disableMyAI: Bool = false) {
        self.disableMyAI = disableMyAI
        super.init(parent: parent, store: store, userStorage: userStorage, compatibleMode: compatibleMode)
    }
    
    public var hasRootMessage: Bool {
        return (try? self.resolver.resolve(assert: ChatKeyboardOpenService.self))?.hasRootMessage ?? false
    }

    public var hasReplyMessage: Bool {
        return (try? self.resolver.resolve(assert: ChatKeyboardOpenService.self))?.hasReplyMessage ?? false
    }

    /// 获取定时消息草稿
    public var getScheduleDraft: Observable<RustPB.Basic_V1_Draft?> {
        return (try? self.resolver.resolve(assert: ChatKeyboardOpenService.self))?.getScheduleDraft ?? .empty()
    }

    public func foldKeyboard() {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatKeyboardOpenService.self).foldKeyboard()
        }
    }

    public func refreshMoreItems() {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatKeyboardOpenService.self).refreshMoreItems()
        }
    }

    public func baseViewController() -> UIViewController {
        return (try? self.resolver.resolve(assert: ChatKeyboardOpenService.self))?.baseViewController() ?? UIViewController()
    }

    public func getRootMessage() -> Message? {
        return try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).getRootMessage()
    }

    public func getReplyMessage() -> Message? {
        return try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).getReplyMessage()
    }

    public func clearReplyMessage() {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).clearReplyMessage()
    }

    public func getInputRichText() -> RustPB.Basic_V1_RichText? {
        return try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).getInputRichText()
    }

    public func sendLocation(parentMessage: Message?,
                             screenShot: UIImage,
                             location: LocationContent) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).sendLocation(parentMessage: parentMessage,
                                                                                      screenShot: screenShot,
                                                                                      location: location)
    }

    public func sendUserCard(shareChatterId: String) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).sendUserCard(shareChatterId: shareChatterId)
    }

    public func sendFile(path: String,
                         name: String,
                         parentMessage: Message?) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).sendFile(path: path,
                                                                                  name: name,
                                                                                  parentMessage: parentMessage)
    }

    public func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).sendText(content: content, lingoInfo: lingoInfo, parentMessage: parentMessage)
    }

    public func sendInputContentAsMessage() {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).sendInputContentAsMessage()
    }

    public func insertAtChatter(name: String, actualName: String, id: String, isOuter: Bool) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).insertAtChatter(name: name,
                                                                                         actualName: actualName,
                                                                                         id: id,
                                                                                         isOuter: isOuter)
    }
    
    public func insertUrl(urlString: String) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).insertUrl(urlString: urlString)
    }
    
    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).insertUrl(title: title, url: url, type: type)
    }

    public func onMessengerKeyboardPanelSendLongPress() {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).onMessengerKeyboardPanelSendLongPress()
    }

    public func onMessengerKeyboardPanelScheduleSendTaped(draft: RustPB.Basic_V1_Draft?) {
        try? self.resolver.resolve(assert: ChatKeyboardOpenService.self).onMessengerKeyboardPanelScheduleSendTaped(draft: draft)
    }
}
