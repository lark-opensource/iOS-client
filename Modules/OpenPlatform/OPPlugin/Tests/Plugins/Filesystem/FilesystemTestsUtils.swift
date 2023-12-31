//
//  FilesystemTestsUtils.swift
//  AppHost-OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/4/26.
//

import Foundation
import OPFoundation
import OPUnitTestFoundation
import LarkOpenAPIModel
import ECOInfra

public enum FileAPI: String {
    case readFile
    case writeFile
    case appendFile
    case access
    case copyFile
    case getFileInfo
    case getSavedFileList
    case mkdir
    case readdir
    case removeSavedFile
    case unlink
    case rename
    case rmdir
    case saveFile
    case stat
    case unzip
}

@available(iOS 13.0, *)
public final class FileSystemTestUtils {
    static var testUtils = OpenPluginGadgetTestUtils()

    static let multiLineString = """
                                This is a string
                                这是一个字符串
                                """
    static let base64String = "dGhpcyBpcyBhIGJhc2U2NCBzdHJpbmc="
    static let hexString = "e8bf99e698afe4b880686578e4b8b2"

    static func writeFile(str: String,
                          using encoding: FileSystemEncoding,
                          type: BDPFolderPathType = .temp,
                          ttfile:FileObject? = nil) throws -> FileObject{
        var file: FileObject
        if let ttfile = ttfile {
            file = ttfile
        }else {
            file = FileObject.generateRandomTTFile(type: type, fileExtension: "txt")
        }
        /// 写入数据
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.writeFile")
        guard let data = FileSystemUtils.decodeFileDataString(str, encoding: encoding) else{
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "data")))
        }
        try FileSystemCompatible.writeSystemData(data, to: file, context: fsContext)
        return file
    }
    
    static func writeFile(data: Data) throws -> FileObject{
        var file: FileObject = FileObject.generateRandomTTFile(type: .temp, fileExtension: "txt")
        /// 写入数据
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.writeFile")
        try FileSystemCompatible.writeSystemData(data, to: file, context: fsContext)
        return file
    }
    
    static func readFile(ttfile: FileObject) throws -> Data{
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.readFile")
        let data = try FileSystem.readFile(
            ttfile,
            position: nil,
            length: nil,
            threshold: 10 * 1024 * 1024,
            context: fsContext
        )
        return data
    }
    
    static func fileExist(ttfile: FileObject) throws -> Bool {
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.fileExist")
        return try FileSystem.fileExist(ttfile, context: fsContext)
    }
    
    static func removeFile(ttfile: FileObject?) throws{
        if let ttfile {
            let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.removeFile")
            /// 删除文件
            try FileSystem.removeFile(ttfile, context: fsContext)
        }
    }
    
    static func removeDir(ttfile: FileObject?) throws{
        if let ttfile {
            let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.removeDir")
            try FileSystem.removeDirectory(ttfile, recursive: true, context: fsContext)
        }
    }
    
    static func generateRandomString() -> String{
        let randomStr = BDPRandomString(15)
        return "\(randomStr)_test"
    }
    
    static func createDirectory(ttfile: FileObject) throws -> FileObject{
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.createDirectory")
        try FileSystem.createDirectory(ttfile, recursive: true, context: fsContext)
        return ttfile
    }
    
    static func fileSize(ttfile: FileObject) throws -> Int64?{
        let path = try Self.getSystemPath(ttfile: ttfile)
        let size = try FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size] as? NSNumber
        return size?.int64Value
    }
    
    static func getSystemPath(ttfile: FileObject) throws -> String{
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.getSystemPath")
        let path = try FileSystemCompatible.getSystemFile(from: ttfile, context: fsContext)
        return path
    }
    
    static func contentsOfDirectory(ttfile: FileObject) throws -> [String] {
        let fsContext = FileSystem.Context(uniqueId: testUtils.uniqueID, trace: nil, tag: "FileUnitTest.contentsOfDirectory")
        let contents = try FileSystem.listContents(ttfile, context: fsContext)
        return contents
    }
    
    static func getUnzipTTFile() throws -> FileObject{
        guard let path = Bundle(for: OpenPluginNetworkTests.self).path(forResource: "TestsResource", ofType: "bundle") else {
            throw OpenPluginUnitTestConfigError.getFilePathFail
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: "\(path)/test.zip"))
        return try Self.writeFile(data: data)
    }
    
}

struct FileSettings {
    struct Key {
        static let larkStorageEnable = "openplatform.filesystem.larkstorage.enable"
        static let sandboxApiConfigKey = "ecosystem_sandbox_standard_config"
        static let sandboxStandardizeEnable = "ecosystem.sandbox.standardize.enable"
    }
    
    struct Value{
        static let sandboxApiConfigValue = """
        {
            "feature_list": [
                    "unzip"
                ],
                "apply_all": false
        }
        """
    }
}
