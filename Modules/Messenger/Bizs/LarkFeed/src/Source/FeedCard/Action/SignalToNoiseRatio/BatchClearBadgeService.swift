//
//  BatchClearBadgeDependency.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/8.
//

import Foundation
import RxSwift
import UIKit

// service
protocol BatchClearBagdeService {
    var pushBatchClearFeedBadges: Observable<PushBatchClearFeedBadge> { get }

    func addTaskID(taskID: String)
}
