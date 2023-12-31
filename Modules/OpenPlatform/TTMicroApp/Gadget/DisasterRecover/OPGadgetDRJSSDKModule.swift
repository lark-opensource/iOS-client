//
//  OPGadgetDRJSSDKModule.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/21.
//

import Foundation
import OPFoundation
import LKCommonsLogging

final class OPGadgetDRJSSDKModule: OPGadgetDRSingleTaskModule {
    
    override class func getModuleName() -> String {
        return DRModuleName.JSSDK.rawValue
    }
    
    override class func getPriority() -> DRModulePriority {
        return .jssdk
    }
    
    override func startDRModule(config: OPGadgetDRConfig?) {
        self.config = config
        //清理本地JSSDK缓存（内存version标记+缓存文件）
        OPGadgetDRLog.logger.info("begin to reset local lib cache")
        BDPVersionManager.resetLocalLibCache()
        //开始初始化到预置版本
        BDPVersionManager.setupBundleVersionIfNeed(.gadget)
        //流程结束
        moduleDidFinished(self)
        //异步强制拉取线上最新JSSDK版本，不阻塞 moduleDidFinished 的调用
        //所以强制更新到线上最新版本的过程放在 moduleDidFinished 之后
        if let manager = ECOConfig.service() as? EMAConfigManager,
            let fetchServiceProvider = manager.fetchServiceProvider,
            OPGadgetDRManager.shareManager.enableJSSDKUpdateAfterDR() {
            //手动通过接口拉取一次 JSSDK 最新的配置
            fetchServiceProvider().fetchSettingsConfig(withKeys: ["jssdk"]) { result, isSuccess in
                if isSuccess {
                    do {
                        OPGadgetDRLog.logger.info("update jssdk with config result:\(result)")
                        //拿到最新的jssdk配置
                        let jssdkConfig = try result["jssdk"]?.convertToJsonObject()
                        if let appEngine = BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate,
                            let jssdkConfig = jssdkConfig {
                            appEngine.updateLibIfNeed(withConfig: jssdkConfig)
                        }
                    } catch  {
                        OPGadgetDRLog.logger.error("jssdkConfig pasrse with error:\(error)")
                    }
                } else {
                    OPGadgetDRLog.logger.warn("fetchSettingsConfig fail")
                }
            }
        }
        OPGadgetDRLog.logger.info("end to reset local lib cache")
    }
    
}
