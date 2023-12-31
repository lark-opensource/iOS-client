//
//  MyAIPageServiceImpl+ChatMode.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import RustPB
import LarkUIKit
import LarkModel
import LarkSceneManager
import LarkMessengerInterface

/// 分会场相关逻辑放这里
public extension MyAIPageServiceImpl {
    // MARK: My AI场景特化的路由跳转
    func onMessageURLTapped(fromVC: UIViewController,
                                   url: URL,
                                   context: [String: Any],
                                   defaultOpenBlock: @escaping () -> Void) {
        //没有命中页面通信时执行这个方法
        func defaultTapUrl() {
            if isOpenResourceInNewSceneEnabled,
               !chatMode,
               Display.pad,
               #available(iOS 13, *) {
                //my ai主会话场景pad要分屏打开
                let localContext = URLPreviewSceneContext(url: url,
                                                          context: context)
                let sceneInfo = LarkSceneManager.Scene(
                    key: "URLPreview",
                    id: url.absoluteString,
                    title: nil,
                    userInfo: ["urlString": url.absoluteString],
                    sceneSourceID: fromVC.currentSceneID(),
                    windowType: "channel",
                    createWay: "window_click"
                )
                SceneManager.shared.active(scene: sceneInfo, from: fromVC, localContext: localContext) { (_, error) in
                    if error != nil {
                        defaultOpenBlock() //分屏报错了的话，走默认逻辑兜底
                    }
                }
            } else {
                defaultOpenBlock()
            }
        }
        if chatMode {
            if chatModeConfig.shouldInteractWithURL(url) {
                defaultTapUrl()
            }
        } else {
            defaultTapUrl()
        }
    }

    func onMessageFileTapped(fromVC: UIViewController,
                                    message: Message,
                                    scene: FileSourceScene,
                                    downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                                    defaultOpenBlock: @escaping () -> Void) {
        if isOpenResourceInNewSceneEnabled,
           !chatMode,
           Display.pad,
           #available(iOS 13, *) {
            //my ai主会话场景pad要分屏打开
            let localContext = FileBrowseSceneContext(message: message, scene: scene, downloadFileScene: downloadFileScene)
            var userInfo: [String: String] = [:]
            let fileName = (message.content as? FileContent)?.name ?? ""
            userInfo["fileName"] = fileName
            userInfo["messageId"] = message.id
            let sceneInfo = LarkSceneManager.Scene(
                key: "FilePreview",
                id: message.id,
                title: fileName,
                userInfo: userInfo,
                sceneSourceID: fromVC.currentSceneID(),
                windowType: "channel",
                createWay: "window_click"
            )
            SceneManager.shared.active(scene: sceneInfo, from: fromVC, localContext: localContext) { (_, error) in
                if error != nil {
                    defaultOpenBlock() //分屏报错了的话，走默认跳转兜底
                }
            }
        } else {
            defaultOpenBlock()
        }
    }

    func onMessageFolderTapped(fromVC: UIViewController,
                                      message: Message,
                                      scene: FileSourceScene,
                                      downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                                      defaultOpenBlock: @escaping () -> Void) {
        if isOpenResourceInNewSceneEnabled,
           !chatMode,
           Display.pad,
           #available(iOS 13, *) {
            //my ai主会话场景pad要分屏打开
            let localContext = FileBrowseSceneContext(message: message, scene: scene, downloadFileScene: downloadFileScene)
            let sceneInfo = LarkSceneManager.Scene(
                key: "FolderPreview",
                id: message.id,
                title: (message.content as? FolderContent)?.name ?? "",
                userInfo: ["messageId": message.id],
                sceneSourceID: fromVC.currentSceneID(),
                windowType: "channel",
                createWay: "window_click"
            )
            SceneManager.shared.active(scene: sceneInfo, from: fromVC, localContext: localContext) { (_, error) in
                if error != nil {
                    defaultOpenBlock() //分屏报错了的话，走默认跳转兜底
                }
            }
        } else {
            defaultOpenBlock()
        }
    }
}
