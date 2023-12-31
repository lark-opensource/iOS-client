//
//  DriveCommentModule.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/24.
//


import UIKit
import RxCocoa
import RxSwift
import LarkReactionView
import SKFoundation
import SKUIKit
import SpaceInterface
import SKCommon

public final class DriveCommentModule: DriveCommentModuleType {
    
    private var commentScheduler: CommentSchedulerServer?
    
    private let disposeBag = DisposeBag()
    
    private weak var viewInteraction: CommentViewInteractionType?
    
    private weak var dependency: DocsCommentDependency?
    
    private var apiAdaper: CommentAPIAdaper

    private var driveController: DriveCommentPanelViewController?
    
    private let fetchDataSubjec = PublishSubject<CommentData>()
    private let switchSubject = PublishSubject<String>()
    
    private var commentData: CommentData?
    
    @discardableResult
    private func initDriveControllerIfNeed() -> DriveCommentPanelViewController {
        guard let driveController = driveController else {
            initPlugin()
            let textPlugin = commentScheduler?.plugin(with: CommentTextPlugin.self)
            let vc = DriveCommentPanelViewController(viewInteraction: self.viewInteraction,
                                    textViewDependency: textPlugin,
                                    cellDelegate: self,
                                    dependency: self.dependency)
            self.driveController = vc
            listeningState(with: vc)
            return vc
        }
        return driveController
    }
    
    public required init(dependency: DocsCommentDependency, apiAdaper: CommentAPIAdaper) {
        self.dependency = dependency
        self.apiAdaper = apiAdaper
        bind()
    }

    func bind() {
        switchSubject.asObservable()
                     .withLatestFrom(fetchDataSubjec) { (id, _) in return id }
                     .subscribe { [weak self]  in
                        self?.switchComment(commentId: $0)
                     }.disposed(by: disposeBag)
    }
    
    private func fetchDataIfNeed(callback: @escaping ((CommentData) -> Void)) {
        if let commentData = self.commentData {
            callback(commentData)
            if isVisiable {
                scheduler?.dispatch(action: .updateData(commentData))
            }
            fetchDataSubjec.onNext(commentData)
        } else {
            guard let rnAPI = apiAdaper as? CommentRNAPIAdaperType else {
                DocsLogger.error("fetch data error, rnAPI is nil", component: LogComponents.comment)
                return
            }
            rnAPI.fetchComment { [weak self] in
                guard let self = self else { return }
                callback($0)
                if self.isVisiable {
                    self.scheduler?.dispatch(action: .updateData($0))
                }
                self.fetchDataSubjec.onNext($0)
            }
        }
    }
    
    private func _hide() {
        driveController?.dismiss(animated: false, completion: nil)
        self.commentData = nil
        driveController = nil
        commentScheduler = nil
        switchSubject.onNext("")
    }

    
    deinit {
        DocsLogger.info("DriveCommentModule deinit", component: LogComponents.comment)
        _hide()
    }
}

// MARK: - private
extension DriveCommentModule {
    
    private func initPlugin() {
        commentScheduler = CommentSchedulerServer()
        setupPlugin()
    }

    private func setupPlugin() {
        let plugins: [CommentPluginType] = [CommentTextPlugin(),
                                            CommentDriveDataPlugin(),
                                            CommentAPIPlugin(api: self.apiAdaper),
                                            CommentDriveInteractionPlugin(),
                                            CommentDraftPlugin(),
                                            CommentStatistPlugin(),
                                            CommentImagePlugin(),
                                            CommentReactionPlugin(),
                                            CommentMenuPlugin(),
                                            CommentBusinessPlugin()]
        commentScheduler?.connect(plugins: plugins)
        commentScheduler?.apply(context: self)
        self.viewInteraction = commentScheduler
    }
    
    private func listeningState(with vc: DriveCommentPanelViewController) {
        spaceAssert(commentScheduler != nil)
        commentScheduler?.state
                        .skip(1)
                        .bufferBeforTrigger(vc.latch)
                        .do(onNext: { [ weak self] state in
                            if case .dismiss = state {
                                self?._hide()
                            }
                         })
                        .bind(to: vc.state)
                        .disposed(by: disposeBag)
    }
}

// MARK: - public

extension DriveCommentModule {
    
    
    public func show(commentId: String?, hostVC: UIViewController, formSheetStyle: Bool = true) {
        let vc = initDriveControllerIfNeed()
        driveController?.isDismissing = false
        if !formSheetStyle,
           let parentVC = hostVC as? FeedPanelViewControllerType {
            vc.transitioningDelegate = parentVC
            vc.syncGap = parentVC.gapState
            vc.baseStyle = .backV2
            parentVC.present(vc, animated: true, completion: { [weak self] in
                parentVC.gapState = .bottom
                if let id = commentId {
                    self?.switchSubject.onNext(id)
                }
            })
        } else {
            vc.baseStyle = .normal
            hostVC.present(vc, animated: true, completion: { [weak self] in
                if let id = commentId {
                    self?.switchSubject.onNext(id)
                }
            })
        }
        fetchDataIfNeed { data in
            if let id = commentId {
                data.currentCommentID = id
                for (idx, comment) in data.comments.enumerated() {
                    if comment.commentID == id {
                        data.currentPage = idx
                        comment.isActive = true
                        break
                    }
                }
            }
        }
    }
    
    public func removeAllMenu() {
        scheduler?.dispatch(action: .removeAllMenu)
    }
    
    public func switchComment(commentId: String?) {
        guard let id = commentId else { return }
        scheduler?.dispatch(action: .switchComment(commentId: id))
    }

    public func udpateDocsInfo(_ docsInfo: CommentDocsInfo) {
        guard let info = docsInfo as? DocsInfo else { return }
        scheduler?.dispatch(action: .updateDocsInfo(docsInfo: info))
    }
    
    /// Drive协同数据返回时，调用
    public func update(_ commentData: CommentData) {
        self.commentData = commentData
        if isVisiable {
            commentScheduler?.dispatch(action: .updateData(commentData))
        } else {
            DocsLogger.info("save drive data when commentView inVisiable: \(commentData.comments.count)", component: LogComponents.comment)
        }
    }
    
    /// 外部调用
    public func hide() {
        viewInteraction?.emit(action: .hideComment)
        _hide()
    }
    
    
    public var isVisiable: Bool {
        guard let driveController = self.driveController else {
            return false
        }
        return !driveController.isDismissing &&
               !driveController.isBeingDismissed
    }
    
    public func setCaptureAllowed(_ allow: Bool) {
        driveController?.setCaptureAllowed(allow)
    }

    public func vcFollowOnRoleChange(role: FollowRole) {}
}

// MARK: - CommentServiceContext

extension DriveCommentModule: CommentServiceContext {

    public var commentPluginView: UIView {
        return driveController?.containerView ?? UIView()
    }

    var scheduler: CommentSchedulerType? {
        commentScheduler
    }
    
    var tableView: UITableView? {
        return nil
    }
    
    var businessDependency: DocsCommentDependency? { dependency }
    
    var pattern: CommentModulePattern { .drive }
    
    var commentVC: UIViewController? { return driveController }
}


extension DriveCommentModule: CommentCollectionViewCellDelegate {
    
    func didClickAvatarImage(item: CommentItem, newInput: Bool) {
        viewInteraction?.emit(action: .clickAvatar(item))
    }
    
    func didClickAtInfo(_ atInfo: AtInfo, item: CommentItem, rect: CGRect, rectInView: UIView) {
        viewInteraction?.emit(action: .clickAtInfoAndCheckPermission(atInfo: atInfo,
                                                                     item: item,
                                                                     rect: rect,
                                                                     view: rectInView))
    }
    
    func didClickURL(_ url: URL) {
        viewInteraction?.emit(action: .clickURL(url))
    }
    
    func didClickMoreAction(button: UIView, cell: UIView, commentItem: CommentItem) {
        var location = CGPoint(x: button.frame.centerX - 4, y: button.frame.origin.y)
        if let tableView = cell.superview {
            location = cell.convert(location, to: tableView)
            if let cell = cell as? CommentTableViewCell {
                viewInteraction?.emit(action: .showReaction(item: commentItem,
                                                            location: location,
                                                            cell: cell,
                                                            trigerView: tableView))
            } else if let cell = cell as? ContentReactionBaseCell {
                viewInteraction?.emit(action: .showBlockReaction(item: commentItem,
                                                            location: location,
                                                            cell: cell,
                                                            trigerView: tableView))
            }
        } else {
            DocsLogger.error("cell superview is nil", component: LogComponents.comment)
        }
    }
    
    func didClickReaction(_ commentItem: CommentItem?, reactionVM: LarkReactionView.ReactionInfo, tapType: LarkReactionView.ReactionTapType) {
        guard let commentItem = commentItem else { return }
        viewInteraction?.emit(action: .clickReaction(commentItem, reactionVM, tapType))
    }
    
    func didLongPressToShowReaction(_ cell: UIView, gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        let point = gesture.location(in: cell)
        if let cell = cell as? CommentTableViewCell,
           let item = cell.item {
            viewInteraction?.emit(action: .longPress(item: item, location: point, cell: cell, trigerView: cell))
        } else if let cell = cell as? ContentReactionBaseCell,
                  let item = cell.commentItem {
            viewInteraction?.emit(action: .showBlockReaction(item: item, location: point, cell: cell, trigerView: cell))
        } else {
            DocsLogger.error("press error", component: LogComponents.comment)
        }
    }
    
    func didClickTranslationIcon(_ commentItem: CommentItem, _ cell: CommentTableViewCell) {
        viewInteraction?.emit(action: .clickTranslationIcon(commentItem))
    }
    
    func didClickSendingDelete(_ commentItem: CommentItem) {
        viewInteraction?.emit(action: .clickSendingDelete(commentItem))
    }
    
    func didClickRetry(_ commentItem: CommentItem) {
        viewInteraction?.emit(action: .clickRetry(commentItem))
    }
    
    func didClickPreviewImage(_ commentItem: CommentItem, imageInfo: CommentImageInfo) {
        viewInteraction?.emit(action: .openImage(item: commentItem, imageInfo: imageInfo))
    }
    
    func markReadMessage(commentItem: CommentItem) {
        viewInteraction?.emit(action: .willDisplayUnread(commentItem))
    }
    
    func didLoadImagefailed(_ commentItem: CommentItem, imageInfo: CommentImageInfo) {
        viewInteraction?.emit(action: .loadImagefailed(commentItem))
    }
    
    func didFinishFetchImage(_ image: UIImage, cacheable: CommentImageCacheable) {
        viewInteraction?.emit(action: .cacheImage(image, cacheable: cacheable))
    }
    
    func inquireImageCache(by cacheable: CommentImageCacheable) -> UIImage? {
        return commentScheduler?.fetchCache(by: cacheable.cacheKey)
    }

    func commentThumbnailImageSyncGetCanPreview() -> Bool? {
        // drive没有图片评论,不作处理
        return true
    }
}
