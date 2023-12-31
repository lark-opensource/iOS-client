//
//  RustConfiguration.swift
//  LarkAccount
//
//  Created by CharlieSu on 11/12/19.
//

import UIKit
import Foundation
import LarkAccountInterface

final class RustConfiguration: RustConfigurationService {
    let preloadGroupPreviewChatterCount: Int = {
        let lrMargin: CGFloat = 16
        let avatarWH: CGFloat = 32
        let avatarSpacing: CGFloat = 12
        let suitableSpace = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return Int(floor(suitableSpace - lrMargin * 2 - avatarWH) / (avatarWH + avatarSpacing))
    }()
}
