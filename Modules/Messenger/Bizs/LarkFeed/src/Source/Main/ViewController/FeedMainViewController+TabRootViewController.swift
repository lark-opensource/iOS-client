//
//  FeedMainViewController+TabRootViewController
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import AnimatedTabBar
import RxRelay
import LarkTab

///
/// TabBar校验相关
///
extension FeedMainViewController: TabRootViewController {
    var tab: Tab { Tab.feed }

    var deamon: Bool { true }

    var controller: UIViewController { self }

    var firstScreenDataReady: BehaviorRelay<Bool>? {
        return mainViewModel.allFeedsViewModel.firstScreenRenderedFinish
    }
}
