//
//  MyAIToolsViewModel.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/22.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxRelay
import LarkMessengerInterface
import LarkContainer
import LarkStorage

final class MyAIToolsViewModel {

    private let disposeBag = DisposeBag()
    struct Cursor {
        var value: Int = 0
        var isEnd = false
    }
    var pageCount = 20
    private(set) var toolsCursor = Cursor()
    private(set) var toolsSearchCursor = Cursor()
    var myAIToolRustService: RustMyAIToolServiceAPI?
    var userResolver: UserResolver

    /// tools 状态回调
    var status = PublishSubject<MyAIToolsStatus>()
    var singleSelectSubject = PublishSubject<Bool>()
    /// tools数据回调
    lazy var toolsObservable: Observable<[MyAIToolInfo]> = self.toolsVariable.asObservable()
    private let toolsVariable = BehaviorRelay<[MyAIToolInfo]>(value: [])

    /// tools搜索数据回调
    lazy var toolsSearchObservable: Observable<[MyAIToolInfo]> = self.toolsSearchVariable.asObservable()
    private let toolsSearchVariable = BehaviorRelay<[MyAIToolInfo]>(value: [])

    var selectToolsSubject = ReplaySubject<[MyAIToolInfo]>.create(bufferSize: 1)
    /// 当前最新的tools状态，默认empty
    private var latestToolsStatus: MyAIToolsStatus = .empty

    private(set) var selectedToolsInfo: [MyAIToolInfo] = []
    private var selectedToolsCache: [String: Int] = [:]
    var selectedToolIds: [String] {
        return selectedToolsInfo.map { $0.toolId }
    }
    private(set) var isSingleSelect: Bool = true
    private(set) var isShowToolAlertPrompt: Bool = true

    private var context: MyAIToolsContext
    weak var toolsVc: MyAIToolsViewController?

    var serverMaxCount: Int?
    var maxSelectCount: Int {
        guard let maxCount = context.maxSelectCount else {
            return serverMaxCount ?? 1
        }
        return maxCount
    }

    private static var unrestrictedTagInt: Int = 0
    private static var selectedToolsCacheTagValue: Int = 1
    public var userID: String { return self.userResolver.userID }
    private lazy var userStore = KVStores.MyAITool.build(forUser: self.userID)

    init(context: MyAIToolsContext,
         userResolver: UserResolver,
         myAIToolRustService: RustMyAIToolServiceAPI?) {
        self.context = context
        self.userResolver = userResolver
        self.myAIToolRustService = myAIToolRustService
        if !context.selectedToolIds.isEmpty {
            for toolId in context.selectedToolIds {
                selectedToolsInfo.append(MyAIToolInfo(toolId: toolId, toolName: "", toolAvatar: "", toolDesc: ""))
                self.selectedToolsCache[toolId] = Self.selectedToolsCacheTagValue
            }
            replenishSelectedToolsInfo()
        }
        selectToolsSubject.onNext(selectedToolsInfo)
    }

    func toggleItemSelected(item: MyAIToolInfo) {
        guard checkIsSelected(item),
              !item.toolId.isEmpty,
                let toolsVc = self.toolsVc else { return }

        if let row = toolsVc.tools.firstIndex(where: { $0.toolId == item.toolId }) {
            toolsVc.tools[row].isSelected.toggle()
        }
        if !toolsVc.searchTools.isEmpty,
            let row = toolsVc.searchTools.firstIndex(where: { $0.toolId == item.toolId }) {
            toolsVc.searchTools[row].isSelected.toggle()
        }

        let isSelected = selectedToolsCache[item.toolId] != nil
        if isSelected {
            selectedToolsInfo.removeAll(where: { $0.toolId == item.toolId })
            selectedToolsCache.removeValue(forKey: item.toolId)
        } else {
            selectedToolsInfo.append(item)
            selectedToolsCache[item.toolId] = Self.selectedToolsCacheTagValue
        }

        if maxSelectCount != Self.unrestrictedTagInt,
            selectedToolIds.count >= maxSelectCount {
            for (index, item) in toolsVc.tools.enumerated() {
                selectedToolsCache[item.toolId] != nil ? (toolsVc.tools[index].enabled = true) : (toolsVc.tools[index].enabled = false)
            }
            if !toolsVc.searchTools.isEmpty {
                for (index, item) in toolsVc.searchTools.enumerated() {
                    selectedToolsCache[item.toolId] != nil ? (toolsVc.searchTools[index].enabled = true) : (toolsVc.searchTools[index].enabled = false)
                }
            }
        } else {
            for index in toolsVc.tools.indices {
                toolsVc.tools[index].enabled = true
            }
            if !toolsVc.searchTools.isEmpty {
                for index in toolsVc.searchTools.indices {
                    toolsVc.searchTools[index].enabled = true
                }
            }
        }
        selectToolsSubject.onNext(selectedToolsInfo)
        status.onNext(MyAIToolsStatus.reload)
    }

    func multipleItemSelected(item: MyAIToolInfo) {
        selectedToolsInfo.removeAll()
        selectedToolsInfo.append(item)
    }

    func processToolsData() {
        guard let toolsVc = self.toolsVc else { return }
        for (index, item) in toolsVc.tools.enumerated() {
            selectedToolsCache[item.toolId] != nil ? (toolsVc.tools[index].isSelected = true) : (toolsVc.tools[index].isSelected = false)
            if maxSelectCount != Self.unrestrictedTagInt,
               selectedToolIds.count >= maxSelectCount {
                selectedToolsCache[item.toolId] != nil ? (toolsVc.tools[index].enabled = true) : (toolsVc.tools[index].enabled = false)
            }
        }
    }

    func processSearchToolsData() {
        guard let toolsVc = self.toolsVc else { return }
        for (index, item) in toolsVc.searchTools.enumerated() {
            selectedToolsCache[item.toolId] != nil ? (toolsVc.searchTools[index].isSelected = true) : (toolsVc.searchTools[index].isSelected = false)
            if maxSelectCount != Self.unrestrictedTagInt,
               selectedToolIds.count >= maxSelectCount {
                selectedToolsCache[item.toolId] != nil ? (toolsVc.searchTools[index].enabled = true) : (toolsVc.searchTools[index].enabled = false)
            }
        }
    }

    func checkIsSelected(_ item: MyAIToolInfo) -> Bool {
        let isSelected = selectedToolsCache[item.toolId] != nil
        if !isSelected,
           maxSelectCount != Self.unrestrictedTagInt,
            selectedToolIds.count >= maxSelectCount {
            return false
        }
        return true
    }

    /// 校验是否改变了tool选择
    func checkIsChangeSelect(_ newTools: [MyAIToolInfo]) -> Bool {
//        let newToolIds = newTools.map { $0.toolId }
//        return context.selectedToolIds.sorted() != newToolIds.sorted()
        return true //视觉走查结论说没有改变也可以重新提交，先保留校验逻辑，后面可能还会变回来(灬ꈍ ꈍ灬)
    }

    func firstLoadToolsData() {
        guard let myAIToolRustService = self.myAIToolRustService else {
            return
        }
        self.status.onNext(.loading)
        let toolConfigObservable: Observable<MyAIToolConfig> = myAIToolRustService.getMyAIToolConfig()
        let toolListObservable: Observable<([MyAIToolInfo], Bool)> = myAIToolRustService.getMyAIToolList("", pageNum: self.toolsCursor.value, pageSize: pageCount, self.context.scenario)

        Observable.zip(toolConfigObservable, toolListObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (config, toolRes) in
                guard let self = self else { return }
                let (toolList, hasMore) = toolRes
                MyAIToolsViewController.logger.info("first load myAITools success count:\(toolList.count) maxNum: \(config.maxSelectNum) hasNotic: \(config.isFirstUseTool)")
                self.isSingleSelect = config.maxSelectNum == 1 ? true : false
                self.userStore[KVKeys.MyAITool.myAIModelType] = self.isSingleSelect
                self.isShowToolAlertPrompt = config.isFirstUseTool
                self.singleSelectSubject.onNext(self.isSingleSelect)
                self.serverMaxCount = config.maxSelectNum
                if toolList.isEmpty {
                    self.status.onNext(.empty)
                    self.latestToolsStatus = .empty
                } else {
                    var temp = self.toolsVariable.value
                    temp.append(contentsOf: toolList)
                    self.toolsCursor.isEnd = !hasMore
                    self.toolsVariable.accept(temp)
                    self.toolsCursor.value += 1
                    let status: MyAIToolsStatus = !hasMore ? .loadComplete : .loadMore
                    self.status.onNext(status)
                    self.latestToolsStatus = status
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                MyAIToolsViewController.logger.info("first load tools failure error:\(error)")
                self.status.onNext(.retry)
                self.latestToolsStatus = .retry
            }).disposed(by: disposeBag)
    }

    func loadMoreToolsData() -> Observable<Bool> {
        return myAIToolRustService?.getMyAIToolList("", pageNum: self.toolsCursor.value, pageSize: pageCount, self.context.scenario).map { [weak self] res -> Bool in
            guard let self = self else { return true }
            let (toolList, hasMore) = res
            var temp = self.toolsVariable.value
            temp.append(contentsOf: toolList)
            self.toolsCursor.isEnd = !hasMore
            self.toolsVariable.accept(temp)
            self.toolsCursor.value += 1
            let status: MyAIToolsStatus = !hasMore ? .loadComplete : .loadMore
            self.status.onNext(status)
            self.latestToolsStatus = status
            return !hasMore
        }.do(onError: { [weak self] (error) in
            guard let self = self else { return }
            self.status.onNext(.fail(.requestError(error)))
        }) ?? Observable.just(true)
    }

    /// 补充已选tools信息，外界拉取面板传入的toolId,需要完善tool信息 (tool列表有分页，为了统一逻辑，直接拉取完善Tool信息)
    func replenishSelectedToolsInfo() {
        let replenishToolIds = selectedToolsInfo.filter { $0.toolName.isEmpty }.map { $0.toolId }
        myAIToolRustService?.getMyAIToolsInfo(toolIds: replenishToolIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tools) in
                guard let self = self else { return }
                MyAIToolsViewController.logger.info("replenish selectedToolsInfo success")
                self.selectedToolsInfo = tools
                self.selectToolsSubject.onNext(self.selectedToolsInfo)
            }, onError: { (error) in
                MyAIToolsViewController.logger.info("replenish selectedToolsInfo failure error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    /// tools搜索
    func firstSearchToolsData(by kewWord: String) -> Observable<Void> {
        self.status.onNext(.searching)
        return myAIToolRustService?.getMyAIToolList(kewWord, pageNum: self.toolsSearchCursor.value, pageSize: pageCount, self.context.scenario).map { [weak self] res in
            guard let self = self else { return }
            let (toolList, hasMore) = res
            MyAIToolsViewController.logger.info("first search myAITools success count:\(toolList.count)")
            if toolList.isEmpty {
                self.status.onNext(.noSearchResult)
            } else {
                var temp = self.toolsSearchVariable.value
                temp.append(contentsOf: toolList)
                self.toolsSearchCursor.isEnd = !hasMore
                self.toolsSearchVariable.accept(temp)
                self.toolsSearchCursor.value += 1
                let status: MyAIToolsStatus = !hasMore ? .searchComplete : .searchMore
                self.status.onNext(status)
            }
        }.do(onError: { [weak self] (error) in
            guard let self = self else { return }
            MyAIToolsViewController.logger.info("search myAITools failure error: \(error)")
            self.status.onNext(.retry)
        }) ?? Observable.just(Void())
    }

    func searchMoreToolsData(by kewWord: String) -> Observable<Bool> {
        return myAIToolRustService?.getMyAIToolList(kewWord, pageNum: self.toolsSearchCursor.value, pageSize: pageCount, self.context.scenario).map { [weak self] res -> Bool in
            guard let self = self else { return true }
            let (toolList, hasMore) = res
            var temp = self.toolsSearchVariable.value
            temp.append(contentsOf: toolList)
            self.toolsSearchCursor.isEnd = !hasMore
            self.toolsSearchVariable.accept(temp)
            self.toolsSearchCursor.value += 1
            let status: MyAIToolsStatus = !hasMore ? .searchComplete : .searchMore
            self.status.onNext(status)
            return !hasMore
        }.do(onError: { [weak self] (error) in
            guard let self = self else { return }
            MyAIToolsViewController.logger.info("search more myAITools failure error: \(error)")
            self.status.onNext(.fail(.searchError(error)))
        }) ?? Observable.just(true)
    }

    /// 重置搜索 Cursor
    func resetSearchCursor() {
        self.toolsSearchCursor.value = 0
        self.toolsSearchVariable.accept([])
        self.toolsSearchCursor.isEnd = false
    }

    /// 清除tools搜索
    func clearSearchToolsData() {
        self.toolsSearchVariable.accept([])
        self.status.onNext(self.latestToolsStatus)
    }

    func teaEventParams(isClick: Bool) -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        params["msg_id"] = context.extra["messageId"] ?? ""
        params["chat_id"] = context.extra["chatId"] ?? ""
        params["source"] = context.extra["source"] ?? ""
        params["type"] = "addExtension"
        if isClick {
            params["tool_id"] = selectedToolIds
        }
        if context.myAIPageService?.chatMode ?? false {
            params["app_name"] = context.myAIPageService?.chatModeConfig.extra["app_name"] ?? "other"
        } else {
            params["app_name"] = "other"
        }
        return params
    }

    func getMessageId() -> String {
        return (context.extra["messageId"] as? String) ?? ""
    }
}

public enum MyAIToolsStatus {
    case fail(MyAIToolsError)
    case retry
    case loading
    case loadMore
    case loadComplete
    case reload
    case empty
    case searching
    case searchMore
    case searchComplete
    case noSearchResult
}

public enum MyAIToolsError: Error {
    case searchError(Error)
    case requestError(Error)
}
