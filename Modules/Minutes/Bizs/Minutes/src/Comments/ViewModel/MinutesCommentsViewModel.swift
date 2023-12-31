//
//  MinutesCommentsViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/2/3.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkLocalizations

class MinutesCommentsViewModel {
    let minutes: Minutes
    var commentsInfo: [String: ParagraphCommentsInfo] = [:]
    var originalCommentsInfo: [String: ParagraphCommentsInfo]?
    var highligtedCommentId: String?
    let isInTranslationMode: Bool
    var sentQueueComments: [String: String] = [:]
    
    init(minutes: Minutes, commentsInfo: [String: ParagraphCommentsInfo], highligtedCommentId: String?, isInTranslationMode: Bool) {
        self.minutes = minutes
        // 如果不在翻译mode下，则commentsInfo为原始数据，否则为翻译数据
        self.commentsInfo = commentsInfo
        // 原始评论数据，总是有
        self.originalCommentsInfo = minutes.data.paragraphComments
        self.highligtedCommentId = highligtedCommentId
        self.isInTranslationMode = isInTranslationMode
    }
    
    func bindCommentAction(catchError: Bool, pid: String, quote: String, commentID: String, offsetAndSize: [OffsetAndSize], success: ((CommentResponseV2) -> Void)?, fail: ((Error) -> Void)?) {
        var highlightInfos: [SentenceHighlightsInfo] = []
        for (pid, offset, size, startTime) in offsetAndSize {
            // select area offset and size in sentence
            let highlight = Highlight(offset: offset, size: size, type: 2, seq: nil, uuid: UUID().uuidString, commentID: nil, startTime: startTime, id: nil)
            // sentence_id
            let highlightsInfo = SentenceHighlightsInfo(id: pid, language: LanguageManager.currentLanguage.localeIdentifier, highlights: [highlight])
            highlightInfos.append(highlightsInfo)
        }

        minutes.data.bindComment(catchError: catchError, quote: quote, commentID: commentID, paragraphID: pid, highlights: highlightInfos, completionHandler: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    success?(response.data)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    fail?(error)
                }
            }
        })
    }

    func sendCommentsAction(catchError: Bool, _ isReply: Bool, text: String, pid: String? = nil, commentId: String? = nil, quote: String? = nil, offsetAndSize: [OffsetAndSize]? = nil, success: ((CommonCommentResponse) -> Void)?, fail: ((Error) -> Void)?) {
        if isReply {
            guard let commentId = commentId else {
                return
            }
            minutes.data.replyComments(catchError: catchError, content: text, commentID: commentId) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        success?(response.data)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        fail?(error)
                    }
                }
            }
        } else {
            guard let pid = pid, let quote = quote, let offsetAndSize = offsetAndSize else { return }
            var highlightInfos: [SentenceHighlightsInfo] = []
            for (pid, offset, size, startTime) in offsetAndSize {
                // select area offset and size in sentence
                let highlight = Highlight(offset: offset, size: size, type: 2, seq: nil, uuid: UUID().uuidString, commentID: nil, startTime: startTime, id: nil)
                // sentence_id
                let highlightsInfo = SentenceHighlightsInfo(id: pid, language: LanguageManager.currentLanguage.localeIdentifier, highlights: [highlight])
                highlightInfos.append(highlightsInfo)
            }

            minutes.data.addComments(catchError: catchError, quote: quote, content: text, paragraphID: pid, highlights: highlightInfos, completionHandler: { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        success?(response.data)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        fail?(error)
                    }
                }
            })
        }
    }

    func deleteComments(catchError: Bool, _ contentID: String, success: ((CommonCommentResponse) -> Void)?, fail: ((Error) -> Void)?) {
        minutes.data.deleteComment(catchError: catchError, contentID: contentID, completionHandler: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    success?(response.data)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    fail?(error)
                }
            }
        })
    }
    
    func unbindComments(catchError: Bool, _ commentId: String, success: ((String) -> Void)?, fail: ((Error) -> Void)?) {
        minutes.data.unbindComment(catchError: catchError, commentId: commentId, completionHandler: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    success?(response.data)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    fail?(error)
                }
            }
        })
    }
}
