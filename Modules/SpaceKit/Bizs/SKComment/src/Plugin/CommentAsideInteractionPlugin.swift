//
//  CommentInteractionPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/7.
//
//  swiftlint:disable cyclomatic_complexity

// 评论Cell UI交互处理

import UIKit
import SKFoundation
import SKUIKit
import SpaceInterface

final class CommentAsideInteractionPlugin: CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "InteractionPlugin"
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .interaction(uiAction):
            handleUIAction(action: uiAction)
        default:
            break
        }
    }
    
    func handleUIAction(action: CommentAction.UI) {
        switch action {
        case let .edit(item):
            handleEdit(item)
        case let .reply(item):
            handleReply(item)
        case let .didSelect(comment):
            handleDidSelect(comment)
        case .keyCommandUp:
            handleKeyCommand(isDown: false)
        case .keyCommandDown:
            handleKeyCommand(isDown: true)
        case .textViewDidBeginEditing:
            scheduler?.dispatch(action: .ipc(.becomeResponser, nil))

        case .hideComment, .clickClose:
            scheduler?.dispatch(action: .ipc(.setNormalMode, { [weak self] (index, _) in
                if let section = index as? CommentIndex {
                    self?.scheduler?.reduce(state: .updateSections([section.value]))
                }
            }))
            scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
            if case .clickClose = action {
                scheduler?.dispatch(action: .api(.closeComment, nil))
                context?.businessDependency?.dismissCommentView()
            }
        case let .willDisplayUnread(item):
            scheduler?.dispatch(action: .api(.readMessage(item), nil))
            
        case let .contentBecomeInvisibale(info):
            scheduler?.dispatch(action: .api(.contentBecomeInvisibale(info), nil))
    
        case let .magicShareScroll(info):
            scheduler?.dispatch(action: .api(.magicShareScroll(info), nil))

        case let .clickRetry(item):
            handleClickRetry(item)
            
        case let .didMention(atInfo):
            scheduler?.dispatch(action: .api(.didMention(atInfo), nil))
            
        case let .switchCard(commentId, height):
            scheduler?.dispatch(action: .api(.switchCard(commentId: commentId, height: height), nil))
            
        case .tapBlank:
            self.scheduler?.dispatch(action: .resetActive)
            self.scheduler?.dispatch(action: .api(.switchCard(commentId: "", height: 0), nil))
            
        default:
            break
        }
    }
    
    var scheduler: CommentSchedulerType? {
        return context?.scheduler
    }
}

extension CommentAsideInteractionPlugin {
    
    private func handleClickRetry(_ item: CommentItem) {
        let error = item.enumError
        if error == .violateTOS1 || error == .violateTOS1 {
            // TODO: - hyf 待测试
            handleEdit(item)
        } else if error == .loadImageError {
            DocsLogger.info("reload image replyId:\(item.replyID)", component: LogComponents.comment)
            // TODO: - hyf 待测试
            item.errorCode = 0
            scheduler?.dispatch(action: .ipc(.refresh(commentId: item.commentId ?? "", replyId: item.replyID), nil))
            // TODO: - hyf 埋点
//                let isActive = currentComment?.commentID == commentItem.commentId
//                CommentTracker.retryLoadImage(docsInfo: commentData.docsInfo, isActive: isActive, commentId: commentItem.commentId ?? "")
        } else { // 其他失败
            scheduler?.dispatch(action: .api(.retry(item), nil))
        }
    }

    private func handleEdit(_ item: CommentItem) {
        guard item.canComment else {
            DocsLogger.error("handle edit error, permission denied", component: LogComponents.comment)
            return
        }
        // 如果当前不是激活评论先要激活
        // 优先取草稿值，没有取内容
        guard let commentId = item.commentId else {
            DocsLogger.error("handleEdit commentId is nil", component: LogComponents.comment)
            return
        }

        activeComment(commentId)
        let action: CommentAction = .ipc(.setEditMode(replyId: item.replyID,
                                                       becomeResponser: true), { [weak self] (response, _)  in
            guard let self = self,
                   let indexPath = response as? IndexPath else {
                return
            }
            // 设置草稿
            self.scheduler?.dispatch(action: .ipc(.setEditDraft(item), nil))
            // 更新UI
            self.scheduler?.reduce(state: .updateSections([indexPath.section]))
            
            self.scheduler?.reduce(state: .keepInputVisiable(indexPath: indexPath, force: false))
        })
        scheduler?.dispatch(action: action)
    }
    
    private func handleReply(_ item: CommentItem) {
        guard item.canComment else {
            DocsLogger.error("handle reply error, permission denied", component: LogComponents.comment)
            return
        }
        guard let commentId = item.commentId, let name = item.name else {
            DocsLogger.error("handleReply commentId is nil", component: LogComponents.comment)
            return
        }
        // 设置草稿
        let atInfo = AtInfo(type: .user, href: "", token: item.userID, at: name)
        scheduler?.dispatch(action: .ipc(.setReplyDraft(item, atInfo), nil))
        
        // 如果当前不是激活评论先要激活
        activeComment(commentId)
        
        let action: CommentAction = .ipc(.setReplyMode(commentId: commentId,
                                                       becomeResponser: true), { [weak self] (response, _)  in
            guard let self = self,
                   let sections = response as? (CommentIndex, CommentIndex) else {
                return
            }
            let (_, next) = sections

            self.scheduler?.reduce(state: .updateSections([next.value]))
            
            // 因为主端有防止crash机制：update firstResponser的cell时，会主动resign
            // 需要重新抢回焦点
            self.forceInputActive()
            
            // 评论过长可能会导致输入框不在视口范围，需要滚动到屏幕范围内
            self.scheduler?.reduce(state: .ensureInScreen(IndexPath(row: -1, section: next.value)))
        })
        scheduler?.dispatch(action: action)
    }
    
    private func forceInputActive() {
        let action = CommentAction.ipc(.fetchSnapshoot, { [weak self] (result, error) in
            guard let snapshoot = result as? CommentSnapshootType else {
                DocsLogger.error("fetch snapshoot, error", error: error, component: LogComponents.comment)
                return
            }
            self?.scheduler?.reduce(state: .forceInputActiveIfNeed(at: snapshoot.indexPath))
        })
        scheduler?.dispatch(action: action)
    }

    private func handleDidSelect(_ comment: Comment) {
        activeComment(comment.commentID)
    }
    
    private func activeComment(_ commentId: String) {
        let fastState = scheduler?.fastState
        let activeCommentId = fastState?.activeCommentId
        
        // 确保comment非当前激活评论
        if commentId != activeCommentId {
            // 上一条评论是新建状态当前非新建状态时，需要通知前端取消新建评论
            if fastState?.activeComment?.isNewInput == true {
                scheduler?.dispatch(action: .api(.cancelPartialNewInput, nil))
            }

            let action: CommentAction = .ipc(.setReplyMode(commentId: commentId,
                                                           becomeResponser: false), { [weak self] (response, _)  in
                guard let self = self,
                       let sections = response as? (CommentIndex, CommentIndex) else {
                    return
                }
                let (_, next) = sections
                // 局部更新会有奇怪闪烁 且对齐偶尔失灵，这里需要reload
                self.scheduler?.reduce(state: .reload)
                
                // 再进行自我对齐
                if next.value != CommentIndex.notFound.value {
                   self.scheduler?.reduce(state: .align(indexPath: IndexPath(row: 0, section: next.value), position: nil))
                   self.scheduler?.reduce(state: .listenKeyboard)
                }
            })
            scheduler?.dispatch(action: action)
        } else {
            DocsLogger.info("click same commentId:\(commentId)", component: LogComponents.comment)
        }
    }
    
    private func handleKeyCommand(isDown: Bool) {
        let action: CommentAction = .ipc( isDown ? .activeNext : .activePre, {  [weak self] (commentId, error) in
            if let id = commentId as? String {
                self?.activeComment(id)
            } else {
                DocsLogger.error("handle KeyCommand action error", error: error, component: LogComponents.comment)
            }
        })
        scheduler?.dispatch(action: action)
    }
}
