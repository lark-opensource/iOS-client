//
//  CommentModule.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/26.
//  


import Foundation

public struct CommentModuleParams {
    public var dependency: DocsCommentDependency
    public var apiAdaper: CommentAPIAdaper
    public init(dependency: DocsCommentDependency, apiAdaper: CommentAPIAdaper) {
        self.dependency = dependency
        self.apiAdaper = apiAdaper
    }
}

/// 评论组件提供给外部调用的接口
public protocol DocsCommentModule {
    
    func update(_ commentData: CommentData)
    
    func removeAllMenu()
    
    func vcFollowOnRoleChange(role: FollowRole)
    
    func updateCopyTemplateURL(urlString: String)
    
    func hide()
    
    var isVisiable: Bool { get }
    
    func setCaptureAllowed(_ allow: Bool)

    /// 展示评论的视图（aside ）
    var commentPluginView: UIView { get }
    
    /// 评论组件模块初始化
    /// - Parameters:
    ///   - dependency: 依赖业务接入方提供的信息&需要业务方自己处理的事件，内部弱引用。
    ///   - CommentAPIAdaper: 增删改的接口，内部强引用。
    init(dependency: DocsCommentDependency, apiAdaper: CommentAPIAdaper)
}

/// 三种评论独有交互放下面
public protocol FloatCommentModuleType: DocsCommentModule {
    var canPresentingDismiss: Bool { get set }
    /// 主动关闭面板并通知前端/业务方
    func manualHide()
    func updateSession(session: Any)
    func update(useOpenID: Bool)
    func retryAddNewComment(commentId: String)
    func addNewCommentFinished(commentUUID: String, isSuccess: Bool, errorCode: String?)
    func scrollComment(commentId: String, replyId: String, percent: CGFloat)
    func update(_ newInputData: CommentInputModelType)
    func show(with topMost: UIViewController)
    func reloadData()
    var commentView: UIView { get }
}

public protocol AsideCommentModuleType: DocsCommentModule {
    func scrollComment(commentId: String, replyId: String, percent: CGFloat)
    func resetActive()
    func reloadData()
}

public protocol DriveCommentModuleType: DocsCommentModule {
    func udpateDocsInfo(_ docsInfo: CommentDocsInfo)
    func switchComment(commentId: String?)
    func show(commentId: String?, hostVC: UIViewController, formSheetStyle: Bool)
}


/// 重要‼️‼️‼️
/// 评论组件依赖外部的功能（非接口请求！）
/// 需要在这里声明的方法的原则如下：
/// 1. 接入方特化的一些依赖判断，判断原则：CCM评论、小程序评论、妙计评论等业务方的交集外的数据和功能
/// 2. 其他业务的路由跳转
public protocol DocsCommentDependency: AnyObject {
    
    // 为了命名不冲突
    var commentDocsInfo: CommentDocsInfo { get }

    func openDocs(url: URL)
    
    func scanQR(code: String)
    
    /// 打开个人信息页
    /// - Parameters:
    ///   - userId: 用户ID或者unionId（小程序使用）
    ///   - from: 有值时表示期望在from页面展示个人信息页
    func showUserProfile(userId: String, from: UIViewController?)
    
    /// aside comment需要业务接入方自己关闭
    func dismissCommentView()

    /// 外部复制权限的开关，需要接入的地方判断，不在评论模块内部判断
    var externalCopyPermission: ExternalCopyPermission { get }
    
    /// Magic Share会议信息，滚动跟随需要获取这些信息
    var commentConference: CommentConference { get }
    
    /// 评论键盘弹起时通知外面
    func keyboardChange(didTrigger event: CommentKeyboardOptions.KeyboardEvent, options: CommentKeyboardOptions, textViewHeight: CGFloat)
    
    /// Drive评论点击顶部空白的时候，需要实现事件穿透，是否穿透需要业务接入方判断，需要穿透则
    /// 返回响应事件的view
    func driveCommentTopMaskHitTestView(_ point: CGPoint, _ event: UIEvent?) -> UIView?
    
    /// 是否可以输入文字（密级强制打标需求）
    var textViewShouldBeginEditing: Bool { get }
    
    /// 接入方控制旋转屏幕
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { get }
    
    var vcFollowDelegate: CommentVCFollowDelegateType? { get }

    var businessConfig: CommentBusinessConfig { get }

    var browserVCTopMost: UIViewController? { get }

    func forcePortraint(force: Bool)
    
    /// 通知外部复制了输入框的内容
    func didCopyCommentContent()

    func commentWillHide()
}

public extension DocsCommentDependency {
    var externalCopyPermission: ExternalCopyPermission { .permit }
    var commentConference: CommentConference { CommentConference(inConference: false, followRole: nil, context: nil) }
    func keyboardChange(didTrigger event: CommentKeyboardOptions.KeyboardEvent, options: CommentKeyboardOptions, textViewHeight: CGFloat) {}
    
    func driveCommentTopMaskHitTestView(_ point: CGPoint, _ event: UIEvent?) -> UIView? { return nil }

    var textViewShouldBeginEditing: Bool { return true }
    
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { return nil }
    
    func scanQR(code: String) {}
    
    var vcFollowDelegate: CommentVCFollowDelegateType? { return nil }
    
    func openDocs(url: URL) {}
    
    func showUserProfile(userId: String, from: UIViewController?) {}
    
    func dismissCommentView() {}
    
    var vcTopMost: UIViewController? { return nil }

    var browserVCTopMost: UIViewController? { return nil }
    
    func forcePortraint(force: Bool) {}
    
    func didCopyCommentContent() {}

    func commentWillHide() {}
}

public enum ExternalCopyPermission {
    case denied(String)
    case permit
}

public enum CommentVCFollowDelegateType {
    case browser(_ delegate: BrowserVCFollowDelegate?)
    case space(_ delegate: SpaceFollowAPIDelegate?)
    
    public var spaceDelegate: SpaceFollowAPIDelegate? {
        switch self {
        case .space(let delegate):
            return delegate
        default:
            return nil
        }
        
    }
    
    public var browserDelegate: BrowserVCFollowDelegate? {
        switch self {
        case .browser(let delegate):
            return delegate
        default:
            return nil
        }
    }
}
