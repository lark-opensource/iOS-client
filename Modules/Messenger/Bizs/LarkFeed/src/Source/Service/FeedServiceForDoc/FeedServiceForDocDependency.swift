//
//  FeedServiceForDocDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/7.
//

import Foundation
import RxSwift
import RustPB

protocol FeedServiceForDocDependency {
    func isFeedCardShortcut(feedId: String) -> Bool
}
