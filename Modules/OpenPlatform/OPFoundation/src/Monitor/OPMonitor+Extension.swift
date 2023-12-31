//
//  OPMonitor+Extension.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/12.
//

import Foundation
import ECOProbe

public extension OPMonitor {
    static let event_h5_api_error = kEventName_op_h5_api_error
    static let event_h5_webview_error = kEventName_op_h5_webview_error
    static let event_h5_launch_result = kEventName_op_h5_launch_result
    static let event_h5_share_result = kEventName_op_h5_share_result
    static let event_h5_api_auth = kEventName_op_h5_api_auth

    /// TODO: 即将删除，请调用 setUniqueID
    func setAppID(_ appID: String) -> OPMonitor {
        addCategoryValue(kEventKey_app_id, appID)
    }

    /// TODO: 即将删除，请调用 setUniqueID
    func setCardID(_ cardID: String) -> OPMonitor {
        addCategoryValue(kEventKey_card_id, cardID)
    }

    /// TODO: 即将删除，请调用 setUniqueID
    /// 设置应用唯一标志符
    /// - Parameter identifier: 唯一标志符
    /// - Returns: OPMonitor
    func setIdentifier(_ identifier: String) -> OPMonitor {
        addCategoryValue(kEventKey_identifier, identifier)
    }
    
    /// TODO: 即将删除，请调用 setUniqueID
    func setAppType(_ appType: BDPType) -> OPMonitor {
        addCategoryValue(kEventKey_app_type, OPAppTypeToString(appType))
    }

    @discardableResult
    func setUniqueID(_ uniqueID: BDPUniqueID?) -> OPMonitor {
        guard let uniqueID = uniqueID else {
           return self
       }
        
        let lazyBindTraceDisable = EMAFeatureGating.boolValue(forKey: "openplatform.foundation.lazybindtrace.disable")
        if !lazyBindTraceDisable, let data = monitorEvent.data, data[OPMonitorEventKey.trace_id] == nil, let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID) {
            _ = monitorEvent.tracing()(trace)
        }

       self.monitorEvent.addFlushTask(withName: "setUniqueID") { monitor in
        guard let monitor = monitor else {
            return
        }
           _ = monitor.addCategoryValue()(kEventKey_app_id, uniqueID.appID)
           _ = monitor.addCategoryValue()(kEventKey_application_id, uniqueID.appID) // application_id和scene_type是需求要求新增的公共参数，这里的application_id是开放平台应用的唯一标识（即client_id），今后会删除app_id。具体情况: https://bytedance.feishu.cn/wiki/wikcnYAaVu1taJMtZmqS954fPjh?sheet=qNDYFb
           if uniqueID.appType == .widget {
               _ = monitor.addCategoryValue()(kEventKey_card_id, uniqueID.identifier)
           }
           _ = monitor.addCategoryValue()(kEventKey_identifier, uniqueID.identifier)
           _ = monitor.addCategoryValue()(kEventKey_app_type, OPAppTypeToString(uniqueID.appType))
           _ = monitor.addCategoryValue()(kEventKey_version_type, OPAppVersionTypeToString(uniqueID.versionType))
           // 要求 scene 为空时 传 空字符串
           _ = monitor.addCategoryValue()(kEventKey_scene_type, "") // Lark埋点公参治理，新增key： https://bytedance.feishu.cn/wiki/wikcnYAaVu1taJMtZmqS954fPjh?sheet=qNDYFb

           // 添加上下文信息（兼容现有小程序代码，有待重构优化）
           if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) {

               // 如果版本为空，设置版本
               if let appVersion = common.model.version, !appVersion.isEmpty {
                   _ = monitor.addCategoryValue()(kEventKey_app_version, appVersion)
               }
               // 通用字段中增加compileVersion
               let compileVersion = common.model.compileVersion
               if !compileVersion.isEmpty {
                   _ = monitor.addCategoryValue()(kEventKey_compile_version, compileVersion)
               }

               if let scene = common.schema.scene, !scene.isEmpty {
                   _ = monitor.addCategoryValue()(kEventKey_scene, scene)
                   _ = monitor.addCategoryValue()(kEventKey_scene_type, scene) // Lark埋点公参治理，新增key： https://bytedance.feishu.cn/wiki/wikcnYAaVu1taJMtZmqS954fPjh?sheet=qNDYFb
                   _ = monitor.addCategoryValue()(kEventKey_sub_scene, common.schema.subScene)
               }
           }
        
           if lazyBindTraceDisable, let data = monitor.data, data[OPMonitorEventKey.trace_id] == nil, let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID) {
               _ = monitor.tracing()(trace)
           }
           //需要上传 “prehandle_enable” 属性的键，和Android一致。不在所有的点里添加 prehandle_enable 数据
           let shouldReportPrehandleEnableMonitorCodes = [EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_accuracy,
                                                          EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_preupdate_start]
           let shouldReportPrehandleEnableMonitorNames = [kEventName_mp_app_launch_result,
                                                          kEventName_op_common_load_meta_result,
                                                          kEventName_op_common_meta_request_result]
           var shouldReport = false
           if let innerMonitorCode = monitor.innerMonitorCode as? EPMClientOpenPlatformGadgetPrehandleCode,
              shouldReportPrehandleEnableMonitorCodes.contains(innerMonitorCode) {
               shouldReport = true
           }else if let name = monitor.name, shouldReportPrehandleEnableMonitorNames.contains(name) {
               shouldReport = true
           }
           if(shouldReport) {
//               _ = monitor.addCategoryValue()("prehandle_enable", BDPPreloadHelper.preHandleEnable())
               _ = monitor.addCategoryValue()("prehandle_enable", OPResolveDependenceUtil.enablePrehandle())
           }
           // 添加小程序应用上下文
           if uniqueID.appType == .gadget {
               _ = monitor.addCategoryValue()(kEventKey_js_version, BDPVersionManager.localLibVersionString())
                   .addCategoryValue()(kEventKey_js_grey_hash, BDPVersionManager.localLibGreyHash())
                   .addCategoryValue()(kEventKey_net_status, OPNetStatusHelperBridge.opNetStatus)
                   .addCategoryValue()(kEventKey_evn_type, OPEnvTypeToString(OPEnvTypeHelper.envType))
           }
           if uniqueID.appType == .block {
//               _ = monitor
//                   .addCategoryValue()(kEventKey_block_id, uniqueID.blockID)
//                   .addCategoryValue()(kEventKey_block_host, uniqueID.host)
//                   .addCategoryValue()(kEventKey_use_merge_js_sdk, "1")
//                   .addCategoryValue()(kEventKey_app_version, uniqueID.packageVersion)
               _ = monitor
                   .addCategoryValue()(kEventKey_block_id, OPResolveDependenceUtil.blockID(with: uniqueID))
                   .addCategoryValue()(kEventKey_block_host, OPResolveDependenceUtil.host(with: uniqueID))
                   .addCategoryValue()(kEventKey_use_merge_js_sdk, "1")
                   .addCategoryValue()(kEventKey_app_version, OPResolveDependenceUtil.packageVersion(with: uniqueID))
           }
       }
       return self

    }
    // TO: OPMonitor+AppLoad.swift
//    public func setLoadType(_ loadType: CommonAppLoadType) -> OPMonitor {
//        addCategoryValue(kEventKey_load_type, loadType.rawValue)
//    }

    func setMethod(_ method: String) -> OPMonitor {
        addCategoryValue(kEventKey_method, method)
    }

    func addTag(_ tag: BDPTagEnum) -> OPMonitor {
        addTag(tag.rawValue)
    }
    
    // TO: OPMonitor+AppLoad.swift
//    public func setAppLoadInfo(_ context: MetaContext, _ loadType: CommonAppLoadType) -> OPMonitor {
//        addTag(.appLoad)
//            .setUniqueID(context.uniqueID)
//            .addCategoryValue(kEventKey_load_type, loadType.rawValue)
//    }
    
    func setBridgeFG() -> OPMonitor {
        addCategoryValue("isNewBridge", BDPSDKConfig.shared().shouldUseNewBridge)
    }
}
