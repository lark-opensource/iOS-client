//
//  ThreadNavigationBarSceneItemSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2022/11/15.
//

import Foundation
import UIKit
import LarkOpenChat
import UniverseDesignToast
import LarkSceneManager
import LarkModel
import LarkMessageCore

public final class ThreadNavigationBarSceneItemSubModule: NavigationBarSceneItemSubModule {
    public override func clickSceneItemClicked(sender: UIButton) {
        if #available(iOS 13.0, *) {
            let scene = LarkSceneManager.Scene(
                key: "Chat",
                id: self.chat?.id ?? "",
                title: self.chat?.displayName,
                sceneSourceID: self.context.chatVC().currentSceneID(),
                windowType: "channel",
                createWay: "window_click"
            )
            SceneManager.shared.active(scene: scene, from: self.context.chatVC()) { [weak self] (_, error) in
                if let self = self, error != nil {
                    UDToast.showTips(
                        with: BundleI18n.LarkThread.Lark_Core_SplitScreenNotSupported,
                        on: self.context.chatVC().view
                    )
                }
            }
        } else {
            assertionFailure()
        }
    }
    /// 获取要创建的 scene的id
    public override func getSceneId() -> String {
        return self.chat?.id ?? ""
    }
    /// 获取要创建的 scene的key
    public override func getSceneKey() -> String {
        return "Chat"
    }
}
