//
//  OpenPluginLocationV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/6/22.
//
import OPSDK
import ECOInfra
import Swinject
import ECOProbe
import OPPluginManagerAdapter
import LarkSetting
import CoreLocation
import OPFoundation
import LarkContainer
import LarkOpenAPIModel
import LarkCoreLocation
import LarkLocationPicker
import LarkPrivacySetting
import LarkOpenPluginManager
import UniverseDesignDialog

final class OpenPluginLocationV2: OpenBasePlugin,
                                 UserDeniedOrLocationDisableAlert,
                                 LocationAccessStatusChange {
    
    @RealTimeFeatureGatingProvider(key: "openplatform.api.block_api_auth_free_invoke") private var blockAuthFreeInvokeEnabled: Bool
    
    /// 单次定位任务 每次调用getLocation生成一个 这里保存正在使用的定位任务
    private var singleLocationTasks: [AnyHashable : SingleLocationTask] = [:]
    /// 持续定位 这里保存正在使用的定位任务 一个应用只会生成一个
    private var continueLocationTasks: [String : ContinueTaskWithContext] = [:]
    /// 是否已经添加过小程序活动状态监听 这里用处理小程序进入后台后的持续定位服务暂停
    private var isAddAppActivityListener: Bool = false
    /// 定位认证
    @InjectedSafeLazy var locationAuth: LocationAuthorization // Global
    
    lazy var gpsDisableSettings = GPSDisableSettings(userResolver: userResolver)
    var didShowAlertEnabled: Bool = false
    var didShowAlertDenied: Bool = false

    lazy var getLocationGpsToastDate = Date.distantPast
    lazy var startLocationUpdateToastDate = Date.distantPast

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
     
        registerInstanceAsyncHandler(for: "chooseLocationV2", pluginType: Self.self,paramsType: OpenAPIBaseParams.self, resultType: OpenAPIChooseLocationResultV2.self) { (this, params, context, callback) in
            
            this.chooseLocationV2(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "openLocationV2", pluginType: Self.self, paramsType: OpenAPIOpenLocationParamsV2.self) { (this, params, context, callback) in
            
            this.openLocationV2(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "getLocationV2", pluginType: Self.self, paramsType: OpenAPIGetLocationParamsV2.self, resultType: OpenAPIGetLocationResultV2.self) { (this, params, context, callback) in
            
            if context.uniqueID?.appType == .block, !this.blockAuthFreeInvokeEnabled {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unable)))
                return
            }
            
            this.getLocationV2(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "startLocationUpdateV2", pluginType: Self.self, paramsType: OpenAPIStartLocationUpdateParamsV2.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            if context.uniqueID?.appType == .block, !this.blockAuthFreeInvokeEnabled {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unable)))
                return
            }
            
            this.startLocationUpdateV2(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: "stopLocationUpdateV2", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            if context.uniqueID?.appType == .block, !this.blockAuthFreeInvokeEnabled {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unable)))
                return
            }
            
            this.stopLocationUpdateV2(params: params, context: context, callback: callback)
        }

    }

    // MARK: - addAppActivityListener
    /// 控制显示小程序左上角的定位标记，当小程序进入后台时，持续定位暂停
    func addAppActivityListener() {
        guard !isAddAppActivityListener else { return }
        isAddAppActivityListener = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterBackground(_:)), name: NSNotification.Name(rawValue: kBDPEnterBackgroundNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterForeground(_:)), name: NSNotification.Name(rawValue: kBDPEnterForegroundNotification), object: nil)
    }

    @objc
    private func handleAppEnterBackground(_ notify: Notification) {
        if let uniqueID = notify.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID,
           let task = continueLocationTask(for: uniqueID) {
            task.stopLocationUpdate()
        }
    }

    @objc
    private func handleAppEnterForeground(_ notify: Notification) {
        if let uniqueID = notify.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID,
           let task = continueLocationTask(for: uniqueID) {
           ///加入 后台定位鉴权错误透传 逻辑
            do {
                try task.startLocationUpdate(forToken: OPSensitivityEntryToken.openPluginLocationV2HandleAppEnterForeground.psdaToken)
            } catch {
                guard let context = continueLocationContext(for: uniqueID) else {
                    return
                }
                let errno = OpenAPILocationErrno.locatingAuthorization
                fireOnLocationChangeError(errno, context)
            }
            
        }
    }
}

private struct ContinueTaskWithContext {
    let continueTask: ContinueLocationTask
    let continueContext: OpenAPIContext
}

// MARK: - LarkCoreLocation tasks
extension OpenPluginLocationV2 {
    func addSingleLocationTask(_ task: SingleLocationTask) {
        singleLocationTasks[task.taskID] = task
    }

    func deleteSingleLocationTask(_ task: SingleLocationTask) {
        singleLocationTasks.removeValue(forKey: task.taskID)
    }

    func continueLocationTask(for key: OPAppUniqueID) -> ContinueLocationTask? {
        continueLocationTasks[key.fullString]?.continueTask
    }
    func continueLocationContext(for key: OPAppUniqueID) -> OpenAPIContext? {
        continueLocationTasks[key.fullString]?.continueContext
    }
    
    func addContinueLocationTask(_ task: ContinueLocationTask, for key: OPAppUniqueID, context: OpenAPIContext) {
        continueLocationTasks[key.fullString] = ContinueTaskWithContext(continueTask: task, continueContext: context)
    }
    
    func deleteContinueLocationTask(for key: OPAppUniqueID) {
        continueLocationTasks.removeValue(forKey: key.fullString)
    }
}
