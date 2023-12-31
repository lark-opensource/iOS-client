//
//  VideoEditorScanManager.swift
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/10/10.
//

import UIKit
import Foundation
import TTVideoEditor
import LKCommonsLogging
import LarkFoundation
import LKCommonsTracker
import ThreadSafeDataStructure

public final class VideoEditorScanManager {
    static let logger = Logger.log(VideoEditorScanManager.self, category: "VideoDirector")

    public static var shared = VideoEditorScanManager()

    private static let textDetectParam: VESceneDetectParam = {
        let param = VESceneDetectParam()
        param.sceneDetectType = .TEXT
        if let jsonPath = BundleConfig.LarkVideoDirectorBundle.path(
            forResource: SceneAlgorithmConfig,
            ofType: SceneAlgorithmConfigExtension),
           // lint:disable:next lark_storage_check
           let configStr = try? NSString(contentsOfFile: jsonPath, encoding: NSUTF8StringEncoding) {
            param.algorithmConfigJson = configStr as String
        }
        return param
    }()

    private let scanQueue = {
        let queue = OperationQueue()
        queue.name = "lvd.ve.scan.text"
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .default
        return queue
    }()

    private var resourceFinder: ve_resource_finder?

    init() {
        self.loadResourceFinderIfNeeded()
    }

    public func scan(image: UIImage, callback: @escaping (Bool) -> Void) {
        self.loadResourceFinderIfNeeded()
        guard let resourceFinder else {
            Self.logger.error("resourceFinder didn't set")
            callback(false)
            return
        }
        IESMMParamModule.setResourceFinder(resourceFinder)
        scanQueue.addOperation {
            let result = VEScan.scanSceneDetect(image, param: Self.textDetectParam)
            Self.logger.info("get result from scanSceneDetect: \(result.error) \(result.prob) \(result.type.rawValue)")
            DispatchQueue.main.async {
                let probThreshold: Float = 0.5
                if result.type == .TEXT, result.prob > probThreshold {
                    callback(true)
                } else {
                    callback(false)
                }
            }
        }
    }

    private func loadResourceFinderIfNeeded() {
        guard self.resourceFinder == nil else {
            return
        }
        #if VideoDirectorKAResource
        Self.logger.info("loadResourceFinderIfNeeded for KA")
        resourceFinder = { _, _, _ in
            if let path = BundleConfig.LarkVideoDirectorKABundle.path(
                forResource: SceneAlgorithmModel,
                ofType: SceneAlgorithmModelExtension) {
                VideoEditorScanManager.logger.info("find resource path: \(path)")
                let count = path.utf8CString.count
                let result: UnsafeMutableBufferPointer<Int8> = UnsafeMutableBufferPointer<Int8>.allocate(capacity: count)
                _ = result.initialize(from: path.utf8CString)
                return result.baseAddress
            }
            VideoEditorScanManager.logger.error("failed to find resource path in KA bundle")
            return nil
        }
        #else
        Self.logger.info("loadResourceFinderIfNeeded for Sass")
        ResourceManager.fetchResource(for: .ocr) { [weak self] path in
            guard let self = self else {
                return
            }

            if let path {
                if self.resourceFinder == nil {
                    Self.logger.info("load path success: \(path)")
                    self.resourceFinder = { _, _, _ in
                        // 这里重新获取一遍是因为，这个 C 闭包无法捕获外界变量
                        guard let path = ResourceManager.localCache(for: .ocr) else {
                            VideoEditorScanManager.logger.error("unexpected to find resource path inside load path callback")
                            return nil
                        }
                        let count = path.utf8CString.count
                        let result: UnsafeMutableBufferPointer<Int8> = UnsafeMutableBufferPointer<Int8>.allocate(capacity: count)
                        _ = result.initialize(from: path.utf8CString)
                        return result.baseAddress
                    }
                }
            } else {
                Self.logger.error("load path is null")
            }
            ScanResourceManagerLegacy.removeRedundantBackupFileIfNeeded() // 7.5 引入，10 个版本后可删除
        }
        #endif
    }
}

import LarkStorage
private enum ScanResourceManagerLegacy {

    static let logger = Logger.log(ScanResourceManagerLegacy.self)

    static func removeRedundantBackupFileIfNeeded() {
        DispatchQueue.global(qos: .utility).async {
            let folderPath = AbsPath.library.appendingRelativePath("OCRModel")
            if folderPath.exists {
                do {
                    try folderPath.notStrictly.removeItem()
                    logger.debug("remove backup OCR model succeeded")
                } catch {
                    logger.info("remove backup OCR model failed: \(error)")
                }
            }
        }
    }
}
