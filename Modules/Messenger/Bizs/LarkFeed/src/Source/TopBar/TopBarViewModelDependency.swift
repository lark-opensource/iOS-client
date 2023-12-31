//
//  TopBarViewModelDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/22.
//

import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface

protocol TopBarViewModelDependency {
    /// 网络状态
    var pushDynamicNetStatus: Observable<PushDynamicNetStatus> { get }
}
