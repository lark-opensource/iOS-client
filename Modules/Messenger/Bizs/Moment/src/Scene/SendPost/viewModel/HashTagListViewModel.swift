//
//  HashTagListViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/7/2.
//

import Foundation
import UIKit
import ServerPB
import LarkContainer
import RxSwift
import LKCommonsLogging

final class HashTagItem {
    var content: String
    var desText: String
    var isUserCreate: Bool
    init(content: String,
         desText: String,
         isUserCreate: Bool) {
        self.content = content
        self.desText = desText
        self.isUserCreate = isUserCreate
    }
}

final class HashTagListViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(HashTagListViewModel.self, category: "Module.Moments.HashTagListViewModel")
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy var hashTagApi: HashTagApiService?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?
    let updateHashTagListCallBack: ((RawData.HashTagResponse) -> Void)?
    var refreshFirstRow: ((Bool) -> Void)?
    /// 表示每一次请求,区分一些请求是否可以丢弃
    var lastRequestIdx: Int = 0
    var requestIdx: Int = 0
    var hashTagItems: [HashTagItem] = []
    init(userResolver: UserResolver, updateHashTagListCallBack: ((RawData.HashTagResponse) -> Void)?) {
        self.userResolver = userResolver
        self.updateHashTagListCallBack = updateHashTagListCallBack
        let userInputItem = HashTagItem(content: "", desText: "", isUserCreate: true)
        hashTagItems.append(userInputItem)
    }
    func updateUserInput(_ input: String) {
        if let firstItem = hashTagItems.first, firstItem.isUserCreate {
            firstItem.content = input
            firstItem.desText = ""
            refreshFirstRow?(input.isEmpty)
        }
        requestIdx += 1
        let idx = requestIdx
        hashTagApi?.hashTagListForInput(input)
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (responseData) in
                guard let self = self, idx > self.lastRequestIdx else { return }
                self.lastRequestIdx = idx
                self.mapToHashTagItemsForResponse((responseData.0, responseData.1))
                self.updateHashTagListCallBack?(responseData.0)
            }, onError: { [weak self] (error) in
                guard let self = self, idx > self.lastRequestIdx else { return }
                self.lastRequestIdx = idx
                /// 如果网络错误 需要将输入的话题展示位新话题
                self.onErrorToDisplayIntput(input)
                Self.logger.error("getHashtag list hashTagListForInput error -- \(error)")
                self.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: nil)
            }).disposed(by: disposeBag)
    }

    func updateData(_ data: (RawData.HashTagResponse, String)) {
        guard let firstItem = hashTagItems.first,
              firstItem.isUserCreate,
              firstItem.content == data.1 else {
            return
        }
        refreshFirstRow?(data.1.isEmpty)
        mapToHashTagItemsForResponse(data)
        updateHashTagListCallBack?(data.0)
    }

    func mapToHashTagItemsForResponse(_ responseData: (RawData.HashTagResponse, String)) {
        guard let firstItem = hashTagItems.first, firstItem.isUserCreate else {
            return
        }
        hashTagItems = responseData.0.hashtagInfos.map { (tagInfo) -> HashTagItem in
            let participateCountStr = BundleI18n.Moment.Lark_Community_TopicsNumberTimesEngagement(tagInfo.participateCount)
            let desText = tagInfo.participateCount > 9999 ? BundleI18n.Moment.Lark_Community_NewPost9999Reactions : participateCountStr
            return HashTagItem(content: tagInfo.content,
                               desText: desText,
                               isUserCreate: false)
        }
        /// 是当前查询的结果
        if firstItem.content == responseData.1 {
            if responseData.0.isNewHashtag {
                firstItem.desText = firstItem.content.isEmpty ? "" : BundleI18n.Moment.Lark_Community_NewHashtag
                hashTagItems.insert(firstItem, at: 0)
            } else {
                // 这里服务端数据异常进入
                if hashTagItems.isEmpty {
                    assertionFailure("服务端数据异常")
                    firstItem.desText = ""
                    hashTagItems.insert(firstItem, at: 0)
                } else {
                    hashTagItems.first?.isUserCreate = true
                }
            }
        } else {
            firstItem.desText = ""
            hashTagItems.insert(firstItem, at: 0)
        }
    }

    func onErrorToDisplayIntput(_ input: String) {
        guard let firstItem = hashTagItems.first,
              firstItem.isUserCreate,
              firstItem.content == input else {
            return
        }
        firstItem.desText = input.isEmpty ? "" : BundleI18n.Moment.Lark_Community_NewHashtag
        refreshFirstRow?(input.isEmpty)
    }

}
