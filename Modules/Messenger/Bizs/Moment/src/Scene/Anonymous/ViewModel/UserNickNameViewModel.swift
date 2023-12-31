//
//  UserNickNameViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import Foundation
import RxSwift
import LarkContainer

final class UserNickNameViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    var datas: [UserNickNameItem] = []
    private var requestCount = 10
    private let disposeBag = DisposeBag()
    private(set) var nickNameInfo: (momentUser: RawData.RustMomentUser, renewNicknameTime: Int64)?
    private let nickNameSettingStyle: NickNameSettingStyle
    /// 当场景为修改花名时，首次进入未刷新，9条数据（包含一条本身的花名），再次刷新10条数据
    private var hasRefresh: Bool = false

    @ScopedInjectedLazy var circleConfigService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var nickNameAndAnonymousService: NickNameAndAnonymousService?

    init(userResolver: UserResolver, nickNameSettingStyle: NickNameSettingStyle = .select) {
        self.userResolver = userResolver
        self.nickNameSettingStyle = nickNameSettingStyle
        /// 花名修改模式下，第一个展示当前使用花名，只需请求9条数据
        if case .modify = nickNameSettingStyle {
            hasRefresh = false
            requestCount = 9
        }
    }

    func refreshUserNikeNames(finish: @escaping (Error?) -> Void) {
        /// 如果为花名选取模式（刷新也会变为选取模式），将拉去花名数设置为10
        nickNameAndAnonymousService?
            .pullNickName(count: requestCount, mock: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] nickNames in
                guard let self = self else { return }
                self.datas = nickNames.map({ (nickName) -> UserNickNameItem in
                    return UserNickNameItem(data: nickName)
                })
                if !self.hasRefresh {
                    switch self.nickNameSettingStyle {
                    case .modify(nickNameID: let nickNameID, nickName: let nickName, avatarKey: let avatarKey):
                        if !self.datas.isEmpty {
                            var curNickName = RawData.AnonymousNickname()
                            curNickName.nicknameID = nickNameID
                            curNickName.nickname = nickName
                            let curNickNameUser = UserNickNameItem(data: curNickName)
                            curNickNameUser.selected = true
                            self.datas.insert(curNickNameUser, at: 0)
                        }
                        /// 刷新之后，settingStyle变为select，请求数也变为10
                        self.hasRefresh = true
                        self.requestCount = 10
                    case .select:
                        break
                    }
                }
                finish(nil)
            }, onError: { error in
                finish(error)
            }).disposed(by: self.disposeBag)
    }

    func confirmNickName(circleId: String, avatarKey: String, nickName: RawData.AnonymousNickname, isRenewal: Bool, finish: @escaping (Error?) -> Void) {
        nickNameAndAnonymousService?
            .createNickNameUser(circleId: circleId,
                                avatarKey: avatarKey,
                                nickName: nickName,
                                isRenewal: isRenewal)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] nickNameInfo in
                self?.nickNameInfo = nickNameInfo
                self?.circleConfigService?.updateUserNickName(momentUser: nickNameInfo.momentUser, renewNicknameTime: nickNameInfo.renewNicknameTime)
                finish(nil)
            }, onError: { error in
                finish(error)
            }).disposed(by: self.disposeBag)
    }
}
