//
//  MinutesSubtitlesViewController+Comment.swift
//  Minutes
//
//  Created by yangyao on 2022/11/17.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

extension MinutesSubtitlesViewController {
    func showNewCommentsCardVC(_ indexPath: IndexPath? = nil,
                            response: CommonCommentResponse? = nil,
                            highligtedCommentId: String? = nil,
                            contentId: String? = nil,
                            needScrollToBottom: Bool = false,
                            canComment: Bool = true,
                               cid: String?) {
        self.commentIndexPath = indexPath
        
        if let id = cid {
            commentDependency?.showCommentCards(commentId: id, replyId: nil)
            if let language = dataProvider?.currentTranslateLanguage() {
                commentDependency?.updateTranslateLang(lan: language)
            }
        } else {
            MinutesLogger.subtitle.info("[comment sdk] minutes show comment card is nil")
        }
    }
        
    func showCommentsCardVC(_ indexPath: IndexPath? = nil,
                            response: CommonCommentResponse? = nil,
                            highligtedCommentId: String? = nil,
                            contentId: String? = nil,
                            needScrollToBottom: Bool = false,
                            canComment: Bool = true) {
        self.commentIndexPath = indexPath
        
        if let highligtedCommentId = highligtedCommentId {
            var pid: String?
            var currentCount: NSInteger = 0
            var indexPath: IndexPath?
            var contentRow: NSInteger?
            // mention 提醒
            guard let vm = commentsViewModel, vm.commentsInfo.keys.count != 0 else { return }
            var didFind: Bool = false
            var didFindComment: Comment?
            // 由于编辑等原因，key可能不在当前的pid数组中
            for (key, value) in vm.commentsInfo where didFind == false && value.commentList != nil && viewData.first(where: { $0.pid == key }) != nil {
                for (idx, c) in value.commentList!.enumerated() where c.id == highligtedCommentId {
                    currentCount = idx
                    pid = key
                    didFind = true
                    contentRow = c.contents.firstIndex(where: { $0.id == contentId })
                    break
                }
            }

            if pid == nil || contentRow == nil {
                self.delegate?.showToast(text: BundleI18n.Minutes.MMWeb_G_AtMentionCommentDeleted_Toast)
                return
            }

            for (idx, pVM) in viewData.enumerated() where pVM.pid == pid {
                indexPath = subtitleIndexPath(idx)
            }

            if let pid = pid, let indexPath = indexPath {
                doShowCommentPage(pid,
                                  currentCount: currentCount,
                                  indexPath: indexPath,
                                  contentRow: contentRow,
                                  needScrollToBottom: needScrollToBottom,
                                  animated: true, canComment: canComment)
            }
        } else {
            var currentCount: NSInteger = 0

            guard let indexPath = indexPath, indexPath.row < viewData.count else { return }
            let pVM: MinutesParagraphViewModel = viewData[indexPath.row]

            if let response = response,
               let commentsInfo = response.comments[pVM.pid],
               let subtitle = response.subtitles[pVM.pid],
               let commentList = commentsInfo.commentList,
               let highligtedCommentId = commentsViewModel?.highligtedCommentId {
                for (idx, c) in commentList.enumerated() where c.id == highligtedCommentId {
                        currentCount = idx
                        break
                    }
                }

            doShowCommentPage(pVM.pid,
                              currentCount: currentCount,
                              indexPath: indexPath,
                              needScrollToBottom: needScrollToBottom,
                              animated: true, canComment: canComment)
        }
    }

    func doShowCommentPage(_ pid: String, currentCount: NSInteger, indexPath: IndexPath, contentRow: NSInteger? = nil, needScrollToBottom: Bool, animated: Bool, canComment: Bool) {
        guard let tableView = tableView else {
            return
        }
        // 弹出评论页面
        isInCommentPage = true
        let commentsCardVC = MinutesCommentsCardViewController(resolver: userResolver, minutes: viewModel.minutes,
                                                               pid: pid,
                                                               commentsViewModel: commentsViewModel,
                                                               currentCount: currentCount,
                                                               contentRow: contentRow,
                                                               needScrollToBottom: needScrollToBottom,
                                                               animated: animated)
        commentsCardVC.canComment = canComment
        commentsCardVC.currentHighlightedBlock = { [weak self] comment in
            guard let self = self else { return }

            self.serialQueue.async {
                // 子线程同步高亮数据
                let range = self.syncHighligtedCommentId(comment.id, indexPath: indexPath)
                DispatchQueue.main.async {
                    // 主线程替换数据
                    self.viewData = self.viewModel.data
                    tableView.reloadRows(at: [indexPath], with: .none)
                    if !self.isInBottom {
                        // 定位到相关位置
                        if let range = range {
                            let offsetY = MinutesSubtileUtils.rangeOffsetIn(self.viewData, row: indexPath.row, range: range)
                            self.scrollTo(offset: offsetY + self.otherSectionHeight, indexPath: indexPath, didCompleted: nil)
                        }
                    }
                }
            }
        }
        commentsCardVC.dismissBlock = { [weak self] in
            guard let self = self else { return }

            self.isInCommentPage = false
            self.serialQueue.async {
                // 同步高亮数据
                self.syncHighligtedCommentId(nil, indexPath: indexPath)
                DispatchQueue.main.async {
                    // 刷新UI
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }

        let nav = UINavigationController(rootViewController: commentsCardVC)
        nav.modalPresentationStyle = .overFullScreen
        self.present(nav, animated: false, completion: {[weak self] in
            self?.delegate?.showComments()
        })

        tracker.tracker(name: .detailClick, params: ["click": "view_comment", "target": "none", "location": "subtitle"])
    }

    // 清除高亮
    func clearCommentHighlight(_ indexPath: IndexPath) {
        guard indexPath.row < viewModel.data.count else { return }

        let pVM = viewModel.data[indexPath.row]
        pVM.selectedRange = nil
    }

    func syncHighligtedCommentId(_ commentId: String?, indexPath: IndexPath) -> NSRange? {
        guard indexPath.row < viewModel.data.count else { return nil }

        let pVM: MinutesParagraphViewModel = viewModel.data[indexPath.row]
        // 更新comment id
        commentsViewModel?.highligtedCommentId = commentId
        // 同步高亮
        let range = pVM.highlightCommentRange(commentId)
        return range
    }
    
    func updateCommentAndHighlightInfo(_ response: CommonCommentResponse,
                                       indexPath: IndexPath,
                                       containerWidth: CGFloat) {
        guard indexPath.row < viewModel.data.count else { return }

        let pVM: MinutesParagraphViewModel = viewModel.data[indexPath.row]
        // 获取最新评论的comment id并更新
        if let commentsInfo = response.comments[pVM.pid],
           let commentList = commentsInfo.commentList,
           let newComment = commentList.sorted(by: { $0.createTime < $1.createTime }).last {
            commentsViewModel?.commentsInfo[pVM.pid] = commentsInfo
            commentsViewModel?.highligtedCommentId = newComment.id
        }

        // 更新highlight信息
        if var paragraphs = viewModel.paragraphs,
           let paragraph = response.subtitles[pVM.pid] {
            let old = viewModel.data[indexPath.row]
            // 替换
            paragraphs[indexPath.row] = paragraph
            viewModel.calculate(containerWidth: containerWidth,
                                 paragraphs: paragraphs,
                                 commentsInfo: commentsViewModel?.commentsInfo,
                                 highlightedCommentId: commentsViewModel?.highligtedCommentId,
                                isInTranslationMode: viewModel.isInTranslationMode, ccmComments: minutesComments) {
                [weak self] data, pidAndSentenceDict, sentenceContentLenDict, pidAndIdxDict in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.viewModel.data = data
                    self.viewModel.paragraphs = paragraphs
                    self.viewModel.pidAndSentenceDict = pidAndSentenceDict
                    self.viewModel.sentenceContentLenDict = sentenceContentLenDict
                    self.viewModel.pidAndIdxDict = pidAndIdxDict
                }
            }
        }
    }
    
    func createLocalId() -> String {
        return UUID().uuidString
    }

    func addNewLocalComments(_ comment: CommentContext) {
        localComments.append(comment)
    }
}

extension MinutesSubtitlesViewController {
    func syncNewHighligtedCommentId(_ commentId: String?, indexPath: IndexPath) -> NSRange?  {
        guard indexPath.row < viewModel.data.count else { return nil }
        var highlightRange: NSRange?
        // 更新comment id
        commentsViewModel?.highligtedCommentId = commentId
        for (idx, pVM) in viewModel.data.enumerated() {
            if idx == indexPath.row {
                let range = pVM.highlightCommentRange(commentId)
                highlightRange = range
            } else {
                pVM.highlightCommentRange(nil)
            }
        }
        return highlightRange
    }

    // 关闭评论发送 or 关闭评论页面 清除黄色高亮
    func clearNewCommentHighlight(_ indexPath: IndexPath) {
        guard indexPath.row < viewModel.data.count else { return }

        commentsViewModel?.highligtedCommentId = nil
        let pVM = viewModel.data[indexPath.row]
        pVM.selectedRange = nil
        pVM.highlightCommentRange(nil)
    }
}
