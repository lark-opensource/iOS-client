//
//  SandBoxFileManager.swift
//  swit_test
//
//  Created by liluobin on 2021/7/5.
//
import Foundation
#if !LARK_NO_DEBUG
import UIKit

final class SandboxFileManager: NSObject {

    static func getFileSizeForPath(_ path: String) -> Int? {
        var isDir: ObjCBool = false
        let isExist = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        if isExist, !isDir.boolValue {
            let dic = try? FileManager.default.attributesOfItem(atPath: path)
            return (dic?[FileAttributeKey.size] as? NSNumber)?.intValue
        }
        return nil
    }

    static func getFileSizeDisplayText(_ fileSize: Int?) -> String {
        guard let fileSize = fileSize, fileSize > 0 else {
            return ""
        }
        var fileSizeText = ""
        if fileSize > 1_024 * 1_024 {
            fileSizeText = String(format: "%.2fMB", Float(fileSize) / Float(1_024 * 1_024))
        } else {
            fileSizeText = String(format: "%.2fKB", Float(fileSize) / Float(1_024))
        }
        return fileSizeText
    }

}
#endif
