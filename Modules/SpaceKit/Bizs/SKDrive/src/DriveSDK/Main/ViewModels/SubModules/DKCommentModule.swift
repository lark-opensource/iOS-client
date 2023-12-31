//
//  DKCommentModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/24.
//
// swiftlint:disable type_body_length file_length cyclomatic_complexity

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import LarkLocalizations
import SKResource
import UniverseDesignDialog
import UniverseDesignColor
import UniverseDesignToast
import SpaceInterface
import SKInfra
import LarkDocsIcon

private struct CommentPermission {

    let canCopy: Bool
    let canRead: Bool
    let canShowCollaboratorInfo: Bool
    let canPreview: Bool

    static var noPermission: CommentPermission {
        CommentPermission(canCopy: false, canRead: false, canShowCollaboratorInfo: false, canPreview: false)
    }

    init(canCopy: Bool, canRead: Bool, canShowCollaboratorInfo: Bool, canPreview: Bool) {
        self.canCopy = canCopy
        self.canRead = canRead
        self.canShowCollaboratorInfo = canShowCollaboratorInfo
        self.canPreview = canPreview
    }
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    init(permissionInfo: DrivePermissionInfo) {
        canCopy = permissionInfo.canCopy
        canRead = permissionInfo.isReadable
        canShowCollaboratorInfo = permissionInfo.canShowCollaboratorInfo
        canPreview = permissionInfo.userPermissions?.canPreview() ?? true
    }
}

private struct CommentViewState {
    let fileInfo: DriveFileInfo
    let docsInfo: DocsInfo
    let permissionInfo: CommentPermission
    let canComment: Bool
    let reachable: Bool
    let enableCommentBar: Bool
}

class DKCommentModule: DKBaseSubModule {
    private(set) var _commentManager: DriveCommentManager?
    private let _isDeleted = BehaviorSubject<Bool>(value: false)
    private let _isLegal = BehaviorSubject<DriveAuditState>(value: (result: .legal, reason: .none))
    private let _isKeyDeleted = BehaviorSubject<Bool>(value: false)
    private let _wikiIsDeleted = BehaviorRelay<Bool>(value: false)
    private var curCommentID: String?

    private var commentPermission: CommentPermission {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let service = hostModule?.permissionService else {
                return .noPermission
            }
            let canCopy = service.validate(operation: .copyContent).allow
            let canRead = service.validate(operation: .view).allow
            let canShowCollaboratorInfo = service.validate(operation: .viewCollaboratorInfo).allow
            let canPreview = service.validate(operation: .preview).allow
            return CommentPermission(canCopy: canCopy,
                                     canRead: canRead,
                                     canShowCollaboratorInfo: canShowCollaboratorInfo,
                                     canPreview: canPreview)
        } else {
            return CommentPermission(permissionInfo: permissionInfo)
        }
    }

    deinit {
        DocsLogger.driveInfo("DKCommentModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            switch action {
            case let .viewComments(commentID, isFromFeed):
                self.viewComments(to: commentID, presentCompletion: nil, isFromFeed: isFromFeed)
            case let .enterComment(area, commentSource):
                self.enterComment(with: area, commentSource: commentSource)
            case let .openSuccess(openType):
                if openType == .wps {
                    self._commentManager?.areaCommentManager.loadAllVersionComments()
                }
            case .fileDidDeleted:
                self._isDeleted.onNext(true)
            case let .wikiNodeDeletedStatus(isDelete):
                self._isDeleted.onNext(isDelete)
            default:
                break
            }
        }).disposed(by: bag)
        
        host.fileInfoErrorOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] err in
            guard let self = self else { return }
            guard let error = err else {
                self._isLegal.onNext(DriveAuditState(result: .legal, reason: .none))
                self._isDeleted.onNext(false)
                return
            }
            switch error {
            case let .serverError(code):
                self._isDeleted.onNext(code == DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue
                                    || code == DriveFileInfoErrorCode.fileNotFound.rawValue)
                self._isKeyDeleted.onNext(code == DriveFileInfoErrorCode.fileKeyDeleted.rawValue)
                if code == DriveFileInfoErrorCode.machineAuditFailureError.rawValue
                    || code == DriveFileInfoErrorCode.humanAuditFailureError.rawValue {
                    self._isLegal.onNext(DriveAuditState(result: .collaboratorIllegal, reason: .none))
                } else {
                    self._isLegal.onNext(DriveAuditState(result: .legal, reason: .none))
                }
            default:
                break
            }
        }).disposed(by: bag)
        
        // 更新docsInfo
        host.docsInfoRelay.subscribe(onNext: { [weak self] docsInfo in
            self?._commentManager?.update(docsInfo: docsInfo)
        }).disposed(by: bag)
        
        // 初始化评论view
        setupCommentView.subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance).subscribe(onSuccess: { [weak self] state in
            guard let self = self, let commentViewState = state else { return }
            self.initialCommentView(commentViewState)
        }).disposed(by: bag)
        
        // 更新评论view
        updateCommentViewState.debug("updateCommentViewState").observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] (state) in
            guard let self = self else { return }
            self.updateCommentView(state)
            if let viewState = state, viewState.reachable, viewState.permissionInfo.canRead {
                self._commentManager?.likeDataManager.loadLikeData()
                self._commentManager?.areaCommentManager.requestAreaComments()
            }
        }).disposed(by: bag)
        
        showCommentViewDriver.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] show in
            guard let self = self, let host = self.hostModule else { return }
            host.hostController?.updateCommentBar(hiddenByPermission: !show)
            host.hostController?.showCommentBar(show, animate: false)
        }).disposed(by: bag)
        
        return self
    }
    lazy var showCommentViewDriver: Observable<Bool> = {
        guard let host = hostModule else { return .never() }
        let permissionCanView: Observable<Bool>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            permissionCanView = host.permissionService.onPermissionUpdated.map { [weak host] _ in
                guard let host else { return false }
                return host.permissionService.validate(operation: .view).allow
            }
        } else {
            permissionCanView = host.permissionRelay.map(\.isReadable)
        }
        return Observable.combineLatest(_isLegal,
                                        _isDeleted.distinctUntilChanged(),
                                        permissionCanView,
                                        host.reachabilityChanged.distinctUntilChanged(),
                                        _isKeyDeleted,
                                        resultSelector: {[weak self] (auditState, deleted, permissionCanView, reachable, keyDelete) -> Bool in
                                            guard let self = self else { return false }
                                            if keyDelete {
                                                // 密钥删除
                                                return false
                                            }
                                            if !reachable {
                                                return true
                                            }
                                            if auditState.result != DriveAuditResult.collaboratorIllegal
                                                && !deleted
                                                && permissionCanView {
                                                return true
                                            }
                                            return false
        }).catchErrorJustReturn(false)
    }()
    private lazy var commentViewState: Observable<CommentViewState?> = {
        guard let host = hostModule else { return .never() }
        let permissionUpdate: Observable<CommentPermission>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            permissionUpdate = host.permissionService.onPermissionUpdated.map { [weak host] _ in
                guard let service = host?.permissionService else {
                    return .noPermission
                }
                let canCopy = service.validate(operation: .copyContent).allow
                let canRead = service.validate(operation: .view).allow
                let canShowCollaboratorInfo = service.validate(operation: .viewCollaboratorInfo).allow
                let canPreview = service.validate(operation: .preview).allow
                return CommentPermission(canCopy: canCopy,
                                         canRead: canRead,
                                         canShowCollaboratorInfo: canShowCollaboratorInfo,
                                         canPreview: canPreview)
            }
        } else {
            permissionUpdate = host.permissionRelay.map { permission in
                CommentPermission(permissionInfo: permission)
            }
        }
        return Observable.combineLatest(host.fileInfoRelay,
                                        host.docsInfoRelay,
                                        permissionUpdate,
                                        host.reachabilityChanged.distinctUntilChanged(),
                                        _isDeleted.distinctUntilChanged(),
                                        resultSelector: {[weak self, weak host] (fileInfo, docsInfo, permissionUpdatedInfo, reachable, deleted) -> CommentViewState? in
                                            DocsLogger.debug("commentViewState changed")
                                            guard let self = self, let host = host, deleted == false else { return nil }
                                            // fileInfo 没有拉取到的情况下，评论功能置灰不可点
                                            let enableCommentBar = fileInfo.source.isFromServer
            return CommentViewState(fileInfo: fileInfo,
                                    docsInfo: docsInfo,
                                    permissionInfo: permissionUpdatedInfo,
                                    canComment: self.canComment(),
                                    reachable: reachable,
                                    enableCommentBar: enableCommentBar)
        }).catchErrorJustReturn(nil)
    }()
    
    private lazy var setupCommentView: Single<CommentViewState?> = {
        return Single<CommentViewState?>.create { [weak self] (single) -> Disposable in
            guard let self = self, let host = self.hostModule else { return Disposables.create() }
            // 只有fileInfo已经拉取到，并且有评论权限才能评论。
            let canComment = self.canComment()
            let canShowCollaboratorInfo = self.canShowCollaboratorInfo
            // fileInfo 没有拉取到的情况下，评论功能置灰不可点
            let enableCommentBar = self.fileInfo.source.isFromServer
            let isReachable = DocsNetStateMonitor.shared.isReachable
            // 初始化DriveCommentManager，并绑定数据流
            let commentManager = DriveCommentManager(canComment: canComment,
                                                     canShowCollaboratorInfo: self.canShowCollaboratorInfo,
                                                     canPreviewProvider: { [weak self] in self?.canPreview ?? false },
                                                     docsInfo: self.docsInfo,
                                                     fileInfo: self.fileInfo,
                                                     feedFromInfo: host.commonContext.feedFromInfo)
            commentManager.followAPIDelegate = self.hostModule?.commonContext.followAPIDelegate
            commentManager.hostController = host.hostController
            commentManager.hostModule = host
            self._commentManager = commentManager
            self.bindCommentEvent(with: commentManager)
            // 初始化默认值
            let initialState = CommentViewState(fileInfo: self.fileInfo,
                                                docsInfo: self.docsInfo,
                                                permissionInfo: self.commentPermission,
                                                canComment: canComment,
                                                reachable: isReachable,
                                                enableCommentBar: enableCommentBar)
            host.subModuleActionsCenter.accept(.didSetupCommentManager(manager: commentManager))
            single(.success(initialState))
            return Disposables.create()
        }.catchErrorJustReturn(nil)
    }()

    private lazy var updateCommentViewState: Observable<CommentViewState?> = {
        let throttleMilliSec = 250
        return commentViewState.debug("commentState")
            .asObservable().debug("commentState update")
            .throttle(.milliseconds(throttleMilliSec), scheduler: MainScheduler.instance)
            .catchErrorJustReturn(nil)
    }()
    
    /// 在需要显示评论条的时机调用此方法
    private func initialCommentView(_ state: CommentViewState) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        hostVC.setupBottomView()
        let commentBar = hostVC.commentBar
        commentBar.likeButtonView.likeButton.isEnabled = state.reachable && state.enableCommentBar
        commentBar.enterCommentButton.isHidden =  !(state.canComment && state.reachable)
        commentBar.viewCommentButton.isEnabled = state.enableCommentBar

        commentBar.delegate = self
        commentBar.dataSource = self
    }
    
    private func updateCommentView(_ state: CommentViewState?) {
        guard let host = hostModule, let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let commentCtx = _commentManager else {
            DocsLogger.warning("no commentContext")
            assertionFailure("no commentContext")
            return
        }
        guard let `state` = state else {
            hostVC.showCommentBar(false, animate: false)
            return
        }
        // 无网络不可点赞、查看评论、发布评论
        hostVC.commentBar.likeButtonView.likeButton.isEnabled = state.reachable && state.enableCommentBar
        let context = UploadCommentContext(docsInfo: state.docsInfo,
                                           canComment: state.canComment,
                                           canCopy: state.permissionInfo.canCopy,
                                           canRead: state.permissionInfo.canRead,
                                           canShowCollaboratorInfo: state.permissionInfo.canShowCollaboratorInfo,
                                           canPreview: state.permissionInfo.canPreview)
        if state.reachable && state.docsInfo.objToken == state.fileInfo.fileToken {
            commentCtx.update(context: context, fileInfo: state.fileInfo)
        }
        
        // 历史版本不支持评论
        let isHistory = (host.commonContext.previewFrom == .history)

        hostVC.commentBar.enterCommentButton.isHidden = !(state.canComment && state.reachable && !isHistory)
        hostVC.commentBar.viewCommentButton.isEnabled = state.enableCommentBar
    }
    
    /// commentManager事件绑定
    func bindCommentEvent(with commentManager: DriveCommentManager) {
        // like
        commentManager.updateLikeCountEvent.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.hostModule?.hostController?.commentBar.reloadLikeStatus()
        }).disposed(by: bag)
        commentManager.updateLikeListEvent.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.hostModule?.hostController?.commentBar.reloadLikeLabel()
        }).disposed(by: bag)
        
        // comment
        commentManager.commentsDataUpdated.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self]  (_, areas) in
            guard let self = self else { return }
            self.updateAreaComments(areas)
        }).disposed(by: bag)
        commentManager.commentCount.map({ _ in () }).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.hostModule?.hostController?.commentBar.reloadCommentCount()
        }).disposed(by: bag)
        commentManager.commentVCSwitchToPage.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] page in
            self?.commentVCSwitchToPage(page)
        }).disposed(by: bag)
        // 记录当前预览的评论，下次打开评论面板可以定位到对应位置
        commentManager.commentVCSwitchToComment.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] commentID in
            self?.curCommentID = commentID
        }).disposed(by: bag)

        // feed message
        commentManager.messageUnreadCount.map({ _ in () }).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            // 更新navibar item 红点
            self?.hostModule?.subModuleActionsCenter.accept(.refreshNaviBarItemsDots)
        }).disposed(by: bag)
        
        // feed 内打开，使用默认的 style
        commentManager.openMessageFeed.observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] in
            self?.hostModule?.subModuleActionsCenter.accept(.showFeed)
        }).disposed(by: bag)
        
        // feed面板隐藏，通知界面调整
        commentManager.messageWillDismiss.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.resetContentView()
        }).disposed(by: bag)
        
        // feed面板评论点击事件
        commentManager.messageDidClickComment.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (commentId, message) in
            self?.messageDidClickComment(commentId, message: message)
        }).disposed(by: bag)
    }
    
    /// 局部评论update
    func updateAreaComments(_ areas: [DriveAreaComment]) {
        guard let areaCommentProtocol = hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol else {
            DocsLogger.warning("Not DriveSupportAreaCommentProtocol")
            return
        }
        areaCommentProtocol.updateAreas(areas)
    }
    /// 局部评论点击选区
    func commentVCSwitchToPage(_ page: Int) {
        guard let areaCommentProtocol = hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol else { return }
        areaCommentProtocol.selectArea(at: page)
    }
    
    /// 收起评论/消息面板，多图
    func resetContentView() {
        guard let host = hostModule else { return }
        host.hostController?.resizeContentViewIfNeed(nil)
        guard let areaCommentProtocol = host.hostController?.children.last as? DriveSupportAreaCommentProtocol else { return }
        areaCommentProtocol.deselectArea()
    }
    
    // 点击feed面板评论，打开评论列表同时局部评论定位到相应的位置
    func messageDidClickComment(_ commentId: String, message: FeedMessageType) {
        if message.isAlive {
            self.viewComments(to: commentId, presentCompletion: nil, isFromFeed: true)
        }

        guard let areaCommentProtocol = hostModule?.hostController?.children.first as? DriveSupportAreaCommentProtocol else { return }
        areaCommentProtocol.selectArea(at: commentId)
    }
    
    /// 浏览/回复评论
    func viewComments(to commentID: String? = nil, presentCompletion: (() -> Void)? = nil, isFromFeed: Bool = false) {
        guard let commentManager = self._commentManager else {
            DocsLogger.driveInfo("no commentContext")
            return
        }
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        // 密级强制打标需求，当FA用户被admin设置强制打标时，不可发表评论
        if SecretBannerCreater.checkForcibleSL(canManageMeta: canManageMeta,
                                               level: docsInfo.secLabel) {
            showFrocibleWarning()
            return
        }
        if self.docsInfo.fileType == nil {
            self.docsInfo.fileType = self.fileInfo.type
        }
        if commentManager.commentCount.value == 0 {
            didEnterCommentCore()
        } else {
            var from: UIViewController = hostVC
            var isFeed: Bool = false
            if isFromFeed,
               let feedVC = self._commentManager?.commentAdapter.feedVC {
                from = feedVC
                isFeed = true
            }
            commentManager.showComment(commentId: commentID,
                                                     hostVC: from,
                                                     isFromFeed: isFeed)
        }
    }
    
    /// 新增评论
    func enterComment(with area: DriveAreaComment.Area, commentSource: DriveCommentSource) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        if self.docsInfo.fileType == nil {
            self.docsInfo.fileType = self.fileInfo.type
        }
        let driveAtInputTextViewDependency = DriveAtInputTextViewDependency()
        driveAtInputTextViewDependency.fileType = docsInfo.type
        driveAtInputTextViewDependency.fileToken = docsInfo.objToken
        driveAtInputTextViewDependency.driveFileType = docsInfo.fileType
        driveAtInputTextViewDependency.dataVersion = fileInfo.dataVersion ?? ""
        driveAtInputTextViewDependency.driveCommentAdapter = _commentManager?.commentAdapter
        driveAtInputTextViewDependency.showAreaBox = showAreaBox()
        driveAtInputTextViewDependency.areaBoxHighlighted = enableAreaBoxHighlight(area: area, commentSource: commentSource)
        driveAtInputTextViewDependency.area = area

        // 数据标签
        driveAtInputTextViewDependency.commentQuote = setupCommentQuote(commentSource, area: area)

        let commentVC = DriveCommentViewController(dependency: driveAtInputTextViewDependency)
        driveAtInputTextViewDependency.fromVC = commentVC
        commentVC.commentSendCompletion = { [weak self] (rnCommentData, area) -> Void in
            guard let self = self,
                let manager = self._commentManager,
                let commentID = rnCommentData.currentCommentID,
                let version = self.fileInfo.dataVersion else { return }
            // 发送drive选区信息后弹出
            let type: DriveAreaComment.AreaType = self.getAreaCommentType(area: area, commentSource: commentSource)
            let areaInfo = DriveAreaComment(commentID: commentID,
                                            version: version,
                                            type: type,
                                            area: area)
            manager.areaCommentManager.addAreaComment(area: areaInfo, complete: { (_, error) in
                guard error == nil else {
                    DocsLogger.error("addAreaComment error: \(String(describing: error?.localizedDescription))")
                    return
                }
                self.showAreaEditView(false)
                self.viewComments(to: commentID, presentCompletion: { [weak self] in
                    self?.showNotNotifyToastIfNeeded(rnCommentData.entities)
                })
            })
        }
        commentVC.showAreaEditView = {[weak self] show in
            guard let self = self else { return }
            self.showAreaEditView(show)
        }
        commentVC.commentVCWillDismiss = { [weak self] in
            guard let areaCommentProtocol = self?.hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol else { return }
            areaCommentProtocol.commentVCWillDismiss()
            let isFullComment = driveAtInputTextViewDependency.area.isBlankArea
            let tracker = DocsContainer.shared.resolve(CommentTrackerInterface.self)
            tracker?.commentReport(action: "cancel_click", docsInfo: self?.docsInfo, cardId: nil, id: nil, isFullComment: isFullComment, extra: [:])
        }
        hostVC.present(commentVC, animated: false, completion: nil)
    }
    
    // 评论输入栏是否需要显示局部评论按钮，这里不应该根据文件类型判断，而是依赖具体的打开方式来判断
    private func showAreaBox() -> Bool {
        // 首先根据文件类型判断
        guard fileInfo.fileType.isSupportAreaComment else {
            return false
        }
        // 检查打开的方式是否支持局部评论
        guard let lastChildVC = hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol else {
            return false
        }
        // 检查子VC目前能否进行局部评论，如 FG 是否打开等
        return lastChildVC.areaCommentEnabled
    }
    
    private func enableAreaBoxHighlight(area: DriveAreaComment.Area, commentSource: DriveCommentSource) -> Bool {
        switch commentSource {
        case .image:
            return !area.isBlankArea
        case .pdf:
            if area.quads != nil {
                /// 如果是文字评论，不高亮
                return false
            } else {
                /// 如果是单页评论，返回false
                if area.isPageComment {
                    return false
                } else {
                    /// 如果是选区评论，返回true
                    return true
                }
            }
        case .unsupportAreaComment:
            return false
        }
    }
    
    private func setupCommentQuote(_ commentSource: DriveCommentSource, area: DriveAreaComment.Area?) -> (key: String, params: [String]) {
        switch commentSource {
        case .image:
            return (DriveMessageQuoteType.comment.rawValue, [])
        case .pdf:
            if let area = area {
                if var text = area.text {
                    let stringMaxCount = 50
                    if text.count > stringMaxCount {
                        text = text[0..<stringMaxCount]
                    }
                    // 第n页xxx
                    return (DriveMessageQuoteType.text.rawValue, [String(area.page + 1), text])
                } else {
                    // 第n页
                    return (DriveMessageQuoteType.page.rawValue, [String(area.page + 1)])
                }
            } else {
                return (DriveMessageQuoteType.comment.rawValue, [])
            }
        case .unsupportAreaComment:
            return (DriveMessageQuoteType.comment.rawValue, [])
        }
    }
    
    private func getAreaCommentType(area: DriveAreaComment.Area, commentSource: DriveCommentSource) -> DriveAreaComment.AreaType {
        var type: DriveAreaComment.AreaType = .noArea
        if commentSource == .image {
            if area.isBlankArea {
                type = DriveAreaComment.AreaType.noArea
            } else {
                type = DriveAreaComment.AreaType.rect
            }
        } else if commentSource == .pdf {
            if area.isPageComment {
                type = .noArea
            } else {
                type = area.quads == nil ? DriveAreaComment.AreaType.rect : DriveAreaComment.AreaType.text
            }
        }
        return type
    }
    
    private func showAreaEditView(_ show: Bool) {
        guard let areaCommentProtocol = self.hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol else { return }
        areaCommentProtocol.showAreaEditView(show)
    }
    
    private func showNotNotifyToastIfNeeded(_ entities: CommentEntities?) {
        guard let notNotifyUsers = entities?.notNotifyUsers, !notNotifyUsers.isEmpty else { return }
        // 确认下怎么触发
        guard let rootVC = hostModule?.hostController?.view.window?.rootViewController,
              let from = UIViewController.docs.topMost(of: rootVC) else {
            spaceAssertionFailure("showNotNotifyToastIfNeeded cannot find from vc")
            return
        }

        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        let names = notNotifyUsers.map { $0.name }.joined(separator: separator)
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.SKResource.Doc_Permission_NotNotifyUser(names))
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm)
        Navigator.shared.present(dialog, from: from)
    }
}

extension DKCommentModule: DriveCommentBottomViewDelegate {
    func didClickLikeLabel(in driveCommentBottomView: DriveCommentBottomView) {
        guard let host = hostModule else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        if LKFeatureGating.setUserRestrictedEnable {
            guard canShowCollaboratorInfo else {
                guard let view = host.hostController?.view else {
                    return
                }
                PermissionStatistics(docsInfo: self.docsInfo).reportPermissionNoCollaboratorProfileListView()
                UDToast.docs.showMessage(BundleI18n.SKResource.LarkCCM_Perm_NoPermToViewLikeProfilePicture, on: view, msgType: .tips)
                return
            }
        }
        _showupLikeList()
        // Drive业务埋点：显示点赞详情
        DriveStatistic.clientPraise(action: DriveStatisticAction.showPraisePage,
                                    fileType: fileInfo.type,
                                    fileId: fileInfo.fileToken,
                                    module: "drive",
                                    previewFrom: host.commonContext.previewFrom.stasticsValue,
                                    additionalParameters: host.additionalStatisticParameters)
    }
    
    func didEnterComment(in driveCommentBottomView: DriveCommentBottomView) {
        // 密级强制打标需求，当FA用户被admin设置强制打标时，不可发表评论
        if SecretBannerCreater.checkForcibleSL(canManageMeta: canManageMeta,
                                               level: docsInfo.secLabel) {
            showFrocibleWarning()
            return
        }
        didEnterCommentCore()
        DriveStatistic.reportClickEvent(DocsTracker.EventType.docsPageClick,
                                        clickEventType: DriveStatistic.DrivePageClickEvent.input,
                                        fileId: fileInfo.fileToken,
                                        fileType: fileInfo.fileType)
    }
    
    private func showFrocibleWarning() {
        if let hostView = hostModule?.hostController?.view.window {
            UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requird_Toast,
                                operationText: BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_Set,
                                on: hostView) { [weak self] _ in
                self?.hostModule?.subModuleActionsCenter.accept(.clickSecretBanner)
            }
        }
    }
    
    private func didEnterCommentCore() {
        if let supportAreaCommentVC = self.hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol {
            enterComment(with: supportAreaCommentVC.defaultCommentArea, commentSource: supportAreaCommentVC.commentSource)
        } else {
            enterComment(with: DriveAreaComment.Area.blankArea, commentSource: .unsupportAreaComment)
        }
    }
    
    func didViewAllComments(in driveCommentBottomView: DriveCommentBottomView) {
        viewComments(to: curCommentID)
        DriveStatistic.reportClickEvent(DocsTracker.EventType.docsPageClick,
                                        clickEventType: DriveStatistic.DrivePageClickEvent.comment,
                                        fileId: fileInfo.fileToken,
                                        fileType: fileInfo.fileType)
    }
    
    func didLikeFile(in driveCommentBottomView: DriveCommentBottomView) {
        guard let likeManager = _commentManager?.likeDataManager else { return }
        DriveStatistic.reportClickEvent(DocsTracker.EventType.docsPageClick,
                                        clickEventType: DriveStatistic.DrivePageClickEvent.like,
                                        fileId: self.fileInfo.fileToken,
                                        fileType: self.fileInfo.fileType)
        if likeManager.likeStatus == .hasLiked {
            likeManager.dislike { [weak self] (_) in
                guard let `self` = self else { return }
                // Drive业务埋点：取消点赞
                DriveStatistic.clientPraise(action: DriveStatisticAction.cancelPraise,
                                            fileType: self.fileInfo.type,
                                            fileId: self.fileInfo.fileToken,
                                            module: "drive",
                                            previewFrom: self.hostModule?.commonContext.previewFrom.stasticsValue ?? DrivePreviewFrom.unknown.stasticsValue,
                                            additionalParameters: self.hostModule?.additionalStatisticParameters)
            }
        } else {
            likeManager.like { [weak self] (_) in
                guard let `self` = self else { return }
                // Drive业务埋点：点赞
                DriveStatistic.clientPraise(action: DriveStatisticAction.confirmPraise,
                                            fileType: self.fileInfo.type,
                                            fileId: self.fileInfo.fileToken,
                                            module: "drive",
                                            previewFrom: self.hostModule?.commonContext.previewFrom.stasticsValue ?? DrivePreviewFrom.unknown.stasticsValue,
                                            additionalParameters: self.hostModule?.additionalStatisticParameters)
            }
        }
    }

    private func _showupLikeList() {
        guard let host = hostModule, let hostVC = host.hostController else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        let vc = LikeListViewController(fileToken: self.docsInfo.objToken, likeType: .drive)
        vc.listDelegate = self
        // 不能跳转到profile页面，因为Lark中使用EENavigator.shared.push跳转到profile
        //        present(vc, animated: true, completion: nil)
        // 这两种都不要使用，navigator本身是给DocBrowerVC使用的，内部会判断是否有web view
        //        navigator?.presentViewController(vc, animated: true)
        //        navigator?.pushViewController(vc)
        // OK
        Navigator.shared.push(vc, from: hostVC, animated: true, completion: nil)
    }
}

extension DKCommentModule: DriveCommentBottomViewDataSource {
    func numberOfCommentsCount(in driveCommentBottomView: DriveCommentBottomView) -> Int {
        return _commentManager?.commentCount.value ?? 0
    }
    func likeModel() -> DriveLikeDataManager {
        if let manager = _commentManager?.likeDataManager {
            return manager
        }
        return DriveLikeDataManager(docInfo: docsInfo, canShowCollaboratorInfo: canShowCollaboratorInfo)
    }
    func canComment() -> Bool {
        // 拉取到fileInfo后才可以评论
        let isHistory = (hostModule?.commonContext.previewFrom == .history)
        let canComment: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canComment = hostModule?.permissionService.validate(operation: .comment).allow ?? false
        } else {
            canComment = permissionInfo.canComment
        }
        return canComment && fileInfo.source.isFromServer && !isHistory
    }
}

extension DKCommentModule: LikeListDelegate {
    func requestDisplayUserProfile(userId: String, fileName: String?, listController: LikeListViewController) {
        HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: docsInfo.title, fromVC: listController))
    }
    // Drive目前没有此功能
    func requestCreateBrowserView(url: String, config: FileConfig) -> UIViewController? {
        return nil
    }
}

// PermissionSDK 过渡期间，从 permissionInfo 读点位收敛在这里
private extension DKCommentModule {
    private var canPreview: Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return hostModule?.permissionService.validate(operation: .preview).allow ?? false
        } else {
            // 第三方附件没有 userPermissions，默认 true
            return permissionInfo.userPermissions?.canPreview() ?? true
        }
    }
    private var canManageMeta: Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return hostModule?.permissionService.validate(operation: .managePermissionMeta).allow ?? false
        } else {
            return permissionInfo.userPermissions?.isFA ?? false
        }
    }

    private var canShowCollaboratorInfo: Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return hostModule?.permissionService.validate(operation: .viewCollaboratorInfo).allow ?? false
        } else {
            return permissionInfo.canShowCollaboratorInfo
        }
    }
}
