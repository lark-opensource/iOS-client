//
//  OPGadgetContainerMountData.swift
//  OPGadget
//
//  Created by yinyuan on 2020/11/27.
//

import Foundation
import OPSDK

@objc public protocol OPGadgetContainerMountDataProtocol: OPContainerMountDataProtocol {
        
    var scene: OPAppScene { get }
    
    /// 启动页面，可以带参数
    var startPage: String? { get }
    
    /// 小程序启动自定义参数，需要具体化
    var customFields: [String: Any]? { get }
    
    //业务数据: 小程序转跳参数.(仅供SDK内部使用)
    var refererInfoDictionary: [String: Any]? { get }
    
    var relaunchWhileLaunching: Bool { get }
    
    var fromReload: Bool { get }
    func markAsFromReload()
    func markFromReloadAsConsumed()
    
    var channel: String {get}
    
    var applinkTraceId: String {get}
    
    var xScreenData: OPGadgetXScreenMountData? {get}
}

@objcMembers public final class OPGadgetContainerMountData: NSObject, OPGadgetContainerMountDataProtocol {
    
    public private(set) var scene: OPAppScene
    
    public let startPage: String?
    
    public let customFields: [String : Any]?
    
    public let refererInfoDictionary: [String : Any]?
    
    public var relaunchWhileLaunching: Bool = false
    
    public var fromReload: Bool = false
    
    // 打开渠道: sslocal/applink，本应为枚举类型，但是涉及objc/swift相互调用，不允许string类型的枚举，所以保存原始的字符串
    public let channel: String
    
    // 用于串联applink->小程序启动的成功统计,无其他业务意义
    public let applinkTraceId: String
    
    public var xScreenData: OPGadgetXScreenMountData?
    
    // iPad标签页打开
    public private(set) var showInTemporaray: Bool?
    
    // iPad标签页打开
    public private(set) var launcherFrom: String?
    
    public required init(scene: OPAppScene, startPage: String?, customFields: [String : Any]? = nil, refererInfoDictionary: [String : Any]? = nil, relaunchWhileLaunching: Bool = false,channel: String? = "", applinkTraceId: String? = "",showInTemporaray: Bool? = nil, launcherFrom: String? = "") {
        self.scene = scene
        self.startPage = startPage
        self.customFields = customFields
        self.refererInfoDictionary = refererInfoDictionary
        self.relaunchWhileLaunching = relaunchWhileLaunching
        self.channel = channel ?? ""
        self.applinkTraceId = applinkTraceId ?? ""
        self.showInTemporaray = showInTemporaray
        self.launcherFrom = launcherFrom
    }
    
    public func markAsFromReload() {
        fromReload = true
    }
    
    public func markFromReloadAsConsumed() {
        fromReload = false
    }
    
    public func updateScene(scene: OPAppScene) {
        self.scene = scene
    }
}


@objcMembers public final class OPGadgetXScreenMountData: NSObject {
    
    public let presentationStyle: String
    
    public required init(presentationStyle: String) {
        self.presentationStyle = presentationStyle
    }
}

@objcMembers public final class MiniProgramExtraParam: NSObject {
    
    public let showInTemporary: Bool?
    public let launcherFrom: String
    
    public required init(showInTemporary: Bool?,launcherFrom: String) {
        self.showInTemporary = showInTemporary
        self.launcherFrom = launcherFrom
    }

}

