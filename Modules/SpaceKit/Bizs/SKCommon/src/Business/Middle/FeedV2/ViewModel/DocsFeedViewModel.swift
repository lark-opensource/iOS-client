//
//  DocsFeedViewModel.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/14.
// swiftlint:disable file_length

import RxSwift
import RxCocoa
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import SpaceInterface
import SKInfra


/// 粘贴功能不需要依赖具体的实现，用于单测
protocol FeedPasteboardType {
    func copyString(_ string: String)
}

public protocol DocsFeedAPI: AnyObject {
    
    /// 通知前端高度 drive没有
    func setPanelHeight(height: CGFloat)
    
    /// 消除红点
    func didClearBadge(messageIds: [String])
    
    func panelDismiss()
    
    /// 展示个人信息
    func showProfile(userId: String)
    
    /// 打开文档
    func openUrl(url: URL)
    
    /// 翻译评论。drive没有
    func translate(commentId: String, replyId: String)
    
    func clickMessage(message: FeedMessageModel)

    /// 通知前端`免打扰`状态
    func didChangeMuteState(isMute: Bool)
}

enum FeedOpenStatus: String {
    case success
    case fail
    case cancel
    case timeout
}

class DocsFeedViewModel {
    
    class FeedPasteboard: FeedPasteboardType {
        init() {}
        func copyString(_ string: String) {
            _ = SKPasteboard.setString(string, psdaToken: PSDATokens.Pasteboard.docs_feed_do_copy)
        }
    }

    enum HUDType {
       case success(String)
       case failure(String)
       case tips(String)
       case loading(String)
       case close
    }
    
    struct Input {
        var trigger: BehaviorRelay<[String: Any]>
        var eventDrive: PublishRelay<FeedPanelViewController.Event>
        var scrollEndRelay: PublishRelay<[IndexPath]>
    }

    struct Output {
        var data: PublishRelay<FeedDataType>
        var close: PublishRelay<Void>
        var readRelay: PublishRelay<IndexPath>
        var showHUD: PublishRelay<HUDType>
        var showEmptyView: PublishRelay<Bool>
        var loading: PublishRelay<Bool>
        var reloadSection: PublishRelay<IndexPath>
        var scrollToItem: PublishRelay<IndexPath>
        var gapStateRelay: PublishRelay<DraggableViewController.GapState>
        var muteToggleClickable: PublishRelay<Bool>
        var muteToggleIsMute: PublishRelay<Bool?> // 是否免打扰, nil则不显示按钮
    }
    
    var status: FeedOpenStatus? {
        willSet {
            if status == nil {
                self.timeDisposeBag = DisposeBag()
                self.report(status: newValue ?? .success)
            }
        }
    }
    
    private(set) var disposeBag = DisposeBag()
    var cacheDisposeBag = DisposeBag()
    var serverDisposeBag = DisposeBag()
    var timeDisposeBag = DisposeBag()
    
    var viewDidLoadRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    /// 和前端交互的接口
    private weak var api: DocsFeedAPI?
    
    /// 记录原始数据可用debug
    private(set) var originData: [String: Any]?
    
    /// 记录各个阶段的时间戳
    var timeStamp: [FeedTimeStage: TimeInterval] = [:]
    
    /// 记录从Lark Feed还是铃铛进入DocsFeed
    private(set) var from: FeedFromInfo
    
    /// 负责后台接口请求，在此用于检查用户权限
    private(set) var service: DocsFeedService
    
    /// 负责拉取缓存数据
    private(set) var feedCache: FeedCache
    
    /// 提供给UI订阅的输出事件集合
    private(set) var output: Output?
    
    private(set) var input: Input?
    
    /// 保存解析后的模型数据，和UI上展示的是同个实例
    private var messages: [FeedMessageModel] = []
    
    /// 文档信息
    private(set) var docsInfo: DocsInfo
    
    var error: DocsFeedService.FeedError?
    
    /// 记录已读的消息， 防止后台重复推送过来，状态不同步导致出现红点闪烁问题
    var readedMessages: [String: Bool] = [:]
    
    /// 记录未读的消息
    var unReadedMessages: [(Int, String)] = []
    
    /// 保存初始化时外面传进来的参数
    var initParam: [String: Any]?
    
    /// 处理模型解析的队列
    let queue = DispatchQueue(label: "com.doc.feed.DocsFeedViewModel")
    
    var shouldScrollToFirstUnread: Bool = true
    var clearMessageCache: [String: FeedMessageModel] = [:]
    
    private let userPermissionsUpdateNotifier = PublishSubject<MultipleFilesResponseModel>()
    
    lazy private var permissionManager: PermissionManager? = {
        return DocsContainer.shared.resolve(PermissionManager.self)
    }()
    
    weak var controller: UIViewController?
    
    var pasteboardType: FeedPasteboardType
    
    public weak var permissionDataSource: CCMCopyPermissionDataSource?
    
    init(api: DocsFeedAPI,
         from: FeedFromInfo,
         docsInfo: DocsInfo,
         pasteboardType: FeedPasteboardType = FeedPasteboard(),
         param: [String: Any]? = nil,
         controller: UIViewController) {
        self.pasteboardType = pasteboardType
        self.api = api
        self.from = from
        self.docsInfo = docsInfo
        self.initParam = param
        self.controller = controller
        self.service = DocsFeedService(docsInfo, from)
        self.feedCache = FeedCache(docsInfo: docsInfo)
        
        self.checkExternalStage()
        self.recordTimeout()
        self.setupNotification()
    }
    
    func transform(input: Input) -> Output {
        let feedDataRelay = PublishRelay<FeedDataType>()
        let closeRelay = PublishRelay<Void>()
        let showEmptyViewRelay = PublishRelay<Bool>()
        let loadingRelay = PublishRelay<Bool>()
        let muteToggleIsMute = PublishRelay<Bool?>()
        
        input.trigger
             .skip(1)
             .do(onNext: { [weak self] (parameters) in
                self?.record(stage: .receiveFrontend)
                self?.originData = parameters
                let isRemind = parameters["is_remind"] as? Bool //开启了提醒
                muteToggleIsMute.accept(isRemind.map{ !$0 })
             })
             .map({ ($0["message"] as? [[String: Any]]) ?? [] })
             .mapFeedModel(type: [FeedMessageModel].self, queue: self.queue)
             .observeOn(MainScheduler.instance)
             .subscribe(onNext: { [weak self] (models) in
                guard let self = self else { return }
                self.cacheDisposeBag = DisposeBag()
                loadingRelay.accept(false)
                // 记录关键节点时间戳
                self.record(stage: .deserialize)
                // 更新UI
                self.updateMessages(.frontend(models))
                
                let isUpdate = self.originData != nil
                DocsLogger.feedInfo("\(isUpdate ? "update" : "show") feed count: \(models.count) deserialize: \(self.getStageTime(from: .receiveFrontend, to: .deserialize))")
                if self.initParam != nil, UserScopeNoChangeFG.HYF.scrollFeedToFirstUnread {
                      self.initParam = nil
                }
            }, onError: { (_) in
                DocsLogger.error("DocsFeed Model deserialize fail")
                showEmptyViewRelay.accept(true)
            }).disposed(by: disposeBag)
                 
        handleScrollEndEvent(event: input.scrollEndRelay)
        handleViewEvent(event: input.eventDrive)
        
        output = Output(data: feedDataRelay,
                        close: closeRelay,
                        readRelay: PublishRelay<IndexPath>(),
                        showHUD: PublishRelay<HUDType>(),
                        showEmptyView: showEmptyViewRelay,
                        loading: loadingRelay,
                        reloadSection: PublishRelay<IndexPath>(),
                        scrollToItem: PublishRelay<IndexPath>(),
                        gapStateRelay: PublishRelay<DraggableViewController.GapState>(),
                        muteToggleClickable: PublishRelay<Bool>(),
                        muteToggleIsMute: muteToggleIsMute)
        self.input = input
        return output!
    }

    func updateMessages(_ dataType: FeedDataType) {
        switch dataType {
        case let .cache(messages),
             let .frontend(messages),
             let .server(messages):
            if let msgs = messages as? [FeedMessageModel] {
                self.messages = msgs
            }
            // 数据为空要展示空占位图
            output?.showEmptyView.accept(messages.isEmpty)
        }
        let results = findUnreadMessage(self.messages, isCache: dataType.isCache)
        unReadedMessages = results
        // 更新UI
        output?.data.accept(dataType)
        
        if canScrollFeedToFirstUnread,
           shouldScrollToFirstUnread,
           !dataType.isCache,
           let firstUnread = results.first {
            if !viewDidLoadRelay.value, let output = self.output {
                DocsLogger.feedInfo("scrollToItem later: \(firstUnread)")
                viewDidLoadRelay.filter({ $0 })
                                .map { _ in IndexPath(row: firstUnread.index, section: 0) }
                                .bind(to: output.scrollToItem)
                                .disposed(by: disposeBag)
            } else {
                DocsLogger.feedInfo("scrollToItem now: \(firstUnread)")
                output?.scrollToItem.accept(IndexPath(row: firstUnread.index, section: 0))
            }
        }
        if !dataType.isCache, canScrollFeedToFirstUnread {
            shouldScrollToFirstUnread = false
        }
    }
    
    var canScrollFeedToFirstUnread: Bool {
        return UserScopeNoChangeFG.HYF.scrollFeedToFirstUnread && self.initParam == nil
    }

    @discardableResult
    func findUnreadMessage(_ messages: [FeedMessageModel], isCache: Bool) -> [(index: Int, id: String)] {
        var results: [(Int, String)] = []
        for (idx, message) in messages.enumerated()  {
            message.associatedDocsType = self.docsInfo.inherentType
            guard message.status == .unread, message.cellIdentifier != FeedCommentEmptyCell.reuseIdentifier else {
               continue
            }
            results.append((idx, message.messageId))
        }
        if !results.isEmpty {
            DocsLogger.feedInfo("unread messageIds isCache:\(isCache) count:\(results.count) messageIds:\(results)")
        }
        return results
    }

    func toggleMuteState(_ isMute: Bool) {
        output?.showHUD.accept(.loading(BundleI18n.SKResource.LarkCCM_Common_Loading_Toast))
        output?.muteToggleClickable.accept(false)
        
        service.toggleMuteState(isMute) { [weak self] result in
            switch result {
            case .success:
                let mutedText = BundleI18n.SKResource.LarkCCM_Docs_Mute_Toast
                let notifyText = BundleI18n.SKResource.LarkCCM_Docs_Unmute_Toast
                let text = isMute ? mutedText : notifyText
                self?.output?.showHUD.accept(.success(text))
                self?.api?.didChangeMuteState(isMute: isMute) // 告知前端
                self?.output?.muteToggleIsMute.accept(isMute)
                self?.reportMuteClick(isMute)
            case .failure(let error):
                self?.output?.showHUD.accept(.failure(error.localizedDescription))
            }
            self?.output?.muteToggleClickable.accept(true)
        }
    }
    
    func toggleCleanButton() {
        reportCleanMessageClick()
        //传给后端的是当前时间（毫秒级）
        let currentTime = floor(Date().timeIntervalSince1970 * 1000)
        service.toggleCleanButton(currentTime) { [weak self] result in
            switch result {
            case .success:
                self?.output?.showHUD.accept(.success(BundleI18n.SKResource.LarkCCM_Docs_Notifications_AllRead_Menu_Mob))
                self?.fetchServiceData()
            case .failure(let error):
                self?.output?.showHUD.accept(.failure(error.localizedDescription))
            }
        }
    }

    deinit {
        DocsLogger.feedInfo("docsFeed deinit")
        // 缓存数据
        self.feedCache.setCache(messages)

        // 立即执行延时任务
        if UserScopeNoChangeFG.HYF.scrollFeedToFirstUnread {
            for (_, model) in self.clearMessageCache {
                DocsLogger.feedInfo("perform delay task id:\(model.messageId)")
                self.clearBadge(with: model, at: IndexPath(row: -1, section: 0))
            }
        }
    }
}


// MARK: - handler

extension DocsFeedViewModel {
    
    private func handleScrollEndEvent(event: PublishRelay<[IndexPath]>) {
        guard UserScopeNoChangeFG.HYF.scrollFeedToFirstUnread else { return }
        event.subscribe(onNext: { [weak self] indexPaths in
            guard let self = self else { return }
            let results = indexPaths.compactMap { indexPath in
                if let message = self.messages.safe(index: indexPath.row),
                   message.cellIdentifier != FeedCommentEmptyCell.reuseIdentifier  {
                    return (indexPath.row, message.messageId, message.status == .unread)
                } else {
                    return nil
                }
            }
            DocsLogger.feedInfo("scrollEnd results:\(results)")
        }).disposed(by: disposeBag)
    }
    
    /// Feed一级事件
    private func handleViewEvent(event: PublishRelay<FeedPanelViewController.Event>) {
        event.subscribe(onNext: { [weak self] (event) in
            guard let self = self else { return }
            switch event {
            
            case .create: // 初始化时
                self.handleCreate()
                self.loadingIfNeed()
                
            case let .cellClick(indexPath): // cell点击
                self.handleCellClickEvent(indexPath)
                
            case let .viewDidLoad(panelHeight),
                 let .repeatShow(panelHeight):
                self.api?.setPanelHeight(height: panelHeight)
                DocsLogger.feedInfo("viewDidLoad")
                if UserScopeNoChangeFG.HYF.scrollFeedToFirstUnread {
                    self.output?.data.accept(.cache(self.messages))
                }
                self.viewDidLoadRelay.accept(true)
                
            case .viewDidAppear:
                self.record(stage: .viewDidAppear)
                DocsLogger.feedInfo("viewDidAppear")
                if self.error == .forbidden { // 面板要在viewDidAppear才能关成功
                    self.output?.close.accept(())
                }
                
            case let .cellWillDisplay(indexPath): // cell准备出现消除红点
                // 消除红点
                if let message = self.messages.safe(index: indexPath.row),
                   message.status == .unread {
                    let item = DispatchWorkItem { [weak self] in
                        self?.clearBadge(with: message, at: indexPath)
                        self?.output?.readRelay.accept(indexPath)
                        self?.readedMessages[message.messageId] = true
                        self?.clearMessageCache[message.messageId] = nil
                    }
                    self.clearMessageCache[message.messageId] = message
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2000, execute: item)
                }
                
            case .dismiss: // 面板关闭通知前端
                self.handleDismiss()
                self.debugReport()
            
            case let .cellEvent(indexPath, event): // cell内容事件
                self.handleCellEvent(indexPath: indexPath, event: event)
            
            case .renderBegin:
                self.record(stage: .renderBegin)
                
            case let .renderEnd(dataType):
                // 只有前端和后台数据渲染成功才上报
                switch dataType {
                case .frontend, .server:
                    self.record(stage: .renderEnd)
                    self.status = .success
                case .cache:
                    break
                }
            }
        }).disposed(by: disposeBag)
    }
    
    /// 面板初始化的一些操作
    func handleCreate() {
        self.record(stage: .create)
        if let param = initParam {
            DocsLogger.feedInfo("使用初始化数据")
            input?.trigger.accept(param)
        } else {
            fetchServiceData()
            fetchCache()
        }
    }
    
    func loadingIfNeed() {
        self.output?.loading.accept(true)
    }
    
    func clearBadge(with message: FeedMessageModel, at indexPath: IndexPath) {
        self.api?.didClearBadge(messageIds: [message.messageId])
        self.service.clearBadge(messageIds: [message.messageId]) { (error) in
            if let err = error {
                DocsLogger.feedError("clear Feed badge interface fail index: \(indexPath.row) id:\(message.messageId) error: \(err)")
            } else {
                DocsLogger.feedInfo("clear Feed badge interface success index: \(indexPath.row) id:\(message.messageId) ")
            }
        }
        message.status = .read
    }
}

// MARK: - UI事件

extension DocsFeedViewModel {
    
    /// Feed二级事件：Cell内容上的事件
    func handleCellEvent(indexPath: IndexPath, event: FeedCommentCell.Event) {
        switch event {
        case let .content(contentEvent),
             let .translated(contentEvent) : // 长摁评论后的操作
            if let message = self.messages.safe(index: indexPath.row),
                message.type == nil {
                DocsLogger.feedError("cellEvent message type not supported")
                return
            }
            switch contentEvent {
            case .copy:
                handleCopy(indexPath: indexPath, event: event)
                
            case .translate:
                handleTranslate(indexPath: indexPath)
                
            case .showOriginal:
                handleShowOriginal(indexPath: indexPath)
                
            case let .tap(label, gesture):
                handleCommentClick(indexPath, label, gesture)
            }
        case .tapAvatar:
            handleTapAvatarEvent(indexPath)
        }
    }
    
    /// 点击了拷贝评论
    func handleCopy(indexPath: IndexPath, event: FeedCommentCell.Event) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation, let permissionService = permissionDataSource?.getCopyPermissionService() {
            _handleCopy(indexPath: indexPath, event: event, permissionService: permissionService)
        } else {
            let docType = docsInfo.type
            let token = docsInfo.token
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: docType, token: token)
            _handleCopy(indexPath: indexPath, event: event, validateResult: result)
        }
    }

    func _handleCopy(indexPath: IndexPath, event: FeedCommentCell.Event, permissionService: UserPermissionService) {
        let response = permissionService.validate(operation: .copyContent)
        guard let message = messages.safe(index: indexPath.row) else { return }
        guard let controller else { return }
        response.didTriggerOperation(controller: controller, BundleI18n.SKResource.Doc_Doc_CopyFailed)
        guard response.allow else {
            copyForbiddenReport(in: message)
            return
        }
        if case .content = event {
            pasteboardType.copyString(message.contentAttiString?.string ?? "")
        } else {
            pasteboardType.copyString(message.translateAttiString?.string ?? "")
        }
        output?.showHUD.accept(.success(BundleI18n.SKResource.Doc_Doc_CopySuccess))
    }
    
    /// (为了给单测调用)
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func _handleCopy(indexPath: IndexPath, event: FeedCommentCell.Event, validateResult: CCMSecurityPolicyService.ValidateResult) {
        guard let message = self.messages.safe(index: indexPath.row) else { return }
        let docType = docsInfo.type
        let token = docsInfo.token
        let action = { [weak self] in
            // 再次校验复制权限, 区分admin / owner
            let adminAllow = self?.permissionDataSource?.adminAllowCopyFG() ?? false
            let ownerAllow = self?.permissionDataSource?.ownerAllowCopyFG() ?? false
            switch (adminAllow, ownerAllow) {
            case (true, true):
                if case .content = event {
                    self?.pasteboardType.copyString(message.contentAttiString?.string ?? "")
                } else {
                    self?.pasteboardType.copyString(message.translateAttiString?.string ?? "")
                }
                self?.output?.showHUD.accept(.success(BundleI18n.SKResource.Doc_Doc_CopySuccess))
            case (true, false):
                self?.output?.showHUD.accept(.failure(BundleI18n.SKResource.Doc_Doc_CopyFailed))
                self?.copyForbiddenReport(in: message)
            case (false, _):
                self?.output?.showHUD.accept(.failure(BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast))
                self?.copyForbiddenReport(in: message)
            }
        }
        
        if validateResult.allow {
            action()
        } else {
            switch validateResult.validateSource {
            case .fileStrategy:
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: docType, token: token)
            case .securityAudit:
                if let view = controller?.view {
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: view)
                }
            case .dlpDetecting, .dlpSensitive, .unknown, .ttBlock:
                DocsLogger.info("unknown type or dlp type")
            }
            
        }
    }
    
    var translationTools: CommentTranslationToolProtocol?  {
        guard let tool = DocsContainer.shared.resolve(CommentTranslationToolProtocol.self) else {
            DocsLogger.feedError("translationTools is nil")
            return nil
        }
        return tool
    }
    /// 点击翻译评论
    func handleTranslate(indexPath: IndexPath) {
        // 保存翻译状态
        guard let message = messages.safe(index: indexPath.row) else {
            return
        }
       
        translationTools?.remove(store: message)
        if message.showTranslation() {
            output?.reloadSection.accept(indexPath)
        } else {
            self.api?.translate(commentId: message.commentId, replyId: message.replyId)
        }
    }
    
    /// 点击展示原文
    func handleShowOriginal(indexPath: IndexPath) {
        if let message = messages.safe(index: indexPath.row) {
            translationTools?.add(store: message)
        }
        output?.reloadSection.accept(indexPath)
    }
    
    /// 点击Cell 定位到评论
    func handleCellClickEvent(_ indexPath: IndexPath) {
        guard let message = self.messages.safe(index: indexPath.row) else {
            return
        }
        if let toast = message.autoStyled.toastTextWhenTapped {
            DocsLogger.feedInfo("did show native toast: \(toast)")
            output?.showHUD.accept(.tips(toast))
        }
        
        if message.isWhole {
            if message.commentDelete || message.finish { // 被删除or被解决的全文评论点了不收起
            } else { // 点正常的全文评论就收起
                output?.close.accept(())
            }
        }
        // TODO: PermissionSDK update
        // 没有文档预览权限时评论直接收起
        if permissionDataSource?.canPreview() != true {
            output?.close.accept(())
        }
        let readed = self.readedMessages[message.messageId] ?? false
        if !readed {
            self.clearBadge(with: message, at: indexPath)
        }
        api?.clickMessage(message: message)
    }
    
    /// 不关闭Feed面板，在Feed面板上，打开个人信息页面
    func handleTapAvatarEvent(_ indexPath: IndexPath) {
        guard let message = self.messages.safe(index: indexPath.row), message.typeSupported else {
            DocsLogger.feedError("message is nil or unsupported")
            return
        }
        output?.close.accept(())
        api?.showProfile(userId: message.userId)
    }
    
    /// 评论内容点击
    private func handleCommentClick(_ indexPath: IndexPath, _ label: UILabel, _ gesture: UITapGestureRecognizer) {
        let detailLocation = gesture.location(in: label)
        if label.bounds.contains(detailLocation), let attributedText = label.attributedText {
            let storage = NSTextStorage(attributedString: attributedText)
            let manager = NSLayoutManager()
            storage.addLayoutManager(manager)
            let container = NSTextContainer(size: CGSize(width: label.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = label.numberOfLines
            container.lineBreakMode = label.lineBreakMode
            manager.addTextContainer(container)
            let index = manager.characterIndex(for: detailLocation, in: container, fractionOfDistanceBetweenInsertionPoints: nil)
            let attributes = attributedText.attributes(at: index, effectiveRange: nil)

            if let atInfo = attributes[AtInfo.attributedStringAtInfoKey] as? AtInfo {
                DocsLogger.feedInfo("点击了@别人或者文档")
                if atInfo.type == .user {
                    openProfile(with: atInfo)
                } else if  atInfo.token == docsInfo.objToken {
                    output?.showHUD.accept(.failure(BundleI18n.SKResource.Doc_Normal_SamePageTip))
                } else {
                    var docsUrl: URL?
                    if let url = atInfo.hrefURL() {
                        docsUrl = url
                    }
                    if let url = docsUrl {
                        output?.close.accept(())
                        api?.openUrl(url: url)
                    } else {
                        DocsLogger.feedError("url is invalid")
                    }
                }
                if atInfo.type != .user, atInfo.type != .unknown {
                    SecLinkStatistics.didClickFeedContentLink(type: docsInfo.type)
                }
            } else if let urlInfo = attributes[AtInfo.attributedStringURLKey] as? URL,
                let modifiedUrl = urlInfo.docs.avoidNoDefaultScheme {
                output?.close.accept(())
                api?.openUrl(url: modifiedUrl)
                DocsLogger.feedInfo("点击了链接")
                SecLinkStatistics.didClickFeedContentLink(type: docsInfo.type)
            } else if let attachment = attributes[.attachment] as? NSTextAttachment,
                let atInfo = attachment.additionalInfo as? AtInfo {
                openProfile(with: atInfo)
                DocsLogger.feedInfo("点击了@自己")
            } else { // 当作点击Cell, 定位到相应评论
                handleCellClickEvent(indexPath)
            }
        }
    }
    
    /// 通过AtInfo打开个人信息页面
    private func openProfile(with atInfo: AtInfo) {
        output?.close.accept(())
        api?.showProfile(userId: atInfo.token)
    }
    
    func handleDismiss() {
        self.api?.panelDismiss()
        self.status = .cancel
        NotificationCenter.default.post(name: Notification.Name.BrowserFullscreenMode,
                                        object: nil,
                                        userInfo: ["enterFullscreen": false,
                                                   "token": docsInfo.objToken])
    }
}

// MARK: - Report

extension DocsFeedViewModel {
    
    private func copyForbiddenReport(in message: FeedMessageModel) {
        guard message.type != nil else { return }
        let location = message.isWhole ? "global_comments" : "part_comments"
        let isHistory = "false"
        let params: [String: Any] = ["forbidden_location": location,
                                     "is_history": isHistory]
        DocsTracker.newLog(enumEvent: .permissionCopyForbiddenToastView, parameters: params)
    }

}

// MARK: - extension

extension DocsLogger {

    public class func feedInfo(_ log: String) {
        DocsLogger.info(" 🍖 \(log)", component: LogComponents.docsFeed)
    }

    public class func feedError(_ log: String) {
        DocsLogger.error(" 🍖 \(log)", component: LogComponents.docsFeed)
    }
}

extension Array where Element == FeedMessageModel {
    
    func safe(index: Int) -> FeedMessageModel? {
        guard self.count > index else {
            DocsLogger.feedError("handleCellClickEvent messages count: \(self.count)")
            return nil
        }
        return self[index]
    }
}
