//
//  LDRGuideViewModel.swift
//  LarkContact
//
//  Created by mochangxing on 2021/4/2.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkAccountInterface

final class LDRGuideViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    @ScopedProvider private var guideAPI: LDRGuideAPI?
    private let disposeBag = DisposeBag()
    let isOversea: Bool

    init(isOversea: Bool, resolver: UserResolver) throws {
        self.isOversea = isOversea
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
    }

    var tenantName: String {
        return passportUserService.userTenant.tenantName
    }

    func getLDRService() -> Driver<GetLDRServiceAppLinkResponse> {
        guard let guideAPI = self.guideAPI else { return .just(GetLDRServiceAppLinkResponse()) }
        return guideAPI.getLDRService().asDriver(onErrorJustReturn: GetLDRServiceAppLinkResponse())
    }

    func reportEvent(eventKeyList: [String]) {
        guard let guideAPI = self.guideAPI else { return }
        _ = guideAPI.reportEvent(eventKeyList: eventKeyList).subscribe().disposed(by: disposeBag)
    }

    func reportEndGuide() {
        guard let guideAPI = self.guideAPI else { return }
        let event = "new_user_create_team_strong_guide"
        _ = guideAPI.reportEvent(eventKeyList: [event]).subscribe().disposed(by: disposeBag)
    }
}
