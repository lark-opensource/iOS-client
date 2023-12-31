//
//  ThreadAdminService.swift
//  LarkThread
//
//  Created by zoujiayi on 2019/10/24.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMessageCore
import LarkSDKInterface
import LarkAccountInterface
import LarkFeatureGating
import RxSwift
import RustPB
import LarkContainer

protocol ThreadAdminService {
    func getCurrentAdminInfo() -> RustPB.Contact_V1_GetUserProfileResponse.AdminInfo?
}

final class ThreadAdminServiceImpl: ThreadAdminService {
    let userResolver: UserResolver
    private var adminInfo: RustPB.Contact_V1_GetUserProfileResponse.AdminInfo?
    private let chatterAPI: ChatterAPI
    private let disposeBag = DisposeBag()
    private var isLoading = false

    init(userResolver: UserResolver, chatterAPI: ChatterAPI) {
        self.userResolver = userResolver
        self.chatterAPI = chatterAPI
        fetchAdminInfo()
    }

    private func fetchAdminInfo() {
        // 可能在异步线程触发。主线程目的是为保证了 isLoading 值正确且只触发一次请求。
        DispatchQueue.main.async { [self] in
            if self.isLoading {
                return
            }
            self.isLoading = true
            self.chatterAPI.fetchUserProfileInfomation(userId: userResolver.userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (profile) in
                    self?.isLoading = false
                    self?.adminInfo = profile.adminInfo
                }, onError: { [weak self] _ in
                    self?.isLoading = false
                }).disposed(by: self.disposeBag)
        }
    }

    func getCurrentAdminInfo() -> RustPB.Contact_V1_GetUserProfileResponse.AdminInfo? {
        if userResolver.fg.staticFeatureGatingValue(with: .init(key: .threadAdminEnabled)) == false {
            //when not available, do not provide admin info
            return nil
        }

        if self.adminInfo == nil {
            fetchAdminInfo()
        }
        return self.adminInfo
    }
}
