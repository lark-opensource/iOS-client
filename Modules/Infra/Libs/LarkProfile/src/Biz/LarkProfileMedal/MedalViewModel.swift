//
//  MedalViewModel.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/15.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkAccountInterface
import LKCommonsLogging

public final class MedalViewModel: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy var profileAPI: LarkProfileAPI?
    private static let logger = Logger.log(MedalViewModel.self, category: "MedalViewModel")

    let userID: String
    var isMe: Bool {
        let accountService = try? userResolver.resolve(assert: PassportUserService.self)
        return accountService?.user.userID == userID
    }

    var avatarKey: String = ""
    var medalKey: String = ""
    var medalFsUnit: String = ""
    var backgroundImageKey: String = ""
    var backgroundImageFsUnit: String = ""
    var dataSource: [LarkMedalItem] = []

    private var disposeBag = DisposeBag()

    private let refreshReplay: ReplaySubject<Void> = ReplaySubject<Void>.create(bufferSize: 1)
    var refreshObservable: Observable<Void> {
        return refreshReplay.asObservable()
    }

    public init(resolver: UserResolver, userID: String) {
        self.userResolver = resolver
        self.userID = userID
        getUserMedalInfo()
    }

    func getUserMedalInfo() {
        self.profileAPI?
            .getMedalListBy(userID: userID)
            .subscribe(onNext: { [weak self] response in
                self?.avatarKey = response.userInfo.avatarKey
                self?.backgroundImageKey = response.userInfo.topImage.key
                self?.backgroundImageFsUnit = response.userInfo.topImage.fsUnit
                self?.dataSource = response.medalList

                for medal in response.medalList {
                    if medal.status == .taking {
                        self?.medalKey = medal.medalShowImage.key
                        self?.medalFsUnit = medal.medalShowImage.fsUnit
                        Self.logger.info("MatchMedalIdAndTaking,\(medal.medalID),\(medal.medalShowImage.key)")
                        break
                    }
                    self?.medalKey = ""
                    self?.medalFsUnit = ""
                }
                Self.logger.info("MatchMedalIdAndValid,\(self?.medalKey)")
                self?.refreshReplay.onNext(())
            }).disposed(by: disposeBag)
    }

    func setMedalBy(medal: LarkMedalItem) -> Observable<Void> {
        guard let profileAPI = self.profileAPI else {
            return .just(())
        }
        return profileAPI.setMedalBy(userID: userID,
                                          medalID: medal.medalID,
                                          grantID: medal.grantID,
                                          isTaking: medal.status != .taking).flatMap({ [weak self] _ -> Observable<Void> in
                                                self?.getUserMedalInfo()
                                                return .just(())
                                          })
    }
}
