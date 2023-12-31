//
//  AsideCommentModule.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/26.
//  


import UIKit
import SKFoundation
import RxCocoa
import RxSwift
import LarkReactionView
import SpaceInterface
import SKCommon

public final class AsideCommentModule {
    
    let commentScheduler: CommentSchedulerServer
    
    private let disposeBag = DisposeBag()
    
    weak var viewInteraction: CommentViewInteractionType?
    
    private lazy var asideCommentView: AsideCommentView = {
        let textPlugin = self.commentScheduler.plugin(with: CommentTextPlugin.self)
        return AsideCommentView(viewInteraction: self.viewInteraction,
                                textViewDependency: textPlugin,
                                cellDelegate: self,
                                dependency: self.dependency)
    }()
    
    weak var dependency: DocsCommentDependency?
    var apiAdaper: CommentAPIAdaper
    public required init(dependency: DocsCommentDependency, apiAdaper: CommentAPIAdaper) {
        self.dependency = dependency
        self.apiAdaper = apiAdaper
        commentScheduler = CommentSchedulerServer()
        setupPlugin()
    }
}

// MARK: - public
extension AsideCommentModule: AsideCommentModuleType {

    public var commentPluginView: UIView {
        asideCommentView
    }
    
    public var commentViewController: UIViewController? {
        return nil
    }
    
    public func update(_ commentData: CommentData) {
        commentScheduler.dispatch(action: .updateData(commentData))
    }
    
    public func scrollComment(commentId: String, replyId: String, percent: CGFloat) {
        commentScheduler.dispatch(action: .scrollComment(commentId: commentId,
                                                          replyId: replyId,
                                                          percent: percent))
    }
    
    public func removeAllMenu() {
        commentScheduler.dispatch(action: .removeAllMenu)
    }
    
    public var isVisiable: Bool {
        asideCommentView.superview != nil && !asideCommentView.isHidden
    }
    
    public func setCaptureAllowed(_ allow: Bool) {
        asideCommentView.setCaptureAllowed(allow)
    }

    public func hide() {
        viewInteraction?.emit(action: .hideComment)
    }
    
    public func vcFollowOnRoleChange(role: FollowRole) {
        scheduler?.dispatch(action: .vcFollowOnRoleChange(role: role))
        asideCommentView.vcFollowOnRoleChange(role: role)
    }
    
    public func resetActive() {
        scheduler?.dispatch(action: .resetActive)
    }
    
    /// 刷新当前UI
    public func reloadData() {
        scheduler?.dispatch(action: .reloadData)
    }
}


// MARK: - private
extension AsideCommentModule {
    
    private func setupPlugin() {
        var plugins: [CommentPluginType] = [CommentTextPlugin(),
                                            CommentAsideDataPlugin(),
                                            CommentAPIPlugin(api: self.apiAdaper),
                                            CommentAsideInteractionPlugin(),
                                            CommentDraftPlugin(),
                                            CommentStatistPlugin(),
                                            CommentImagePlugin(),
                                            CommentReactionPlugin(),
                                            CommentMenuPlugin(),
                                            CommentBusinessPlugin()]
        let docsInfo = dependency?.commentDocsInfo as? DocsInfo
        if docsInfo?.isInCCMDocs == true {
            plugins.append(CommentMonitorPlugin())
        }
        commentScheduler.connect(plugins: plugins)
        commentScheduler.apply(context: self)
        self.viewInteraction = commentScheduler
        commentScheduler.state.skip(1).subscribe(onNext: { [weak self] (state) in
            guard let self = self else { return }
            self.asideCommentView.handleState(state)
        }).disposed(by: disposeBag)
    }
}

// MARK: - CommentServiceContext

extension AsideCommentModule: CommentServiceContext {

    var commentView: UIView {
        asideCommentView
    }
    
    var scheduler: CommentSchedulerType? {
        commentScheduler
    }
    
    var tableView: UITableView? {
        asideCommentView.tableView
    }
    
    var businessDependency: DocsCommentDependency? { dependency }
    
    var pattern: CommentModulePattern { .aside }

}

// MARK: - CommentTableViewCellDelegate

extension AsideCommentModule: CommentTableViewCellDelegate {

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
        return commentScheduler.fetchCache(by: cacheable.cacheKey)
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
