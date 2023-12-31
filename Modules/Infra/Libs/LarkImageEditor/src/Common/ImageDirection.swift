//
//  ImageDirection.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2018/8/6.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation

enum ImageDirection: Int {
    case up = 0
    case left = 1
    case down = 2
    case right = 3

    func antiClockwiseRotate() -> ImageDirection {
        return ImageDirection(rawValue: (self.rawValue + 1) % 4) ?? .up
    }

    var reverted: ImageDirection {
        switch self {
        case .up: return .up
        case .left: return .right
        case .down: return .down
        case .right: return .left
        }
    }

    var radian: CGFloat {
        switch self {
        case .up: return 0
        case .left: return -0.25 * 2 * CGFloat.pi
        case .down: return -0.5 * 2 * CGFloat.pi
        case .right: return -0.75 * 2 * CGFloat.pi
        }
    }

    var widthHeightSwapped: Bool {
        return self == .left || self == .right
    }
}
