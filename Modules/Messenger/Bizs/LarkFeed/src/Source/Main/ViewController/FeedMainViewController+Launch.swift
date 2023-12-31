//
//  FeedMainViewController+Launch.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/6.
//

import Foundation
import LarkUIKit
import RxRelay
import RxSwift
import LarkPerf

extension FeedMainViewController: UserControlledLaunchTransition {
    var dismissSignal: BehaviorRelay<Bool> {
        return mainViewModel.allFeedsViewModel.firstScreenRenderedFinish
    }
}
