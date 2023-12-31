//
//  PresentType.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/9.
//

import Foundation

enum PresentType: String, CustomStringConvertible {
    case filterType
    case floatAction

    var description: String {
        rawValue
    }
}
