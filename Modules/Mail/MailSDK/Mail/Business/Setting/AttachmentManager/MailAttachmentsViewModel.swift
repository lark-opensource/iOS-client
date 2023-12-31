//
//  MailAttachmentsViewModel.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/24.
//

import Foundation
import LarkSwipeCellKit
import ServerPB
import RxSwift
import UniverseDesignToast

class MailAttachmentsViewModel {
    private(set) var dataSource: [MailAttachmentsListCellViewModel] = []
    // 文件总数
    private(set) var fileTotal: Int32 = 0
    // 文件总量
    private(set) var capacity: Int64 = 0
    var hasMore: Bool = false
    // 排序方式 默认创建时间
    var orderFiled: MailOrderFiled = .createdTime
    // 排序顺序 默认从新到旧
    var orderType: MailOrderType = .desc
    private(set) var nextSessionId: String = String(0)
    static let pageSize: Int64 = 20
    var transferFolderKey: String = ""
    private let disposeBag = DisposeBag()
    let accountID: String
    enum DataState {
        case firstRefresh // 首次刷新完成
        case refreshed // 刷新完成
        case loading // 加载中
        case loadMore // 加载更多
        case empty // 空页面
        case failed // 失败页面
        case multiDelete // 多项删除
        case delete(indexPath: IndexPath) // 删除数据
        case loadMoreFailure
        case deleteFailed // 多项删除&删除数据
    }
    
    var isLoading: Bool = false
    
    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }
    
    func syncDataSource(datas: [MailAttachmentsListCellViewModel]) {
        dataSource = datas
    }
    
    // MARK: Observable
    @DataManagerValue<DataState> var dataState
    
    init(transferFolderKey: String, accountID: String) {
        self.accountID = accountID
        self.transferFolderKey = transferFolderKey
    }
    
    // 首次进入页面刷新
    func firstRefresh() {
        self.$dataState.accept(.loading)
        self.refreshData(orderFiled: self.orderFiled, orderType: self.orderType, sessionId: String(0), transferFolderKey: self.transferFolderKey)
    }
    
    // 下拉刷新
    func pullRefresh() {
        self.refreshData(orderFiled: self.orderFiled, orderType: self.orderType, sessionId: String(0), transferFolderKey: self.transferFolderKey)
    }
    // 上拉加载更多
    func loadMore() {
        fetcher?.listLargeAttachmentRequest(self.orderFiled, orderType:self.orderType, sessionId:self.nextSessionId, transferFolderKey:self.transferFolderKey, accountID: self.accountID).subscribe { [weak self] resp in
            guard let `self` = self else { return }
            self.dataSource = self.dataSource + self.pbConvertToDataSource(attachmentInfo: resp.infoList)
            self.fileTotal = resp.total >= 0 ? resp.total : 0
            self.capacity = resp.capacity >= 0 ? resp.capacity : 0
            self.nextSessionId = resp.nextSessionID
            self.hasMore = resp.hasMore_p
            self.$dataState.accept(.loadMore)
        } onError: { [weak self] err in
            MailLogger.info("[attachment_large] load_more err \(err)")
            self?.$dataState.accept(.loadMoreFailure)
        }.disposed(by: self.disposeBag)
    }
    
    func refreshData(orderFiled:MailOrderFiled, orderType:MailOrderType, sessionId:String, transferFolderKey:String) {
        fetcher?.listLargeAttachmentRequest(orderFiled, orderType:orderType, sessionId:sessionId, transferFolderKey:transferFolderKey, accountID: self.accountID).subscribe { [weak self] resp in
            guard let `self` = self else { return }
            self.dataSource = self.pbConvertToDataSource(attachmentInfo: resp.infoList)
            self.fileTotal = resp.total >= 0 ? resp.total : 0
            self.capacity = resp.capacity >= 0 ? resp.capacity : 0
            self.nextSessionId = resp.nextSessionID
            self.hasMore = resp.hasMore_p
            if self.fileTotal > 0 {
                self.$dataState.accept(.refreshed)
            } else {
                self.$dataState.accept(.empty)
            }
        } onError: { [weak self] err in
            MailLogger.info("[attachment_large] refreshData err \(err), orderType \(orderFiled), orderType \(orderType), sessionId \(sessionId)")
            self?.$dataState.accept(.failed)
        }.disposed(by: self.disposeBag)
    }
    func multiDeleteData(deleteList:Dictionary<Int64, String>) {
        let deleteValues: [String] = deleteList.values.map({$0})
        MailLogger.debug("[attachment_large] multi_deleteData")
        fetcher?.deleteLargeAttachmentRequest(deleteValues, isDraftDelete: false, meessageBizID: "").subscribe { [weak self] resp in
            guard let `self` = self else { return }
            self.capacity = resp.capacity >= 0 ? resp.capacity : 0
            self.fileTotal = resp.total
            self.dataSource = self.dataSource.filter( {!deleteValues.contains($0.fileToken ?? "")})
            self.$dataState.accept(.multiDelete)
        } onError: { [weak self] err in
            // 删除失败 请稍后再试弹窗
            MailLogger.debug("[attachment_large] multi_deleteData err \(err)")
            self?.$dataState.accept(.deleteFailed)
        }.disposed(by: self.disposeBag)
    }
    
    func deleteData(deleteList:Dictionary<Int64, String>, indexPath: IndexPath) {
        let deleteValues = deleteList.values.map({$0})
        MailLogger.debug("[attachment_large] deleteData")
        fetcher?.deleteLargeAttachmentRequest(deleteValues, isDraftDelete: false, meessageBizID: "").subscribe { [weak self] resp in
            guard let `self` = self else { return }
            self.fileTotal = resp.total
            self.capacity = resp.capacity >= 0 ? resp.capacity : 0
            self.dataSource = self.dataSource.filter( {!deleteValues.contains($0.fileToken ?? "")})
            self.$dataState.accept(.delete(indexPath: indexPath))
        } onError: { [weak self] err in
            // 删除失败 请稍后再试弹窗
            MailLogger.debug("[attachment_large] deleteData err \(err)")
            self?.$dataState.accept(.deleteFailed)
        }.disposed(by: self.disposeBag)
    }
    
    func pbConvertToDataSource(attachmentInfo:[MailLargeAttachmentInfo]) -> [MailAttachmentsListCellViewModel] {
        var data: [MailAttachmentsListCellViewModel] = []
        for attachment in attachmentInfo {
            let cellVM = MailAttachmentsListCellViewModel(with: attachment)
            data.append(cellVM)
        }
        return data
    }
}
