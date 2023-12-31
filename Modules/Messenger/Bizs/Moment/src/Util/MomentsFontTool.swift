//
//  MomentsFontTool.swift
//  Moment
//
//  Created by liluobin on 2021/3/13.
//

import Foundation
import UIKit

final class MomentsFontTool {
    static func dinBoldFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "DINAlternate-Bold", size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        return font
    }
}
