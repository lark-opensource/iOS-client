//
//  OpenAPISettingModel.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/22.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

final class OpenAPIGetSettingResult: OpenAPIBaseResult {
    
    public let authSetting: SettingData?
    // 原先的返回类型 之后删除
    public let oldAuthSetting: [AnyHashable: Any]?

    init(with authSetting: SettingData) {
        self.authSetting = authSetting
        self.oldAuthSetting = nil
        super.init()
    }
    
    // 原先result的init 之后删除
    init(with authSetting: [AnyHashable: Any]) {
        self.oldAuthSetting = authSetting
        self.authSetting = nil
        super.init()
    }
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        var settingData: [AnyHashable : Any] = [:]
        if let authSetting = authSetting {
            settingData[Scope.userInfo.rawValue] = authSetting.userInfo.isAuth
            settingData[Scope.userLocation.rawValue] = authSetting.userLocation.isAuth
            settingData[Scope.record.rawValue] = authSetting.record.isAuth
            settingData[Scope.writePhotosAlbum.rawValue] = authSetting.writePhotosAlbum.isAuth
            settingData[Scope.clipboard.rawValue] = authSetting.clipboard.isAuth
            settingData[Scope.runData.rawValue] = authSetting.runData.isAuth
            settingData[Scope.appBadge.rawValue] = authSetting.appBadge.isAuth
            settingData[Scope.bluetooth.rawValue] = authSetting.bluetooth.isAuth
            settingData[Scope.camera.rawValue] = authSetting.camera.isAuth
            return ["authSetting": settingData]
        }
        return ["authSetting": oldAuthSetting]
    }
}
