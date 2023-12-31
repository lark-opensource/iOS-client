//
//  Xcode.swift
//  Calendar_Cloud
//
//  Created by wangwanxin on 2021/5/13.
//

import Foundation

struct Xcode {
    static func xcodeVersion() -> String {
        return shell("xcodebuild -version").replacingOccurrences(of: "\n", with: " ")
    }
}
