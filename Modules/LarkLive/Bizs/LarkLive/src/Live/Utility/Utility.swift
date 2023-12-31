//
//  Utility.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/6/22.
//

import Foundation
import RxSwift

struct Util {
    @inline(__always)
    @usableFromInline
    static func runInMainThread(_ block: @escaping () -> Void) {
        if Thread.current == Thread.main {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

extension CGSize {
    func equalSizeTo(_ other: CGSize) -> Bool {
        return (width == other.width && height == other.height) || (height == other.width && width == other.height)
    }
}

