//
//  LarkInlineAIDebugUtility.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/10/8.
//

import Foundation

/// 调试工具
#if BETA || ALPHA || DEBUG
public struct LarkInlineAIDebugUtility {
    
    public init() {}
    
    /// 手动替换roadster资源包
    /// - Parameters:
    ///   - roadsterZipURL: zip格式roadster资源包的URL，一般从"文件"app中选取
    public func replaceWith(roadsterZipURL: URL) throws {
        try unzip(roadsterZipURL: roadsterZipURL)
    }
    
    /// 恢复使用包内自带的roadster资源
    public func recoverOriginRoadsterRes() throws {
        // 删除现有目录中的资源
        let dstPath = InlineAIPackageBussiness.roadsterSavePath()
        try dstPath.removeItem()
        
        InlineAIResourceManager.shared.unzipResToSandboxIfNeed()
    }
}

extension LarkInlineAIDebugUtility {
    
    private func unzip(roadsterZipURL: URL) throws {
        // 解压
        let dstPath = InlineAIPackageBussiness.roadsterSavePath()
        let zipPath = roadsterZipURL.path
        let result = InlineAIPackageExtractor.unzipBundlePkg(zipFilePath: zipPath, to: dstPath)
        switch result {
        case .success:
            break
        case .failure(let error):
            throw error
        }
        
        // 写入版本号
        let version = InlineAIPackageBussiness.roadsterVeriosn
        let versionPath = dstPath.appendingRelativePath("/\(InlineAIPackageBussiness.versionFileName)")
        let success = versionPath.createFileIfNeeded(with: version.data(using: .utf8))
        LarkInlineAILogger.info("roadster version [\(version)], success:\(success)")
    }
}
#endif
