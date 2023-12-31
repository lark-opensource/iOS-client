//
//  ChangeRetIndexHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/13.
//

import Foundation
import RxSwift
import LarkKeyboardKit

/**
 * 场景3：上下切换搜索结果的处理
 * 技术文档：https://bytedance.feishu.cn/wiki/wikcnsrBau9PMm8wSRCSteS35pb#
 */
final class ChangeRetIndexHandler {

    // 最短切换上下个的间隔时间，低于此值的忽略掉传递数据
    private let MIN_NEXT_TIME_FRAME = 100
    private var lastChangeTime: TimeInterval?
    private(set) var currentRetIndex = 0
    private(set) var currentRetMsgIdx: (msgID: String?, idx: Int)?
    private weak var searchViewModel: MailMessageSearchViewModel?
    private var isKeyboardShown = false
    private var shouldWaitForKeyboardDismiss = false
    private let disposeBag = DisposeBag()

    init(searchViewModel: MailMessageSearchViewModel) {
        self.searchViewModel = searchViewModel
        self.listenKeyboard()
    }

    func reset() {
        lastChangeTime = nil
        currentRetMsgIdx = nil
        currentRetIndex = 0
        currentRetMsgIdx = nil
    }

    func closeSearch() {
        reset()
    }

    func doChangeIndex(_ index: Int) {
        MailLogger.info("ContentSearch doChangeIndex")
        if lastChangeTime == nil {
            // 第一次点击，就等待 MIN_NEXT_TIME_FRAME 后再看是否发出传输数据
            lastChangeTime = Date().timeIntervalSince1970
        }

        currentRetIndex = max(min(currentRetIndex + index, (searchViewModel?.totalSearchRetCount ?? 1) - 1), 0)
        if isKeyboardShown {
            shouldWaitForKeyboardDismiss = true
        } else {
            toJsStartChangeIndex()
            searchViewModel?.updateSearchView()
        }
    }

    func listenKeyboard() {
        KeyboardKit.shared.keyboardEventChange.subscribe { [weak self] event in
            guard let self = self, let type = event.element?.type else { return }
            switch type {
            case .didShow:
                self.isKeyboardShown = true
            case .didHide:
                self.isKeyboardShown = false
                guard self.shouldWaitForKeyboardDismiss else { return }
                self.shouldWaitForKeyboardDismiss = false
                self.toJsStartChangeIndex()
                self.searchViewModel?.updateSearchView()
            default: break
            }
        }.disposed(by: disposeBag)
    }

    func onJSSearchDone(idx: Int, searchRetInfo: [[String: Any]]) {
        MailLogger.info("ContentSearch onJSSearchDone \(searchRetInfo)")
        var changedMsgId: String?
        if let messageItems = searchViewModel?.mailItem?.messageItems, messageItems.count > 1 {
            changedMsgId = searchRetInfo.first?["messageId"] as? String
        }
        toJsStartChangeIndex(changedMsgId: changedMsgId)
    }

    func toJsStartChangeIndex(changedMsgId: String? = nil) {
        guard let searchViewModel = searchViewModel else {
            return
        }
        // 如果是JS刷新搜索导致的变更，不定位到最新位置
        var needLocateSearch = true
        if let changedMsgId = changedMsgId {
            needLocateSearch = false
            // 如果是部分JS刷新导致的变更，根据维持在 currentRetMsgId
            // 如果变动的是当前msg或之后的msg，维持idx
            let orderedSearchTask = searchViewModel.getOrderedSearchTasks()
            if let currentRetIdxInMsg = currentRetMsgIdx?.idx, let retMsgId = currentRetMsgIdx?.msgID {
                if let retMsgOrder = orderedSearchTask.firstIndex(where: { $0.messageID == retMsgId }), let changeMsgOrder = orderedSearchTask.firstIndex(where: { $0.messageID == changedMsgId }) {
                    // 如果变动的是之前或当前的msg，更新currentRetIndex，维持在当前msg
                    if changeMsgOrder <= retMsgOrder {
                        var totalIndex = 0
                        for searchTask in searchViewModel.getOrderedSearchTasks() {
                            if searchTask.messageID == retMsgId {
                                let count = searchTask.searchRetMap[searchViewModel.currentSearchKeyword] ?? 0
                                currentRetIndex = min(totalIndex + currentRetIdxInMsg, totalIndex + count - 1)
                                searchViewModel.delegate?.updateSearchView(currentIdx: currentRetIndex, total: searchViewModel.totalSearchRetCount)
                                break
                            } else if let count = searchTask.searchRetMap[searchViewModel.currentSearchKeyword] {
                                totalIndex += count
                            }
                        }
                    }
                }

            }
        }

        var msgID = ""
        var msgRetIndex = 0
        var totalAddIndex = 0
        var totalLastAddIndex = 0
        var isTitleNativeSearch = false
        // 通过 currentRetIndex 和 总结果，计算出 msg 纬度的 idx 和 对应msgID 进行 JS 调用
        for searchTask in searchViewModel.getOrderedSearchTasks() {
            let searchRetMap = searchTask.searchRetMap
            totalLastAddIndex = totalAddIndex
            if let count = searchRetMap[searchViewModel.currentSearchKeyword] {
                totalAddIndex += count
            }
            if totalAddIndex - 1 >= currentRetIndex {
                if searchTask.messageID == "mail_title" {
                    isTitleNativeSearch = searchTask.isNativeSearch
                }
                msgID = searchTask.messageID
                msgRetIndex = currentRetIndex - totalLastAddIndex
                break
            }
        }
        MailLogger.log(level: .debug, message: "testSearchABC toJsStartChangeIndex msgID:\(msgID)  msgRetIndex:\(msgRetIndex)")
        if !msgID.isEmpty {
            let titleSearchKey = searchViewModel.currentSearchKeyword
            var titleLocateIdx: Int?
            titleLocateIdx = (isTitleNativeSearch && msgID == "mail_title") ? msgRetIndex : nil
            searchViewModel.delegate?.updateNativeTitleUI(searchKey: titleSearchKey, locateIdx: titleLocateIdx)
            if needLocateSearch {
                currentRetMsgIdx = (msgID, msgRetIndex)
                searchViewModel.callJSFunction("locateSearch", params: [msgID, "\(msgRetIndex)", ""])
            }
        }
    }
}
