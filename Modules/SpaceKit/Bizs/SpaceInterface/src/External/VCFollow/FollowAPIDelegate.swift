//
//  FollowAPIDelegate.swift
//  SpaceInterface
//
//  Created by nine on 2019/9/10.
//

import Foundation

///Follow时文档中的各种操作
public enum FollowOperation: CustomStringConvertible {
   // 打开了链接，包含Docs文档、其他类型的文档、外部链接等
    case openUrl(url: String)
    //专门用于第二次打开moveToWiki链接
    case openMoveToWikiUrl(wikiUrl: String, originUrl: String)
    //专门用于第二次打开moveToSpace链接,在VC侧与moveToWiki的逻辑相同
    public static func openMoveToSpaceUrl(spaceUrl: String, originUrl: String) -> Self {
        openMoveToWikiUrl(wikiUrl: spaceUrl, originUrl: originUrl)
    }

    //打开了一个图片
    case openPic(url: String)
    //点选了一个评论
    case selectComments(info: [String: Any])
    //翻转屏幕 --（Sheet\PPT需要)
    case rotateScreen(orientation: UIInterfaceOrientation)
    //标题变化
    case onTitleChange(title: String)
    //打开用户Profile页
    case showUserProfile(userId: String)
    //设置为小窗，然后返回可以跳转的 fromVC
    case setFloatingWindow(getFromVCHandler: (UIViewController?) -> Void)
    //打开 url，然后在 push 可以做些处理
    case openUrlWithHandlerBeforeOpen(url: String, handler: () -> Void)
    //打开附件时通知 VC，isOpen： true 时为打开，false 时为关闭。
    case openOrCloseAttachFile(isOpen: Bool)

    public var description: String {
        //数据含有token，打印时只打印operation
        switch self {
        case .openUrl:
            return "openUrl"
        case .openMoveToWikiUrl:
            return "openMoveToWikiUrl"
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
        case .openUrlWithHandlerBeforeOpen:
            return "openUrlWithHandlerBeforeOpen"
        case .openOrCloseAttachFile:
            return "openOrCloseAttachFile"
        }
    }
}

/// FollowAPI的 delegate类型，FollowAPI主动通知信息
public protocol FollowAPIDelegate: AnyObject {
    /// 传递滚动等followState
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - event:  返回的事件，根据 FollowAPI setup 注册
    ///   - actions: Follow Action 数组
    func follow(_ follow: FollowAPI, on event: FollowEvent, with states: [SpaceInterface.FollowState], metaJson: String?)

    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - operation: 动作信息，key为操作类型，value为动作参数
    func follow(_ follow: FollowAPI, onOperate operation: FollowOperation)

    /// WebView调用VC Native的方法
    /// [Magic Share Runtime 技术方案](https://bytedance.feishu.cn/docs/doccnLvQUvvly6MS9GMb9zMgwIg) -> JS SDK Call Follow Runtime
    /// getEnv\zoom(level)\log(msg)...
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    ///   - invocation: 调用信息，key为调用方法，value为调用参数，将透传给VC
    func follow(_ follow: FollowAPI, onJsInvoke invocation: [String: Any]?)

    /// Docs相关js加载完毕
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followDidReady(_ follow: FollowAPI)

    /// Docs渲染完成
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followDidRenderFinish(_ follow: FollowAPI)

    /// DocsBrowserVC中用户点击返回按钮，页面即将退出
    ///
    /// - Parameters:
    ///   - follow: 产生该回调的API实例
    func followWillBack(_ follow: FollowAPI)
}

// 可选实现
public extension FollowAPIDelegate {

    func follow(_ follow: FollowAPI, onJsInvoke invocation: [String: Any]?) {}
}
