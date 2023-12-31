//
//  GeckoPackageManager+bundleExtract.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/1/7.
//  


import Foundation
import Compression
import SKFoundation
import SKResource
import LibArchiveKit
import SSZipArchive
import LarkStorage

extension BundlePackageExtractor {
    public static func unzipBundlePkg(zipFilePath: SKFilePath, to unzipPath: SKFilePath) -> Swift.Result<(), Swift.Error> {
        let result = BundlePackageExtractor.unzipBundle(zipFilePath: zipFilePath, to: unzipPath)
        switch result {
        case .success:
            GeckoLogger.info("unzip success")
            if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                //解压完成创建plist文件
                GeckoLogger.info("unzipBundlePkg - create plist：\(unzipPath)")
                let dic = GeckoPackageManager.shared.createFilePathsPlist(at: unzipPath)
                GeckoLogger.info("unzipBundlePkg - plist count：\(dic?.count ?? 0)")
            }
            //解压结果
            GeckoLogger.info("unzip result：\(String(describing: unzipPath.fileListInDirectory()))")
        case .failure(let error):
            GeckoLogger.info("unzip failed \(error)")
            GeckoPackageManager.shared.logZipRetryUnzipFail("\(error)", isUseingSSZip: false)
        }
        return result
    }
}


