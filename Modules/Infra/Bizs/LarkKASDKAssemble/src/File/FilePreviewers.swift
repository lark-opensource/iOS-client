//
//  KAFileAssembly.swift
//  LarkKASDKAssemble
//
//  Created by Supeng on 2021/12/21.
//

import Foundation
import Swinject
import LarkKASDKAssemble
import UIKit
import KAFileInterface

public enum FilePreviewers {
    public static let allPreviewers: [FilePreviewer] = {
        var allPreviewers: [FilePreviewer] = []
        if let tempClass = NSClassFromString("LarkKAFileRegistry"),
           let tabClass = tempClass as? NSObjectProtocol {
            let sel = NSSelectorFromString("registeredFilePreviewers")
            if tabClass.responds(to: sel), let result = tabClass.perform(sel).takeUnretainedValue() as? [FilePreviewer] {
                allPreviewers = result
            }
        }
        return allPreviewers
    }()

    public static func previewFilePath(_ filePath: String) -> UIViewController? {
        allPreviewers.first(where: { $0.canPreviewFileName(filePath) })?.previewFilePath(filePath)
    }

    public static func canPreviewFileName(_ fileName: String) -> Bool {
        allPreviewers.contains(where: { $0.canPreviewFileName(fileName) })
    }
}
