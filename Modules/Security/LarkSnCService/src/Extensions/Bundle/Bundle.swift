//
//  SnCFileReader.swift
//  LarkSnCService
//
//  Created by ByteDance on 2023/7/27.
//

import Foundation
import SSZipArchive

// ignoring lark storage check for snc bundle data
// lint:disable lark_storage_check

public enum FileType: String {
    case json
    case zip
}

/// 读取文件的错误
public enum SnCReadFileError: Error {
    case bundlePathNotFound
    case convertToJsonObjFailed
}

extension SnCReadFileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bundlePathNotFound:
            return "Read Bundle file failed: bundle path not found."
        case .convertToJsonObjFailed:
            return "Read Bundle file failed: convert jsonObj to dictionary failed."
        }
    }
}

extension Bundle {
    // 解压路径下的 .zip 文件，返回解压后文件的 url
    private func getUnzipUrl(forResource name: String, zipPath: String) throws -> URL {
        var unzipFileName = ""
        let progressHandler: ((String, unz_file_info, Int, Int) -> Void)? = { (fileName, _, _, _) in
            // 获取解压缩后的文件名称
            unzipFileName = fileName
        }
        var unzipError: Error?
        let completionHandler: ((String, Bool, Error?) -> Void)? = { (_, succeeded, error) in
            if !succeeded {
                unzipError = error
            }
        }
        
        let tmpDirUrl = FileManager.default.temporaryDirectory // 获取当前App的临时目录（/tmp）
        SSZipArchive.unzipFile(atPath: zipPath, toDestination: tmpDirUrl.path, progressHandler: progressHandler, completionHandler: completionHandler) // 解压后会覆盖掉旧的文件
        
        if let error = unzipError {
            throw error
        }
        return tmpDirUrl.appendingPathComponent(unzipFileName)
    }
    
    // 读取（zip/json）文件返回 Data
    public func readFileToData(forResource name: String, ofType ext: FileType) throws -> Data {
        guard let path = path(forResource: name, ofType: ext.rawValue) else {
            throw SnCReadFileError.bundlePathNotFound
        }
        
        var url: URL
        switch ext {
        case .json:
            url = URL(fileURLWithPath: path)
        case .zip:
            url = try getUnzipUrl(forResource: name, zipPath: path)
        }
        // 读取内容是非加密内容，直接使用原生接口
        let data = try Data(contentsOf: url)
        return data
    }
    
    // 读取（zip/json）文件返回 Dictionary
    public func readFileToDictionary(forResource name: String, ofType ext: FileType) throws -> [String: Any] {
        let localData = try readFileToData(forResource: name, ofType: ext)
        
        let jsonObj = try JSONSerialization.jsonObject(with: localData, options: .mutableContainers)
        
        guard let dictionary = jsonObj as? [String: Any] else {
            throw SnCReadFileError.convertToJsonObjFailed
        }
        return dictionary
    }
}
