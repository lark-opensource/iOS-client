//
//  Stream.swift
//  LarkStorage
//
//  Created by zhangwei on 2023/9/5.
//

import Foundation

public protocol SBStream: AnyObject {
    func open()
    func close()
    var streamStatus: Stream.Status { get }
    var streamError: Error? { get }
}

extension Stream: SBStream {}

public protocol SBInputStream: SBStream {
    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int

    var hasBytesAvailable: Bool { get }
}

extension InputStream: SBInputStream {}

public protocol SBOutputStream: SBStream {
    func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int
    var hasSpaceAvailable: Bool { get }
}

extension OutputStream: SBOutputStream {}
