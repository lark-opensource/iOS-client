//
//  InlineAIResourceManager.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/16.
//

import Foundation

final class InlineAIResourceManager {
    
    static let shared = InlineAIResourceManager()
    
    private static let unzipQueue = DispatchQueue(label: "com.inlineAI.unzipQueue")
    
    func unzipResToSandboxIfNeed() {
        // roadster压缩包
        InlineAIResourceManager.unzipQueue.async {
            self.unzipRoadsterResToSandbox(roadsterVeriosn: InlineAIPackageBussiness.roadsterVeriosn)
        }
    }
    
    private func unzipRoadsterResToSandbox(roadsterVeriosn: String) {
        let versionFolder = InlineAIPackageBussiness.roadsterSavePath()
        let revision: String? = InlineAIPackageBussiness.getCurRevisionFileContent(in: versionFolder)
        if let revisionContent = revision, revisionContent == roadsterVeriosn {
            LarkInlineAILogger.info("same version no need unzipRoadsterRes \(roadsterVeriosn)")
            return
        }
        let unzipPath = InlineAIPackageBussiness.roadsterSavePath()
        let zipFilePath = InlineAIPackageBussiness.getRoadsterZipPath()
        let firstUnzipResult = InlineAIPackageExtractor.unzipBundlePkg(zipFilePath: zipFilePath, to: unzipPath)
        let firstUnzipOkay: Bool
        var unzipError: Error?
        switch firstUnzipResult {
        case .success:
            firstUnzipOkay = true
        case .failure(let error):
            firstUnzipOkay = false
            unzipError = error
        }
        
        func _updateVersion(_ version: String ) {
            let resultPath = InlineAIPackageBussiness.getRoadsterVersionPath()
            let success = resultPath.createFileIfNeeded(with: version.data(using: .utf8))
            LarkInlineAILogger.info("create roadster version file \(success)")
        }
        
        if !firstUnzipOkay {
            LarkInlineAILogger.info("unzipRoadster fail，delete Dir:\(unzipPath)")
            do {
                try unzipPath.removeItem()
            } catch let error {
                LarkInlineAILogger.error("delete Dir fail:\(unzipPath), error: \(error)")
            }
            let retryTime = 3
            for i in 0..<retryTime {
                let unzipResult = InlineAIPackageExtractor.unzipBundlePkg(zipFilePath: zipFilePath, to: unzipPath)
                let finish: Bool
                switch unzipResult {
                case .success:
                    finish = true
                    unzipError = nil
                case .failure(let error):
                    finish = false
                    unzipError = error
                }
                LarkInlineAILogger.info("unzipRoadster retry to:\(unzipPath) success: \(finish)")
                if finish {
                    LarkInlineAILogger.info("unzipRoadster retry success")
                    _updateVersion(roadsterVeriosn)
                    break
                } else {
                    if i != retryTime - 1 {
                        do {
                            try unzipPath.removeItem()
                        } catch let error {
                            LarkInlineAILogger.error("unzipRoadster fail，delete file:\(unzipPath), error\(error)")
                        }
                    } else {
                        LarkInlineAILogger.info("unzipRoadster retry fail")
                    }
                }
            }
        } else {
            _updateVersion(roadsterVeriosn)
        }
        if let error = unzipError {
            LarkInlineAITracker.trackUnZipFail(error: error)
        }
    }
}

extension InlineAIResourceManager {
    
}
