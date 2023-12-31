//
//  LabelConfig.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/22.
//

import Foundation
import LarkUIKit

final class LabelConfig {
    static let loadMoreLabelCount: Int32 = Display.phone ? phoneCount : padCount
    static let loadMoreFeedCount: Int32 = Display.phone ? phoneCount : padCount
    static let loadMoreLabelMaxTimes: Int = 100
    private static let phoneCount: Int32 = 50
    private static let padCount: Int32 = 100
}
