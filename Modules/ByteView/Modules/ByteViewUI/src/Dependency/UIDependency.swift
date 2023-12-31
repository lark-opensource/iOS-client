//
//  UIDependency.swift
//  ByteViewUI
//
//  Created by kiri on 2023/2/21.
//

import Foundation
import ByteViewCommon

public final class UIDependencyManager {
    private(set) static var dependency: UIDependency?
    public static func setupDependency(_ dependency: UIDependency) {
        self.dependency = dependency
    }
}

public protocol UIDependency {
    /// iPad上SplitViewController下获取TopMost，否则返回空
    func topMost(of vc: UIViewController) -> UIViewController?

    /// 创建一个AvatarView
    func createAvatarView() -> AvatarViewProtocol

    func createFocusTagView() -> UserFocusTagViewProtocol

    /// 为某个window请求横竖屏的控制能力
    ///
    /// - 目前lark使用`application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?)`来控制转向
    /// - 主端默认取scene的window为横竖屏的主window，其他window都和该window做交集。设置shouldControl为true后，window的转向不再和主window做交集。
    func setOrientationControl(for window: UIWindow, shouldControl: Bool)
    func setWindowIdentifier(_ identifier: String, for window: UIWindow)

    /// 创建代理以使用LarkUIKit组件中UIScrollView+LoadMore.swift中提供的能力
    func createScrollViewLoadingDelegate(for scrollView: UIScrollView) -> UIScrollViewLoadingDelegate

    /// 异步设置图片
    func setImage(for imageView: UIImageView, resource: ImageResource, placeholder: UIImage?, completion: ((Result<UIImage?, Error>) -> Void)?) -> ImageRequest?

    func setSquircleMask(for view: UIView, cornerRadius: CGFloat, rect: CGRect)

    /// 是否可以开启多scene
    var supportsMultipleScenes: Bool { get }

    /// 打开辅助scene
    func openScene(from: UIWindow?, info: SceneInfo, localContext: AnyObject?, completion: ((UIWindow?, Error?) -> Void)?)

    /// 关闭 UIScene
    /// - Parameters:
    ///   - from: UIScene
    ///   - animation: 关闭动画样式
    ///   - errorHandler: 错误处理回调
    @available(iOS 13, *)
    func deactive(from: UIScene, animation: SceneDismissalAnimation, errorHandler: ((Error) -> Void)?)

    /// 判断 scene 是否已经被激活
    /// - Parameter scene: SceneInfo 配置
    /// - Returns: 返回是否被激活
    @available(iOS 13, *)
    func isConnected(scene: SceneInfo) -> Bool

    /// 返回 UIScene
    /// - Parameter scene: scene 配置
    /// - Returns: 返回 UIScene
    @available(iOS 13.0, *)
    func connectedScene(scene: SceneInfo) -> UIScene?

    /// 判断 scene 是否有效
    /// - Parameter scene: 需要判断的 UIWindowScene
    /// - Returns: 返回是否有效
    @available(iOS 13.0, *)
    func isValidScene(scene: UIWindowScene) -> Bool

    /// 进入一个VC（appear）
    func trackEnterViewController(_ uniqueId: String)

    /// 离开一个VC（disappear）
    func trackLeaveViewController(_ uniqueId: String)

    var pushCard: PushCardDependency { get }

    /// 根据key获取LarkEmotion的图片
    func imageByKey(_ key: String) -> UIImage?
}

public protocol ImageRequest {
    func cancel()
}

public enum ImageResource {
    /// 普通图片，支持 Rust image key (不带协议头默认为此) & http(s):// & file:// & data(base64) url
    case url(String, accessToken: String)
    /// reaction表情
    case reaction(String)
    /// 表情分栏icon
    case emojiSectionIcon(String)
}

/// 头像View的实现
public protocol AvatarViewProtocol: UIView {
    /// 根据图片设置头像
    func setAvatarInfo(_ avatarInfo: AvatarInfo, size: AvatarSize)

    /// 设置头像样式（圆的还是方的）
    func updateStyle(_ style: AvatarStyle)

    /// for dm in LarkBizAvatar
    func removeMaskView()

    /// 设置点击事件
    func setTapAction(_ action: (() -> Void)?)
}

/// 头像的尺寸
public enum AvatarSize: Equatable {
    case size(CGFloat) // 支持指定大小
    case small // 预留字段，目前与medium相同
    case medium // 头像最长边为98及更小，接口会返回128 * 128的图片；如果最长边超过了98，会自动去加载640 * 640的图片
    case large // 头像最长边大于98，接口会返回640 * 640的图片；如果缓存中没有，会先返回128 * 128的图片，下载好后再返回640 *640的图片
}

/// 头像样式
public enum AvatarStyle: Int, Equatable {
    case square
    case circle
}

public protocol UIScrollViewLoadingDelegate: AnyObject {
    var bottomLoadingView: UIView? { get }
    func addBottomLoading(handler: @escaping () -> Void)
    func endBottomLoading(hasMore: Bool)
    func removeBottomLoading()

    var topLoadingView: UIView? { get }
    func addTopLoading(handler: @escaping () -> Void)
    func endTopLoading(hasMore: Bool)
    func removeTopLoading()
}

/// 用户状态，用于展示User.CustomStatus
public protocol UserFocusTagViewProtocol: UIView {
    /// set [User.CustomStatus]
    func setCustomStatuses(_ customStatuses: [Any])
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
public struct SceneInfo: Equatable, Hashable {
    /// key 用于不同 scene
    public let key: SceneKey
    /// id 用于区分同一 scene 场景中不同数据
    /// 例如文档 scene，不同的文档对应不同的 id
    public let id: String
    /// scene 的标题
    public var title: String?
    /// 用户自定义信息
    public var userInfo: [String: String] = [:]
    public var windowType: String?
    public var createWay: String?
    public var extraInfo: [String: Any] = [:]

    public init(key: SceneKey, id: String) {
        self.key = key
        self.id = id
    }

    public static let main = SceneInfo(key: .main, id: "")

    public static func == (lhs: SceneInfo, rhs: SceneInfo) -> Bool {
        return lhs.key == rhs.key && lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine("key=\(key.rawValue),id=\(id)")
    }
}

public enum SceneKey: String, CustomStringConvertible {
    case main
    case vc
    case vcSideBar = "vc_side_bar"
    case chat = "Chat"

    public var description: String { rawValue }
}

extension SceneInfo: CustomStringConvertible {
    public var description: String {
        "SceneInfo(key: \(key), id: \(id), userInfo: \(userInfo), windowType: \(windowType ?? ""), createWay: \(createWay ?? ""), extraKeys: \(extraInfo.keys))"
    }
}

/// 外部依赖：push卡片
public protocol PushCardDependency {

    func postCard(id: String, isHighPriority: Bool, extraParams: [String: Any]?, view: UIView, tap: ((String) -> Void)?)

    func remove(with id: String, changeToStack: Bool)

    func findPushCard(id: String, isBusy: Bool?) -> String?

    func update(with id: String)
}
