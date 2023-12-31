//
//  Util.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation
import LKCommonsLogging

final class Util {
    static func uuid() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement() ?? letters[letters.startIndex] })
    }

    static func formatDuration(_ time: TimeInterval) -> String {
        if time > 1 {
            return String(format: "%.3fs", time)
        } else {
            return String(format: "%.1fms", time * 1_000)
        }
    }
}

extension Logger {
    static let shortcut = Logger.log(Shortcut.self, category: "LarkShortcut")
}
