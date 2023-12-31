//
//  Builder.swift
//  ByteView
//
//  Created by fakegourmet on 2021/12/24.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

protocol BuilderProtocol {
    associatedtype Product

    func build() -> Product
    init()
}

protocol Buildable {
    associatedtype Builder: BuilderProtocol where Builder.Product == Self
}

extension BuilderProtocol {
    static func runInMainThread<T>(_ block: @escaping () -> T) -> T {
        if Thread.isMainThread {
           return block()
        } else {
            return DispatchQueue.main.sync {
                block()
            }
        }
    }
}
