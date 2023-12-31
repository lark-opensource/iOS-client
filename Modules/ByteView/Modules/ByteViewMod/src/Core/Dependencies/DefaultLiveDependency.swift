//
//  DefaultLiveDependency.swift
//  LarkByteView
//
//  Created by kiri on 2021/7/2.
//

import Foundation
import ByteView

final class DefaultLiveDependency: LiveDependency {
    var isLiving: Bool {
        false
    }

    func stopLive() {
    }

    func trackFloatWindow(isConfirm: Bool) {}
}
