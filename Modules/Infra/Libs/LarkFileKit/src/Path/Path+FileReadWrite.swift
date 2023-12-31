//
//  Path+FileReadWrite.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/14.
//

import Foundation
extension Path {
    /// 写文件
    /// - Parameter data: 要写的数据，需要符合DataType类型
    public func write<DataType: ReadableWritable>(_ data: DataType) throws {
        try write(data, atomically: true)
    }

    /// 写文件
    /// - Parameters:
    ///   - data: 要写的数据，需要符合DataType类型
    ///   - useAuxiliaryFile: If true, the data is written to an auxiliary file that is then renamed to the file.
    ///    If false, the data is written to the file directly.
    public func write<DataType: ReadableWritable>(_ data: DataType, atomically useAuxiliaryFile: Bool) throws {
        try data.write(to: self, atomically: useAuxiliaryFile)
    }

    /// 读文件
    public func read<DataType: ReadableWritable>() throws -> DataType {
        try DataType.read(from: self)
    }
}
