//
//  FileInfo.swift
//  ByteWebImage
//
//  Created by Saafo on 2023/7/25.
//

/// 文件信息
public struct FileInfo: CustomStringConvertible {
    /// 文件名
    internal let file: String
    /// 函数名
    internal let function: String
    /// 行数
    internal let line: Int

    /// 文件信息描述
    public let description: String

    internal init(file: String, function: String, line: Int) {
        self.file = file
        self.function = function
        self.line = line

        self.description = "file: \(file), func: \(function), line: \(line)"
    }
}

