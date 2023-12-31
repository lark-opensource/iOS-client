//
//  HashTagDetailHeaderViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/7/2.
//

import Foundation
import UIKit
import LarkContainer
import RxSwift
import LKCommonsLogging

final class HashTagDetailHeaderViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var hashTagApi: HashTagApiService?
    private let disposeBag = DisposeBag()
    private let hashtagId: String
    var detailInfo: RawData.HashTagDetailInfo?
    static let logger = Logger.log(HashTagDetailHeaderViewModel.self, category: "Module.Moments.HashTagDetailHeaderViewModel")
    init(userResolver: UserResolver, hashtagId: String) {
        self.userResolver = userResolver
        self.hashtagId = hashtagId
    }
    func getHashTagDetail(finish: (() -> Void)?) {
        hashTagApi?.getDetailInfoWithHashTagId(hashtagId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                self?.detailInfo = info
                finish?()
            }, onError: { (error) in
                Self.logger.error("getHashTagDetail fail -\(error)")
            }).disposed(by: disposeBag)
    }
}
