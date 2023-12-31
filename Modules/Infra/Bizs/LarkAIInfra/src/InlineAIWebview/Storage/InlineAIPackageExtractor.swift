//
//  InlineAIPackageExtractor.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/15.
//

import Foundation
import LibArchiveKit
import SSZipArchive
import LarkStorage
import Compression
import LarkStorageCore

private enum ExtractError: LocalizedError {
    
    case sourceDataEmpty
    case sourceDataBaseAddressNil
    case decodedSizeIsZero
    case decodedDataEmpty
    
    var errorDescription: String? {
        switch self {
        case .sourceDataEmpty:
            return "BundlePkg Extract: sourceData empty"
        case .sourceDataBaseAddressNil:
            return "BundlePkg Extract: sourceData baseAddress nil"
        case .decodedSizeIsZero:
            return "BundlePkg Extract: decoded size is 0"
        case .decodedDataEmpty:
            return "BundlePkg Extract: decodedData empty"
        }
    }
}

struct InlineAIPackageExtractor {
    
    enum Format: CaseIterable {
        
        case tarXz
        
        case sevenZip
        
        case zip
        
        /// 文件扩展名
        var fileExtension: String {
            switch self {
            case .zip:
                return "zip"
            case .sevenZip:
                return "7z"
            case .tarXz:
                return "txz"
            }
        }
        
        /// 文件真实类型识别标识  (参考 https://en.wikipedia.org/wiki/List_of_file_signatures)
        fileprivate var magicNumber: [UInt8] {
            switch self {
            case .zip:
                // nolint-next-line: magic number
                let zipNumber: [UInt8] = [80, 75, 3, 4]
                return zipNumber             // "50 4b 03 04" (普通zip, 非空 非分卷)
            case .sevenZip:
                // nolint-next-line: magic number
                let sevenZipNumber: [UInt8] = [55, 122, 188, 175, 39, 28]
                return sevenZipNumber  // "37 7a bc af 27 1c"
            case .tarXz:
                // nolint-next-line: magic number
                let tarXzNumber: [UInt8] = [253, 55, 122, 88, 90, 0]
                return tarXzNumber   // "fd 37 7a 58 5a 00"
            }
        }
    }
    
    private static var _format: Format?
    
}

extension InlineAIPackageExtractor {
    
    static func trySweepFolder(path: AIFilePath) -> Bool {
        //清除资源
        if path.exists {
            do {
                LarkInlineAILogger.info("delete dir:\(path)")
                try path.removeItem()
            } catch let error {
                LarkInlineAILogger.info("delete dir fail \(error) \(path)")
            }
        }
        //创建路径
        if !path.exists {
            do {
                LarkInlineAILogger.info("create dir:\(path)")
                try path.createDirectory(withIntermediateDirectories: true)
            } catch let error {
                LarkInlineAILogger.error("create dir fail:\(error) \(path)")
                return false
            }
        }
        return true
    }
    
    /// 解压内置zip包
    static func unzipBundlePkg(zipFilePath: String, to unzipPath: AIFilePath) -> Swift.Result<(), Swift.Error> {
        let cleanResult = trySweepFolder(path: unzipPath)
        LarkInlineAILogger.info("trySweepFolder, result:\(cleanResult)")
        do {
            let format = getFileFormat(zipFilePath: zipFilePath)
            switch format {
            case .tarXz:
                LarkInlineAILogger.info("prepare xz decompress, source path:\(zipFilePath)")
                let sourceData = try Data.read(from: unzipPath)
                LarkInlineAILogger.info("prepare xz decompress, sourceData isEmpty:\(sourceData.isEmpty)")
                let decodedData = try sourceData.decompressedDataUsingAILZMA()
                LarkInlineAILogger.info("prepare xz decompress, decodedData isEmpty:\(decodedData.isEmpty)")
                let file = try LibArchiveFile(data: decodedData)
                LarkInlineAILogger.info("start xz unzip, sourcePath:\(zipFilePath)")
                try extractArchiveFile(file: file, format: .tarXz, targetPath: unzipPath)
            case .sevenZip:
                let file = try LibArchiveFile(path: zipFilePath)
                LarkInlineAILogger.info("start 7zip unzip, sourcePath:\(zipFilePath)")
                try extractArchiveFile(file: file, format: .sevenZip, targetPath: unzipPath)
            case .zip:
                LarkInlineAILogger.info("start zip unzip, sourcePath:\(zipFilePath)")
                let file = try LibArchiveFile(path: zipFilePath)
                try extractArchiveFile(file: file, format: .zip, targetPath: unzipPath)
            case .none:
                LarkInlineAILogger.error("unzipBundlePkg: format unknown!")
            }
        } catch {
            LarkInlineAILogger.info("unzip fail: \(error)")
            return .failure(error)
        }
        LarkInlineAILogger.info("unzip success")
        //解压结果
        LarkInlineAILogger.info("unzip result：\(String(describing: unzipPath.fileListInDirectory()))")
        return .success(())
    }
    
    /// 解压LibArchiveFile
    private static func extractArchiveFile(file: LibArchiveFile,
                                           format: InlineAIPackageExtractor.Format,
                                           targetPath: AIFilePath) throws {
        do {
            if format == .sevenZip {
                try file.extract7z(toDir: targetPath.pathURL)
            } else {
                try file.extract(toDir: targetPath.pathURL)
            }
            let list = targetPath.fileListInDirectory() ?? []
            if list.isEmpty {
                let userInfo = [NSLocalizedDescriptionKey: "\(format) extract output dir is empty!"]
                throw NSError(domain: "com.docs.extractBundlePkg", code: -1, userInfo: userInfo)
            }
            LarkInlineAILogger.info(" finish \(format) unzip, output:\(targetPath)")
        } catch {
            LarkInlineAILogger.error("\(format) unzip fail: \(error)")
            throw error
        }
    }
    
    /// 获取zipFilePath文件的真实格式
    private static func getFileFormat(zipFilePath: String) -> InlineAIPackageExtractor.Format? {
        
        guard let handle = FileHandle(forReadingAtPath: zipFilePath) else {
            LarkInlineAILogger.error("can not create FileHandle for zipFilePath:\(zipFilePath)")
            return nil
        }
        
        for format in InlineAIPackageExtractor.Format.allCases {
            let magics = format.magicNumber
            handle.seek(toFileOffset: 0)
            let subData = handle.readData(ofLength: magics.count)
            if [UInt8](subData) == magics {
                handle.closeFile()
                LarkInlineAILogger.info("getFileFormat:\(format)")
                return format
            }
        }
        
        handle.closeFile()
        LarkInlineAILogger.error("can not recognize file FORMAT at zipFilePath:\(zipFilePath)")
        return nil
    }
}


private extension Data {
    
    /// 解压后的数据
    func decompressedDataUsingAILZMA() throws -> Data {
        guard !isEmpty else {
            throw ExtractError.sourceDataEmpty
        }
        let maxDstSize = 150_000_000 // 解压后最大为150M，兜底终止条件
        let increaseSize = 10_000_000
        var dstSize = self.count * 8 // 起始预估解压后大小为8倍
        var result = Swift.Result<Data, Error>.success(Data())
        while result.isEmpty, dstSize < maxDstSize {
            result = _processDecode(dstSize)
            if case .failure(let err) = result {
                LarkInlineAILogger.error("decompress failure: \(err)")
            }
            dstSize += increaseSize // 每次递增10M
        }
        LarkInlineAILogger.info("decompressedDataUsingAILZMA，dstSize:\(dstSize)")
        switch result {
        case .success(let data):
            guard !data.isEmpty else {
                throw ExtractError.decodedDataEmpty
            }
            return data
        case .failure(let error):
            throw error
        }
    }
    
    /// 实际解压
    /// - Parameter dstSize: 预期解压后大小(bytes)
    /// - Returns: 解压后Data
    func _processDecode(_ dstSize: Int) -> Swift.Result<Data, Error> {
        
        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstSize)
        let srcCount = self.count
        do {
            let decompressed: Data = try self.withUnsafeBytes {
                guard let srcPointer = $0.bindMemory(to: UInt8.self).baseAddress else {
                    throw ExtractError.sourceDataBaseAddressNil
                }
                let outSize = compression_decode_buffer(dstBuffer, dstSize, srcPointer, srcCount, nil, COMPRESSION_LZMA)
                guard outSize > 0 else {
                    throw ExtractError.decodedSizeIsZero
                }
                let outData = Data(bytesNoCopy: dstBuffer, count: outSize, deallocator: .free)
                if outData.isEmpty {
                    throw ExtractError.decodedDataEmpty
                }
                return outData
            }
            return .success(decompressed)
        } catch {
            return .failure(error)
        }
    }
}

private extension Swift.Result where Success == Data {
    var isEmpty: Bool {
        switch self {
        case .success(let data):
            return data.isEmpty
        case .failure:
            return true
        }
    }
}
