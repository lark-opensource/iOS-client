//
//  InterruptResult.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/11/15.
//

import Foundation

struct InterruptResult {
    var begin: [SceneMediaConfig] = []
    var end: [SceneMediaConfig] = []

    static var `default`: Self { InterruptResult() }

    static func begin(_ begin: [SceneMediaConfig]) -> Self {
        InterruptResult(begin: begin)
    }

    static func end(_ end: [SceneMediaConfig]) -> Self {
        InterruptResult(end: end)
    }
}
