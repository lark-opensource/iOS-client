//
//  GroupShareHistoryViewModel.swift
//  Action
//
//  Created by kongkaikai on 2019/7/23.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import LarkModel
import LKCommonsLogging
import LarkSDKInterface
import RustPB
import LarkContainer

final class GroupShareHistoryViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(
        GroupShareHistoryViewModel.self,
        category: "LarkChat.GroupShareHistoryViewModel")

    private let disposeBag = DisposeBag()

    let chatID: String

    private var datas: [GroupShareHistoryListItem] = []
    private var _dataSource = PublishSubject<Result<[GroupShareHistoryListItem], Error>>()
    var dataSource: Driver<Result<[GroupShareHistoryListItem], Error>> {
        return _dataSource.asDriver(onErrorJustReturn: .success(self.datas))
    }

    private let chatAPI: ChatAPI
    private var pageCount: Int32 = 40 // 分页数据大小
    private let isThreadGroup: Bool
    var hasMore: Bool = false // 是否还有更多
    private var cursor: String? = "0" // 下一页指针

    init(chatID: String, chatAPI: ChatAPI, isThreadGroup: Bool, userResolver: UserResolver) {
        self.chatID = chatID
        self.chatAPI = chatAPI
        self.isThreadGroup = isThreadGroup
        self.userResolver = userResolver
    }

    /// 拉取数据
    func loadData() {
        let chatID = self.chatID
        self.chatAPI.getGroupShareHistory(chatID: chatID, cursor: cursor, count: pageCount)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.cursor = result.nextCursor
                self.hasMore = result.hasMore_p
                let isTopicGroup = self.isThreadGroup
                self.datas += result.shareHistory.map { $0.item(isTopicGroup: isTopicGroup) }
                self._dataSource.onNext(.success(self.datas))

                GroupShareHistoryViewModel.logger.info(
                    "fetch group share history result",
                    additionalData: [
                        "chatID": chatID,
                        "count": "\(result.shareHistory.count)",
                        "cursor": "\(result.nextCursor)",
                        "hasMore": "\(result.hasMore_p)"
                ])
            }, onError: { [weak self] (error) in
                GroupShareHistoryViewModel.logger.error(
                    "fetch group share history error",
                    additionalData: [
                        "chatID": chatID,
                        "cursor": "\(self?.cursor ?? "null")"
                    ],
                    error: error)
                self?._dataSource.onNext(.failure(error))
            }).disposed(by: disposeBag)
    }

    // disable 掉某些分享
    func disableShare(with shareIDs: [String]) {
        ChatSettingTracker.invalidateGroupShareHistory()
        var disableTokens = [String]()
        func refreshDatas(_ isVailed: Bool) {
            for index in 0..<datas.count {
                if shareIDs.contains(datas[index].id) {
                    datas[index].isVailed = false
                    disableTokens.append(datas[index].token)
                }
            }

            _dataSource.onNext(.success(datas))
        }

        // 先刷新UI
        refreshDatas(false)

        let chatID = self.chatID

        self.chatAPI.updateGroupShareHistory(tokens: disableTokens, status: .deactived)
            .subscribe(onNext: { _ in
            }, onError: { (error) in
                GroupShareHistoryViewModel.logger.error(
                    "update group share history status error",
                    additionalData: ["chatID": chatID],
                    error: error)
                // 失败则回刷
                refreshDatas(true)
            }).disposed(by: disposeBag)
    }

    func emptyDataContent() -> String {
        return self.isThreadGroup ? BundleI18n.LarkChatSetting.Lark_Groups_ShareHistoryEmpty : BundleI18n.LarkChatSetting.Lark_Group_SharingHistoryBlankPage
    }
}
