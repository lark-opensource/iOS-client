//
//  Git.swift
//  Calendar_Cloud
//
//  Created by Rico on 2021/4/21.
//

import Foundation

struct Git {
    static func userName() -> String {
        return shell("git config user.name").trimmingCharacters(in: .newlines)
    }
}
