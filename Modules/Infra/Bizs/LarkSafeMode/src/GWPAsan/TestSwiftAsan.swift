//
//  TestSwiftAsan.swift
//  LarkSafeMode
//
//  https://bytedance.feishu.cn/docx/doxcnMZzFBgFLQAqYGV4HfJ6zye
//  https://developer.apple.com/documentation/xcode/use-of-deallocated-memory
//  Created by luyz on 2022/7/26.
//

import Foundation

public final class TestSwiftAsan: NSObject {
    
    static let count = 3
    static let stride = MemoryLayout<Int>.stride
    static let alignment = MemoryLayout<Int>.alignment
    static let byteCount = stride * count
    
    static let pointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
    
    public static func testDoubleFree() {
        do {
            defer {
                pointer.deallocate()
                pointer.deallocate()
            }
            pointer.load(as: Int.self)
            pointer.advanced(by: stride).load(as: Int.self)
        }
    }
    
    public static func testUseAfterFree() {
        pointer.deallocate()
        
        pointer.storeBytes(of: 42, as: Int.self)
        pointer.advanced(by: stride).storeBytes(of: 6, as: Int.self)
        pointer.advanced(by: stride*3).storeBytes(of: 7, as: Int.self)
        
        let bufferPointer = UnsafeRawBufferPointer(start: pointer, count: byteCount)
        for (index, byte) in bufferPointer.enumerated() {
            print("luyz:byte \(index): \(byte)")
        }
    }
}

