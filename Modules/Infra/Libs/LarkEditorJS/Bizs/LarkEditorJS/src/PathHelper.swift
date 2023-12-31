//
//  PathHelper.swift
//  LarkEditorJS
//
//  Created by tefeng liu on 2020/7/28.
//

import Foundation
import LKCommonsLogging

class PathHelper {
    static let mailCommitBranch: String = "editor-kit-m" // 请勿手动修改此行，脚本自动修改
    static let mailCommitId: String = "eed2b2380aeb685ac5ec90219c37c967b6e1e787" // 请勿手动修改此行，脚本自动修改
    static let jsVersionFileName: String = "EditorVendorJS.version"
    static let vendorJSFileName: String = "editor_kit.vendor.js"
    static let logger = Logger.log(PathHelper.self, category: "Module.LarkEditorJS")
    static let libPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last ?? ""
}

// MARK: Bundle resource path
extension PathHelper {
    enum bundle {
        static let larkEditorJSPath = libPath.appendingPathComponent("LarkEditorJS")

        static let executeFilesPath = larkEditorJSPath.appendingPathComponent("EditorVendorJS")

        static let jsFilePath = executeFilesPath.appendingPathComponent(vendorJSFileName)

        static let versionFilePath = larkEditorJSPath.appendingPathComponent(jsVersionFileName)
    }
}

// MARK: Hotpatch path
extension PathHelper {
    enum hotpatch {
        static let larkEditorJSPath = libPath.appendingPathComponent("LarkEditorJS_hotpatch")

        static let executeFilesPath = larkEditorJSPath.appendingPathComponent("EditorVendorJS")

        static let jsFilePath = executeFilesPath.appendingPathComponent(vendorJSFileName)

        static let versionFilePath = larkEditorJSPath.appendingPathComponent(jsVersionFileName)
    }
}

// MARK: action
extension PathHelper {
    static func copyFiles(_ srcFolder: String, to destFolder: String) -> Bool {

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: destFolder) {
            do {
                try fileManager.createDirectory(atPath: destFolder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch let error {
                logger.warn("larkEditorJS createDirectory failed with error :\(error)")
                return false
            }
        }

        // clean dst files
        do {
            try fileManager.removeItem(atPath: destFolder)
        } catch let error {

        }

        // replace dst files
        do {
            try fileManager.copyItem(atPath: srcFolder, toPath: destFolder)
        } catch let error {
            return false
        }

        return true
    }
}


