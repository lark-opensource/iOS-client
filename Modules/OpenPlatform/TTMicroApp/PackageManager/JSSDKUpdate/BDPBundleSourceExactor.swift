//
//  TXZBundleExactor.swift
//  TTMicroApp
//
//  Created by qsc on 2022/6/8.
//

import Foundation
import LKCommonsLogging
import LibArchiveKit
import Compression
import ECOProbe
import SSZipArchive

/// 资源压缩类型
@objc public enum BDPBundleResourceType: Int {
    /// zip 压缩文件，支持密码
    case ZIP = 0
    /// txz 压缩文件：不支持密码
    /// 压缩命令： tar cfJ result.txz source
    case TXZ
    /// txz + zip 双重处理后的 JSSDK 文件：先走 zip 解压流程(支持密码)，再走 txz 解包流程
    /// 小程序内置 JSSDK 特化流程
    case TXZJSSDK
}

/// 内置资源解压
public final class BDPBundleResourceExtractor: NSObject {
    static let logger = Logger.oplog(BDPBundleResourceExtractor.self, category: "BDPBundleResourceExtractor")

    private override init() {}

    /// 解压资源，支持 zip、txz 以及 jsssdk 特有的 txz+zip
    /// - Parameters:
    ///   - path: 待解压资源路径
    ///   - type: 资源类型，目前支持：zip、txz、txzjssdk，详见 BDPBundleResourceType
    ///   - targetPath: 目标路径
    ///   - password: 可选，zip 解压密码
    ///   - overwrite: 可选，zip 解压选项
    /// - Important
    ///   - 为防止解压过程中外部有其它文件操作行为导致文件完入失败等情况，targetPath 应当为临时目录或提供保证原子性保障
    @objc public static func extractBundleResource(path: String, type: BDPBundleResourceType, targetPath: String, password: String? = nil, overwrite: Bool = true) throws {
        logger.info("extrace resource: \(path), type: \(type), target: \(targetPath), password: \(password == nil), overwrite: \(overwrite)")
        switch type {
        case .ZIP:
            try SSZipArchive.unzipFile(atPath: path, toDestination: targetPath, overwrite: overwrite, password: password)
        case .TXZ:
            try Self.extractTXZFile(filePath: path, to: targetPath)
        case .TXZJSSDK:
            let tmpTxzFilePath = targetPath.appending("/delta.txz")
            try SSZipArchive.unzipFile(atPath: path, toDestination: targetPath, overwrite: overwrite, password: password)
            try Self.extractTXZFile(filePath: tmpTxzFilePath, to: targetPath)
        }
    }

    @objc
    public static func extractTXZFile(filePath: String, to targetPath: String) throws {
        logger.info("extractTXZFile path: \(filePath), target: \(targetPath)")
        let sourceData = try LSFileSystem.main.readData(from: filePath)
        let decodedData = try sourceData.decompressDataUsingLZMA()
        let file = try LibArchiveFile(data: decodedData)
        try file.extract(toDir: URL(fileURLWithPath: targetPath))
    }
}


private enum ExtractError: LocalizedError {

    case sourceDataNotFound(source: String)
    case sourceDataEmpty
    case sourceDataBaseAddressNil
    case decodedSizeIsZero
    case decodedDataEmpty

    var errorDescription: String? {
        switch self {
        case .sourceDataEmpty:
            return "lzma decode failed: sourceData empty"
        case .sourceDataBaseAddressNil:
            return "lzma decode failed: sourceData baseAddress nil"
        case .decodedSizeIsZero:
            return "lzma decode failed: decoded size is 0"
        case .decodedDataEmpty:
            return "lzma decode failed: decodedData empty"
        case .sourceDataNotFound(let source):
            return "source: \(source) NotFound!"
        }
    }
}

private extension Data {
    /// 解压使用 lzma 压缩算法压缩的数据，如使用 tar cfJ 或 xz 命令压缩的数据
    func decompressDataUsingLZMA() throws -> Data {

        guard !isEmpty else {
            throw ExtractError.sourceDataEmpty
        }

        let maxDstSize = 50_000_000 // 解压后最大为50M，兜底终止条件
        var dstSize = self.count * 7 // 起始预估解压后大小为7倍
        var result: Data?
        while result == nil, dstSize < maxDstSize {
            result = try _processDecode(dstSize)
            dstSize = dstSize * 2 // 每次扩大一倍
        }

        if let resultData = result {
            return resultData
        }
        throw ExtractError.decodedDataEmpty
    }

    /// 实际解压
    /// - Parameter dstSize: 预期解压后大小(bytes)
    /// - Returns: 解压后Data
    private func _processDecode(_ dstSize: Int) throws -> Data? {

        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstSize)
        let srcCount = self.count
        let decompressed: Data? = try self.withUnsafeBytes {
            guard let srcPointer = $0.bindMemory(to: UInt8.self).baseAddress else {
                throw ExtractError.sourceDataBaseAddressNil
            }
            let outSize = compression_decode_buffer(dstBuffer, dstSize, srcPointer, srcCount, nil, COMPRESSION_LZMA)
            guard outSize > 0 else {
                throw ExtractError.decodedSizeIsZero
            }
            return Data(bytesNoCopy: dstBuffer, count: outSize, deallocator: .free)
        }
        return decompressed
    }
}

