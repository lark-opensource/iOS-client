//
//  MailFeedDraftListViewModel.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/9.
//

import Foundation
import RxSwift
import RxRelay
import ThreadSafeDataStructure
import RustPB

class MailFeedDraftListViewModel {
    private let dataService = MailMessageListDataService()
    private let disposeBag = DisposeBag()
    var dataSource: [MailFeedDraftListCellViewModel] = [] // 倒序排列
    var hasMore: Bool = false
    var fetcher: DataService?
    let threadActionDataManager = ThreadActionDataManager()

    enum DataState {
        case refreshed // 刷新完成
        case loading // 加载中
        case loadMore // 加载更多
        case failed // 失败页面
        case deleteFailure // 删除失败
        case deleteSuccess(indexPath: IndexPath) // 删除成功
        case loadMoreFailure
    }
    var isLoading: Bool = false

    let feedCardID: String
    
    // MARK: Observable
    @DataManagerValue<DataState> var dataState
    @DataManagerValue<(threadId: String, labelIds: [String])> var mailThreadChange

    init(feedCardID: String) {
        self.feedCardID = feedCardID
        self.firstRefresh()
    }
    
    func firstRefresh() {
        self.$dataState.accept(.loading)
        self.loadFeedDraft(feedCardId: self.feedCardID, timestamp: 0)
    }
    
    func loadMore() {
        if let lastTimestamp = self.dataSource.last?.lastmessageTime {
            dataService.loadFeedDraft(feedCardId: self.feedCardID,
                                      timestamp: lastTimestamp)
            .subscribe { [weak self] (draftItems, hasMore) in
                guard let self = self else { return }
                self.dataSource = self.dataSource + self.draftItemsConvertToVM(draftItems: draftItems)
                self.hasMore = hasMore
                self.$dataState.accept(.loadMore)
            } onError: { [weak self] err in
                guard let self = self else { return }
                MailLogger.info("[mail_load_feedDraft] refreshData feedCardId \(self.feedCardID), timestamp \(lastTimestamp), error: \(err)")
                self.$dataState.accept(.loadMoreFailure)
            }.disposed(by: disposeBag)
        }
    }
    
    func loadFeedDraft(feedCardId: String,
                       timestamp: Int64) {
        dataService.loadFeedDraft(feedCardId: feedCardId,
                                  timestamp: timestamp)
        .subscribe { [weak self] (draftItems, hasMore) in
            guard let self = self else { return }
            self.dataSource = self.draftItemsConvertToVM(draftItems: draftItems)
            self.hasMore = hasMore
            self.$dataState.accept(.refreshed)
        } onError: { [weak self] err in
            MailLogger.info("[mail_load_feedDraft] loadFeedDraft feedCardId \(feedCardId), timestamp \(timestamp), error: \(err)")
            self?.$dataState.accept(.failed)
        }.disposed(by: disposeBag)
    }
    
    
    func deleteDraft(draftID: String, threadID: String, indexPath: IndexPath) {
        threadActionDataManager.deleteDraft(draftID: draftID, threadID: threadID, feedCardId: self.feedCardID, onSuccess: { [weak self] in
            guard let self = self else { return }
            MailLogger.info("[mail_load_feedDraft] deleteDraft succ")
            self.$dataState.accept(.deleteSuccess(indexPath: indexPath))
        }, onError: { [weak self] in
            guard let self = self else { return }
            MailLogger.info("[mail_load_feedDraft] deleteDraft failed")
            self.$dataState.accept(.deleteFailure)
        })
    }
    
    private func draftItemsConvertToVM(draftItems: [MailFeedDraftItem]) -> [MailFeedDraftListCellViewModel] {
         return draftItems.map({ MailFeedDraftListCellViewModel(with: $0)})
    }
}


