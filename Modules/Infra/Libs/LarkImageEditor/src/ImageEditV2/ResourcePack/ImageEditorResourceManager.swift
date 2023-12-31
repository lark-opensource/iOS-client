//
//  ImageEditorResourceManager.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/9.
//

import Foundation
import UniverseDesignToast
import LKCommonsLogging
import SSZipArchive
import UIKit

enum ImageEditorResourceManager {
    private static let brushFileName = "Brush2D_Simple_2"
    private static let mosaicFileName = "Brush2D_Mosiac"
    private static let mosaicGuassFileName = "Brush2D_Guass"
    private static let mosaicRectFileName = "Sticker_Rect_Mosaic"
    private static let guassRectFileName = "Sticker_Rect_Guass"
    private static let vectorGraphicsStickerFileName = "VectorGraphicsSticker"
    private static let rectVectorFileName = "Rect"
    private static let circleVectorFileName = "Ellipse"
    private static let arrowVectorFileName = "ArrowLine"
    private static let allFileNames = [Self.brushFileName, Self.mosaicFileName, Self.mosaicGuassFileName,
                                       Self.mosaicRectFileName, Self.guassRectFileName,
                                       Self.vectorGraphicsStickerFileName, Self.rectVectorFileName,
                                       Self.circleVectorFileName, Self.arrowVectorFileName]

    private static let logger = Logger.log(ImageEditorResourceManager.self, category: "LarkImageEditor")

    static let cachePath = NSTemporaryDirectory()
    static let brushResourcePath = NSTemporaryDirectory() + brushFileName
    static let mosaicResourcePath = NSTemporaryDirectory() + mosaicFileName
    static let mosaicGuassResourcePath = NSTemporaryDirectory() + mosaicGuassFileName
    static let mosaicRectResourcePath = NSTemporaryDirectory() + mosaicRectFileName
    static let mosaicGuassRectResourcePath = NSTemporaryDirectory() + guassRectFileName
    static let vectorGraphicsStickerResourcePath = NSTemporaryDirectory() + vectorGraphicsStickerFileName
    static let rectVectorResourcePath = NSTemporaryDirectory() + rectVectorFileName
    static let circleVectorResourcePath = NSTemporaryDirectory() + circleVectorFileName
    static let arrowVectorResourcePath = NSTemporaryDirectory() + arrowVectorFileName

    static func unzip(currentView: UIView) {
        let hud = UDToast.showLoading(with: "", on: currentView, disableUserInteraction: true)
        DispatchQueue.global().async {
            allFileNames.forEach {
                let zipPath = BundleConfig.LarkImageEditorBundle.bundlePath + "/" + $0 + ".zip"
                let success = SSZipArchive.unzipFile(atPath: zipPath, toDestination: NSTemporaryDirectory())
                assert(success, "unzip resource failed")
                Self.logger.info("unzip for " + zipPath + " status: " + (success ? "success! " : "fail! "))
            }
            DispatchQueue.main.async {
                hud.remove()
            }
        }
    }

    static func clean() {
        DispatchQueue.global().async {
            allFileNames.forEach {
                do {
                    try FileManager.default.removeItem(atPath: NSTemporaryDirectory() + $0)
                } catch {
                    assertionFailure("clean resource failed!")
                    Self.logger.error("clean resource failed!", error: error)
                }
            }
        }
    }
}
