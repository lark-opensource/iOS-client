//
//  SearchInputHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/13.
//

import Foundation

/**
 * 场景1：预先准备好搜索的数据
 * 技术文档：https://bytedance.feishu.cn/wiki/wikcnsrBau9PMm8wSRCSteS35pb#
 */
class PreSearchHandler {

    private lazy var processItemContentsQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
        return queue
    }()

    private lazy var mRegExQuote = try? NSRegularExpression(pattern: "<[^>]*id=\"lark-mail-quote-", options: .caseInsensitive)
    private lazy var mRegExSpanStart = try? NSRegularExpression(pattern: "<[\\s]*?span[^>]*?>", options: .caseInsensitive)
    private lazy var mRegExSpanEnd = try? NSRegularExpression(pattern: "<[\\s]*?\\/[\\s]*?span[\\s]*?>", options: .caseInsensitive)

    private var needContentsMsgIds = ThreadSafeArray<String>(array: [])
    private(set) var readyItemContents = ThreadSafeArray<(msgId: String, itemContent: String)>(array: [])

    private weak var searchViewModel: MailMessageSearchViewModel?

    init(searchViewModel: MailMessageSearchViewModel) {
        self.searchViewModel = searchViewModel
    }

    func closeSearch() {
        // handle search end
    }

    func preprocessItemContents(notLoadedMsgIDs: [String]) {
        needContentsMsgIds = ThreadSafeArray<String>(array: notLoadedMsgIDs)
        readyItemContents = ThreadSafeArray<(msgId: String, itemContent: String)>(array: [])
        processItemContents()
    }

    /// Reset 并返回没有append的msgids
    func reset() {
        processItemContentsQueue.isSuspended = true
        processItemContentsQueue.cancelAllOperations()
    }

    func endPreSearch(searchTaskMap: inout [String: SearchTask], messageItems: [MailMessageItem]) -> [String] {
        var notJSLoadedMsgIds = [String]()
        let readyMsgIds = readyItemContents.all.map({ $0.msgId })
        let needContentsMsgIds = self.needContentsMsgIds.all
        for id in needContentsMsgIds where !readyMsgIds.contains(where: { needContentsMsgIds.contains($0) }) {
            notJSLoadedMsgIds.append(id)
        }

        let nativeSearchTitle = searchViewModel?.delegate?.shouldNativeSearchTitle() == true
        let mailTitleSearchTask = SearchTask(msgID: "mail_title", isNativeSearch: nativeSearchTitle)
        if nativeSearchTitle {
            notJSLoadedMsgIds.append("mail_title")
        }
        searchTaskMap["mail_title"] = mailTitleSearchTask

        for messageItem in messageItems {
            let isNativeSearch = notJSLoadedMsgIds.contains(where: { $0 == messageItem.message.id })
            searchTaskMap[messageItem.message.id] = SearchTask(msgID: messageItem.message.id, isNativeSearch: isNativeSearch)
        }
        MailLogger.info("mailcontentsearch preserch notJSLoadedMsgIds \(notJSLoadedMsgIds)")
        return notJSLoadedMsgIds
    }

    private func processItemContents() {
        processItemContentsQueue.cancelAllOperations()
        guard needContentsMsgIds.all.count > 0, let searchViewModel = searchViewModel else {
            return
        }
        let workload = 5
        var allMsgs = needContentsMsgIds.all
        let jobCount = allMsgs.count / workload
        processItemContentsQueue.isSuspended = false
        for _ in 0...jobCount where allMsgs.count > 0 {
            let jobMsgs: [String]
            if allMsgs.count > workload {
                jobMsgs = Array(allMsgs.dropLast(allMsgs.count - workload))
            } else {
                jobMsgs = allMsgs
            }
            allMsgs.removeFirst(jobMsgs.count)
            processItemContentsQueue.addOperation { [weak self] in
                guard let self = self else { return }
                jobMsgs.forEach { (msgId) in
                    let itemContent = searchViewModel.getItemContentFor(msgId: msgId)
                    self.readyItemContents.append(newElement: (msgId, itemContent))
                }
                // do stuff here, prepare itemContent
                searchViewModel.sendPatchItemContentsToJS()
            }
        }
    }

    /// 获取message文本
    func getMessageText(bodyHtml: String) -> String {
        var result = removeQuote(bodyHtml: bodyHtml)
        result = spanToEmptyStr(bodyHtml: result)
        return result
    }

    /// 去除引用后的内容，不搜索引用
    private func removeQuote(bodyHtml: String) -> String {
        if let firstMatch = mRegExQuote?.firstMatch(in: bodyHtml,
                                                    options: .reportCompletion,
                                                    range: NSRange(
                                                        location: 0,
                                                        length: bodyHtml.utf16.count
                                                    )),
           firstMatch.numberOfRanges > 0,
           let range = bodyHtml.range(from: firstMatch.range(at: 0)) {
            return String(bodyHtml[bodyHtml.startIndex..<range.lowerBound])
        }
        return bodyHtml
    }

    /// 去除span tag，只留正文
    private func spanToEmptyStr(bodyHtml: String) -> String {
        guard let mRegExSpanStart = mRegExSpanStart, let mRegExSpanEnd = mRegExSpanEnd else {
            return bodyHtml
        }
        let result = NSMutableString(string: bodyHtml)
        mRegExSpanStart.replaceMatchesInString(string: result, with: "")
        mRegExSpanEnd.replaceMatchesInString(string: result, with: "")
        return result as String
    }
}
