//
//  MinutesSubtitlesViewController+CCM.swift
//  Minutes
//
//  Created by yangyao on 2022/11/14.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

struct CommentContext {
    let pid: String
    let indexPath: IndexPath
    let quote: String
    var localCommentID: String
    let offsetAndSize: [OffsetAndSize]
    let range: NSRange
}

extension MinutesSubtitlesViewController {
    func createCCMInitMonitorTimer(_ handler: (() -> Void)?) {
        ccmInitMonitorTimer = Timer(timeInterval: 5.0, repeats: true, block: { [weak self] (_) in
            handler?()
        })
        if let timer = ccmInitMonitorTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    func invaliateCCMInitMonitorTimer() {
        ccmInitMonitorTimer?.invalidate()
        ccmInitMonitorTimer = nil
    }
    
    func createCCMMetaDataMonitorTimer(_ handler: (() -> Void)?) {
        ccmMetaDataMonitorTimer = Timer(timeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            handler?()
        })
        if let timer = ccmMetaDataMonitorTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    func invaliateCCMMetaDataMonitorTimer() {
        ccmMetaDataMonitorTimer?.invalidate()
        ccmMetaDataMonitorTimer = nil
    }

    // disable-lint: magic number
    func initCCMModule() {
        commentDependency = try? userResolver.resolve(MinutesCommentDependency.self)
        MinutesLogger.subtitle.info("[comment sdk] minutes call initCCMModule: \(commentDependency)")
        let token = viewModel.minutes.objectToken
        
        let hasPermission = viewModel.minutes.basicInfo?.canComment == true
        let language = dataProvider?.currentTranslateLanguage()
        commentDependency?.initCCMCommentModule(token: token, type: 28, permission: MinutesCommentPermissionType(canComment: hasPermission, canResolve: hasPermission, canShowMore: true, canShowVoice: true, canReaction: true, canCopy: true, canDelete: hasPermission, canTranslate: true, canDownload: true), translateLanguage: language, delegate: self)

        createCCMInitMonitorTimer { [weak self] in
            if self?.isCCMInitSuccess == false {
                self?.commentDependency?.fetchComment()
            }
        }
    }
    // enable-lint: magic number
    
    func showAddCommentPanel(context: CommentContext) {
        let localId = createLocalId()
        
        var commentContext = context
        commentContext.localCommentID = localId
        addNewLocalComments(commentContext)

        MinutesLogger.subtitle.info("[comment sdk] minutes showAddCommentPanel: \(commentDependency), \(context.quote), \(localId)")
                        
        let hasPermission = viewModel.minutes.info.statusInfo?.canComment == true
        commentDependency?.updatePermission(permission: MinutesCommentPermissionType(canComment: hasPermission, canResolve: hasPermission, canShowMore: true, canShowVoice: true, canReaction: true, canCopy: true, canDelete: hasPermission, canTranslate: true, canDownload: true))
        commentDependency?.showCommentInput(quote: context.quote, tmpCommentId: localId)
    }
}

extension MinutesSubtitlesViewController: CCMCommentDelegate {
    func didDeleteComment(with commentId: String) {
        
    }
    
    func didResolveComment(with commentId: String) {
        
    }
    
    func didSwitchCard(commentId: String, height: CGFloat) {
        var indexPath: IndexPath?
        for pVM in viewModel.data {
            if let result = pVM.commentIDAndRanges.keys.first { $0 == commentId } {
                indexPath = subtitleIndexPath(pVM.pIndex)
                break
            }
        }
        guard let indexPath = indexPath else { return }
        serialQueue.async {
            // 子线程同步高亮数据
            let range = self.syncNewHighligtedCommentId(commentId, indexPath: indexPath)
            DispatchQueue.main.async {
                // 主线程替换数据
                self.viewData = self.viewModel.data
                self.reloadData()
                // 定位到相关位置
                if let range = range {
                    let offsetY = MinutesSubtileUtils.rangeOffsetIn(self.viewData, row: indexPath.row, range: range)
                    self.scrollTo(offset: offsetY + self.otherSectionHeight, indexPath: indexPath, forceScroll: true, didCompleted: nil)
                }
            }
        }
    }
    
    /// 关掉评论UI时会回调给业务接入方
    func cancelComment(type: MinutesCloseCommentType) {
        guard let indexPath = commentIndexPath else { return }

        if type == .closeNewInput {
            
        }
        // 关闭评论发送 or 关闭评论页面
        if type == .cancelNewInput || type == .closeFloatCard {
            // 子线程处理数据
            serialQueue.async {
                self.clearNewCommentHighlight(indexPath)
                DispatchQueue.main.async {
                    // 主线程替换数据
                    self.viewData = self.viewModel.data
                    self.tableView?.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
    
    /// 键盘事件通知
    func keyboardChange(options: Int, textViewHeight: CGFloat) {}
}


extension MinutesSubtitlesViewController {
    func updateHighlightInfo(_ response: CommentResponseV2,
                                       indexPath: IndexPath,
                             containerWidth: CGFloat, didCompleted: (() -> Void)?) {
        guard indexPath.row < viewModel.data.count else { return }

        let pVM: MinutesParagraphViewModel = viewModel.data[indexPath.row]

        // 更新highlight信息
        if var paragraphs = viewModel.paragraphs,
           let paragraph = response.subtitles[pVM.pid] {
            let highlightedCommentId = (commentDependency?.isVisiable ?? false) ? response.commentID : nil
            // 替换
            paragraphs[indexPath.row] = paragraph
            viewModel.calculate(containerWidth: containerWidth,
                                 paragraphs: paragraphs,
                                 commentsInfo: commentsViewModel?.commentsInfo,
                                highlightedCommentId: highlightedCommentId,
                                isInTranslationMode: viewModel.isInTranslationMode, ccmComments: minutesComments) {
                [weak self] data, pidAndSentenceDict, sentenceContentLenDict, pidAndIdxDict in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.viewModel.data = data
                    self.viewModel.paragraphs = paragraphs
                    self.viewModel.pidAndSentenceDict = pidAndSentenceDict
                    self.viewModel.sentenceContentLenDict = sentenceContentLenDict
                    self.viewModel.pidAndIdxDict = pidAndIdxDict
                    didCompleted?()
                }
            }
        }
    }
}
