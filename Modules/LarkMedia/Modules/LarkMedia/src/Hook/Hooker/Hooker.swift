//
//  Hooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/27.
//

import Foundation

protocol Hooker: AnyObject {
    var enabled: Bool { get }
    func willHook()
    func hook()
    func didHook()
}

extension Hooker {
    var enabled: Bool {
        true
    }
}
