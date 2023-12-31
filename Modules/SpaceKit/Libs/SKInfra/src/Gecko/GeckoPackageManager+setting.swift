//
//  GeckoPackageManager+setting.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/6/27.
//

import Foundation
import SKFoundation

extension GeckoPackageManager {
    
    //setting下发下去重启，重新解压资源包
    func checkResourcePkgSetting() {
        
        guard let pkgSetting = SettingConfig.resourcePkgConfig else {
            GeckoLogger.info("resourcePkgConfig is nil")
            return
        }
        
        guard pkgSetting.clearEnable == true else {
            GeckoLogger.info("resourcePkgConfig clearEnable false")
            return
        }
        
        let lastVersion = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.resourcePkgConfigVersion) ?? ""
        
        //版本不一致，下次重启清除资源包
        if pkgSetting.version != lastVersion {
            GeckoLogger.info("resourcePkgConfig clear，lastVersion：\(lastVersion), currentVersion: \(pkgSetting.version)")
            CCMKeyValue.globalUserDefault.set(pkgSetting.version, forKey: UserDefaultKeys.resourcePkgConfigVersion)
            //共用rn清除资源包的标志
            CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.needClearAllFEPkg)
        }
        
    }


    //异常情况设置，下次重启创建解压资源包
    public func clearResourcePkgIfNeed() {
        
        guard let pkgSetting = SettingConfig.resourcePkgConfig else {
            GeckoLogger.info("clearResourcePkgIfNeed resourcePkgConfig is nil")
            return
        }
        
        guard pkgSetting.recreatePkgWhenError == true else {
            GeckoLogger.info("clearResourcePkgIfNeed recreatePkgWhenError false")
            return
        }
        
        GeckoLogger.info("clearResourcePkgIfNeed recreatePkgWhenError true")
        //共用rn清除资源包的标志
        CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.needClearAllFEPkg)
        
    }
}


