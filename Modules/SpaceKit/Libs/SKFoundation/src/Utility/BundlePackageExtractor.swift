//
//  BundlePackageExtractor.swift
//  SKFoundation
//
//  Created by lijuyou on 2023/11/20.
//

import Foundation
import Compression
import SKResource
import LibArchiveKit
import SSZipArchive
import LarkStorage

//前端包解压工具
public struct BundlePackageExtractor {
    public enum Format: CaseIterable {
        
        case tarXz
        
        case sevenZip
        
        case zip
        
        /// 文件扩展名
        public var fileExtension: String {
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
        // nolint: magic number
        fileprivate var magicNumber: [UInt8] {
            switch self {
            case .zip:
                return [80, 75, 3, 4]               // "50 4b 03 04" (普通zip, 非空 非分卷)
            case .sevenZip:
                return [55, 122, 188, 175, 39, 28]  // "37 7a bc af 27 1c"
            case .tarXz:
                return [253, 55, 122, 88, 90, 0]    // "fd 37 7a 58 5a 00"
            }
        }
        // enable-lint: magic number
    }
    
    private static var _format: Format?
    
    /// 前端包文件名，例如eesz.txz
    public static var packageFileName: String {
        "eesz." + (currentFormat ?? .zip).fileExtension // 使用zip作为兜底格式，与打包脚本保持一致
    }
    
    /// 前端包格式
    public static var currentFormat: Format? {
        
        if let format = _format {
            return format
        }
        
        let resource = "eesz-zip/eesz"
        // 按枚举case的顺序检测文件是否存在
        let format = Format.allCases.first(where: { item -> Bool in
            let path = I18n.resourceBundle.path(forResource: resource, ofType: item.fileExtension)
            return path != nil
        })
        if format == nil {
            spaceAssertionFailure("can not find bundle package!")
        }
        
        _format = format
        return format
    }
}


extension BundlePackageExtractor {
    
    /// 解压内置前端包
    public static func unzipBundle(zipFilePath: SKFilePath, to unzipPath: SKFilePath) -> Swift.Result<(), Swift.Error> {
        spaceAssert(Thread.isMainThread == false)
        trySweepFolder(path: unzipPath)
        let zipFilePathString = zipFilePath.pathString
        do {
            let format = getFileFormat(zipFilePath: zipFilePath)
            switch format {
            case .tarXz:
                DocsLogger.info("prepare tarXz decompress, source path:\(zipFilePathString)", component: LogComponents.fePackgeManager)
                let sourceData = try Data.read(from: zipFilePath)
                DocsLogger.info("prepare tarXz decompress, sourceData isEmpty:\(sourceData.isEmpty)", component: LogComponents.fePackgeManager)
                let decodedData = try sourceData.decompressedDataUsingLZMA()
                DocsLogger.info("prepare tarXz decompress, decodedData isEmpty:\(decodedData.isEmpty)", component: LogComponents.fePackgeManager)
                let file = try LibArchiveFile(data: decodedData)
                DocsLogger.info("begin tarXz unzip, source path:\(zipFilePathString)", component: LogComponents.fePackgeManager)
                try extractArchiveFile(file: file, format: .tarXz, targetPath: unzipPath)
            case .sevenZip:
                let file = try LibArchiveFile(path: zipFilePathString)
                DocsLogger.info("begin 7zip unzip, source path:\(zipFilePathString)", component: LogComponents.fePackgeManager)
                try extractArchiveFile(file: file, format: .sevenZip, targetPath: unzipPath)
            case .zip:
                DocsLogger.info("begin zip unzip, source path:\(zipFilePathString)", component: LogComponents.fePackgeManager)
                let file = try LibArchiveFile(path: zipFilePathString)
                try extractArchiveFile(file: file, format: .zip, targetPath: unzipPath)
            case .none:
                DocsLogger.error("unzipBundlePkg: format unknown!", component: LogComponents.fePackgeManager)
                return .failure(NSError(domain: "unzipBundlePkg: format unknown", code: -1))
            }
        } catch {
            DocsLogger.error("unzipBundlePkg exception!", error: error, component: LogComponents.fePackgeManager)
            return .failure(error)
        }
        return .success(())
    }
    
    /// 解压LibArchiveFile
    private static func extractArchiveFile(file: LibArchiveFile,
                                           format: BundlePackageExtractor.Format,
                                           targetPath: SKFilePath) throws {
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
            DocsLogger.info("\(format) extract finish, output:\(targetPath)", component: LogComponents.fePackgeManager)
        } catch {
            DocsLogger.info("\(format) extract failed", error: error, component: LogComponents.fePackgeManager)
            throw error
        }
    }
    
    @discardableResult
    private static func trySweepFolder(path: SKFilePath) -> Bool {
        //清除资源
        if path.exists {
            do {
                DocsLogger.info("remove dir:\(path)")
                try path.removeItem()
            } catch let error {
                DocsLogger.error("remove dir failed \(path)", error: error, component: LogComponents.fePackgeManager)
            }
        }
        //创建路径
        if !path.exists {
            do {
                DocsLogger.info("create dir:\(path)")
                try path.createDirectory(withIntermediateDirectories: true)
            } catch let error {
                DocsLogger.warning("create dir failed:\(path)", error: error, component: LogComponents.fePackgeManager)
                return false
            }
        }
        return true
    }
    
    /// 获取zipFilePath文件的真实格式
    private static func getFileFormat(zipFilePath: SKFilePath) -> BundlePackageExtractor.Format? {
        
        guard let handle = try? zipFilePath.fileReadingHandle() else {
            DocsLogger.error("can not create FileHandle for zipFilePath:\(zipFilePath.pathString)", component: LogComponents.fePackgeManager)
            return nil
        }
        
        for format in BundlePackageExtractor.Format.allCases {
            let magics = format.magicNumber
            handle.seek(toFileOffset: 0)
            let subData = handle.readData(ofLength: magics.count)
            if [UInt8](subData) == magics {
                handle.closeFile()
                DocsLogger.info("getFileFormat:\(format)", component: LogComponents.fePackgeManager)
                return format
            }
        }
        
        handle.closeFile()
        DocsLogger.error("can not recognize file FORMAT at zipFilePath:\(zipFilePath.pathString)", component: LogComponents.fePackgeManager)
        return nil
    }
}


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

private extension Data {
    static let maxDstSize = 350_000_000 // 解压后最大为350M，兜底终止条件
    static let stepSize = 10_000_000 // 每次递增10M
    
    /// 解压后的数据
    func decompressedDataUsingLZMA() throws -> Data {
        
        guard !isEmpty else {
            throw ExtractError.sourceDataEmpty
        }
        
        var dstSize = self.count * 8 // 起始预估解压后大小为8倍
        var result = Swift.Result<Data, Error>.success(Data())
        while result.isEmpty, dstSize < Self.maxDstSize {
            result = _processDecode(dstSize)
            if case .failure(let err) = result {
                DocsLogger.error("decompress failure: \(err)")
            }
            dstSize += Self.stepSize // 每次递增10M
        }
        if dstSize >= Self.maxDstSize {
            DocsLogger.error("decodedData too large: \(dstSize)!", component: LogComponents.fePackgeManager)
        }
        DocsLogger.info("decompressedDataUsingLZMA，dstSize:\(dstSize)", component: LogComponents.fePackgeManager)
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
