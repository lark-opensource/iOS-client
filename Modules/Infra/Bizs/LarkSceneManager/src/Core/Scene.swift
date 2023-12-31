//
//  Scene.swift
//  LarkSceneManager
//
//  Created by 李晨 on 2021/1/17.
//

import UIKit
import Foundation

/// scene 配置
public final class Scene: Codable, Hashable {

    /// 主 scene 对应的 key
    public static let mainSceneKey: String = "Main"
    /// 无效 scene 对应的 key
    public static let invalidSceneKey: String = "Invalid"

    /// scene 对应的 ActivityType
    public static let sceneActivityType: String = "Scene"

    /// key 用于不同 scene
    public let key: String

    /// id 用于区分同一 scene 场景中不同数据
    /// 例如文档 scene，不同的文档对应不同的 id
    public let id: String

    /// scene 的标题
    public var title: String?

    /// 是否持久化
    public var needRestoration: Bool

    /// 用户自定义信息
    public var userInfo: [String: String]

    /// scene 创建来源, 需要设置为开启当前 scene 的原始 scene session 的 persistentIdentifier
    public var sceneSourceID: String?

    /// windowType
    public var windowType: String?

    /// 创建方式
    public var createWay: String?

    /// 最近一次变为 active 的时间
    public var activeTime: Date

    /// init method
    public init(
        key: String,
        id: String,
        title: String? = nil,
        needRestoration: Bool = true,
        userInfo: [String: String] = [:],
        sceneSourceID: String? = nil,
        windowType: String? = nil,
        createWay: String? = nil
    ) {
        self.key = key
        self.id = id
        self.title = title
        self.userInfo = userInfo
        self.needRestoration = needRestoration
        self.sceneSourceID = sceneSourceID
        self.windowType = windowType
        self.createWay = createWay
        self.activeTime = Date()
    }

    /// 是否是 main scene
    public func isMainScene() -> Bool {
        return self.key == Scene.mainSceneKey
    }

    /// 是否是 无效 scene
    public func isInvalidScene() -> Bool {
        return self.key == Scene.invalidSceneKey
    }

    /// 返回来源 scene
    @available(iOS 13.0, *)
    public func sourceScene() -> UIScene? {
        guard let sourceID = self.sceneSourceID else {
            return nil
        }
        return UIApplication.shared.connectedScenes.first { (scene) -> Bool in
            return scene.session.persistentIdentifier == sourceID
        }
    }

    /// targetContentIdentifier 用于匹配 content
    public var targetContentIdentifier: String {
        var identifier = "scene_\(key)"
        if !id.isEmpty {
            identifier += "_id_\(id)"
        }
        return identifier
    }

    public static func == (lhs: Scene, rhs: Scene) -> Bool {
        return lhs.key == rhs.key &&
            lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
        hasher.combine(self.id)
    }

    /// 返回传递给系统用户恢复的 scene
    public func restorationScene() -> Scene {
        return Scene(
            key: self.key,
            id: self.id,
            title: self.title,
            needRestoration: self.needRestoration,
            userInfo: self.userInfo,
            sceneSourceID: nil,
            windowType: self.windowType,
            createWay: nil
        )
    }
}

extension Scene {
    public static func mainScene() -> Scene {
        return Scene(
            key: mainSceneKey,
            id: "",
            title: nil,
            needRestoration: false,
            userInfo: [:]
        )
    }

    public static func invalidScene() -> Scene {
        return Scene(
            key: invalidSceneKey,
            id: "",
            title: nil,
            needRestoration: false,
            userInfo: [:]
        )
    }
}
