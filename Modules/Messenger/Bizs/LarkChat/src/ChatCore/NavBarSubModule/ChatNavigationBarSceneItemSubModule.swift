//
//  ChatNavigationBarSceneItemSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2022/11/15.
//

import Foundation
import UIKit
import LarkSceneManager
import UniverseDesignToast
import LarkOpenChat
import LarkModel
import LarkMessageCore
import LarkContainer
import LarkMessengerInterface

public final class ChatNavigationBarSceneItemSubModule: NavigationBarSceneItemSubModule {
    override public func needShowSceneButtonItem() -> Bool {
        if let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode {
            return false
        }
        return super.needShowSceneButtonItem()
    }

    public override func clickSceneItemClicked(sender: UIButton) {
        if #available(iOS 13.0, *) {
            guard let chat = self.chat else { return }
            let targetVC = self.context.chatVC()
            let scene: LarkSceneManager.Scene
            if chat.type == .p2P {
                var userInfo: [String: String] = [:]
                userInfo["chatID"] = "\(chat.id)"
                let key = "P2pChat"
                let windowType = chat.chatter?.type == .bot ? "bot" : "single"
                scene = LarkSceneManager.Scene(
                    key: key,
                    id: chat.chatterId,
                    title: chat.displayName,
                    userInfo: userInfo,
                    sceneSourceID: targetVC.currentSceneID(),
                    windowType: windowType,
                    createWay: "window_click"
                )
            } else {
                var windowType: String = "group"
                if chat.isMeeting {
                    windowType = "event_group"
                } else if !chat.oncallId.isEmpty {
                    windowType = "help_desk"
                }
                scene = LarkSceneManager.Scene(
                    key: "Chat",
                    id: chat.id,
                    title: chat.displayName,
                    sceneSourceID: targetVC.currentSceneID(),
                    windowType: windowType,
                    createWay: "window_click"
                )
            }

            let vc = (self.context.chatVC().children.first as? ChatMessagesViewController) ?? self.context.chatVC()
            SceneManager.shared.active(scene: scene, from: vc) { [weak targetVC] (_, error) in
                if let targetVC = targetVC, error != nil {
                    UDToast.showTips(
                        with: BundleI18n.LarkChat.Lark_Core_SplitScreenNotSupported,
                        on: targetVC.view
                    )
                }
            }
        } else {
            assertionFailure()
        }
    }
    /// 获取要创建的 scene的id
    public override func getSceneId() -> String {
        guard let chat = self.chat else { return "" }
        if chat.type == .p2P {
            return chat.chatterId
        } else {
            return chat.id
        }
    }
    /// 获取要创建的 scene的key
    public override func getSceneKey() -> String {
        guard let chat = self.chat else { return "" }
        if chat.type == .p2P {
            return "P2pChat"
        } else {
            return "Chat"
        }
    }
}
