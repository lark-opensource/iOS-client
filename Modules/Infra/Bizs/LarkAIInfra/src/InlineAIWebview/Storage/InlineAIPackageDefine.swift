//
//  InlineAIPackageDefine.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/16.
//

import Foundation
import LarkStorageCore

class InlineAIPackageBussiness {
    
    static let roadsterVeriosn = "0.0.48"
    
    static let versionFileName = "current_revision"

    /// 当前roadster解压缩的文件夹路径的path
    class func roadsterSavePath() -> AIFilePath {
        return getAPath(folderName: "Roadster/unzip")
    }
    
    class func getAPath(folderName: String) -> AIFilePath {
        let location = AIFilePath.aiGlobalSandboxWithLibrary
        let dataFolderName = "\(folderName)"
        let rootPath = location.appendingRelativePath(dataFolderName)
        return rootPath
    }
    
    class func getRoadsterZipPath() -> String {
        let bundle = Bundle.resourceBundle
        let path = bundle.path(forResource: "AIModule", ofType: "7z") ?? ""
        return path
    }
    
    class func getRoadsterHtmlPath() -> URL? {
        return getAPath(folderName: "Roadster/unzip/index.html").pathURL
    }
    
    class func getRoadsterVersionPath() -> AIFilePath {
        return getAPath(folderName: "Roadster/unzip/" + versionFileName)
    }
    
    class func getCurRevisionFileContent(in folder: AIFilePath) -> String? {
        guard folder.exists else {
            LarkInlineAILogger.error("\(folder.pathString) unexists")
            return nil
        }
        var revision: String?
        let filePath = folder.appendingRelativePath(versionFileName)
        do {
            revision = try String.read(from: filePath, encoding: .utf8)
        } catch {
            LarkInlineAILogger.error("can't read content from: \(filePath.pathString)")
        }
       return revision
    }
}


extension String {
    static func read(from: AIFilePath, encoding: Encoding = .utf8) throws -> Self {
        switch from {
        case .isoPath(let path):
            return try String.read(from: path, encoding: encoding)
        }
    }
}

extension Data {

    static func read(from: AIFilePath, options: Data.ReadingOptions = []) throws -> Self {
        switch from {
        case .isoPath(let path):
            return try Data.read(from: path, options: options)
        }
    }
}
