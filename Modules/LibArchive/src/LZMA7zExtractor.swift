//
//  LZMA7zExtractor.swift
//  LibArchiveKit
//
//  Created by chensi(陈思) on 2021/10/29.
//  


import Foundation

// lint:disable lark_storage_migrate_check

/// 7zip解压工具类
final class LZMA7zExtractor {
    
    /// 解压7zip文件
    /// - Parameters:
    ///   - path: 7zip源文件路径
    ///   - targetDir: 解压目标路径
    ///   - preserveDir: 是否保留压缩包内文件目录结构
    /// - Returns: 解压后的文件路径列表
    @discardableResult
    class func extract7zArchive(path: String, targetDir: String, preserveDir: Bool) throws -> [String] {
        
        do {
            return try _extract7zArchive(path: path, targetDir: targetDir, preserveDir: preserveDir)
        } catch {
            throw error
        }
    }
}

private extension LZMA7zExtractor {
    
    class func _extract7zArchive(path: String, targetDir: String, preserveDir: Bool) throws -> [String] {
        
        ArchiveLogger.shared.assertError(!path.isEmpty, "archive path is Empty!")
        ArchiveLogger.shared.assertError(!targetDir.isEmpty, "targetDir is Empty!")
        
        var worked = false
        var isDir: ObjCBool = false
        var existsAlready = false
        
        existsAlready = FileManager.default.fileExists(atPath: targetDir, isDirectory: &isDir)
        
        // targetDir是一个已存在的文件，则删除
        if existsAlready, isDir.boolValue == false {
            do {
                try FileManager.default.removeItem(atPath: targetDir)
                worked = true
            } catch {
                worked = false
                ArchiveLogger.shared.error((error as NSError).description)
                throw error
            }
            ArchiveLogger.shared.assertError(worked, "could not remove existing file with same name as target dir")
        }
        
        // targetDir是一个已存在的目录，则删除其中的所有内容
        if existsAlready, isDir.boolValue {
            
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: targetDir)) ?? []
            
            for path in contents {
                ArchiveLogger.shared.debug("found existing dir path: \(path)")
                let myTmpDirPath = (targetDir as NSString).appendingPathComponent(path)
                do {
                    try FileManager.default.removeItem(atPath: myTmpDirPath)
                    worked = true
                } catch {
                    worked = false
                    ArchiveLogger.shared.error((error as NSError).description)
                    throw error
                }
                ArchiveLogger.shared.assertError(worked, "could not remove existing file")
            }
        } else {
            do {
                try FileManager.default.createDirectory(atPath: targetDir, withIntermediateDirectories: true)
                worked = true
            } catch {
                worked = false
                ArchiveLogger.shared.error((error as NSError).description)
                throw error
            }
            ArchiveLogger.shared.assertError(worked, "could not create tmp dir")
        }
        
        // Create dir str that has a '/' character at the end so that strcat() can be used to
        // create a path string without using Cocoa path join logic.
        
        var dirQualMStr = targetDir
        if dirQualMStr.hasSuffix("/") == false {
            dirQualMStr.append("/")
        }
        
        let archiveCachePath = generateUniqueTmpCachePath()
        ArchiveLogger.shared.debug("archiveCachePath: \(archiveCachePath)")
        let fullPaths: Int32 = preserveDir ? 1 : 0
        
        let result = do7z_extract_entry(UnsafeMutablePointer<Int8>(mutating: (path as NSString).utf8String),
                                        UnsafeMutablePointer<Int8>(mutating: (archiveCachePath as NSString).utf8String),
                                        UnsafeMutablePointer<Int8>(mutating: (dirQualMStr as NSString).utf8String),
                                        UnsafeMutablePointer<Int8>(mutating: nil), // entryNamePtr
                                        UnsafeMutablePointer<Int8>(mutating: nil), // entryPathPtr
                                        fullPaths)
        ArchiveLogger.shared.assertError(result == 0, "could not extract files from 7z archive, error:\(result)")
        
        // Examine the contents of the current directory to see what was extracted
        var fullPathContents = [String]()
        recurseIntoDirectories(fullPathContents: &fullPathContents, dirName: targetDir, entryPrefix: "")
        
        let message = "extract7z output \(fullPathContents.count) items: \(fullPathContents.joined(separator: "\n"))"
        ArchiveLogger.shared.debug(message)
        return fullPathContents
    }
    
    /// 递归遍历目录，以确定解压后各文件的完整路径
    private class func recurseIntoDirectories(fullPathContents: inout [String],
                                              dirName: String,
                                              entryPrefix: String) {
        
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: dirName)) ?? []
        ArchiveLogger.shared.assertError(!contents.isEmpty, "contentsOfDirectoryAtPath:\(dirName) failed")
        
        for path in contents {
            let fullPath = (dirName as NSString).appendingPathComponent(path)
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
            ArchiveLogger.shared.assertError(exists, "\(fullPath) not exist!")
            
            let combinedEntryPrefix: String
            if entryPrefix.isEmpty {
                combinedEntryPrefix = path
            } else {
                combinedEntryPrefix = "\(entryPrefix)/\(path)"
            }
            
            if isDirectory.boolValue {
                // Recurse into this directory and add the files in the directory
                recurseIntoDirectories(fullPathContents: &fullPathContents,
                                       dirName: fullPath,
                                       entryPrefix: combinedEntryPrefix)
            } else {
                // A plain file path, append the entry name portion of the path
                fullPathContents.append(fullPath)
            }
        }
        return
    }
    
    /// 生成唯一的临时缓存路径名
    private class func generateUniqueTmpCachePath() -> String {
        let tmpDir = NSTemporaryDirectory()
        
        let ti = NSDate().timeIntervalSinceReferenceDate
        // Format number of seconds as a string with a decimal separator
        let doubleString = String(format: "%f", ti)
        
        // Remove the decimal point so that the file name consists of numeric characters only.
        var range: NSRange
        range = NSMakeRange(0, (doubleString as NSString).length)
        let noDecimalString = (doubleString as NSString).replacingOccurrences(of: ".", with: "",
                                                                              options: .init(rawValue: 0),
                                                                              range: range)
        range = NSMakeRange(0, (noDecimalString as NSString).length)
        let noMinusString = (noDecimalString as NSString).replacingOccurrences(of: "-", with: "",
                                                                               options: .init(rawValue: 0),
                                                                               range: range)
        let filename = "\(noMinusString).cache"
        let tmpPath = (tmpDir as NSString).appendingPathComponent(filename)
        return tmpPath
    }
}

// lint:enable lark_storage_migrate_check