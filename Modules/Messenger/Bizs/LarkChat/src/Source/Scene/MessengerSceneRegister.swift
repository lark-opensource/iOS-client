//
//  MessengerSceneRegister.swift
//  LarkChat
//
//  Created by 李晨 on 2021/2/9.
//

import UIKit
import Foundation
import LarkSceneManager
import LarkMessengerInterface
import LarkUIKit
import LarkContainer
import EENavigator
import LarkSDKInterface
import LarkBizAvatar
import SnapKit
import LarkAIInfra
import LarkRichTextCore
import UniverseDesignIcon

final class MessengerSceneRegister {
    /// 注册 Messenger 相关  scene
    static func registerMessengerScene() {
        if #available(iOS 13.0, *) {
            SceneManager.shared.register(config: ChatSceneConfig.self)
            SceneManager.shared.register(config: P2pSceneConfig.self)
            SceneManager.shared.register(config: CryptoSceneConfig.self)
            SceneManager.shared.register(config: ThreadSceneConfig.self)
            SceneManager.shared.register(config: MyAIChatModeSceneConfig.self)
            SceneManager.shared.register(config: FilePreviewSceneConfig.self)
            SceneManager.shared.register(config: FolderPreviewSceneConfig.self)
            SceneManager.shared.register(config: URLPreviewSceneConfig.self)
        }
    }
}

/// Chat 详情页面
@available(iOS 13.0, *)
final class ChatSceneConfig: SceneConfig {

    static var key: String { "Chat" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        var body: ChatControllerByIdBody
        if let positionStr = sceneInfo.userInfo["position"],
           let position = Int32(positionStr) {
            body = ChatControllerByIdBody(
                chatId: sceneInfo.id,
                position: position,
                fromWhere: ChatFromWhere(fromValue: sceneInfo.userInfo["chatFromWhere"]) ?? .ignored
            )
            body.controllerService = localContext as? ChatViewControllerService
        } else {
            body = ChatControllerByIdBody(
                chatId: sceneInfo.id,
                fromWhere: ChatFromWhere(fromValue: sceneInfo.userInfo["chatFromWhere"]) ?? .ignored
            )
            body.controllerService = localContext as? ChatViewControllerService
        }
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        userResolver.navigator.push(body: body, from: navi, animated: false)
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        guard
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
            let chat = chatAPI.getLocalChat(by: sceneInfo.id)
        else { return }
        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.id, avatarKey: chat.avatarKey, avatarViewParams: .defaultThumb,
                                         backgroundColorWhenError: .clear, completion: { [weak imageView] result in
            switch result {
            case .success:
                imageView?.image = nil
            default:
                break
            }
        })
        imageView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

/// Chatter 单聊
@available(iOS 13.0, *)
final class P2pSceneConfig: SceneConfig {

    static var key: String { "P2pChat" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        if let chatID = sceneInfo.userInfo["chatID"] {
            let body = ChatControllerByIdBody(chatId: chatID)
            userResolver.navigator.push(body: body, from: navi, animated: false)
        } else {
            let body = ChatControllerByChatterIdBody(
                chatterId: sceneInfo.id,
                isCrypto: false
            )
            userResolver.navigator.push(body: body, from: navi, animated: false)
        }
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        guard let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self),
            let chatter = chatterAPI.getChatterFromLocal(id: sceneInfo.id)
        else { return }
        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(chatter.id, avatarKey: chatter.avatarKey, avatarViewParams: .defaultThumb,
                                         backgroundColorWhenError: .clear, completion: { [weak imageView] result in
            switch result {
            case .success:
                imageView?.image = nil
            default:
                break
            }
        })
        imageView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

/// Chatter 加密单聊
@available(iOS 13.0, *)
final class CryptoSceneConfig: SceneConfig {

    static var key: String { "P2pCryptoChat" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        if let chatID = sceneInfo.userInfo["chatID"] {
            let body = ChatControllerByIdBody(chatId: chatID)
            userResolver.navigator.push(body: body, from: navi, animated: false)
        } else {
            let body = ChatControllerByChatterIdBody(
                chatterId: sceneInfo.id,
                isCrypto: true
            )
            userResolver.navigator.push(body: body, from: navi, animated: false)
        }
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self), let chatId = sceneInfo.userInfo["chatID"], let chat = chatAPI.getLocalChat(by: chatId)
        else { return }
        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.id, avatarKey: chat.avatarKey, avatarViewParams: .defaultThumb,
                                         backgroundColorWhenError: .clear, completion: { [weak imageView] result in
            switch result {
            case .success:
                imageView?.image = nil
            default:
                break
            }
        })
        imageView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

/// Thread 详情页面
@available(iOS 13.0, *)
final class ThreadSceneConfig: SceneConfig {

    static var key: String { "Thread" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        let body: ThreadDetailByIDBody
        if let positionStr = sceneInfo.userInfo["position"],
           let position = Int32(positionStr) {
            body = ThreadDetailByIDBody(
                threadId: sceneInfo.id,
                loadType: .position,
                position: position
            )
        } else {
            body = ThreadDetailByIDBody(
                threadId: sceneInfo.id,
                loadType: .unread
            )
        }
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        userResolver.navigator.push(body: body, from: navi, animated: false)
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
            let chatId = sceneInfo.userInfo["chatID"],
            let chat = chatAPI.getLocalChat(by: chatId)
        else { return }
        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.id, avatarKey: chat.avatarKey, avatarViewParams: .defaultThumb,
                                         backgroundColorWhenError: .clear, completion: { [weak imageView] result in
            switch result {
            case .success:
                imageView?.image = nil
            default:
                break
            }
        })
        imageView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

/// MyAI分会场
@available(iOS 13.0, *)
final class MyAIChatModeSceneConfig: SceneConfig {
    /// TODO：@李勇，这个好像没办法做用户态迁移？
    @Provider static var myAIService: MyAIService
    @Provider static var chatAPI: ChatAPI

    static var key: String { "MyAIChatMode" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        guard let config = localContext as? MyAIChatModeConfig else { return nil }
        let body = myAIService.getMyAIChatModeBody(config: config)
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        Navigator.shared.push(body: body, from: navi, animated: false)
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        guard let chatId = sceneInfo.userInfo["chatID"], let chat = chatAPI.getLocalChat(by: chatId) else { return }
        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.id, avatarKey: chat.avatarKey, avatarViewParams: .defaultThumb,
                                         backgroundColorWhenError: .clear, completion: { [weak imageView] result in
            switch result {
            case .success:
                imageView?.image = nil
            default:
                break
            }
        })
        imageView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

/// 文件预览
@available(iOS 13.0, *)
final class FilePreviewSceneConfig: SceneConfig {
    static var key: String { "FilePreview" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        guard let context = localContext as? FileBrowseSceneContext else {
            //主工程被杀死的话 localContext会拿不到，走降级逻辑
            if let messageId = sceneInfo.userInfo["messageId"] {
                var body = MessageFileBrowseBody(messageId: messageId, scene: .unknown)
                body.isOpeningInNewScene = true
                let navi = LkNavigationController()
                navi.view.backgroundColor = UIColor.ud.bgBody
                Navigator.shared.push(body: body, from: navi, animated: false)
                return navi
            }
            return nil
        }
        var body = MessageFileBrowseBody(message: context.message,
                                         scene: context.scene,
                                         downloadFileScene: context.downloadFileScene)
        body.isOpeningInNewScene = true
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        Navigator.shared.push(body: body, from: navi, animated: false)
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        guard let fileName = sceneInfo.userInfo["fileName"] else { return }
        imageView.image = LarkRichTextCoreUtils.fileIcon(with: fileName)
    }
}

/// 文件夹预览
@available(iOS 13.0, *)
final class FolderPreviewSceneConfig: SceneConfig {
    static var key: String { "FolderPreview" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        guard let context = localContext as? FileBrowseSceneContext else {
            //主工程被杀死的话 localContext会拿不到，走降级逻辑
            if let messageId = sceneInfo.userInfo["messageId"] {
                var body = FolderManagementBody(messageId: messageId,
                                                scene: .unknown)
                body.isOpeningInNewScene = true
                let navi = LkNavigationController()
                navi.view.backgroundColor = UIColor.ud.bgBody
                Navigator.shared.push(body: body, from: navi, animated: false)
                return navi
            }
            return nil
        }

        var body = FolderManagementBody(
            message: context.message,
            scene: context.scene,
            downloadFileScene: context.downloadFileScene
        )
        body.isOpeningInNewScene = true
        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody
        Navigator.shared.push(body: body, from: navi, animated: false)
        return navi
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        imageView.image = UDIcon.folderOutlined
    }
}

/// URL预览
@available(iOS 13.0, *)
final class URLPreviewSceneConfig: SceneConfig {
    static var key: String { "URLPreview" }

    static func icon() -> UIImage { Resources.chatIcon }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                        sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        func getResVC(url: URL, customContext: [String: Any]) -> UIViewController {
            let navi = LkNavigationController()
            navi.view.backgroundColor = UIColor.ud.bgBody
            var navContext: [String: Any] = customContext
            navContext["showTemporary"] = false // 用于文档打开的时候传入标识，走push方法打开不走标签方式打开

            DispatchQueue.main.async {
                Navigator.shared.push(url, context: navContext, from: navi)
            }
            return navi
        }

        guard let context = localContext as? URLPreviewSceneContext else {
            //主工程被杀死的话 localContext会拿不到，走降级逻辑
            if let urlString = sceneInfo.userInfo["urlString"],
               let url = try? URL.forceCreateURL(string: urlString) {
                return getResVC(url: url, customContext: [:])
            }
            return nil
        }

        return getResVC(url: context.url, customContext: context.context)
    }
}
