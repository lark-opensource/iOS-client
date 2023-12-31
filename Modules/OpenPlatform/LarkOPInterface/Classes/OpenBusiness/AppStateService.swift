//
//  AppStateService.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/6/25.
//

import Foundation
import RustPB

/// App类型
public enum AppType {
    case microApp
    case bot
    case webApp
}

public protocol AppStateService {
    
    //小程序获得应用机制数据接口
    func getMiniAppControlInfo(appID: String, callback:(RustPB.Openplatform_V1_GetMiniAppControlInfoResponse?) -> Void)
    
    //机器人获得应用机制数据接口
    func getBotControlInfo(appID: String, callback:(RustPB.Openplatform_V1_GetBotControlInfoResponse?) -> Void)
    
    //网页应用获得应用机制数据接口
    func getWebControlInfo(appID: String, callback:@escaping (RustPB.Openplatform_V1_GetH5ControlInfoResponse?) -> Void)
    
    //若无权限，展示弹窗接口
    func presentAlert(appID: String, appName: String, tips: Openplatform_V1_GuideTips, VC: UIViewController, appType: AppType, closeAppBlock: (() -> Void)?)
}
