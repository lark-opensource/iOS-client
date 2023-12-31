//
//  CommentSDK.swift
//  SpaceInterface
//
//  Created by huayufan on 2022/11/15.
//  

public struct CommentModulePermission {

    public var canComment: Bool
    public var canResolve: Bool
    public var canShowMore: Bool
    public var canShowVoice: Bool
    public var canReaction: Bool
    public var canCopy: Bool
    public var canDelete: Bool
    public var canTranslate: Bool
    /// 下载点位，一般用于控制评论中的图片是否可以下载
    public var canDownload: Bool
    
    public init(canComment: Bool,
                canResolve: Bool,
                canShowMore: Bool,
                canShowVoice: Bool,
                canReaction: Bool,
                canCopy: Bool,
                canDelete: Bool,
                canTranslate: Bool) {
         self.canComment = canComment
         self.canResolve = canResolve
         self.canShowMore = canShowMore
         self.canShowVoice = canShowVoice
         self.canReaction = canReaction
         self.canCopy = canCopy
         self.canDelete = canDelete
         self.canTranslate = canTranslate
         self.canDownload = canCopy // TODO.chensi 移除旧接口
     }
    
    public init(canComment: Bool,
                canResolve: Bool,
                canShowMore: Bool,
                canShowVoice: Bool,
                canReaction: Bool,
                canCopy: Bool,
                canDelete: Bool,
                canTranslate: Bool,
                canDownload: Bool) {
         self.canComment = canComment
         self.canResolve = canResolve
         self.canShowMore = canShowMore
         self.canShowVoice = canShowVoice
         self.canReaction = canReaction
         self.canCopy = canCopy
         self.canDelete = canDelete
         self.canTranslate = canTranslate
         self.canDownload = canDownload
     }
}


/// 评论数据返回的类型
public enum CommentModuleAction: Int {
    /// 手动拉取评论时返回
    case fetch = 0
    /// 主动推送
    case change
    /// 新增评论数据
    case publish
    ///  删除评论
    case delete
    /// 解决评论
    case resolve
    /// 编辑评论
    case edit
}

public class RemoteCommentData {
    public class DiffComment {
        /// 远端更新评论
        public var addedComments: [Comment]?
        /// 远端删除评论
        public var deletedComments: [Comment]?
        /// 远端更新评论
        public var updatedComments: [Comment]?
        /// 远端解决评论
        public var resolveStatusChangedComments: [Comment]?
        
        public init(addedComments: [Comment]? = nil, deletedComments: [Comment]? = nil, updatedComments: [Comment]? = nil, resolveStatusChangedComments: [Comment]? = nil) {
            self.addedComments = addedComments
            self.deletedComments = deletedComments
            self.updatedComments = updatedComments
            self.resolveStatusChangedComments = resolveStatusChangedComments
        }
    }
    
    public var code: Int?
    public var msg: String?
    public var currentCommentId: String?

    public var comments: [Comment] = []
    /// 远端数据变更时不为空
    public var diffComments: DiffComment?
    
    public init(_ comments: [Comment],
                _ currentCommentId: String?,
                _ code: Int?,
                _ msg: String?,
                _ diff: DiffComment?) {
        self.comments = comments
        self.currentCommentId = currentCommentId
        self.code = code
        self.msg = msg
        self.diffComments = diff
    }
}



public struct CommentKeyboardOptions {
    public enum KeyboardEvent: String {
        case willChangeFrame
        case willShow
        case didChangeFrame
        case didShow
        case willHide
        case didHide
    }

    public let event: KeyboardEvent
    public let beginFrame: CGRect
    public let endFrame: CGRect
    public let animationCurve: UIView.AnimationCurve
    public let animationDuration: Double
    
    public init(event: CommentKeyboardOptions.KeyboardEvent, beginFrame: CGRect, endFrame: CGRect, animationCurve: UIView.AnimationCurve, animationDuration: Double) {
        self.event = event
        self.beginFrame = beginFrame
        self.endFrame = endFrame
        self.animationCurve = animationCurve
        self.animationDuration = animationDuration
    }
}


public enum CommentModuleUIType {
    case inputView // 关闭新增评论输入框
    case floatCard // 关闭评论卡片
}


public enum CommentModuleCancelType {
    case close(CommentModuleUIType) // 关闭评论UI
    case newInput // 取消新增评论（局部评论)
}

public struct CommentShowCardParamsBody {
    /// 展示的评论Id
    public let commentId: String
    /// 有值时可以将某条回复滚动可视区并高亮展示
    public let replyId: String?

    public init(commentId: String,
                replyId: String? = nil) {
        self.commentId = commentId
        self.replyId = replyId
    }
}

public struct CommentInputParamsBody {

    /// 评论引用的正文
    public var quote: String
    /// 业务方传入的临时评论Id
    public var tmpCommentId: String?
    
    public init(quote: String,
                tmpCommentId: String? = nil) {
        self.quote = quote
        self.tmpCommentId = tmpCommentId
    }
}

public struct CommentMetadataParamsBody {
    
    /// 要显示在UI上的评论Id，业务方保序
    public let commentIds: [String]

    public init(commentIds: [String] = []) {
        self.commentIds = commentIds
    }
}

/// 提供给非CCM业务使用的评论模块，包含了RN运行环境。
public protocol DocCommentModuleSDK: AnyObject {
    
    /// 初始化评论SDK接口，并会自动拉取一次数据，数据通过`didReceiveCommentData`接口返回
    init(paramsBody: CommentModuleParamsBody)
    
    /// 主动拉取评论接口，数据通过`didReceiveCommentData`接口返回
    func fetchComment()

    /// 展示评论卡片
    func showCommentCards(body: CommentShowCardParamsBody)

    /// 业务方过滤完要显示的评论数据之后让评论组件保存
    /// - Parameter commentIds:
    func setCommentMetadata(body: CommentMetadataParamsBody)
    
    /// 新增评论
    func showCommentInput(body: CommentInputParamsBody)
    
    ///  权限变更时调用该接口
    func updatePermission(permission: CommentModulePermission)
    
    func updateTranslateLang(translateLang: CommentTranslateLang)

    /// 主动关掉评论
    func dismiss()

    /// 是否正在展示
    var isVisiable: Bool { get }
}


public protocol DocCommentModuleDependency: AnyObject {
    
    
    /// 首次拉取评论数据 or 协同数据通过此接口返回
    /// - Parameters:
    ///   - response: 评论数据
    ///   - action: 区分是评论增、删、改数据，还是协同数据
    func didReceiveCommentData(commentData: RemoteCommentData, action: CommentModuleAction)

    /// 用户滚动了评论卡片
    /// - Parameters:
    ///   - commentId: 滚动到目的评论的评论Id
    ///   - height: 评论卡片顶部距离容器底部的高度
    func didSwitchCard(commentId: String, height: CGFloat)
    
    /// 关掉评论UI时会回调给业务接入方
    func cancelComment(type: CommentModuleCancelType)
    
    /// 键盘事件通知
    func keyboardChange(options: CommentKeyboardOptions, textViewHeight: CGFloat)
    
    /// 业务接入方提供展示评论的父控制器
    var topViewController: UIViewController? { get }
    
    /// 点击了评论的链接
    func openURL(url: URL)
    
    /// 请求打开个人信息页
    func showUserProfile(userId: String)
}

public enum CommentTranslateLang: String {
   case zh
   case en
   case ja
   case th
   case hi
   case id
   case zh_hant = "zh-Hant"
   case fr
   case es
   case pt
   case ko
   case vi
   case ru
   case de
   case it
   case ar
   case pl
}

public struct CommentModuleParamsBody {
    
    public enum CommentTranslateMode: Int {
        case onlyShowTranslation = 2
        case bothShow = 3
    }

    public var token: String
    
    public var type: Int

    public var permission: CommentModulePermission
    
    public weak var dependency: DocCommentModuleDependency?
    
    /// 组件内部自己处理openURL事件, false为外部处理
    public var canOpenURL: Bool
    
    /// 组件内部自己处理openProfil事件, false为外部处理
    public var canOpenProfile: Bool
    
    /// 翻译语言
    public var translateLang: CommentTranslateLang
    
    public var translateMode: CommentTranslateMode = .onlyShowTranslation
    
    /// 初始化评论组件时传入的必要参数集合
    /// - Parameters:
    ///   - token: 文档/页面token
    ///   - type: 文档/页面类型
    ///   - permission: 评论权限
    ///   - dependency: 评论组件依赖接入方的能力，评论组件是内部是弱引用，由接入方管理生命周期
    public init(token: String,
                type: Int,
                canOpenURL: Bool = false,
                canOpenProfile: Bool = false,
                translateLang: CommentTranslateLang,
                translateMode: CommentTranslateMode,
                permission: CommentModulePermission,
                dependency: DocCommentModuleDependency) {
        self.token = token
        self.type = type
        self.canOpenURL = canOpenURL
        self.canOpenProfile = canOpenProfile
        self.translateLang = translateLang
        self.dependency = dependency
        self.permission = permission
        self.translateMode = translateMode
    }
}

public typealias CommentTranslateConfig = CommentBusinessConfig.TranslateConfig
public struct CommentBusinessConfig {

    public struct TranslateConfig: Codable {
        
        // 展示逻辑
        public enum DisplayType: Int, Codable {
            case onlyShowOrigin = 1
            case onlyShowTranslation = 2
            case bothShow = 3
            case unKnown = 4
        }
        public let autoTranslate: Bool
        public let displayType: DisplayType
        public let enableCommentTranslate: Bool

        private enum CodingKeys: String, CodingKey {
            case autoTranslate = "enable_auto_translate"
            case displayType = "display_type"
            case enableCommentTranslate = "enable_comment_translate"
        }
        
        public init(autoTranslate: Bool,
                    displayType: CommentBusinessConfig.TranslateConfig.DisplayType,
                    enableCommentTranslate: Bool) {
            self.autoTranslate = autoTranslate
            self.displayType = displayType
            self.enableCommentTranslate = enableCommentTranslate
        }
    }
    
    public struct MonitorConfig {
        public let fpsEnable: Bool
        public let editEnable: Bool
        public let loadedEnable: Bool

        public init(fpsEnable: Bool, editEnable: Bool, loadedEnable: Bool) {
            self.fpsEnable = fpsEnable
            self.editEnable = editEnable
            self.loadedEnable = loadedEnable
        }
    }

    /// 是否支持在组件内部处理openURL
    public let canOpenUR: Bool
    /// 是否支持在组件内部处理OpenProfile
    public let canOpenProfile: Bool
    /// 是否显示评论拷贝入口
    public let canCopyCommentLink: Bool

    public let translateConfig: TranslateConfig?
    
    public var monitorConfig: MonitorConfig?

    /// 指定的vc模态显示style
    public var customPresentationStyle: UIModalPresentationStyle?
    
    /// 无添加协作者权限时，评论中无阅读权限者人名是否置灰
    public var canShowDarkName: Bool

    public weak var imagePermissionDataSource: CommentImagePermissionDataSource?

    public var sendResultReporter: CommentSendResultReporterType?

    public init(canOpenURL: Bool = true,
                canOpenProfile: Bool = true,
                canCopyCommentLink: Bool = false,
                monitorConfig: MonitorConfig? = nil,
                translateConfig: TranslateConfig? = nil,
                customPresentationStyle: UIModalPresentationStyle? = nil,
                canShowDarkName: Bool = true,
                sendResultReporter: CommentSendResultReporterType? = nil) {
        self.canOpenUR = canOpenURL
        self.canOpenProfile = canOpenProfile
        self.canCopyCommentLink = canCopyCommentLink
        self.translateConfig = translateConfig
        self.monitorConfig = monitorConfig
        self.customPresentationStyle = customPresentationStyle
        self.canShowDarkName = canShowDarkName
        self.sendResultReporter = sendResultReporter
    }
}

public protocol CommentDocsInfo {
    var type: DocsType { get }
    var objToken: String { get }
}

/// 评论图片权限(文档附件权限)
public protocol CommentImagePermissionDataSource: AnyObject {
    func syncGetCommentImagePermission() -> CommentImagePermission?
    func asyncGetCommentImagePermission(token: String, completion: @escaping (CommentImagePermission) -> Void)
}

public struct CommentImagePermission {
    public let canPreview: Bool
    public let canDownload: Bool
    public init(canPreview: Bool, canDownload: Bool) {
        self.canPreview = canPreview
        self.canDownload = canDownload
    }
}

extension CommentBusinessConfig {
    // 发送场景
    @frozen public enum SendScene {
        case add // 新增
        case reply // 回复
        case edit // 编辑
    }
    // 发送结果
    @frozen public enum SendResult {
        case success // 成功
        case failure(reason: String) // 失败
        case cancel // 取消 (发送评论后还未得到结果时退出文档)
    }
}

/// 用户视角发送成功率埋点
public protocol CommentSendResultReporterType {
    var commentDocsInfoBlock: (() -> CommentDocsInfo?)? { get set }
    func markEventStart(uuid: String, scene: CommentBusinessConfig.SendScene)
    func markEventEndBy(uuid: String, result: CommentBusinessConfig.SendResult)
    func markEventEndBy(commentData: CommentData)
    func markDocExit()
}
