//
//  CCMDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/27.
//

import Foundation

/// Lark文档依赖
public protocol CCMDependency {
    /// 是否有效的Lark文档地址
    func isDocsURL(_ urlString: String) -> Bool

    /// 创建妙享文档工厂
    func createFollowDocumentFactory() -> FollowDocumentFactory

    /// 创建纪要文档工厂
    func createNotesDocumentFactory() -> NotesDocumentFactory

    /// 下载Lark文档缩略图
    /// - Parameters:
    ///   - url: 图片 url
    ///   - thumbnailInfo: ["nonce":"随机数", "secret":"秘钥","type" :"解密方式"]
    ///   - imageSize: 目标图片大小, nil 表示不调整，直接返回原图
    ///   - completion: 下载完成的回调
    func downloadThumbnail(url: String, thumbnailInfo: [String: Any], imageSize: CGSize?,
                           completion: @escaping (Result<UIImage, Error>) -> Void)

    /// 创建模板页面
    func createBVTemplate() -> BVTemplate?

    /// 创建LkNavigationController对象，供纪要文档内使用，进行跳转，以确保顶部显示样式与Lark内跳转一致
    func createLkNavigationController() -> UINavigationController

    func setDocsIcon(iconInfo: String, url: String, completion: ((UIImage) -> Void)?)

    /// 获取DocsAPIDomain
    func getDocsAPIDomain() -> String
}

/// Lark文档工厂，用来打开的Lark文档
public protocol FollowDocumentFactory: AnyObject {
    /// 开始会议
    func startMeeting()

    /// 结束会议
    func stopMeeting()

    /// 打开Lark文档
    /// - Parameters:
    ///   - urlString: url
    /// - returns: 返回实现FollowAPI的实例
    ///     以下情况会返回失败 1.非法URL
    func open(url: String) -> FollowDocument?

    /// - Parameters:
    ///   - urlString: url
    ///   - events: 注册的事件
    ///   - injectScript: 注入的JS
    /// - returns: 返回实现FollowAPI的实例
    ///     以下情况会返回失败 1.非法URL
    func openGoogleDrive(url: String, injectScript: String?) -> FollowDocument?
}

// MARK: - MagicShare(Follow)

/// 表示一篇被打开的Lark文档
public protocol FollowDocument: AnyObject {

    /// 当前FollowAPI 所对应的 docs 连接
    var followUrl: String { get }

    /// 当前FollowAPI 所对应的 docs 文档标题
    var followTitle: String { get }

    /// 返回当前Follow的ViewController
    var followVC: UIViewController { get }

    /// 文档是否支持回到上次位置目前只有 doc和wiki-doc
    var canBackToLastPosition: Bool { get }

    /// 当前用户是否正在编辑态
    var isEditing: Bool { get }

    /// 返回当前UIScrollView
    var scrollView: UIScrollView? { get }

    /// 设置Follow回调Delgate
    func setDelegate(_ delegate: FollowDocumentDelegate)

    /// 开始记录Action
    ///
    /// - Returns: 无
    func startRecord()

    /// 停止记录Action
    ///
    /// - Returns: 无
    func stopRecord()

    /// 开启Follow状态
    /// 参会人端初始化时调用
    /// - Returns: 无
    func startFollow()

    /// 停止跟随
    /// 参会人端自由浏览时调用，结束Follow状态后，有FollowState来时，仍然需要调用 setState()，只是此时FollowState会存在起来不生效，等用户回到跟随浏览状态时，立即应用最新版FollowState。
    /// - Returns: 无
    func stopFollow()

    /// 播放action
    ///
    /// - Parameter actions: 要播放的action
    /// - Parameter meta: 元数据如uuid等
    /// - Returns: 无
    func setState(states: [String], meta: String?)

    ///  获取所有类型的最新动作。
    ///  主持人端VC APP定时调用, 返回最新的FollowState对象。
    /// - Returns: 最新动作数组
    func getState(callBack: @escaping ([String], String?) -> Void)

    /// 刷新当前页面
    ///
    /// - Returns: 无
    func reload()

    /// 注入JS
    func injectJS(_ script: String)

    /// 回到上次位置
    func backToLastPosition()

    /// 清除位置记录。清除当前 token 文档记录，不传token的话是清除所有文档的位置记录
    func clearLastPosition(_ token: String?)

    /// 记住当前位置
    func keepCurrentPosition()

    ///MagicShare共享人端发送提频
    func updateOptions(_ options: String?)

    /// 容器即将消失，调用此方法通知CCM侧收起打开的页面
    func willSetFloatingWindow()

    /// 回到全屏，动画结束
    func finishFullScreenWindow()

    /// 向CCM前端上报共享人的数据，JSON字符串
    func updateContext(_ context: String?)

    /// 根据名字调用CCM前端方法
    /// - Parameters:
    ///   - funcName: 方法名
    ///   - paramJson: 主要参数
    ///   - metaJson: 次要参数（其他参数）
    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?)
}

/// FollowAPI的 delegate类型，FollowAPI主动通知信息
public protocol FollowDocumentDelegate: AnyObject {

    /// 传递滚动等followState
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - event:  返回的事件，根据 FollowAPI setup 注册
    ///   - actions: Follow Action 数组
    func follow(_ follow: FollowDocument, on event: FollowEvent, with states: [String], metaJson: String?)

    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - operation: 动作信息，key为操作类型，value为动作参数
    func follow(_ follow: FollowDocument, onOperate operation: FollowOperation)

    /// WebView调用VC Native的方法
    /// [Magic Share Runtime 技术方案](https://bytedance.feishu.cn/docs/doccnLvQUvvly6MS9GMb9zMgwIg) -> JS SDK Call Follow Runtime
    /// getEnv\zoom(level)\log(msg)...
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - invocation: 调用信息，key为调用方法，value为调用参数，将透传给VC
    func follow(_ follow: FollowDocument, onJsInvoke invocation: [String: Any]?)

    /// Docs相关js加载完毕
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followDidReady(_ follow: FollowDocument)

    /// Docs渲染完成
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followDidRenderFinish(_ follow: FollowDocument)

    /// DocsBrowserVC中用户点击返回按钮，页面即将退出
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followWillBack(_ follow: FollowDocument)
}

/// 用于监听事件
public enum FollowEvent: String, Hashable {
    case unknown = "UNKNOWN"
    /// 有新的action产生
    case newAction = "NEW_ACTIONS"
    /// 有新的FollowPatch产生
    case newPatches = "NEW_PATCHES"
    /// 文档标题变化
    case titleChange = "SUITE_TITLE_CHANGE"
    /// 日志信息
    case followLog = "FOLLOW_LOG"
    /// 【已废弃】文档共享人/阅读者位置变化
    case positionChange = "POSITION_CHANGE"
    /// sheet touch事件
    case touchPositionChange = "TOUCH_POSITION_CHANGE"
    /// 【已废弃】文档共享人/阅读者位置变化
    case presenterFollowerLocation = "PRESENTER_FOLLOWER_LOCATION"
    /// 前端资源包版本改变
    case versionLag = "FOLLOW_ACTION_VERSION_LAG"
    /// 前端有信息需要通过VC-iOS侧进行埋点上报
    case track = "FOLLOW_TRACK"
    /// 【已废弃】有FollowAction变化，需要监测并埋点
    case lifeCycleChange = "FOLLOW_ACTION_LIFECYCLE_CHANGE"
    /// lifeCycleChange的升级版本，传递多个FollowAction供成功率检测埋点使用
    case actionChangeList = "ACTION_CHANGE_LIST"
    /// 文档被分享后，首次滑动文档埋点上报
    case firstPositionChangeAfterFollow = "FIRST_POSITION_CHANGE_AFTER_FOLLOW"
    /// presenterFollowerLocation的升级版本，文档共享人/阅读者位置变化
    case relativePositionChange = "RELATIVE_POSITION_CHANGE"
    /// 上报shareInfo，提供给minutes分段
    case magicShareInfo = "MAGIC_SHARE_INFO"
}

///Follow时文档中的各种操作
public enum FollowOperation: CustomStringConvertible, CustomDebugStringConvertible {
    /// 未知/无效操作
    case unknown
    /// 点击文档中的url链接
    case openUrl(url: String)
    /// 点击文档中的url链接，且该链接已被转换到wiki类型
    case openMoveToWikiUrl(wikiUrl: String, originUrl: String)
    /// 点击文档中的url链接，且打开url前需要执行额外的handler
    case openUrlWithHandlerBeforeOpen(url: String, handler: () -> Void)
    /// 点击文档中的图片链接
    case openPic(url: String)
    /// 点击文档中的评论
    case selectComments(info: [String: Any])
    /// 旋转屏幕
    case rotateScreen(orientation: UIInterfaceOrientation)
    /// 文档标题被改变
    case onTitleChange(title: String)
    /// 点击UserProfile
    case showUserProfile(userId: String)
    /// 需要VC切换小窗，接着执行handler，并提供一个供push的ViewController（ViewController获取方式与弹起UserProfile相同）
    case setFloatingWindow(getFromVCHandler: (UIViewController?) -> Void)
    /// 打开文档中的附件
    case openOrCloseAttachFile(isOpen: Bool)
    // openOrCloseAttachFile

    public var description: String {
        // 数据含有token，打印时只打印operation
        switch self {
        case .unknown:
            return "unknown"
        case .openUrl:
            return "openUrl"
        case .openMoveToWikiUrl:
            return "openMoveToWikiUrl"
        case .openUrlWithHandlerBeforeOpen:
            return "openUrlWithHandlerBeforeOpen"
        case .openPic:
            return "openPic"
        case .selectComments:
            return "selectComments"
        case .rotateScreen:
            return "rotateScreen"
        case .onTitleChange:
            return "onTitleChange"
        case .showUserProfile:
            return "openUserProfile"
        case .setFloatingWindow:
            return "setFloatingWindow"
        case .openOrCloseAttachFile:
            return "openOrCloseAttachFile"
        }
    }

    public var debugDescription: String {
        description
    }
}
