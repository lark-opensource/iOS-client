//
//  SBUtil+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2023/8/10.
//

// 从 LarkFoundation 的 Utils+SkipBackup.swift 迁移而来

import Foundation

extension SBUtils {
    /// 给指定目录添加不同步到iCloud的属性
    @discardableResult
    static func addSkipBackupAttributeToItemAtPath(_ path: String) -> Bool {
        var url = URL(fileURLWithPath: path)

        Swift.assert(FileManager.default.fileExists(atPath: path), "File \(path) does not exist")

        var success: Bool
        do {
            var value = URLResourceValues()
            value.isExcludedFromBackup = true
            try url.setResourceValues(value)
            success = true
        } catch let error as NSError {
            success = false
            print("Error excluding \(path) from backup \(error)")
        }

        return success
    }

    /// 给Documents\Library 下所有子目录添加不同步到iCloud的属性，Cache 默认是不同步的
    public static func addSkipBackupAttributeToAllUserFile() {
        let manager = FileManager.default

        func addSkipBackupAttributeToPathSubitems(_ path: String) {
            if manager.fileExists(atPath: path) {
                do {
                    let subpaths = try manager.contentsOfDirectory(atPath: path)
                    for subpath in subpaths {
                        addSkipBackupAttributeToItemAtPath(URL(fileURLWithPath: path).appendingPathComponent(subpath).path)
                    }
                } catch let error {
                    print("Error get \(path) content \(error)")
                }
            }
        }

        // Documents\Library; Cache 默认是不同步的
        let ignoreKeys: [FileManager.SearchPathDirectory] = [.documentDirectory, .libraryDirectory]
        for key in ignoreKeys {
            if let path = NSSearchPathForDirectoriesInDomains(key, .userDomainMask, true).first {
                addSkipBackupAttributeToPathSubitems(path)
            }
        }
    }
}

public extension SBUtils {
    private static let disableAssertKey = "lark_storage.sandbox.disable_assert"

    static func disableSwiftAssert() {
        #if DEBUG
        Thread.current.threadDictionary[disableAssertKey] = true
        #endif
    }

    static func enableSwiftAssert() {
        #if DEBUG
        Thread.current.threadDictionary[disableAssertKey] = false
        #endif
    }

    internal static var isSwiftAssertDisabled: Bool {
        #if DEBUG
        return (Thread.current.threadDictionary[disableAssertKey] as? Bool) ?? false
        #else
        return true
        #endif
    }
}
