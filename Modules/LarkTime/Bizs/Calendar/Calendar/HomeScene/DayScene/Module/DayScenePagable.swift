//
//  DayScenePagable.swift
//  Calendar
//
//  Created by 张威 on 2020/7/16.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit

/// DayScene 支持水平滑动的 Child

protocol DayScenePagableChild: UIViewController {
    // 同步 pageOffset 的变化
    typealias PageOffsetSyncer = (_ pageOffset: PageOffset, _ source: DayScenePagableChild) -> Void
    var onPageOffsetChange: PageOffsetSyncer? { get set }
    func scroll(to pageOffset: PageOffset, animated: Bool)
}
