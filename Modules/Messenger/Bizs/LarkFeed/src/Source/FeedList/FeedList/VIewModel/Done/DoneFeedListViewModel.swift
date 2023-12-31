//
//  DoneFeedListViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/1/7.
//

import RxSwift
import Foundation
import RustPB
import LarkOpenFeed

final class DoneFeedListViewModel: FeedListViewModel {
    override var bizType: FeedBizType {
        return .done
    }

    override func feedType() -> Basic_V1_FeedCard.FeedType {
        .done
    }
}
