//
//  FeedThreeBarService.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/10/7.
//

import Foundation
import RustPB

public enum Feed3BarStyle: CaseIterable {
    case phone         // 三栏iPhone
    case padRegular    // 三栏iPad之R视图
    case padCompact    // 三栏iPad之C视图
}

public protocol FeedThreeBarService {
    var padUnfoldStatus: Bool? { get }
    var currentStyle: Feed3BarStyle { get }
}

public protocol FeedThreeColumnsGuideService: AnyObject {
    func triggerThreeColumnsGuide(scene: Feed_V1_ThreeColumnsSetting.TriggerScene) -> Bool
}
