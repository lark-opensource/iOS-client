//
//  OCRImageCacheManager.swift
//  SpaceKit
//
//  Created by maxiao on 2019/6/13.
//


import UIKit
import SKFoundation

class OCRImageCacheManager {

    static let cachePath = SKFilePath.globalSandboxWithCache
    static let imageFileDir = cachePath.appendingRelativePath("OCRCacheImage")

    class func save(imageData: Data, with fileName: String) -> SKFilePath? {
        let filePath = imageFileDir.appendingRelativePath(fileName)
        imageFileDir.createDirectoryIfNeeded()
        do {
            try imageData.write(to: filePath)
            DocsLogger.info("[SKFilePath] save OCRImage to cache success.")
        } catch {
            DocsLogger.error("[SKFilePath] save OCRImage to cache failed.")
            return nil
        }
        return filePath
    }

}
