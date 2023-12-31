//
//  OPGadgetSchemaAdapter.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/18.
//

import Foundation
import OPFoundation
import OPSDK
import TTMicroApp
import ECOInfra

class OPGadgetSchemaAdapter {
    
    func parseSchema(url: URL, scene: Int, channel: String? = "", applinkTraceId: String? = "", extra: MiniProgramExtraParam? = nil) throws -> (OPAppUniqueID, OPGadgetContainerMountData, OPGadgetContainerConfig) {
        
        guard let schemaCodec = OPUnsafeObject(try BDPSchemaCodec.schemaCodecOptions(from: url)) else {
            throw GDMonitorCode.parse_schem_error.error()
        }
        
        var scene: OPAppScene = OPAppScene(rawValue: scene) ?? .undefined
        if scene == .undefined {
            if let sceneStr = OPUnsafeObject(schemaCodec.scene),
               let sceneInt = Int(sceneStr),
               let _scene = OPAppScene(rawValue: sceneInt) {
                scene =  _scene
            }
        }
        
        if BDPPerformanceProfileManager.sharedInstance().profileEnable{
            //真机调试 和 性能调试 在当前的判断下 会误判断为扫码，没有重新根据sslocal里的scene赋值，是一个bug
            if scene == .camera_qrcode && url.absoluteString.range(of: "isdev") != nil{
                if let sceneStr = OPUnsafeObject(schemaCodec.scene),
                   let sceneInt = Int(sceneStr),
                   let _scene = OPAppScene(rawValue: sceneInt) {
                    scene =  _scene
                }
            }
        }
        
        let fullStartPage = schemaCodec.fullStartPageDecoded
        
        let showInTemporary = extra?.showInTemporary
        let launcherFrom = extra?.launcherFrom
        
        let mountData = OPGadgetContainerMountData(
            scene: scene,
            startPage: fullStartPage,
            customFields: schemaCodec.customFields as? [String: Any],
            refererInfoDictionary: schemaCodec.refererInfoDictionary as? [String: Any],
            relaunchWhileLaunching: schemaCodec.relaunchWhileLaunching,
            channel:channel ?? "",
            applinkTraceId: applinkTraceId ?? "",
            showInTemporaray: showInTemporary,
            launcherFrom: launcherFrom
        )
        
        // 半屏模式第一期不支持iPad,参数不解析;BDPXScreenManager.isXScreenMode()方法内部依赖启动参数，此处用开关判断是否解析启动参数，增加保护
        if !BDPDeviceHelper.isPadDevice() && BDPXScreenManager.isXScreenFGConfigEnable() {
            if let XScreenMode = schemaCodec.xScreenMode, XScreenMode == "panel" {
                let XScreendata = OPGadgetXScreenMountData(presentationStyle: schemaCodec.xScreenPresentationStyle ?? "high")
                mountData.xScreenData = XScreendata
            }
        }
        
        let config = OPGadgetContainerConfig(previewToken: schemaCodec.token, enableAutoDestroy: true, wsForDebug: schemaCodec.wsForDebug, ideDisableDomainCheck: schemaCodec.ideDisableDomainCheck)
        
        let uniqueID = OPAppUniqueID(
            appID: OPSafeObject(schemaCodec.appID, ""),
            identifier: schemaCodec.identifier,
            versionType: schemaCodec.versionType,
            appType: .gadget,
            instanceID: schemaCodec.instanceID
        )
        
        return (uniqueID, mountData, config)
    }
    
    static func getSchema(containerContext: OPContainerContext) throws -> (URL, BDPSchema) {
        
        let scene = containerContext.currentMountData?.scene ?? .undefined
        
        let schemaCodecOptions = BDPSchemaCodecOptions()
        schemaCodecOptions.appID = containerContext.uniqueID.appID
        schemaCodecOptions.identifier = containerContext.uniqueID.identifier
        schemaCodecOptions.instanceID = containerContext.uniqueID.instanceID
        if EMAFeatureGating.boolValue(forKey: "openplatform.web.ide_disable_domain_check") {
        schemaCodecOptions.versionType = containerContext.uniqueID.versionType
        }
        
        if let containerConfig = containerContext.containerConfig as? OPGadgetContainerConfigProtocol {
            schemaCodecOptions.token = containerConfig.previewToken
            schemaCodecOptions.wsForDebug = containerConfig.wsForDebug
            schemaCodecOptions.ideDisableDomainCheck = containerConfig.ideDisableDomainCheck
        }
        
        schemaCodecOptions.scene = String(scene.rawValue)
        
        if let currentMountData = containerContext.currentMountData as? OPGadgetContainerMountDataProtocol {
            // 这里需要注意由于目前的 fullStartPage 只能接收一个已经被正确 encode 的内容，因此需要在外部先提前完成 encode
            schemaCodecOptions.fullStartPage = currentMountData.startPage?.urlEncoded()
            schemaCodecOptions.customFields.addEntries(from: currentMountData.customFields ?? [:])
            schemaCodecOptions.refererInfoDictionary.addEntries(from: currentMountData.refererInfoDictionary ?? [:])
            
            if let XScreenMountData = currentMountData.xScreenData {
                schemaCodecOptions.xScreenMode = "panel"
                schemaCodecOptions.xScreenPresentationStyle = XScreenMountData.presentationStyle
                if let chatID = currentMountData.customFields?["chat_id"] as? String {
                    schemaCodecOptions.chatID = chatID
                }
            }
        }
        let url = try BDPSchemaCodec.schemaURL(from: schemaCodecOptions)
        
        guard OPUnsafeObject(url) != nil else {
            throw GDMonitorCode.parse_schem_error.error(message: "get schema URL from schemaCodecOptions failed. uniqueID:\(containerContext.uniqueID)")
        }
        
        let schema = try BDPSchemaCodec.schema(from: url, appType: containerContext.uniqueID.appType)
        
        guard OPUnsafeObject(schema) != nil else {
            throw GDMonitorCode.parse_schem_error.error(message: "get schema form url failed. uniqueID:\(containerContext.uniqueID), url:\(url)")
        }
        
        return (url, schema)
    }
    
}
