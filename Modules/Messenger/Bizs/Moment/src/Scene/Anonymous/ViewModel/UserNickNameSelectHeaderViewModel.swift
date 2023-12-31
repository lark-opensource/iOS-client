//
//  UserNickNameSelectHeaderViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//
import Foundation
import LarkContainer
import RxSwift

final class UserNickNameSelectHeaderViewModel: UserResolverWrapper {
    var selectedIcon: String?
    var layout: UserNickNameHeaderLayout?
    /// data
    var nickNameData: RawData.AnonymousNickname?
    let userResolver: UserResolver
    @ScopedInjectedLazy private var nickNameAndAnonymousService: NickNameAndAnonymousService?
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 当前是否可以选中
    func canConfirm(curNickNameID: String? = nil) -> Bool {
        if let curNickNameID = curNickNameID {
            return nickNameData?.nickname != nil && selectedIcon != nil && nickNameData?.nicknameID != curNickNameID
        } else {
            return nickNameData?.nickname != nil && selectedIcon != nil
        }
    }

    func refreshIcon(finish: @escaping (Error?) -> Void) {
        self.nickNameAndAnonymousService?.pullNickNameAvatar()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { key in
                self.selectedIcon = key
                finish(nil)
            }, onError: { error in
                finish(error)
            }).disposed(by: self.disposeBag)
    }
}
