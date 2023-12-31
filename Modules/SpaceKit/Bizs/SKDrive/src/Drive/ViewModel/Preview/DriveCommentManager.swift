//
//  DriveCommentManager.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/8.
//

import Foundation
import SwiftyJSON
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignToast
import SpaceInterface
import LarkEmotionKeyboard
import SKInfra

public struct UploadCommentContext {
    public let docsInfo: DocsInfo
    public let canComment: Bool
    public let canCopy: Bool
    public let canRead: Bool
    public let canShowCollaboratorInfo: Bool
    public let canPreview: Bool
}

class DriveCommentManager {
    private(set) var messageUnreadCount = BehaviorRelay<Int>(value: 0)
    private(set) var openMessageFeed = PublishSubject<()>()
    private(set) var messageDidClickComment = PublishSubject<(String, FeedMessageType)>()
    private(set) var messageWillDismiss = PublishSubject<Void>()
    private(set) var commentVCDismissed = PublishSubject<Void>()

    private(set) var commentsDataUpdated = PublishSubject<(rnCommentData: RNCommentData, areas: [DriveAreaComment])>()
    private(set) var commentCount = BehaviorRelay<Int>(value: 0)
    private(set) var commentVCSwitchToPage = PublishSubject<Int>()
    private(set) var commentVCSwitchToComment = PublishSubject<String>()

    private(set) var updateLikeCountEvent = PublishSubject<()>()
    private(set) var updateLikeListEvent = PublishSubject<()>()

    private(set) var docsInfo: DocsInfo
    private var fileInfo: DriveFileInfo
    private var canComment: Bool
    private(set) var canCopy: Bool = false
    private(set) var canPreviewProvider: () -> Bool
    weak var hostModule: DKHostModuleType?
    private var commentPermission: CommentPermission {
        return canComment ? [.canComment, .canResolve, .canShowMore, .canShowVoice, .canReaction] : [.canShowMore]
    }

    @ThreadSafe
    private(set) var areaCommentManager: DriveAreaCommentManager
    @ThreadSafe
    private(set) var commentAdapter: DriveCommentAdapter
    @ThreadSafe
    private(set) var likeDataManager: DriveLikeDataManager

    private(set) var currentMessages: [NewMessage]?
    let disposeBag = DisposeBag()
    // VC Comment Follow
    weak var followDelegate: FollowableContentDelegate?
    weak var followAPIDelegate: SpaceFollowAPIDelegate?
    // 存储当前的state
    let commentStateRelay = BehaviorRelay<State>(value: .default)
    // 接收来自 follow 的 state
    let commentFollowStateSubject = PublishSubject<State>()
    var additionalStatisticParameters: [String: String]?
    
    
    /// 记录可能来自larkFeed的消息
    var feedFromInfo: FeedFromInfo?
    
    weak var hostController: UIViewController? {
        didSet {
            commentAdapter.hostController = hostController
        }
    }
    
    /// 后续使用这个类接入评论
    lazy var commentModule: DriveCommentModuleType? = {
        if let emojiImageService = EmojiImageService.default {
            emojiImageService.loadReactions()
        } else {
            assertionFailure("EmojiImageService is nil")
        }
        let api = CommentRNAPIAdaper(rnRequest: self,
                                     commentService: self,
                                     dependency: self)
        let params = CommentModuleParams(dependency: self, apiAdaper: api)
        return DocsContainer.shared.resolve(DriveCommentModuleType.self,
                                            argument: params)
    }()
    var isCanSendComment: Bool = true
    var isShowComment: Bool = false


    init(canComment: Bool,
         canShowCollaboratorInfo: Bool,
         canPreviewProvider: @escaping () -> Bool,
         docsInfo: DocsInfo,
         fileInfo: DriveFileInfo,
         feedFromInfo: FeedFromInfo?) {
        self.docsInfo = docsInfo
        self.fileInfo = fileInfo
        self.canComment = canComment
        self.canPreviewProvider = canPreviewProvider
        self.feedFromInfo = feedFromInfo
        let permission: CommentPermission = canComment ? [.canComment, .canResolve, .canShowMore, .canShowVoice, .canReaction] : [.canShowMore]
        commentAdapter = DriveCommentAdapter(docsInfo: docsInfo,
                                             permission: permission,
                                             permissionService: hostModule?.permissionService,
                                             canCopy: canCopy,
                                             canRead: true,
                                             canPreviewProvider: canPreviewProvider)
        areaCommentManager = DriveAreaCommentManager(fileToken: docsInfo.objToken,
                                                     version: fileInfo.dataVersion,
                                                     docsType: docsInfo.type)
        likeDataManager = DriveLikeDataManager(docInfo: docsInfo, canShowCollaboratorInfo: canShowCollaboratorInfo)
        _configCommentAdapter()
        _configAreaCommentManager()
        _configLikeDataManager()
    }

    private func _configCommentAdapter() {
        commentAdapter = DriveCommentAdapter(docsInfo: docsInfo,
                                             permission: commentPermission,
                                             permissionService: hostModule?.permissionService,
                                             canCopy: canCopy,
                                             canRead: true,
                                             canPreviewProvider: canPreviewProvider)
        commentAdapter.canManageMetaGetter = { [weak self] in self?.canManageDriveMeta() ?? false }
        commentAdapter.canEditGetter = { [weak self] in self?.canEdit() ?? false }
        commentAdapter.followAPIDelegate = followAPIDelegate
        commentAdapter.commentFilter = { [weak self] rnCommentData in
            guard let self = self else {
                rnCommentData.comments.removeAll()
                return (rnCommentData, [])
            }
            return self._commentsUpdated(rnCommentData)
        }
        commentAdapter.messageFilter = { [weak self] rnResponse in
            guard let self = self else { return ([:], []) }
            return (self._handleRawMessageData(rnResponse), self.currentMessages ?? [])
        }
        commentAdapter.messageDidRead = { [weak self] messages in
            self?._updateBadgeWhileReading(with: messages)
        }
        commentAdapter.messageDidClickComment = { [weak self] (commentId, message) in
            self?.messageDidClickComment.onNext((commentId, message))
        }
        commentAdapter.messageWillDismiss = { [weak self] in
            self?.messageWillDismiss.onNext(())
        }
        commentAdapter.commentVCDismissed = { [weak self] in
            // 为了兼容老的逻辑，dismissed之前额外发送一次willDismiss的事件
            self?.messageWillDismiss.onNext(())
            self?.commentVCDismissed.onNext(())
        }
        commentAdapter.commentVCDidSwitchToPage = { [weak self] (page, commentID) in
            self?.commentVCSwitchToPage.onNext(page)
            self?.commentVCSwitchToComment.onNext(commentID)
        }
        commentAdapter.observeCommentCount { [weak self] (count) in
            self?.commentCount.accept(count)
        }
        
        commentAdapter.commentUpdate = { [weak self] (data, ids) in
            data.localCommentIds = ids
            self?.commentModule?.update(data)
        }
    }

    private func _configAreaCommentManager() {
        // 注册长链
        RNManager.manager.injectDriveCommonPushChannel()
        areaCommentManager.delegate = self
    }

    private func _configLikeDataManager() {
        likeDataManager.delegate = self
    }
}

/// 对外接口
extension DriveCommentManager {
    func update(context: UploadCommentContext, fileInfo: DriveFileInfo) {
        self.canComment = context.canComment
        self.canCopy = context.canCopy
        if self.docsInfo.objToken == context.docsInfo.objToken {
            commentAdapter.update(context.docsInfo, permission: commentPermission, canCopy: context.canCopy, canRead: context.canRead)
            areaCommentManager.update(fileToken: context.docsInfo.objToken,
                                      version: fileInfo.dataVersion,
                                      docsType: context.docsInfo.type)
            likeDataManager.update(canShowCollaboratorInfo: context.canShowCollaboratorInfo)
            commentAdapter.fetchCommentCount()
        } else {
            self.docsInfo = context.docsInfo
            self.fileInfo = fileInfo
            self.commentAdapter = DriveCommentAdapter(docsInfo: context.docsInfo,
                                                      permission: commentPermission,
                                                      permissionService: hostModule?.permissionService,
                                                      canCopy: context.canCopy,
                                                      canRead: context.canRead,
                                                      canPreviewProvider: canPreviewProvider)
            self.commentAdapter.canManageMetaGetter = { [weak self] in self?.canManageDriveMeta() ?? false }
            self.commentAdapter.canEditGetter = { [weak self] in self?.canEdit() ?? false }
            self.areaCommentManager = DriveAreaCommentManager(fileToken: context.docsInfo.objToken,
                                                              version: fileInfo.dataVersion,
                                                              docsType: context.docsInfo.type)
            self.likeDataManager = DriveLikeDataManager(docInfo: context.docsInfo, canShowCollaboratorInfo: context.canShowCollaboratorInfo)
            _configAreaCommentManager()
            _configLikeDataManager()
            _configCommentAdapter()
        }
        commentModule?.udpateDocsInfo(context.docsInfo)
        commentModule?.setCaptureAllowed(context.canCopy)
        if !context.canRead {
            commentModule?.hide()
        }
    }

    func update(docsInfo: DocsInfo) {
        // drive 拉取到最新的docsInfo会调用。保证feed的docsInfo必定是最新值
        DocsLogger.driveInfo("🐦drive comment get lateset docsInfo ，need to fetch again")
        self.docsInfo = docsInfo
        self.commentAdapter.update(docsInfo, permission: commentPermission, canCopy: canCopy, canRead: nil)
        self.commentAdapter.rnCommentDataManager.fetchFeedData(docInfo: docsInfo, response: { _ in })
    }
}

// MARK: - DriveCommentAdapter Callback
extension DriveCommentManager {
    /// 评论过滤：返回过滤后的评论数据，同时更新选区
    private func _commentsUpdated(_ rnCommentData: RNCommentData) -> (RNCommentData, [String]) {
        let data = areaCommentManager.updateComments(rnCommentData)
        DocsLogger.debug("areas count1: \(data.areaData.count)")
        commentsDataUpdated.onNext((rnCommentData: data.rnData, areas: data.areaData))
        return (data.rnData, data.areaData.partCommentIds)
    }

    /// 消息过滤
    // 0、反序列化json，用commentId过滤消息提醒
    // 1、过滤分享字段，消除分享的badge
    // 2、更新read的badge的数字
    // 3、重新序列化model，返回一个json
    @discardableResult
    private func _handleRawMessageData(_ data: Any) -> [String: Any] {
        guard let feedData = data as? [String: Any] else {
            DocsLogger.warning("cannot fetch message data")
            return [:]
        }
        return self._handleMessageData(feedData)
    }

    private func _handleMessageData(_ feedData: [String: Any]) -> [String: Any] {
        let areaComments = areaCommentManager.areaComments
        
        DocsLogger.driveInfo("_handleMessageData: areaComments:\(areaComments.count)")
        
        let areaCommentIDs = areaComments.map { (_, value) -> String in
            return value.commentID
        }
        var messages = NewMessage.deserializeMessages(JSON(feedData))
        DocsLogger.driveInfo("_handleMessageData: origin messages:\(messages.count)")
        
        messages = messages.filter({ (msg) -> Bool in
            areaCommentIDs.contains(msg.commentID) || msg.type == .share
        })

        DocsLogger.driveInfo("_handleMessageData: filtered messages:\(messages.count)")
        
        self.currentMessages = messages
        _changeUnreadCount(messages)
        messages = _changeMessageQuote(messages)
        let filteredJSON: [String: Any] = ["message": NewMessage.serializeMessages(messages)]
        return filteredJSON
    }

    private func _changeMessageQuote(_ messages: [NewMessage]) -> [NewMessage] {
        return messages.map { (message) -> NewMessage in
            let newMessage = message
            if let jsonData = message.quote.data(using: .utf8, allowLossyConversion: false),
                let dic = try? JSON(data: jsonData),
                let key = dic["key"].string {

                switch DriveMessageQuoteType(type: key) {
                case .comment: newMessage.quote = BundleI18n.SKResource.Drive_Drive_FeedComment
                case .text:
                    if let para = dic["params"].array,
                        let page = para.first?.string,
                        let text = para.last?.string {
                        newMessage.quote = BundleI18n.SKResource.Drive_Drive_QuoteText(page, text)
                    } else {
                        DocsLogger.warning("drive larkfeed text消息数据标签解析失败")
                        newMessage.quote = BundleI18n.SKResource.Drive_Drive_FeedComment
                    }
                case .page:
                    if let para = dic["params"].array,
                        let page = para.first?.string {
                        newMessage.quote = BundleI18n.SKResource.Drive_Drive_QuotePage(page)
                    } else {
                        DocsLogger.warning("drive larkfeed page消息数据标签解析失败")
                        newMessage.quote = BundleI18n.SKResource.Drive_Drive_FeedComment
                    }
                }

            } else {
                DocsLogger.warning("drive larkfeed消息数据标签解析失败")
                newMessage.quote = BundleI18n.SKResource.Drive_Drive_FeedComment
            }
            return newMessage
        }
    }

    private func _changeUnreadCount(_ messages: [NewMessage]) {
        var count = 0
        messages.forEach { (msg) in
            if msg.status == .unread && msg.related == true {
                count += 1
            }
        }
        messageUnreadCount.accept(count)
    }

    // 清除历史记录的bagde
    private func _clearHistoryBadge(data: Any) {
        guard let feedData = data as? [String: Any] else {
            DocsLogger.warning("cannot fetch message data")
            return
        }
        let historyData = self._filteredHistoryMessageData(feedData)
        DispatchQueue.main.async {
            self.clearBadge(with: historyData)
        }
    }

    // 过滤出历史消息的json
    private func _filteredHistoryMessageData(_ feedData: [String: Any]) -> [String] {
        let areaComments = areaCommentManager.filteredAreaComments
        let areaCommentIDs = areaComments.map({ $0.commentID })
        var messages = NewMessage.deserializeMessages(JSON(feedData))
        messages = messages.filter({ (msg) -> Bool in
            !areaCommentIDs.contains(msg.commentID) && msg.status == .unread && msg.type == .comment
        })

        if messages.filter({ $0.finish == false && $0.commentDelete == 0 }).count > 0 {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: nil,
                                              message: BundleI18n.SKResource.Drive_Drive_ViewHistoryMessage,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_OK,
                                              style: .default))
                UIViewController.docs.topMost(of: self.hostController)?.present(alert, animated: false, completion: nil)
            }
        }
        return messages.map({ $0.messageID })
    }

    private func _updateBadgeWhileReading(with didReadMessages: [String]) {
        guard var messages = self.currentMessages else { return }
        // 过滤掉已读的message
        messages = messages.filter({ !didReadMessages.contains( $0.messageID ) })
        _changeUnreadCount(messages)
    }

    func clearBadge(with ids: [String]) {
        let params = ["doc_type": docsInfo.inherentType,
                      "obj_token": docsInfo.token,
                      "isFromFeed": true,
                      DocsSDK.Keys.readFeedMessageIDs: ids] as [String: Any]
        guard let awesomeManager = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
            DocsLogger.driveInfo("FeedDiffReload----failed to clear badge")
            return
        }
        awesomeManager.sendReadMessageIDs(params, in: nil, callback: { _ in })
    }
}

// MARK: - DriveAreaCommentManagerDelegate
extension DriveCommentManager: DriveAreaCommentManagerDelegate {
    func commentsDataUpdated(_ rnCommentData: RNCommentData, areas: [DriveAreaComment]) {
        let partCommentIds = areas.partCommentIds
        commentAdapter.updateCommentViewControllerNoFilter(rnCommentData, partCommentIds: partCommentIds)
        DocsLogger.debug("areas count2: \(areas.count)")
        commentsDataUpdated.onNext((rnCommentData: rnCommentData, areas: areas))
    }

    func areasCommentsDataFirstUpdated() {
        // 用于第一次进来fetch数据
        commentAdapter.rnCommentDataManager.fetchFeedData(docInfo: docsInfo) { [weak self] (response) in
            guard let self = self else { return }
            /// 处理显示红点
            self.commentAdapter.decodeQueue.async {
                
                let isNil = self.currentMessages == nil
                let messageList = self.currentMessages ?? []
                let total = messageList.count
                let unread = messageList.filter({ $0.status == .unread }).count
                DocsLogger.driveInfo("🐦comment：drive fetch messages, total:\(total), unread:\(unread), currentMessages isNil:\(isNil)")
                
                if isNil || total == 0 {
                    let areaCommentsCount = (self.areaCommentManager.areaComments).count
                    DocsLogger.driveInfo("🐦comment：no messages, areaCommentsCount:\(areaCommentsCount)")
                    self.commentAdapter.newMessageHandler(response, filterCompletion: { [weak self] in
                        self?.prepare_handleMessageFeedFromLark(response)
                    })
                } else {
                    self.prepare_handleMessageFeedFromLark(response)
                }
            }
        }
    }
    
    // 非private，是为了给单测调用
    func prepare_handleMessageFeedFromLark(_ response: Any) {
        let isNil = self.currentMessages == nil
        let messageList = self.currentMessages ?? []
        let total = messageList.count
        let unread = messageList.filter({ $0.status == .unread }).count
        DocsLogger.driveInfo("drive feed：start jump, total:\(total), unread:\(unread), currentMessages isNil:\(isNil)")
        /// 处理是否从lark进入的情况
        _handleMessageFeedFromLark(response)
    }
    
    private func _handleMessageFeedFromLark(_ response: Any) {
        // 兜底逻辑
        let data = JSON(response)
        if let ver = data["data"]["badge"]["ver"].int32,
            let count = data["data"]["badge"]["count"].int32 {
            DocsFeedService.clearBadge(ver, count, docsInfo.objToken)
        }

        if let unreadMessages = self.currentMessages?.filter({ $0.status == .unread }) {
            // 表示当前有未读消息
            /// 判断是否是lark进入的
            guard self.feedFromInfo?.canShowFeedAtively == true else {
                DocsLogger.driveInfo("should not present message FeedViewController")
                return
            }
            /// 打点
            DriveStatistic.enterFileFromLark(additionalParameters: additionalStatisticParameters)

            if unreadMessages.count > 0 {
                /// 走打开面板的逻辑
                self.openMessageFeed.onNext(())
                DocsLogger.driveInfo("🐦comment：open from lark feed with \(unreadMessages.count) message")
            }
            /// 消除历史badge
            self._clearHistoryBadge(data: response)
        } else {
            if self.feedFromInfo?.isFromPushNotification ?? false { // 从推送消息进来的，直接打开feed面板
                openMessageFeed.onNext(())
                DocsLogger.driveInfo("🐦comment：open form lark push notification")
                _clearHistoryBadge(data: response)
            } else {
                DocsLogger.driveInfo("DriveCommentManager, isFromPushNotification == false")
            }
        }
    }
}

// MARK: - DriveLikeDataManagerDelegate
extension DriveCommentManager: DriveLikeDataManagerDelegate {
    func updateLikeCount() {
        updateLikeCountEvent.onNext(())
    }

    func updateLikeList() {
        updateLikeListEvent.onNext(())
    }

    func handleLikeFailed(code: Int) {
        guard code != NSURLErrorCancelled else {
            DocsLogger.driveInfo("like request canceled")
            return
        }
        guard let window = hostController?.view.window else { return }
        UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_LikeFail,
                               on: window)
    }
}

// MARK: - Permission
extension DriveCommentManager {

    func canManageDriveMeta() -> Bool {
        let canManage: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canManage = hostModule?.permissionService.validate(operation: .managePermissionMeta).allow ?? false
        } else {
            if let permission = hostModule?.permissionRelay.value.userPermissions {
                canManage = docsInfo.isFromWiki ? permission.canSinglePageManageMeta() : permission.canManageMeta()
            } else {
                canManage = false
            }
        }
        return canManage
    }
    
    func canEdit() -> Bool {
        guard let hostModule else { return false }
        let editable: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            editable = hostModule.permissionService.validate(operation: .edit).allow
        } else {
            editable = hostModule.permissionRelay.value.userPermissions?.canEdit() ?? false
        }
        return editable
    }
}

// MARK: - Unit Test
extension DriveCommentManager {
    
    func updateMessages(_ list: [NewMessage]) {
        self.currentMessages = list
    }
}
