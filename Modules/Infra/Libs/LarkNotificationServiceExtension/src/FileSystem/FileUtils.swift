//
//  FileUtils.swift
//  CryptoSwift
//
//  Created by mochangxing on 2019/7/29.
//

import Foundation

public final class FileUtils {
    public class func directoryExists(_ path: String) -> Bool {
        var isDir = ObjCBool.init(false)
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    public class func fileSize(_ path: String) throws -> UInt64 {
        var size: UInt64 = 0
        if FileManager.default.fileExists(atPath: path) {
            let dict = try FileManager.default.attributesOfItem(atPath: path) as NSDictionary
            size = dict.fileSize()
        }
        return size
    }
}
