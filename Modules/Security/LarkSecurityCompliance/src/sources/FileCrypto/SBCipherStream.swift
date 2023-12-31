//
//  SBCipherStream.swift
//  LarkStorage
//
//  Created by 汤泽川 on 2022/12/1.
//

import Foundation

public enum SBSeekWhere {
    case start
    case current
    case end
}

public protocol SBCipherStream {
    func open(shouldAppend append: Bool) throws
    func close() throws
}

extension SBCipherStream {
    func open() throws {
        try open(shouldAppend: false)
    }
}

/// 写入数据流
public protocol SBCipherOutputStream: SBCipherStream {
    func write(data: Data) throws
}

/// 读取数据流
public protocol SBCipherInputStream: SBCipherStream {
    func read(maxLength len: UInt32) throws -> Data
    func readAll() throws -> Data
    func seek(from where: SBSeekWhere, offset: UInt64) throws -> UInt64
}
