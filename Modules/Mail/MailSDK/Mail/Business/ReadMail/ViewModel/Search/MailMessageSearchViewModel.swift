//
//  MailMessageSearchViewModel.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/13.
//

import Foundation

protocol MailMessageSearchDelegate: AnyObject {
    func updateNativeTitleUI(searchKey: String?, locateIdx: Int?)
    func shouldNativeSearchTitle() -> Bool
    func getSearchMailItem() -> MailItem?
    func getItemContentFor(msgId: String) -> String
    func updateSearchView(currentIdx: Int, total: Int)
    func quitSearch()
    func callJSFunction(_ funName: String, params: [String], withThreadId threadID: String?, completionHandler: ((Any?, Error?) -> Void)?)
    func didStartInputSearch()
    func showSearchLoading(_ loading: Bool)
}

class MailMessageSearchViewModel {

    static let JS_SEARCH_RET_TYPE_LOADED = 0
    static let JS_SEARCH_RET_TYPE_UNLOAD = 1

    var mailItem: MailItem? {
        return delegate?.getSearchMailItem()
    }
    private(set) var currentSearchKeyword: String = ""

    /// 是否正在搜索
    private var isSearching = false
    var nextKeyword: String?

    weak var delegate: MailMessageSearchDelegate?
    var searchLogInfo: [String: Any]?

    private lazy var preSearchHandler = PreSearchHandler(searchViewModel: self)
    private lazy var searchInputHandler = SearchInputHandler(searchViewModel: self)
    private lazy var changeRetIndexHandler = ChangeRetIndexHandler(searchViewModel: self)
    private lazy var quitSearchHandler = QuitSearchHandler(searchViewModel: self)

    var totalSearchRetCount: Int {
        return searchInputHandler.totalSearchRetCount
    }

    /// JS回调还有几个message没有加载后----场景1：点击搜索时候(还没输入文字)就马上启动预搜索准备数据任务
    func preSearch(notLoadedMsgIDs: [String]) {
        preSearchHandler.preprocessItemContents(notLoadedMsgIDs: notLoadedMsgIDs)
    }

    func handleJSSearchStart() {
        isSearching = true
        let beginTime = MailTracker.getCurrentTime()
        searchLogInfo = ["beginTime": beginTime]
        delegate?.showSearchLoading(true)
    }

    func logJSSearch(countInfo: [String: Int]) {
        guard let beginTime = searchLogInfo?["beginTime"] as? Int else {
            MailLogger.error("MailContentSearch log beginTime not found")
            return
        }
        let timeCost = MailTracker.getCurrentTime() - beginTime
        var msgCount = 0
        var htmlCount = 0
        var totalResultCount = 0
        let mailItem = delegate?.getSearchMailItem()
        for (_, (msgID, count)) in countInfo.enumerated() {
            totalResultCount += count
            if msgID == "mail_title" {
                htmlCount += mailItem?.displaySubject.count ?? 0
            } else if let mailItem = mailItem, let msgItem = mailItem.messageItems.first(where: { $0.message.id == msgID }) {
                msgCount += 1
                htmlCount += msgItem.message.bodyHtml.count
            }
        }
        MailTracker.log(event: "mail_content_search_cost_dev", params: ["time_cost": timeCost,
                                                                        "result_count": totalResultCount,
                                                                        "html_length": htmlCount,
                                                                        "message_count": msgCount])
        searchLogInfo = nil

        // slardar
        let event = MailAPMEventSingle.ContentSearch()
        typealias Param = MailAPMEventSingle.ContentSearch.EndParam
        event.totalCostTime = TimeInterval(timeCost) / 1000.0
        event.endParams.append(Param.result_count(totalResultCount))
        event.endParams.append(Param.html_length(htmlCount))
        event.endParams.append(Param.message_count(msgCount))
        let msgIds = mailItem?.messageItems.reduce(into: "") { (result, item) in
            result += item.message.id + ";"
        } ?? ""
        event.endParams.append(Param.messageIDs(msgIds))
        event.markPostStart()
        event.postEnd()
    }

    /// 场景2：输入文字完成后，真正进行关键字搜索
    func startSearch(keyword: String?) {
        guard currentSearchKeyword != keyword else {
            MailLogger.info("MailContentSearch keyword same as current, skip")
            return
        }
        guard !isSearching else {
            //正在搜索中，不进行搜索，只需要记录关键字
            nextKeyword = keyword
            MailLogger.info("MailContentSearch isSearching, mark keyword for next")
            if currentSearchKeyword.isEmpty {
                //关闭搜索的时候上次残留的搜索，补上loading
                delegate?.showSearchLoading(true)
            }
            return
        }
        guard let mailItem = mailItem else { return }
        if let keyword = keyword {
            MailLogger.info("MailContentSearch startinput keyword count: \(keyword.count)")
        } else {
            MailLogger.info("MailContentSearch startinput keyword nil")
        }
        isSearching = true
        nextKeyword = nil
        // showLoading
        delegate?.didStartInputSearch()

        searchInputHandler.reset()
        let notJSSearchedMsgIDs = preSearchHandler.endPreSearch(searchTaskMap: &searchInputHandler.searchTaskMap,
                                                                messageItems: mailItem.messageItems)
        preSearchHandler.reset()
        currentSearchKeyword = keyword ?? ""

        // 获取没有
        for id in notJSSearchedMsgIDs {
            if let task = searchInputHandler.searchTaskMap[id] {
                if id == "mail_title" {
                    task.messageText = mailItem.oldestSubject
                } else if let messageItem = mailItem.messageItems.first(where: { $0.message.id == id }) {
                    task.messageText = preSearchHandler.getMessageText(bodyHtml: messageItem.message.bodyHtml)
                }
            }
        }

        var searchTaskList = [SearchTask]()
        for (_, task) in searchInputHandler.searchTaskMap where task.isNativeSearch {
            searchTaskList.append(task)
        }

        // 去掉有缓存的
        searchTaskList.removeAll(where: { $0.searchRetMap.contains(where: { $0.key == currentSearchKeyword }) })

        for task in searchTaskList {
            searchInputHandler.doSearch(searchTask: task, searchKey: currentSearchKeyword)
        }
        searchInputHandler.onNativeSearchDone(searchKey: currentSearchKeyword)

        // start js search
        callJSFunction("search", params: [(keyword ?? "").cleanEscapeCharacter()])
    }

    /**
     * 场景3：切换上下个搜索结果
     * indexDis: 负数为向上查找，正数为向下查找
     */
    func changeSearchRetIndex(indexDis: Int) {
        changeRetIndexHandler.doChangeIndex(indexDis)
    }

    /**
     * 场景4：退出搜索
     */
    func quitSearch() {
        currentSearchKeyword = ""
        delegate?.quitSearch()
        quitSearchHandler.closedSearch()
        preSearchHandler.closeSearch()
        searchInputHandler.closeSearch()
        changeRetIndexHandler.closeSearch()
    }

    func getOrderedSearchTasks() -> [SearchTask] {
        var tasks = [SearchTask]()
        if let titleTask = searchInputHandler.searchTaskMap["mail_title"] {
            tasks.append(titleTask)
        }

        guard let mailItem = mailItem else {
            return tasks
        }
        var taskContent = [SearchTask]()
        taskContent.append(contentsOf: mailItem.messageItems.compactMap({ (messageItem) -> SearchTask? in
            guard let task = searchInputHandler.searchTaskMap[messageItem.message.id] else {
                return nil
            }
            return task
        }))
        if let mailAccount = Store.settingData.getCachedCurrentAccount(), mailAccount.mailSetting.mobileMessageDisplayRankMode {
        //mobileMessageDisplayRankMode为true表示最新邮件展示在顶部, 此时顺序需要反转
            taskContent.reverse()
        }
        tasks += taskContent
        return tasks
    }

    func onJSSearchDone(searchKey: String, searchType: Int, idx: Int, resultInfo: [[String: Any]]) {
        if let nextKeyword = nextKeyword {
            MailLogger.info("MailContentSearch searchKey not match current")
            // 有nextKeyword，不结束搜索，最后搜索结束再更新UI
            isSearching = false
            startSearch(keyword: nextKeyword)
        } else if isSearching && searchKey == currentSearchKeyword {
            MailLogger.info("MailContentSearch handle jsSearchDone")
            switch searchType {
            case MailMessageSearchViewModel.JS_SEARCH_RET_TYPE_LOADED:
                changeRetIndexHandler.reset()
                searchInputHandler.onJSSearchDone(searchKey: searchKey, searchType: searchType, searchRetInfo: resultInfo)
            case MailMessageSearchViewModel.JS_SEARCH_RET_TYPE_UNLOAD:
                // 纠正数目
                searchInputHandler.onJSSearchDone(searchKey: searchKey, searchType: searchType, searchRetInfo: resultInfo)
                changeRetIndexHandler.onJSSearchDone(idx: idx, searchRetInfo: resultInfo)
            default:
                break
            }
        } else {
            isSearching = false
            MailLogger.error("MailContentSearch isSearch \(isSearching), keyword match \(searchKey == currentSearchKeyword)")
        }
    }

    func getItemContentFor(msgId: String) -> String {
        return delegate?.getItemContentFor(msgId: msgId) ?? ""
    }

    func sendPatchItemContentsToJS(count: Int = 5) {
        guard let paramString = getPatchItemContentsJsonString() else {
            return
        }
        callJSFunction("addItemContent", params: [paramString])
    }

    /// 准备 addItemContent 的JSON数据
    private func getPatchItemContentsJsonString(count: Int = 5) -> String? {
        var params = [String: String]()
        for _ in 0..<count {
            if let first = preSearchHandler.readyItemContents.first {
                preSearchHandler.readyItemContents.removeFirst()
                params[first.msgId] = first.itemContent
            } else {
                break
            }
        }
        if params.count > 0,
           let data = try? JSONSerialization.data(withJSONObject: params, options: []),
           let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
            return JSONString
        } else {
            return nil
        }
    }

    func callJSFunction(_ funName: String, params: [String]? = nil, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        delegate?.callJSFunction(funName, params: params ?? [], withThreadId: mailItem?.threadId, completionHandler: completionHandler)
    }

    func updateSearchView() {
        delegate?.updateSearchView(currentIdx: changeRetIndexHandler.currentRetIndex, total: totalSearchRetCount)
        isSearching = false
        // try do next search
        if let nextKeyword = nextKeyword {
            startSearch(keyword: nextKeyword)
        }
    }
}
