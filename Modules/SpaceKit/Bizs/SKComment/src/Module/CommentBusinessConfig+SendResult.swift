//
//  CommentBusinessConfig+SendResult.swift
//  SKCommon
//
//  Created by ByteDance on 2023/5/9.
//

import Foundation
import SKFoundation
import SKCommon
import SpaceInterface

extension CommentBusinessConfig.SendScene {

    fileprivate var description: String {
        switch self {
        case .add: return "create"
        case .reply: return "reply"
        case .edit: return "edit"
        }
    }
}

extension CommentBusinessConfig.SendResult {

    fileprivate var description: String {
        switch self {
        case .success: return "success"
        case .failure: return "fail"
        case .cancel: return "cancel"
        }
    }

    fileprivate var failReason: String? {
        switch self {
        case .failure(let reason): return "\(reason)"
        default: return nil
        }
    }
}

typealias SendScene = CommentBusinessConfig.SendScene
typealias SendResult = CommentBusinessConfig.SendResult

// 上报记录
private struct SendReportRecord {
    let identifier: String
    let scene: SendScene
    let startTime: CFAbsoluteTime
    private var endTime: CFAbsoluteTime = 0
    private var result: SendResult?

    // 耗时, 单位秒
    private var duration: CFAbsoluteTime { max(0, endTime - startTime) }

    init(identifier: String, scene: SendScene) {
        self.identifier = identifier
        self.scene = scene
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    fileprivate mutating func markEnd(result: SendResult, addtionalParams: CommentDocsInfo? = nil) {
        self.endTime = CFAbsoluteTimeGetCurrent()
        self.result = result
        self.report(addtionalParams: addtionalParams)
    }
    // 上报
    private func report(addtionalParams: CommentDocsInfo? = nil) {
        guard let info = addtionalParams, let result = result else { return }

        var params: [CommentTracker.PerformanceKey: Any] = [:]
        params[.succResult] = result.description
        if let reason = result.failReason {
            params[.failReason] = reason
        }
        params[.cost] = Int(duration * 1000) // 毫秒
        params[.domain] = "part_comment"
        params[.type] = scene.description
        params[.fileType] = info.type.name
        params[.fileId] = DocsTracker.encrypt(id: info.objToken)
        CommentTracker.reportSubmit(params: params)

        let sortedParams = params.sorted {
            $0.key.rawValue.compare($1.key.rawValue) == .orderedAscending
        }
        let desc = sortedParams.reduce("") { $0 + "🔘\($1.key.rawValue): \($1.value)" }
        DocsLogger.info("comment send report params:\(desc)")
    }
}

/// 用户视角发送成功率埋点
final class CommentSendResultReporter {

    var commentDocsInfoBlock: (() -> CommentDocsInfo?)?

    // 测试遍历1k条回复耗时1ms左右，性能消耗较小
    private var uuidDict = ThreadSafeDictionary<String, SendReportRecord>()

    private func findTargetCommentItemBy(commentData: CommentData, filterBlock: (String) -> Bool) -> CommentItem? {
        for comment in commentData.comments {
            for reply in comment.commentList {
                let isSending = reply.isSending // `发送中`的需要排除
                if isSending == false, filterBlock(reply.replyUUID) {
                    return reply
                }
            }
        }
        return nil
    }
    
    // case1: 在大图界面新增的评论,markStart时只有commentUUID,发送后通过showCard过来的数据只能通过commentUUID匹配
    // case2: iPad新建评论在侧边栏展示时
    private func findTargetCommentBy(commentData: CommentData) -> (String, CommentItem)? {
        for comment in commentData.comments {
            if uuidDict.value(ofKey: comment.commentUUID) != nil {
                let reply = comment.commentList.first(where: { $0.uiType.isNormal })
                if let reply = reply, reply.isSending == false {
                    return (comment.commentUUID, reply)
                }
            }
        }
        return nil
    }
}

extension CommentSendResultReporter: CommentSendResultReporterType {

    /// 开始`发送`
    func markEventStart(uuid: String, scene: CommentBusinessConfig.SendScene) {
        let record = SendReportRecord(identifier: uuid, scene: scene)
        self.uuidDict.updateValue(record, forKey: uuid)
    }

    /// 完成`发送`
    func markEventEndBy(uuid: String, result: CommentBusinessConfig.SendResult) {
        if var record = self.uuidDict.value(ofKey: uuid) {
            let params = self.commentDocsInfoBlock?()
            record.markEnd(result: result, addtionalParams: params)
            self.uuidDict.removeValue(forKey: uuid)
        } else {
            DocsLogger.info("can not find record by uuid:\(uuid)")
        }
    }

    /// 完成`发送`
    func markEventEndBy(commentData: CommentData) {
        let filterBlock: (String) -> Bool = { [weak self] key in
            self?.uuidDict.value(ofKey: key) != nil
        }
        let tuple: (uuid: String, item: CommentItem)?
        if let item = findTargetCommentItemBy(commentData: commentData, filterBlock: filterBlock) {
            tuple = (item.replyUUID, item)
        } else if let value = findTargetCommentBy(commentData: commentData) {
            tuple = value
        } else {
            tuple = nil
        }
        guard let tuple = tuple else { return }
        let result: SendResult = (tuple.item.enumError == nil) ? .success : .failure(reason: "\(tuple.item.errorCode)")
        self.markEventEndBy(uuid: tuple.uuid, result: result)
    }

    /// 退出文档
    func markDocExit() {
        let uuids = uuidDict.all().keys
        for uuid in uuids {
            self.markEventEndBy(uuid: uuid, result: .cancel)
        }
    }
}

class DummyCommentSendResultReporter: CommentSendResultReporterType {
    var commentDocsInfoBlock: (() -> CommentDocsInfo?)?
    func markEventStart(uuid: String, scene: CommentBusinessConfig.SendScene) {}
    func markEventEndBy(uuid: String, result: CommentBusinessConfig.SendResult) {}
    func markEventEndBy(commentData: CommentData) {}
    func markDocExit() {}
}
