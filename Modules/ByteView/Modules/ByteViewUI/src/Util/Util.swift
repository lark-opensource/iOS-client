//
//  Util.swift
//  ByteViewUI
//
//  Created by kiri on 2023/1/17.
//

import Foundation

@inline(__always)
@usableFromInline
func assertMain(function: StaticString = #function) {
    assert(Thread.isMainThread, "Method must called in main thread: \(function)")
}
