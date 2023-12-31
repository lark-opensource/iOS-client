//
//  SetQueryNumberViewModel.swift
//  LarkContact
//
//  Created by 李勇 on 2019/5/1.
//

import Foundation
import RxSwift
import LarkSDKInterface

final class SetQueryNumberViewModel {
    private let chatterId: String
    private let chatterAPI: ChatterAPI
    private let disposeBag: DisposeBag = DisposeBag()
    /// 最大查询次数
    var maxLimit: Int32 = 0
    /// 当天已经查询次数
    var todayQuota: Int32 = 0

    init(chatterId: String, chatterAPI: ChatterAPI) {
        self.chatterId = chatterId
        self.chatterAPI = chatterAPI
        /// 同步获取一次
        self.chatterAPI.getPhoneQueryQuotaRequest(userId: self.chatterId)
            .subscribe(onNext: { (quota, limit) in
                self.todayQuota = quota
                self.maxLimit = limit
            }).disposed(by: self.disposeBag)
    }

    /// 异步获取查询次数
    func fetchPhoneQueryQuota() -> Observable<(Int32, Int32)> {
        return self.chatterAPI.fetchPhoneQueryQuotaRequest(userId: self.chatterId)
    }

    /// 设置查询次数
    func requestQueryNumber(quota: String) -> Observable<Void> {
        return self.chatterAPI.setPhoneQueryQuotaRequest(userId: self.chatterId, quota: quota)
    }
}
