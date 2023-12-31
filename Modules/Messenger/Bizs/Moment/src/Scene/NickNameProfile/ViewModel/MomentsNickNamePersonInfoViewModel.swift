//
//  MomentsNickPersonInfoViewModel.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer
import LKCommonsLogging

final class MomentsNickNamePersonInfoViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var configService: MomentsConfigAndSettingService?
    var config: RawData.UserCircleConfig?
    /// nickNameProfile的设置信息
    struct NickNameProfile {
        var nickNamePersonInfo: [(title: String, subTitle: String)] = []
        let privacyPolicyUrl: String
        init(nickNamePersonInfo: [(String, String)] = [], privacyPolicyUrl: String = "") {
            self.nickNamePersonInfo = nickNamePersonInfo
            self.privacyPolicyUrl = privacyPolicyUrl
        }
    }

    static let logger = Logger.log(MomentFeedListViewModel.self, category: "Module.Moments.MomentsPolybasicProfileViewModel")
    @ScopedInjectedLazy private var profileApi: ProfileApiService?
    let disposeBag = DisposeBag()
    var nickNameProfile: NickNameProfile = NickNameProfile()
    let userId: String
    init(userResolver: UserResolver, userId: String) {
        self.userResolver = userResolver
        self.userId = userId
        self.getCircleConfig()
    }

    func getCircleConfig() {
        configService?.getUserCircleConfigWithFinsih({ config in
            self.config = config
        }, onError: nil)
    }

    func getNickNamePersonInfo(finishCallBack: (() -> Void)?) {
        profileApi?.getGetNicknameProfileFor(userID: self.userId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { nicknameProfile in
                var nickNamePersonInfo: [(title: String, subTitle: String)] = []
                for userField in nicknameProfile.userFields {
                    nickNamePersonInfo.append((title: userField.key, subTitle: userField.value))
                }
                self.nickNameProfile = NickNameProfile(nickNamePersonInfo: nickNamePersonInfo, privacyPolicyUrl: nicknameProfile.privacyPolicyURL)
                finishCallBack?()
            }, onError: { (error) in
                Self.logger.error("momentNickNameProfile load fail", error: error)
            }).disposed(by: disposeBag)
    }
}
