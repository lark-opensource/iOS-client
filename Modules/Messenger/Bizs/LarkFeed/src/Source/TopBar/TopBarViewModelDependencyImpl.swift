//
//  TopBarViewModelDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/22.
//

import Foundation
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface
import LarkNavigation

final class TopBarViewModelDependencyImpl: TopBarViewModelDependency {

    private let disposeBag: DisposeBag = DisposeBag()

    var pushDynamicNetStatus: Observable<PushDynamicNetStatus>

    init(pushDynamicNetStatus: Observable<PushDynamicNetStatus>) {
        self.pushDynamicNetStatus = pushDynamicNetStatus
    }
}
