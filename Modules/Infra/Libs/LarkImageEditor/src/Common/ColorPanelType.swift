//
//  ColorPanelType.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/30.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignColor

enum ColorPanelType: Int {
    case red = 1
    case white, black, green, orange, blue, pink
    func color() -> UIColor {
        switch self {
        case .red:
            return .ud.colorfulRed.alwaysLight
        case .white:
            return .ud.N00.alwaysLight
        case .black:
            return .ud.N1000.alwaysLight
        case .green:
            return .ud.colorfulGreen.alwaysLight
        case .orange:
            return .ud.colorfulYellow.alwaysLight
        case .blue:
            return .ud.colorfulBlue.alwaysLight
        case .pink:
            return .ud.colorfulCarmine.alwaysLight
        }
    }

    static var `default`: ColorPanelType {
        return .red
    }
}
