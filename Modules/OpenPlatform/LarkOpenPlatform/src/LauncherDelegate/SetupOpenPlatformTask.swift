//
//  SetupOpenPlatformTask.swift
//  LarkOpenPlatform
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkContainer
import RunloopTools
import EEMicroAppSDK
import LarkOPInterface
import AppContainer
import ECOProbe
import ECOInfra
import LKLoadable
import vmsdk
import Heimdallr
import LarkReleaseConfig
import LarkAccountInterface
import LKCommonsLogging
import LarkSetting
import LarkStorage
import LarkUIKit
import UniversalCardInterface
import EcosystemWeb
import UniversalCard
import LarkWebViewContainer

fileprivate let log = Logger.oplog(SetupOpenPlatformTask.self, category: "SetupOpenPlatformTask")

/// 主端同学 kangtao@bytedance.com 配置在afterLoginStage的阶段执行
class SetupOpenPlatformTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupOpenPlatformTask"

    override var scope: Set<BizScope> { return [.openplatform] }
    
    override class var compatibleMode: Bool { OPUserScope.compatibleModeEnabled }

    @ScopedProvider var openPlatformService: OpenPlatformService?

    override func execute(_ context: BootContext) {
        self.openPlatformService?.setup()

        // ⚠️注意，此任务被标记为 AfterLoginStage 执行，如改变执行时机，请调整 isAfterLoginStage = true 至合适时机⚠️
        let probeDependencyImpl = try? resolver.resolve(assert: OPProbeConfigDependency.self)
        probeDependencyImpl?.isAfterLoginStage = true

        let openPlatformAssembly = OpenPlatformAssembly()
        openPlatformAssembly.assembleMenuPlugin(resolver: self.userResolver)
        MessageCardStyleConfig.setup(resolver: self.userResolver)
        RunloopDispatcher.shared.addTask(identify: "MessageCardStyleManagerSetup") {
            DispatchQueue.global().async {
                MessageCardStyleManager.shared.setupLoadTask(resolver: self.userResolver)
            }
        }
        //登陆完成后，开始内置包解压的各种操作
        EMABuildinAppManager.sharedInstance.buildinPackageProcess()
        #if NativeApp
        try? userResolver.resolve(assert: NativeAppManagerInternalProtocol.self).getNativeAppGuideInfo()
        #endif
        
        setupVMSDKMonitor()
        if let passportUserService = try? userResolver.resolve(assert: PassportUserService.self) {
            OPEncryptUtils.userID = passportUserService.user.userID
        }
        
        if let deviceService = try? userResolver.resolve(assert: DeviceService.self) {
            OPEncryptUtils.deviceID = deviceService.deviceId
            OPEncryptUtils.deviceLoginID = deviceService.deviceLoginId
            if LarkWebSettings.lkwEncryptLogEnabel {
                log.info("op setup for deviceid:\(String(describing: OPEncryptUtils.deviceID)), loginid:\(String(describing: OPEncryptUtils.deviceLoginID))")
            }
        }
        
        registerMenuPlugin()

        if let module = try? userResolver.resolve(assert: UniversalCardModuleDependencyProtocol.self) {
            module.loadTemplate()
        }

    }
    
    func setupVMSDKMonitor() {
        //VMSDK monitor init
        guard FeatureGatingManager.shared.featureGatingValue(with: "openplatform.gadget.vmsdk.monitor") else {// user:global
            log.info("VMSDK Monitor is not endabled! skip")
            return
        }
        log.info("VMSDK Monitor begin setup")
        let appId = ReleaseConfig.appIdForAligned
        let versionCode = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        let updateVersionCode = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
        var channel = ReleaseConfig.channelName
        // 上传Slardar时判断逻辑,非KA上报channelName,KA上报releaseChannel
        if ReleaseConfig.isKA {
            channel = ReleaseConfig.kaChannelForAligned
        }
        if KVPublic.FG.oomDetectorOpen.value() {
            channel = "oom_test"
        }
        if KVPublic.FG.spacePerformanceDetector.value() {
            channel = "space_performance_test"
        }
        guard let deviceService = userResolver.resolve(DeviceService.self) else {
            log.error("deviceService is nil")
            return
        }
        let deviceId = deviceService.deviceId
        
        let monitorInfo = MonitorInfo("8398", deviceID: deviceId, channel: channel, hostAppID: appId, appVersion: updateVersionCode)
        VmsdkMonitor.sharedMonitorInfo(monitorInfo)?.monitorEvent("vmsdk_init", metric: nil, category: [
            "biz_name": "lark_miniapp"], extra: ["log": "vmsdk ios monitor init successfully at SetupOpenPlatformTask"])
        
        log.info("VMSDK Monitor end setup")
    }
    
    private func registerMenuPlugin() {
        // 注册网页应用头和机器人的菜单插件
        let webAppInformationContext = MenuPluginContext(
            plugin: WebAppInformationMenuPlugin.self,
            parameters: [WebAppInformationMenuPlugin.providerContextResloveKey: userResolver]
        )
        MenuPluginPool.registerPlugin(pluginContext: webAppInformationContext)
        
        /// 注册多任务插件
        let webFloatingContext = MenuPluginContext(
            plugin: WebFloatingMenuPlugin.self,
            parameters: [WebFloatingMenuPlugin.providerContextResloveKey: userResolver]
        )
        MenuPluginPool.registerPlugin(pluginContext: webFloatingContext)
    }
}
