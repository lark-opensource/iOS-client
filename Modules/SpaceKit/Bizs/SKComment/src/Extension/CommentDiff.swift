//
//  CommentDiff.swift
//  SKCommon
//
//  Created by huayufan on 2022/11/4.
//  


import SKFoundation
import RxDataSources
import Differentiator

extension Differentiator.Changeset where Section == CommentSection {
    func printDiff(with commentSections: [CommentSection]) {
        if !self.deletedSections.isEmpty {
            var commentLog = ""
            if self.deletedSections.count == 0,
               let comment = commentSections[CommentIndex(self.deletedSections[0])] {
                commentLog = "commentId:\(comment.commentID)"
            }
            DocsLogger.info("[diff] deletedSections:\(self.deletedSections) \(commentLog)", component: LogComponents.comment)
        }
            
        if !self.insertedSections.isEmpty {
            var commentLog = ""
            if self.deletedSections.count == 0,
               let comment = commentSections[CommentIndex(self.insertedSections[0])] {
                commentLog = "commentId:\(comment.commentID)"
            }
            DocsLogger.info("[diff] insertedSections:\(self.insertedSections) \(commentLog)", component: LogComponents.comment)
        }

        for (source, target) in self.movedSections {
            DocsLogger.info("[diff] movedSections: source:\(source) target:\(target)", component: LogComponents.comment)
        }

        if !self.deletedItems.isEmpty {
            let paths = self.deletedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }
            var replyLog = ""
            if paths.count == 1, let item = commentSections[paths[0]] {
                replyLog = "commentId:\(item.commentId ?? "") replyId:\(item.replyID) "
            }
            DocsLogger.info("[diff] deletedItems:\(paths) \(replyLog)", component: LogComponents.comment)
        }

        if !self.insertedItems.isEmpty {
            let paths = self.insertedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }
            var replyLog = ""
            if paths.count == 1, let item = commentSections[paths[0]] {
                replyLog = "commentId:\(item.commentId ?? "") replyId:\(item.replyID) "
            }
            DocsLogger.info("[diff] insertedItems:\(paths) replyInfo:\(replyLog)", component: LogComponents.comment)
        }

        if !self.updatedItems.isEmpty {
            let paths = self.updatedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }
            DocsLogger.info("[diff] updatedItems:\(paths)", component: LogComponents.comment)
        }

        for (source, target) in self.movedItems {
            let sourceIndex = IndexPath(row: source.itemIndex, section: source.sectionIndex)
            let targetIndex = IndexPath(row: target.itemIndex, section: target.sectionIndex)
            DocsLogger.info("[diff] movedItems:source:\(sourceIndex) target:\(targetIndex)", component: LogComponents.comment)
        }
    }
}
