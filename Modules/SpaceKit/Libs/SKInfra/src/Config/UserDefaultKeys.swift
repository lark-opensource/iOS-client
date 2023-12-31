//
//  UserDefaultKeys.swift
//  SKInfra
//
//  Created by ByteDance on 2023/4/12.
//

import Foundation

public enum UserDefaultKeys {
    private static let prefixStr = "DocsCoreDefaultPrefix"
    
    //这里看后续是否可以优化下UserDefaultKeys的实现方式，目前UserDefaultKeys拆分到各个模块自己管理，需要加个后缀区分，避免key一样重复的问题
    private static let modularSuffix = "_SKInfra"
    
    public static func generateKeyFor(major: Int, minor: Int, patch: Int, keyIndex: Int) -> String {
        let maxNumerPerDigit = 100
        let uniqueID = ((major * maxNumerPerDigit + minor) * maxNumerPerDigit + patch) * maxNumerPerDigit + keyIndex
        return UserDefaultKeys.prefixStr + "\(uniqueID)"
    }
    
    // MARK: - 3.21
    public static let geckoLauchUpdateChannels = UserDefaultKeys.generateKeyFor(major: 3, minor: 21, patch: 0, keyIndex: 4)
    
    // MARK: - 3.39
    // RN资源包加载出错时，记录下来，下次启动重置前端资源包
    public static let needClearAllFEPkg = UserDefaultKeys.generateKeyFor(major: 3, minor: 39, patch: 0, keyIndex: 2)
    
    // MARK: - 3.34
    public static let lastUnzipEESZZipVersion = UserDefaultKeys.generateKeyFor(major: 3, minor: 34, patch: 0, keyIndex: 0)
    // 是否强制使用精简包
    public static let isUseSimplePackage = UserDefaultKeys.generateKeyFor(major: 3, minor: 34, patch: 0, keyIndex: 3)
    
    // MARK: - 6.6
    //public static let docsContainerEnableProjectOptimize = UserDefaultKeys.generateKeyFor(major: 6, minor: 6, patch: 0, keyIndex: 1) + modularSuffix
    
    // MARK: - 6.8
    public static let resourcePkgConfigVersion = UserDefaultKeys.generateKeyFor(major: 6, minor: 8, patch: 0, keyIndex: 1) + modularSuffix
}
