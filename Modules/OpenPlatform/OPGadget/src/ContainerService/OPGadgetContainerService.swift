//
//  OPGadgetContainerService.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/17.
//

import Foundation
import OPSDK
import LarkUIKit
import TTMicroApp
import OPFoundation
import LarkFeatureGating
import LKCommonsLogging


class WeakWrapper<T: AnyObject> {
  weak var value : T?
  init (value: T?) {
    self.value = value
  }
}

private var _UIWindowNavigationProtocolKey: UInt8 = 0x000012    // it can be any value

public protocol UIWindowNavigationProtocol: AnyObject {
    var gadgetNavigationController: UINavigationController? { set get }
}

extension UIWindow: UIWindowNavigationProtocol {
    //小程序跳转时可提供一个navigationController作为指定导航进行push
    //为空才使用遍历window的办法查询（结局一部分通过查询导航错误的跳转问题）
    public var gadgetNavigationController: UINavigationController? {
        set {
            //WeakWrapper 弱引用封装，（VC 释放后由于weak可置为nil，避免野指针问题）
            objc_setAssociatedObject(self, &_UIWindowNavigationProtocolKey, WeakWrapper<UINavigationController>(value: newValue) , .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            let weakWrapper = objc_getAssociatedObject(self, &_UIWindowNavigationProtocolKey) as? WeakWrapper<UINavigationController>
            return weakWrapper?.value
        }
    }
}

/// Gadget 特有的容器服务
@objcMembers public final class OPGadgetContainerService: NSObject, OPContainerServiceProtocol {

    static let logger = Logger.oplog(OPContainerServiceProtocol.self, category: "OPGadgetContainerService")
    
    public let appTypeAbility: OPAppTypeAbilityProtocol = OPGadgetTypeAbility()
    
    private let schemaAdapter: OPGadgetSchemaAdapter = OPGadgetSchemaAdapter()
    
    public override init() {
        super.init()
        setup()
    }
    
    /// 初始化 ContainerService
    private func setup() {
        // 注册小程序浮窗菜单插件
        MenuPluginPool.registerPlugin(pluginContext: MenuPluginContext(plugin: GadgetMultiTaskMenuPlugin.self))
        MenuPluginPool.registerPlugin(pluginContext: MenuPluginContext(plugin: GadgetMenuMonitorMenuPlugin.self))
    }
    
    public func fastMountByPush(
        uniuqeID: OPAppUniqueID?,
        mountData: OPGadgetContainerMountData?,
        containerConfig: OPGadgetContainerConfig?,
        window: UIWindow?
    ) -> OPContainerProtocol? {
        /// 如果启用了新的容器以及新的路由策略，那么使用OPUniversalPushControllerRenderSlot插槽
        if let window = window, uniuqeID?.window == nil {
            uniuqeID?.window = window
        }
        
        if !Display.pad && mountData?.xScreenData != nil {
            let renderSlot = OPXScreenControllerRenderSlot(presentingViewController: OPNavigatorHelper.topMostVC(window: UIApplication.shared.keyWindow)!, defaultHidden: false)
            return fastMount(uniuqeID: uniuqeID, mountData: mountData, containerConfig: containerConfig, renderSlot: renderSlot)
        }
        
        let renderSlot = OPUniversalPushControllerRenderSlot(window: window ?? OPWindowHelper.fincMainSceneWindow(), defaultHidden: false)
        return fastMount(uniuqeID: uniuqeID, mountData: mountData, containerConfig: containerConfig, renderSlot: renderSlot)
    }
    
    public func fastMount(
        uniuqeID: OPAppUniqueID?,
        mountData: OPGadgetContainerMountData?,
        containerConfig: OPGadgetContainerConfig?,
        renderSlot: OPRenderSlotProtocol
    ) -> OPContainerProtocol? {
        
        if BDPTimorClient.shared().isOpenURLEnabled() == false {
            // 小程序旧架构无法很好地支撑连续启动，会导致白屏
            return nil
        }
        
        guard let uniuqeID = uniuqeID else {
            return nil
        }
        
        let application = OPApplicationService.current.getApplication(appID: uniuqeID.appID) ?? OPApplicationService.current.createApplication(appID: uniuqeID.appID)
        
        if uniuqeID.versionType == .preview {
            // 预览版每次都要重新启动，需要先销毁旧的 preview 版本
            application.getContainer(uniqueID: uniuqeID)?.destroy(monitorCode: GDMonitorCode.preview_restart)
        }
        
        if EMAFeatureGating.boolValue(forKey: "openplatform.gadget.relaunchdowngrade") {
            if let relaunchWhileLaunching = mountData?.relaunchWhileLaunching,relaunchWhileLaunching {
                // 强制冷启动
                application.getContainer(uniqueID: uniuqeID)?.destroy(monitorCode: GDMonitorCode.query_force_cold_start)
            }
        }

        // 如果满足止血要求, 那么强制冷启动
        if let newUpdater = OPSDKConfigProvider.silenceUpdater?(.gadget), newUpdater.enableSlienceUpdate() {
            // 新产品化止血逻辑
            if let metaModel = BDPCommonManager.shared().getCommonWith(uniuqeID)?.model {
                let launchLeastAppVersion = mountData?.customFields?["least_app_version"] as? String
                if newUpdater.canSilenceUpdate(uniqueID: uniuqeID, metaAppVersion: metaModel.appVersion, launchLeastAppVersion: launchLeastAppVersion) {
                    // 强制冷启动
                    let monitorCode = OPMonitorCode(code:EPMClientOpenPlatformCommonBandageCode.mp_silence_update_cold_start)
                    application.getContainer(uniqueID: uniuqeID)?.destroy(monitorCode:monitorCode)
                }
            } else {
                // Note: 冷启动的时候会获取不到BDPModel对象.
                Self.logger.info("[GadgetSilence] can not get BDPModel with uniqueID: \(uniuqeID.fullString)")
            }
        } else {
            //原产品化止血逻辑
            if let metaModel = BDPCommonManager.shared().getCommonWith(uniuqeID)?.model {
                let launchLeastAppVersion = mountData?.customFields?["least_app_version"] as? String
                if OPPackageSilenceUpdateServer.shared.canSilenceUpdate(uniqueID: uniuqeID, metaAppVersion: metaModel.appVersion, launchLeastAppVersion: launchLeastAppVersion) {
                    // 强制冷启动
                    let monitorCode = OPMonitorCode(code:EPMClientOpenPlatformCommonBandageCode.mp_silence_update_cold_start)
                    application.getContainer(uniqueID: uniuqeID)?.destroy(monitorCode:monitorCode)
                }
            } else {
                // Note: 冷启动的时候会获取不到BDPModel对象.
                Self.logger.info("can not get BDPModel with uniqueID: \(uniuqeID.fullString)")
            }
        }
        
        let container: OPContainerProtocol
        if let _container = application.getContainer(uniqueID: uniuqeID) {
            // 热启动
            container = _container
        } else {
            // 冷启动
            container = application.createContainer(
                uniqueID: uniuqeID,
                containerConfig: containerConfig ?? OPGadgetContainerConfig(previewToken: "", enableAutoDestroy: true))
        }
        let leastVersionRemote = BDPRouteMediator.sharedManager()?.leastVersionLaunchParams(uniuqeID) ?? ""

        //解析url传入的止血配置信息;
        //优先解析'least_version'字段(对齐Android和PC);解析不到则解析'leastVersion';
        var leastVersionFromLaunch = ""
        if let _leastVersionFromLaunch = mountData?.customFields?["least_version"] as? String {
            leastVersionFromLaunch = _leastVersionFromLaunch
        } else {
            leastVersionFromLaunch = mountData?.customFields?["leastVersion"] as? String ?? ""
        }

        Self.logger.info("leastVersionFromLaunch: \(leastVersionFromLaunch), leastVersionRemote: \(leastVersionRemote)")

        //取两者之间较大的版本
        uniuqeID.leastVersion = BDPVersionManager.returnLargerVersion(leastVersionRemote, with: leastVersionFromLaunch)
        container.mount(data: mountData ?? OPGadgetContainerMountData(scene: .undefined, startPage: nil), renderSlot: renderSlot)
        
        return container
    }
    
    /// 兼容现有的 sslocal 协议，即将废弃，除了改 bug请不要再使用或扩展新能力
    public func fastMountByPush(url: URL, scene: Int, window: UIWindow?, channel:String = "", applinkTraceId: String = "", extra: MiniProgramExtraParam? = nil) -> OPContainerProtocol? {
        do {
            let (uniuqeID, mountData, containerConfig) = try schemaAdapter.parseSchema(url: url, scene: scene, channel:channel, applinkTraceId: applinkTraceId, extra: extra)
             
            return fastMountByPush(uniuqeID: uniuqeID, mountData: mountData, containerConfig: containerConfig, window: window)
            
        } catch {
            // TODO:
        }
        return nil
    }
    
    /// 兼容现有的 sslocal 协议，即将废弃，除了改 bug请不要再使用或扩展新能力（这里 renderSlot 用于支持自定义加载场景，例如iPad上showDetail启动小程序）
    public func fastMount(url: URL, scene: Int, renderSlot: OPRenderSlotProtocol) -> OPContainerProtocol? {
        do {
            let (uniuqeID, mountData, containerConfig) = try schemaAdapter.parseSchema(url: url, scene: scene)
             
            return fastMount(uniuqeID: uniuqeID, mountData: mountData, containerConfig: containerConfig, renderSlot: renderSlot)
            
        } catch {
            // TODO:
        }
        return nil
    }
    
}

extension OPApplicationService {
    public func gadgetContainerService() -> OPGadgetContainerService {
        if let containerService = containerService(for: .gadget) as? OPGadgetContainerService {
            return containerService
        }
        let containerService = OPGadgetContainerService()
        registerContainerService(for: .gadget, service: containerService)
        return containerService
    }
}
