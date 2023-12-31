//
//  NoPermissionBaseStep.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/1/6.
//

import UIKit
import RxSwift
import RxCocoa
import LarkContainer

class NoPermissionBaseStep: NoPermissionStep, UserResolverWrapper {

    let userResolver: UserResolver

    let http = DeviceManagerAPI()
    let context: NoPermissionStepContext

    let bag = DisposeBag()

    let updateUI = PublishSubject<Void>()

    let viewDidAppear = PublishSubject<Void>()

    let nextButtonLoading = PublishSubject<Bool>()

    let refreshWithAnimationFromStep = PublishSubject<Void>()

    let retryButtonClicked = PublishSubject<Void>()

    required init(resolver: UserResolver, context: NoPermissionStepContext) throws {
        self.userResolver = resolver
        self.context = context
    }

    func next() {}

    // MARK: - UI

    var nextTitle: String { "" }
    var detailTitle: String { "" }
    var detailSubtitle: String { "" }
    var emptyDetail: String { "" }

    var nextHidden: Bool { false }
    var reasonDetailHidden: Bool { true }
    var refreshTop: NoPermissionLayout.Refresh { .init(top: 16, align: .next) }
    var nextTop: NoPermissionLayout.Next { .init(top: 24, align: .empty) }
}
