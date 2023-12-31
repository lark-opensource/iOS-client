//
//  Colors.swift
//  LarkTourDev
//
//  Created by Meng on 2020/5/22.
//

import Foundation
import UIKit

enum Colors {
    private static var defaultColors: [UIColor] = [
        /*.red,*/ .green, .brown,
        .cyan, .gray, .magenta,
        .orange, .purple, .yellow
    ]

    private static var colors: [UIColor] = []

    static func random() -> UIColor {
        if colors.isEmpty {
            colors = defaultColors.shuffled()
        }
        return colors.removeLast()
    }
}
