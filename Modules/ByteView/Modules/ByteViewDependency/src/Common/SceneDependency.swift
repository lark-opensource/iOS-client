//
//  SceneDependency.swift
//  ByteViewInterface
//
//  Created by kiri on 2021/3/23.
//

import Foundation

/// 多scene依赖
public protocol SceneDependency {
    /// 是否可以开启多scene
    var supportsMultipleScenes: Bool { get }
    /// 打开主scene
    @available(iOS 13, *)
    func openMainScene(from: UIWindow?, completion: ((UIWindow?, Error?) -> Void)?)
    /// 打开辅助scene
    @available(iOS 13, *)
    func openScene(from: UIWindow?, info: SceneInfo, localContext: AnyObject?, completion: ((UIWindow?, Error?) -> Void)?)

    /// 销毁 scene
    /// - Parameters:
    ///   - scene: SceneInfo
    ///   - animation: 关闭动画样式
    ///   - errorHandler: 错误处理回调
    func closeScene(_ scene: SceneInfo, animation: SceneDismissalAnimation, errorHandler: ((Error) -> Void)?)

    /// 判断 scene 是否已经被激活
    /// - Parameter scene: SceneInfo 配置
    /// - Returns: 返回是否被激活
    func isConnected(scene: SceneInfo) -> Bool

    /// 返回 UIScene
    /// - Parameter scene: scene 配置
    /// - Returns: 返回 UIScene
    @available(iOS 13.0, *)
    func connectedScene(scene: SceneInfo) -> UIScene?

    var mainSceneWindow: UIWindow? { get }
}

/// scene 配置
@available(iOS 13.0, *)
public protocol SceneService {

    /// scene 配置对应的图标
    static func icon() -> UIImage

    /// scene 配置对应的创建 RootVC 的方法
    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: SceneInfo,
                             localContext: AnyObject?) -> UIViewController?
}

public enum SceneKey {
    /// IM 聊天
    case chat
    /// vc 会中主窗口
    case vc
    /// vc 侧边栏
    case vcSideBar

    public var key: String {
        switch self {
        case .chat:
            return "Chat"
        case .vc:
            return "vc"
        case .vcSideBar:
            return "vc_side_bar"
        }
    }
}

/// scene 销毁动画
public enum SceneDismissalAnimation {

    /// 缩小消失
    case standard

    /// 向上划出
    case commit

    /// 向下划出
    case decline
}

/// scene 配置
public struct SceneInfo {

    /// key 用于不同 scene
    public let key: String

    /// id 用于区分同一 scene 场景中不同数据
    /// 例如文档 scene，不同的文档对应不同的 id
    public let id: String

    /// 是否持久化
    public var needRestoration: Bool

    /// scene 的标题
    public var title: String?

    /// 用户自定义信息
    public var userInfo: [String: String]

    /// windowType
    public var windowType: String?

    /// windowType
    public var createWay: String?

    /// 点击关闭按钮回调
    public var closeAction: (() -> Void)?

    ///  chat message渲染完成回调
    public var messageRenderBlock: (() -> Void)?

    /// chat vc deinit
    public var messageDeinitBlock: (() -> Void)?

    public init(id: String, key: String = SceneKey.vc.key, needRestoration: Bool = true, title: String? = nil, userInfo: [String: String] = [:]) {
        self.key = key
        self.id = id
        self.needRestoration = needRestoration
        self.title = title
        self.userInfo = userInfo
    }
}

extension SceneInfo: CustomStringConvertible, CustomDebugStringConvertible {
    var desc: String {
        "SceneInfo(key: \(key), id: \(id), needRestoration: \(needRestoration), userInfo: \(userInfo)), windowType: \(windowType ?? ""), createWay: \(createWay ?? ""))"
    }

    public var description: String { desc }
    public var debugDescription: String { description }
}
