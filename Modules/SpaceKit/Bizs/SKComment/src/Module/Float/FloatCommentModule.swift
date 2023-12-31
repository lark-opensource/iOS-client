//
//  FloatCommentModule.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/26.
//  


import UIKit
import RxCocoa
import RxSwift
import LarkReactionView
import SKFoundation
import SKUIKit
import SpaceInterface
import SKCommon

public final class FloatCommentModule: FloatCommentModuleType {
    
    
    private var commentScheduler: CommentSchedulerServer?
    
    private let disposeBag = DisposeBag()
    
    private weak var viewInteraction: CommentViewInteractionType?
    
    private weak var dependency: DocsCommentDependency?
    
    private var apiAdaper: CommentAPIAdaper

    private var floatController: FloatCommentViewController?
    /// 小程序打开profile后不能让其手势滑动，需要使用这个控制器
    private var commentNavigationController: CommentNavigationController?
    
    /// 是否通过父控制器关闭评论。（图片评论场景要设置为false）
    public var canPresentingDismiss: Bool = true
    
    @discardableResult
    private func initFloatControllerIfNeed() -> CommentNavigationController {
        guard floatController != nil,
              let nav = commentNavigationController else {
            initPlugin()
            let textPlugin = commentScheduler?.plugin(with: CommentTextPlugin.self)
            let vc = FloatCommentViewController(viewInteraction: self.viewInteraction,
                                    textViewDependency: textPlugin,
                                    cellDelegate: self,
                                    dependency: self.dependency)
            self.floatController = vc
            listeningState(with: vc)
            if let nav = commentNavigationController {
                return nav
            } else {
                let nav = CommentNavigationController(rootViewController: vc)
                if let style = self.dependency?.businessConfig.customPresentationStyle {
                    nav.modalPresentationStyle = style
                } else {
                    nav.modalPresentationStyle = .overCurrentContext
                }
                commentNavigationController = nav
                return nav
            }
        }
        return nav
    }
    
    public required init(dependency: DocsCommentDependency, apiAdaper: CommentAPIAdaper) {
        self.dependency = dependency
        self.apiAdaper = apiAdaper
    }
    
    
    public func banPanGesture() {
        commentNavigationController?.banPanGesture()
    }
    
    public var commentPluginView: UIView {
        return floatController?.view ?? UIView()
    }
    
    /// 查看、回复、编辑、解决评论
    public func update(_ commentData: CommentData) {
        commentScheduler?.dispatch(action: .updateData(commentData))
        if let docsInfo = commentData.docsInfo {
            checkCopyCapturePermission(docsInfo: docsInfo,
                                       permission: commentData.commentPermission)
        }
    }
    
    public func removeAllMenu() {
        commentScheduler?.dispatch(action: .removeAllMenu)
    }
    
    /// 新建评论
    public func update(_ newInputData: CommentInputModelType) {
        guard let data = newInputData as? CommentShowInputModel else { return }
        commentScheduler?.dispatch(action: .updateNewInputData(data))
    }
    
    public func scrollComment(commentId: String, replyId: String, percent: CGFloat) {
        commentScheduler?.dispatch(action: .scrollComment(commentId: commentId,
                                                          replyId: replyId,
                                                          percent: percent))
    }
    
    /// 刷新当前UI
    public func reloadData() {
        commentScheduler?.dispatch(action: .reloadData)
    }
    
    public func retryAddNewComment(commentId: String) {
        commentScheduler?.dispatch(action: .retryAddNewComment(commentId: commentId))
    }
    
    public func addNewCommentFinished(commentUUID: String, isSuccess: Bool, errorCode: String?) {
        let action = CommentAction.addNewCommentFinished(commentUUID: commentUUID,
                                                         isSuccess: isSuccess,
                                                         errorCode: errorCode)
        commentScheduler?.dispatch(action: action)
    }

    public func updateSession(session: Any) {
        floatController?.updateSession(session: session)
    }
    
    public func update(useOpenID: Bool) {
        floatController?.update(useOpenID: useOpenID)
    }
    
    public func show(with topMost: UIViewController) {

        let vc = initFloatControllerIfNeed()
 
        vc.isBegingPresenting = true
        floatController?.isDismissing = false
        guard vc.presentingViewController == nil else {
            DocsLogger.error("float comment had presented", component: LogComponents.comment)
            return
        }
        if docsInfo?.isInVideoConference == true {
            vc.priorityPresentSelf(with: topMost, animated: false) { [weak vc] in
                vc?.isBegingPresenting = false
                DocsLogger.info("priorityPresentSelf done", component: LogComponents.comment)
            }
        } else {
            topMost.present(vc, animated: false) { [weak vc] in
                vc?.isBegingPresenting = false
            }
        }
    }
    
    /// 外部调用
    public func hide() {
        if case .newInput = scheduler?.fastState.mode {
            // 新增评论不销毁，还需要保留重试的功能
            floatController?.dismiss(animated: false)
            floatController?.textView.hideImagePickerView()
        } else {
            viewInteraction?.emit(action: .hideComment)
            _hide()
        }
    }
    
    public func manualHide() {
        viewInteraction?.emit(action: .hideComment)
        _hide()
    }
    
    private func _hide() {
        if docsInfo?.isInVideoConference == true {
            commentNavigationController?.priorityDismissSelf(animated: false, completion: nil)
        } else {
            if canPresentingDismiss {
                // 让父控制器关掉，这样顶部的控制器才能完全关闭
                commentNavigationController?.presentingViewController?.dismiss(animated: false)
            } else {
                commentNavigationController?.dismiss(animated: false)
            }
        }
        dependency?.commentWillHide()
        commentNavigationController?.representEnable = false
        floatController = nil
        commentScheduler = nil
        commentNavigationController = nil
    }
    
    public var isVisiable: Bool {
        guard let floatController = self.floatController,
        let nav = commentNavigationController else {
            return false
        }
        return !floatController.isDismissing &&
               !floatController.isBeingDismissed &&
               !nav.isBeingDismissed
    }
    
    public func setCaptureAllowed(_ allow: Bool) {
        floatController?.setCaptureAllowed(allow)
    }
    
    public func vcFollowOnRoleChange(role: FollowRole) {
        scheduler?.dispatch(action: .vcFollowOnRoleChange(role: role))
        floatController?.currentCommentView.vcFollowOnRoleChange(role: role)
    }
    
    deinit {
        DocsLogger.info("FloatCommentModule deinit", component: LogComponents.comment)
    }
}

// MARK: - private
extension FloatCommentModule {
    
    private func initPlugin() {
        commentScheduler = CommentSchedulerServer()
        setupPlugin()
    }

    private func setupPlugin() {
        var plugins: [CommentPluginType] = [CommentTextPlugin(),
                                            CommentFloatDataPlugin(),
                                            CommentAPIPlugin(api: self.apiAdaper),
                                            CommentFloatInteractionPlugin(),
                                            CommentDraftPlugin(),
                                            CommentStatistPlugin(),
                                            CommentImagePlugin(),
                                            CommentReactionPlugin(),
                                            CommentMenuPlugin(),
                                            CommentBusinessPlugin()]
        if (dependency?.commentDocsInfo as? DocsInfo)?.isInCCMDocs == true {
            plugins.append(CommentMonitorPlugin())
        }
        commentScheduler?.connect(plugins: plugins)
        commentScheduler?.apply(context: self)
        self.viewInteraction = commentScheduler
    }
    
    private func listeningState(with vc: FloatCommentViewController) {
        spaceAssert(commentScheduler != nil)
        commentScheduler?.state
                        .skip(1)
                        .bufferBeforTrigger(vc.latch)
                        .do(onNext: { [ weak self] state in
                            if case .dismiss = state {
                                self?.hide()
                            }
                         })
                        .bind(to: vc.state)
                        .disposed(by: disposeBag)
    }
}


// MARK: - CommentServiceContext

extension FloatCommentModule: CommentServiceContext {

    public var commentView: UIView {
        return floatController?.view ?? UIView()
    }

    var scheduler: CommentSchedulerType? {
        commentScheduler
    }
    
    var tableView: UITableView? {
        return nil
    }
    
    var businessDependency: DocsCommentDependency? { dependency }
    
    var pattern: CommentModulePattern { .float }
    
    var banCanComment: Bool { return floatController?.isLandscapeBaned ?? false }
    
    var commentVC: UIViewController? { return floatController }
}


extension FloatCommentModule: CommentTableViewCellDelegate {
    
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
        // 未配置的业务不做管控，例如妙计
        guard let dataSource = dependency?.businessConfig.imagePermissionDataSource else {
            return true
        }
        let canPreview = dataSource.syncGetCommentImagePermission()?.canPreview
        return canPreview
    }
}

extension FloatCommentModule {
    
    
    /// 通过返回的评论权限信息更新，防截图功能，因为小程序等非文档业务没有单独
    private func checkCopyCapturePermission(docsInfo: DocsInfo, permission: CommentPermission) {
        // 小程序无额外的itl权限，获取内部评论权限判断即可
        if docsInfo.isInCCMDocs == false {
           let canCopy = permission.contains(.canCopy)
           floatController?.setCaptureAllowed(canCopy)
        }
    }
}
