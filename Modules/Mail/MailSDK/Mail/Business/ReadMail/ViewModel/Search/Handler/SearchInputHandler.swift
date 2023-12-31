//
//  SearchInputHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/13.
//

import Foundation

/**
 * 场景2：搜索输入文字后的处理
 * 技术文档：https://bytedance.feishu.cn/wiki/wikcnsrBau9PMm8wSRCSteS35pb#
 */
final class SearchInputHandler {

    let search_ret_key_msgid = "messageId"
    let search_ret_key_count = "count"

    /// msgid: SearchTask
    var searchTaskMap: [String: SearchTask]
    // [[String: Int]]
    var searchRetInfo = [[String: Any]]()

    var isJSSearchDone = false
    var isNativeSearchDone = false
    var totalSearchRetCount = 0

    // @3#噶hN\+\^\[\*\$}!\*-=x61
    private let divideLists = ["@", "3", "#", "噶", "h", "N", "\\+", "\\^", "\\[", "\\*", "\\$", "}", "!", "\\*", "-", "=", "x", "6", "1"]

    /// 过滤所有以<开头以>结尾的标签
    private lazy var regxpForHtml = try? NSRegularExpression(pattern: "<([^>]*)>", options: .caseInsensitive)

    private weak var searchViewModel: MailMessageSearchViewModel?

    init(searchViewModel: MailMessageSearchViewModel) {
        self.searchTaskMap = [String: SearchTask]()
        self.searchViewModel = searchViewModel
    }

    func closeSearch() {
        searchTaskMap.removeAll()
        reset()
    }

    func reset() {
        isJSSearchDone = false
        isNativeSearchDone = false
        totalSearchRetCount = 0
        searchViewModel?.delegate?.updateNativeTitleUI(searchKey: nil, locateIdx: 0)
    }

    func doSearch(searchTask: SearchTask, searchKey: String) {
        reset()
        if searchKey.isEmpty {
            searchTask.searchRetMap[searchKey] = 0
            return
        }
        let divideText = divideLists.first(where: { !searchKey.contains($0) }) ?? " "
        let searchTextMutableString = NSMutableString(string: searchTask.messageText.lowercased())
        regxpForHtml?.replaceMatchesInString(string: searchTextMutableString, with: divideText)
        let matchCount = (searchTextMutableString as String).indicesOf(string: searchKey.lowercased()).count
        searchTask.searchRetMap[searchKey] = matchCount
        searchTaskMap[searchTask.messageID] = searchTask
    }

    func onNativeSearchDone(searchKey: String) {
        isNativeSearchDone = true
        if isJSSearchDone {
            updateSearchUI(searchKey: searchKey, searchType: MailMessageSearchViewModel.JS_SEARCH_RET_TYPE_LOADED)
        }
    }

    func updateSearchUI(searchKey: String, searchType: Int) {
        guard let searchViewModel = searchViewModel else {
            return
        }
        totalSearchRetCount = 0
        var firstMatchSearchTask: SearchTask?
        for task in searchViewModel.getOrderedSearchTasks() {
            if let count = task.searchRetMap[searchKey], count > 0 {
                if firstMatchSearchTask == nil {
                    firstMatchSearchTask = task
                }
                totalSearchRetCount += count
            }
        }

        if totalSearchRetCount > 0, let firstMatchSearchTask = firstMatchSearchTask {
            if searchType == MailMessageSearchViewModel.JS_SEARCH_RET_TYPE_LOADED {
                if firstMatchSearchTask.messageID == "mail_title" && firstMatchSearchTask.isNativeSearch {
                    // update title view ui
                    searchViewModel.delegate?.updateNativeTitleUI(searchKey: searchKey, locateIdx: 0)
                } else {
                    searchViewModel.delegate?.updateNativeTitleUI(searchKey: searchKey, locateIdx: nil)
                    searchViewModel.callJSFunction("locateSearch", params: [firstMatchSearchTask.messageID, "0", ""])
                }
            }
        }
        searchViewModel.updateSearchView()
    }

    func onJSSearchDone(searchKey: String, searchType: Int, searchRetInfo: [[String: Any]]) {
        addJSSearchRet(searchRetInfo: searchRetInfo, searchKey: searchKey)
        isJSSearchDone = true
        if isNativeSearchDone {
            updateSearchUI(searchKey: searchKey, searchType: searchType)
        }
    }

    func addJSSearchRet(searchRetInfo: [[String: Any]], searchKey: String) {
        var countInfo = [String: Int]()
        for info in searchRetInfo {
            if let msgID = info["messageId"] as? String, let count = info["count"] as? Int {
                countInfo[msgID] = count
                if let task = searchTaskMap[msgID] {
                    task.searchRetMap[searchKey] = count
                    task.isNativeSearch = false
                } else {
                    let newTask = SearchTask(msgID: msgID, isNativeSearch: false)
                    newTask.searchRetMap[searchKey] = count
                    searchTaskMap[msgID] = newTask
                }
            }
        }
        searchViewModel?.logJSSearch(countInfo: countInfo)
    }
}
