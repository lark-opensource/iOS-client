//
//  AESFileFactory.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/30.
//

import UIKit

public protocol AESFile {
    /// seek 到指定位置，然后再进行文件加解密操作，注意：
    /// 1. ReadFile: 可以seek到任意位置
    /// 2. AppendFile&WriteFile: 不支持seek到任意位置，只能seek到结尾
    /// - Parameters:
    ///   - seekWhere: 从什么地方开始seek，支持：start、current、end
    ///   - offset: seek的byte数
    /// - Returns: 返回数据流新的offset
    func seek(from seekWhere: AESSeekWhere, offset: UInt64) throws -> UInt64
    func read(maxLength len: UInt32, position: UInt64?) throws -> Data
    func write(data: Data, position: UInt64?) throws -> UInt32
    
    func sync() throws
    func close() throws
    func offset() throws -> UInt64
    
    func readToEnd() throws -> Data?
}

protocol AESBaseFile: AESFile {
    var fileHandle: SCFileHandle { get }
    var cryptor: AESCryptor { get }
    
    init(deviceKey: Data, header: AESHeader, filePath: String) throws
}

extension AESBaseFile {
    
    func sync() throws {
        try fileHandle.synchronize()
    }
    
    func close() throws {
        try fileHandle.close()
    }
    
    func offset() throws -> UInt64 {
        let offset = try fileHandle.offset()
        return max(0, offset - AESHeader.size)
    }
    
    func seek(from seekWhere: AESSeekWhere, offset: UInt64) throws -> UInt64 {
        switch seekWhere {
        case .start:
            try fileHandle.seek(toOffset: offset + AESHeader.size)
            cryptor.seek(to: offset)
        case .end:
            let newOffset = try fileHandle.seekToEnd()
            cryptor.seek(to: newOffset - AESHeader.size)
        case .current:
            let current = try fileHandle.offset()
            try fileHandle.seek(toOffset: current + offset + AESHeader.size)
            cryptor.seek(to: current + offset)
        }
        
        return try self.offset()
    }
}

public struct AESFileFactory {
    
    public static func createFile(deviceKey: Data, header: AESHeader, filePath: String, option: AESFileOption) throws -> AESFile {
        let type: AESBaseFile.Type = {
            switch option {
            case .append:
                return AESUpdateFile.self
            case .read:
                return AESReadFile.self
            case .write:
                return AESWriteFile.self
            }
        }()
        return try type.init(deviceKey: deviceKey, header: header, filePath: filePath)
    }
    
    static func cryptoVersion(_ filePath: String) -> AESFileKind {
        do {
            let handle = try SCFileHandle(path: filePath, option: .read)
            try handle.seek(toOffset: 0)
            guard let headerData = try handle.read(upToCount: Int(AESHeader.size)) else {
                try handle.close()
                return .regular
            }
            try handle.close()
            let header = try AESHeader(data: headerData)
            // 1. 先验证magic
            let magicChecked = header.values[.magic1]?.bytes == AESFileKind.v1.magic
            && header.values[.magic2]?.bytes == AESFileKind.v2.magic
            if magicChecked, let versionD = header.values[.version] {
                let version: UInt8 = versionD.convertToInteger()
                return AESFileKind(rawValue: version) ?? .regular
            }
            return .regular
        } catch {
            return .regular
        }
    }
    
}
