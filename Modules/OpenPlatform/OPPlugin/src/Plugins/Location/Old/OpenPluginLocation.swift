//
//  OpenPluginLocation.swift
//  OPPlugin
//
//  Created by yi on 2021/3/1.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import CoreLocation
import ECOProbe
import OPFoundation
import OPSDK
import OPPluginManagerAdapter
import TTMicroApp
import OPPluginBiz
import UniverseDesignDialog
import ECOInfra
import LarkPrivacySetting
import LarkSetting
import LarkLocationPicker
import LarkCoreLocation
import Swinject
import LarkContainer

final class OpenPluginLocation: OpenBasePlugin,
                               UserDeniedOrLocationDisableAlert,
                               LocationAccessStatusChange {
    /// 单次定位任务 每次调用getLocaiton生成一个 这里保存正在使用的定位任务
    private var singleLocationTasks: [AnyHashable : SingleLocationTask] = [:]
    /// 持续定位 这里保存正在使用的定位任务 一个应用只会生成一个
    private var continueLocationTasks: [String : ContinueLocationTask] = [:]
    /// 是否已经添加过小程序活动状态监听 这里用处理小程序进入后台后的持续定位服务暂停
    private var isAddAppActivityListener: Bool = false
    /// 定位权限相关
    @InjectedSafeLazy var locationAuth: LocationAuthorization // Global
    
    private lazy var gpsDisableSettings = GPSDisableSettings(userResolver: userResolver)
    var didShowAlertEnabled: Bool = false
    var didShowAlertDenied: Bool = false

    private var continueLocationManager: OpenPluginContinueLocationManager?
    lazy var getLocationGpsToastDate = Date.distantPast
    lazy var startLocationUpdateToastDate = Date.distantPast
    func getLocationStatus(params: OpenAPIBaseParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenPluginGetLocationStatusResponse>) -> Void) {
        OpenLocationMonitorUtils.report(apiName: "getLocationStatus", locationType: "", context: context)
        //用户权限
        guard let uniqueID = context.uniqueID,
           let permissionPlugin = BDPTimorClient.shared().permissionPlugin.sharedPlugin() as? EMAPermissionSharedService else{
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("getLocationStatus uniqueID or permissionPlugin nil")
            callback(.failure(error: error))
            return
        }
        let permissionList = permissionPlugin.getPermissionDataArray(with: uniqueID)
        let hasLocationPermission = permissionList.contains { permission in
            permission.scope == "location" && permission.isGranted
        }
        if !hasLocationPermission {
            context.apiTrace.warn("No Location Permission")
            callback(.success(data: OpenPluginGetLocationStatusResponse(gpsStatus: .off)))
            return
        }
        //  定位服务关闭，直接回调 off
        if !locationAuth.locationServicesEnabled() {
            context.apiTrace.warn("CLLocationManager locationServices is not Enabled")
            callback(.success(data: OpenPluginGetLocationStatusResponse(gpsStatus: .off)))
            return
        }
        let status = CLLocationManager.authorizationStatus()
        if status != .authorizedAlways && status != .authorizedWhenInUse {
            //  定位服务虽然打开，但是并非 AuthorizedAlways 或者 AuthorizedWhenInUse
            context.apiTrace.warn("unsupportable CLLocationManager authorizationStatus \(status)")
            callback(.success(data: OpenPluginGetLocationStatusResponse(gpsStatus: .off)))
            return
        }
        context.apiTrace.info("location status on")
        callback(.success(data: OpenPluginGetLocationStatusResponse(gpsStatus: .on)))
    }

    func chooseLocation(params: OpenPluginChooseLocationParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIChooseLocationResult>) -> Void) {
        OpenLocationMonitorUtils.report(apiName: "chooseLocation", locationType: params.type, context: context)
        guard let gadgetContext = context.gadgetContext,
              let controller = gadgetContext.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("host controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }


        context.apiTrace.info("choose \(params.type) coordinate system")

        let picker = OpenLocationPickerController()
        picker.locationPickerFinishError = { controller, error in
            context.apiTrace.error("locationPickerFinishError :\(error)")
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: apiError))
        }
        picker.locationPickerFinishSelect = { (_ controller: OpenLocationPickerController, _ data: OpenLocationModel) -> (Void) in
            context.apiTrace.info("EMALocationPickerController return user data")

            if EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyChooseLocationSupportWGS84) {
                /**
                 Note： type为用户期望返回的坐标系，gcj02的坐标只有国内才支持
                 (OPLocaionOCBridge.canConvertToGCJ02()表示是否可以将其他坐标转换成gcj02. 在这边可以用来判断是否为国内飞书.)
                 1. 国内，apple map返回gcj02,
                    1. 用户type = ‘gcj02’。 直接返回坐标
                    2. 用户type = ‘wgs84’。 将gcj02转换为wgs84后返回
                 2. 海外，apple map返回wgs84,
                    1. 用户type = ‘gcj02’。 直接返回wjs84坐标（不做转换, 国外不允许获取gcj02坐标）
                    2. 用户type = ‘wgs84’。 直接返回坐标
                 */
                if params.type == "wgs84" && OPLocaionOCBridge.canConvertToGCJ02() {
                    context.apiTrace.info("convert location to wgs84 type")
                    let wgs84Location = OPLocaionOCBridge.convertGCJ02(toWGS84: CLLocationCoordinate2D(latitude: data.location.latitude, longitude: data.location.longitude))
                    let result = OpenAPIChooseLocationResult(name: data.name, address: data.address, latitude: wgs84Location.latitude, longitude: wgs84Location.longitude)
                    callback(.success(data: result))
                    return
                }
            }

            let result = OpenAPIChooseLocationResult(name: data.name, address: data.address, latitude: data.location.latitude, longitude: data.location.longitude)
            callback(.success(data: result))
        }

        picker.locationPikcerCancelSelect = {
            (_ controller: OpenLocationPickerController) -> (Void) in
            context.apiTrace.info("EMALocationPickerController return user cancel")
            // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
            // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
            // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setOuterMessage("user cancel")
            callback(.failure(error: apiError))
        }

        let navi = UINavigationController(rootViewController: picker)
        navi.modalPresentationStyle = .overFullScreen
        navi.navigationBar.isTranslucent = false

        if let topMostAppController = OPNavigatorHelper.topMostAppController(window: controller.view.window) {
            topMostAppController.present(navi, animated: true, completion: nil)
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("topMostAppController is nil, can not push location picker")
            callback(.failure(error: error))
        }
    }

    func openLocation(params: OpenAPILocationParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        OpenLocationMonitorUtils.report(apiName: "openLocation", locationType: params.type ?? "" , context: context)
        guard let gadgetContext = context.gadgetContext,
              let controller = gadgetContext.controller else {
                  let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                      .setMonitorMessage("host controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
                  callback(.failure(error: error))
                  return
              }

        var latitude = params.latitude
        var longitude = params.longitude
        context.apiTrace.info("open \(String(describing: params.type)) type coordinate location")

        /**
         Note:这边有几种情况:
         1.国内用户传wgs84坐标; 这种情况需要将wgs84转换成gjc02坐标, 国内地图只接收gcj02坐标;
         2.国内用户传gcj02坐标; 这种情况不需要处理, 国内地图默认接收gcj02坐标;
         3.海外用户传wgs84坐标; 这种情况不需要处理, 海外地图接收wgs84坐标;
         4.海外用户传gcj02坐标; 不可能出现这样的情况, 海外无法获取到gcj02坐标;(直接报错)
         (OPLocaionOCBridge.canConvertToGCJ02()用来判断当前是否在国内;)
         因此只有情况1需要进行处理
        */
        // Lark上传gcj02. 则直接报错;(这边逻辑是双端对齐且和getLocation对齐的)
        if params.type == OPCoordinateSystemType.GCJ02.rawValue && !OPLocaionOCBridge.canConvertToGCJ02() {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("cannot use gcj02 type without amap")
            callback(.failure(error: error))
            return
        }
       
        if params.type == OPCoordinateSystemType.WGS84.rawValue,
           FeatureUtils.isAMap(),
           FeatureUtils.AMapDataAvailableForCoordinate(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        {
            context.apiTrace.info("convert locationCoordinate from wgs84 to gcj02")
            let gcj02Location = OPLocaionOCBridge.bdp_convertLocation(toGCJ02: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            latitude = gcj02Location.latitude
            longitude = gcj02Location.longitude
        }
        let locationController: UIViewController

        /*
         https://meego.feishu.cn/larksuite/story/detail/4346969
         openLocation 原使用地图 OpenViewLocationController是开放平台开发的，所以会有和主端表现不一致的问题。
         线上的OpenLocaiton API，对于 坐标系type是非必须的。
         现在主端提供的地图OpenLocationController是要传坐标系type的。
         这里和主端沟通后：主端使用坐标系类型：如果是84就用Apple地图如果是02就用高德地图
         所以我这里现在如果用户不传类型就按照84处理，主端使用Apple地图。至少是和线上愿逻辑保持一致的。
         这里的 "open_api_openlocation_use_opmap" 预防线上出现问题，好做回滚。
         此 fgkey 时间不会太长，全量后就下掉。
         此 fgkey默认是关闭状态
         */
        if userResolver.fg.dynamicFeatureGatingValue(with: "open_api_openlocation_use_opmap") {
            locationController = OpenViewLocationController(location: CLLocationCoordinate2DMake(latitude, longitude), scale: params.scale, name: params.name, address: params.address)
        } else {
            let isInternal = FeatureUtils.AMapDataAvailableForCoordinate(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            let setting = LocationSetting(
                name: params.name ?? "", // POI name
                description: params.address ?? "", // POI address
                center: CLLocationCoordinate2DMake(latitude, longitude), // location, CLLocationCoordinate2D
                zoomLevel: Double(params.scale), // map zoom level
                isCrypto: false, // 是否密聊，一般场景传入false
                isInternal: isInternal, // 坐标国内或者国外
                defaultAnnotation: true, // 是否展示默认annotation
                needRightBtn: false // 是否需要右上角发送按钮
            )
            locationController = OpenLocationController(setting: setting)
        }
        OPNavigatorHelper.push(locationController, window: controller.view.window, animated: true)
        callback(.success(data: nil))
    }
    
    func getLocation(params: OpenAPIGetLocationParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetLocationResult>) -> Void) {
        OpenLocationMonitorUtils.report(apiName: "getLocation", locationType: params.type, context: context)
        guard let controller = (context.gadgetContext)?.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("host controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }
        // https://meego.feishu.cn/larksuite/story/detail/4520991
        // lark gps 开关关闭
        guard LarkLocationAuthority.checkAuthority() else {
            // gps toast 频控
            if Int(Date().timeIntervalSince(getLocationGpsToastDate)) >= gpsDisableSettings.toastDuration {
                getLocationGpsToastDate = Date()
                LarkLocationAuthority.showDisableTip(on: controller.view)
            }
            let msg = String(format: "admin disabled gps")
            let error = OpenAPIError(code: GetLocationErrorCode.adminDisabledGPS)
                            .setMonitorMessage(msg)
            callback(.failure(error: error))
            return
        }
        guard locationAuth.locationServicesEnabled() else {
            context.apiTrace.error("system location is disable, \(String(describing: context.uniqueID)) request location failed")
            // 弹出提示框
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: false, fromController: context.controller)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                            .setMonitorMessage(BDPI18n.unable_access_location)
                            .setOuterMessage(BDPI18n.unable_access_location)
            callback(.failure(error: error))
            return
        }
        let status = CLLocationManager.authorizationStatus()
        if status == .denied {
            context.apiTrace.error("system location authorization status is Denied, \(String(describing: context.uniqueID)) request location failed")
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: true, fromController: context.controller)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                            .setMonitorMessage(BDPI18n.unable_access_location)
                            .setOuterMessage(BDPI18n.unable_access_location)
            callback(.failure(error: error))
            return;
        }
        if status == .restricted {
            context.apiTrace.error("system location authorization authorization status is Restricted, \(String(describing: context.uniqueID)) request location failed")
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: true, fromController: context.controller)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                            .setMonitorMessage(BDPI18n.unable_access_location)
                            .setOuterMessage(BDPI18n.unable_access_location)
            callback(.failure(error: error))
            return
        }
        updateLocationAccessStatus(isUsing: true)
        context.apiTrace.info("\(String(describing: context.uniqueID)) start call location service")
        reqeustLocation(params: params, context: context, gadgetContext: context.gadgetContext) { [weak self] (location, accuracy, error) in
            guard let self = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage("self is nil When call API")
                callback(.failure(error: error))
                return
            }
            if let error = error {
                if let errno = error as? OpenAPIError {
                    // 如果是 OpenAPIError, 直接抛出
                    callback(.failure(error: errno))
                    return
                }
                let msg = String(format: "host return error: %@", error.localizedDescription)
                let error = OpenAPIError(code: GetLocationErrorCode.locationFail)
                                .setMonitorMessage(msg)
                                .setOuterMessage(msg)
                callback(.failure(error: error))
                return
            }
            if let location = location {
                let data = self.dic(context: context, from: location, accuracy: accuracy)
                callback(.success(data: OpenAPIGetLocationResult(data: data)))
                self.updateLocationAccessStatus(isUsing: false)
                return
            } else {
                if !self.checkCLAuthoriztionStatus(status: CLLocationManager.authorizationStatus()) {
                    let msg = "Unable to access your location"
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                                    .setMonitorMessage(msg)
                                    .setOuterMessage(msg)
                    callback(.failure(error: error))
                    return
                } else {
                    let msg = "getLocation failed"
                    let error = OpenAPIError(code: GetLocationErrorCode.locationFail)
                                    .setMonitorMessage(msg)
                                    .setOuterMessage(msg)
                    callback(.failure(error: error))
                    return
                }
            }
        }
    }

    func startLocationUpdate(params: OpenAPILocationUpdateParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("startLocationUpdate params: <type: \(params.type), accuracy:\(params.accuracy)>")
        OpenLocationMonitorUtils.report(apiName: "startLocationUpdate", locationType: params.type, context: context)
        let uniqueID = gadgetContext.uniqueID
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        //https://meego.feishu.cn/larksuite/story/detail/4520991
        // lark gps 开关关闭
        guard LarkLocationAuthority.checkAuthority() else {
            // gps toast 频控
            if Int(Date().timeIntervalSince(startLocationUpdateToastDate)) >= gpsDisableSettings.toastDuration {
                LarkLocationAuthority.showDisableTip(on: controller.view)
                startLocationUpdateToastDate = Date()
            }
            let msg = String(format: "admin disabled gps")
            let error = OpenAPIError(code: StartLocationUpdateErrorCode.adminDisabledGPS)
                            .setMonitorMessage(msg)
            callback(.failure(error: error))
            return
        }

        guard locationAuth.locationServicesEnabled() else {
            context.apiTrace.error("system location is disable, \(uniqueID) request location failed")
            // 弹出提示框
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: false, fromController: context.controller)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny).setMonitorMessage(BDPI18n.unable_access_location).setOuterMessage(BDPI18n.unable_access_location)
            callback(.failure(error: error))
            return
        }

        let status = CLLocationManager.authorizationStatus()
        if status == .denied {
            context.apiTrace.error("authorizationStatus is Denied, \(uniqueID) request location failed")
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: true, fromController: context.controller)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny).setMonitorMessage(BDPI18n.unable_access_location).setOuterMessage(BDPI18n.unable_access_location)
            callback(.failure(error: error))
            return;
        }

        if status == .restricted {
            context.apiTrace.error("authorizationStatus is Restricted, \(uniqueID) request location failed")
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: true, fromController: context.controller)
            let error = OpenAPIError(code: StartLocationUpdateErrorCode.locationFail).setMonitorMessage(BDPI18n.unable_access_location).setOuterMessage(BDPI18n.unable_access_location)
            callback(.failure(error: error))
            return
        }
        /// log 精确位置授权信息
        let accuracyAuthorization: OPAccuracyAuthorization
        if #available(iOS 14, *) {
            accuracyAuthorization = OPAccuracyAuthorization(rawValue: CLLocationManager().accuracyAuthorization.rawValue) ?? .unknow
        } else {
            accuracyAuthorization = .unknow
        }
        context.apiTrace.info("startLocationUpdate authorizationAccuracy: \(String(describing:accuracyAuthorization))")
       

        context.apiTrace.info("\(uniqueID) start call location service")

        getContiuneLocationManager(uniqueID).startLocationUpdate(accuracy: params.accuracy,
                                                                 coordinateSystemType: params.type)
        { (location, locations, systemType) in
            do {
                var dic = location.dictionary
                let systemTypeStr = systemType.rawValue
                dic["type"] = systemTypeStr
                dic["locations"] = locations.map({ (location) -> [String:Any] in
                    var dic = location.dictionary
                    dic["type"] = systemTypeStr
                    return dic
                })
                let fireEvent = try OpenAPIFireEventParams(event: "onLocationChange",
                                                           sourceID: NSNotFound,
                                                           data: dic,
                                                           preCheckType: .shouldInterruption,
                                                           sceneType: .normal)
                let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
                context.apiTrace.info("onLocationChange callback location: <systemType : \(systemTypeStr), location: \(location), locations: \(locations)>")
            } catch {
                context.apiTrace.error("syncCall fireEvent onLocationChange error:\(error)")
            }

        } completion: { (error) in
            if let err = error {
                callback(.failure(error: err))
                context.apiTrace.error("startLocationUpdate completion with error: \(err)")
                return
            }
            context.apiTrace.info("startLocationUpdate completion success")
            callback(.success(data: nil))
        }
    }


    func stopLocationUpdate(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        OpenLocationMonitorUtils.report(apiName: "stopLocationUpdate", locationType: "", context: context)

        let uniqueID = gadgetContext.uniqueID
        getContiuneLocationManager(uniqueID).stopLocationUpdate { (error) in
            if let err = error {
                callback(.failure(error: err))
                return
            }
            callback(.success(data: nil))
        }
    }


    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "getLocationStatus", pluginType: Self.self, resultType: OpenPluginGetLocationStatusResponse.self) { (this, params, context, callback) in
            
            this.getLocationStatus(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "chooseLocation", pluginType: Self.self,paramsType: OpenPluginChooseLocationParams.self, resultType: OpenAPIChooseLocationResult.self) { (this, params, context, callback) in
            
            this.chooseLocation(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "openLocation", pluginType: Self.self, paramsType: OpenAPILocationParams.self) { (this, params, context, callback) in
            
            this.openLocation(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "getLocation", pluginType: Self.self, paramsType: OpenAPIGetLocationParams.self, resultType: OpenAPIGetLocationResult.self) { (this, params, context, callback) in
            
            this.getLocation(params: params, context: context, callback: callback)
        }


        registerInstanceAsyncHandlerGadget(for: "startLocationUpdate", pluginType: Self.self, paramsType: OpenAPILocationUpdateParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.startLocationUpdate(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "stopLocationUpdate", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.stopLocationUpdate(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

    }
}

extension OpenPluginLocation {
    private func reqeustLocation(params: OpenAPIGetLocationParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol?, completion: @escaping (_ location: CLLocation?, _ accuracyAuthorization: BDPAccuracyAuthorization, _ error: Error?) -> Void) {
        let type = params.type
        let accuracy = params.accuracy
        let baseAccuracy = getAccuracy(num: params.baseAccuracy)
        var timeout = params.timeout
        var cacheTimeout = params.cacheTimeout
        let desiredAccuracy = accuracy == "best" ? kCLLocationAccuracyBest : kCLLocationAccuracyHundredMeters
        
        var coordinateSystemType = EMACoordinateSystemTypeWGS84
        if params.type == OPLocationType.gcj02.rawValue {
            guard OPLocaionOCBridge.canConvertToGCJ02() else {
                let msg = "cannot use gcj02 type without amap"
                let error = NSError(domain: "getLocation", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
                completion(nil, .unknown, error)
                return
            }
            coordinateSystemType = EMACoordinateSystemTypeGCJ02
        }
        
        // 超时范围限制在 [3, 180]，超出范围则使用默认逻辑
        if timeout < 3 || timeout > 180 {
            if desiredAccuracy < kCLLocationAccuracyHundredMeters {
                timeout = 10   // 高精度默认10s
            } else {
                timeout = 3    // 百米精度默认3s
            }
        }
        
        //如果cacheTimeout小于0或大于60s，则不使用缓存
        if cacheTimeout < 0 || cacheTimeout > 60 {
            cacheTimeout = 0
        }
        
        context.apiTrace.info("start location with params: accuracy: { type: \(params.type), accuracy: \(params.accuracy), cacheTimeout: \(params.cacheTimeout), timeout: \(params.timeout) }")
        
        EMALocationManagerV2.sharedInstance().reqeustLocation(
            withDesiredAccuracy: desiredAccuracy,
            baseAccuracy: baseAccuracy,
            coordinateSystemType: coordinateSystemType,
            timeout: timeout,
            cacheTimeout: cacheTimeout,
            appType: OPAppTypeToString(gadgetContext?.uniqueID.appType ?? OPAppType.unknown),
            appID: gadgetContext?.uniqueID.appID
        ) { (location, locations) in
            // 构造 onLocationChange 参数
            var data = self.getDic(location: location, type: type)
            let onLocationChangeEvent = "onLocationChange"
            if let locations = locations {
                let finnalLocations = locations.map { (loc) -> [String: Any] in
                    self.getDic(location: loc, type: type)
                }
                data["locations"] = finnalLocations
            }
            if self.isAppActive(gadgetContext: gadgetContext, location: location) {
                _ = gadgetContext?.fireEvent(
                    event: onLocationChangeEvent,
                    sourceID: NSNotFound,
                    data: data
                )
            } else {
                context.apiTrace.info("onLocationChange app !isActive")
            }
        } completion: { (location, accuracyAuthorization, error) in
            completion(location, accuracyAuthorization, error)
        }
    }
    /**
     *  kCLLocationAccuracyThreeKilometers: 3000
     *  kCLLocationAccuracyKilometer: 1000
     *  kCLLocationAccuracyHundredMeters: 100
     *  kCLLocationAccuracyNearestTenMeters: 10
     *  kCLLocationAccuracyBest: -1
     *  kCLLocationAccuracyBestForNavigation: -2
     */
    private func getAccuracy(num: Int) -> CLLocationAccuracy{
        var accuracy = kCLLocationAccuracyBest
        switch num {
        case 3000:
            accuracy = kCLLocationAccuracyThreeKilometers
            break
        case 1000:
            accuracy = kCLLocationAccuracyKilometer
            break
        case 100:
            accuracy = kCLLocationAccuracyHundredMeters
            break
        case 10:
            accuracy = kCLLocationAccuracyNearestTenMeters
            break
        case -1:
            accuracy = kCLLocationAccuracyBest
            break
        case -2:
            accuracy = kCLLocationAccuracyBestForNavigation
            break
        default:
            break
        }
        return accuracy
    }
    
    /** 原 OC 代码 （旧代码删除时删除本注释）
     - (NSMutableDictionary *)getDicWithLocation:(CLLocation *)location type:(NSString *)type{
         NSMutableDictionary *data = NSMutableDictionary.dictionary;
         data[@"type"] = type;
         data[@"latitude"] = @(location.coordinate.latitude);
         data[@"longitude"] = @(location.coordinate.longitude);
         data[@"verticalAccuracy"] = @(location.verticalAccuracy);
         data[@"horizontalAccuracy"] = @(location.horizontalAccuracy);
         data[@"timestamp"] = @((int64_t)(location.timestamp.timeIntervalSince1970 * 1000));
         data[@"accuracy"] = @(MAX(location.horizontalAccuracy, location.verticalAccuracy));
         return data;
     }
     */
    private func getDic(location: CLLocation?, type: String) -> [String: Any] {
        var data: [String: Any] = [:]
        data["type"] = type
        data["latitude"] = location?.coordinate.latitude
        data["longitude"] = location?.coordinate.longitude
        data["verticalAccuracy"] = location?.verticalAccuracy
        data["horizontalAccuracy"] = location?.horizontalAccuracy
        data["timestamp"] = Int64((location?.timestamp.timeIntervalSince1970 ?? 0) * 1000)
        data["accuracy"] = max(location?.horizontalAccuracy ?? 0, location?.verticalAccuracy ?? 0)
        return data
    }
    
    /** 原 OC 代码 （旧代码删除时删除本注释）
     //  中间方法等待志友完全处理common，就换成common协议方法
     - (BOOL)isAppActiveWithEngine:(id<BDPEngineProtocol>)engine location:(CLLocation *)location {
         if ([engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
             BDPJSBridgeEngine gadgetEngine = (BDPJSBridgeEngine)engine;
             BDPTask *appTask = [[BDPTaskManager sharedManager] getTaskWithUniqueID:gadgetEngine.uniqueID];
             BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:gadgetEngine.uniqueID];
             //  如果ready并且active就进行回调
             if (appTask && common.isReady && common.isActive && location) {
                 return YES;
             } else {
                 return NO;
             }
         }
         return YES;
     }
     */
    //  中间方法等待志友完全处理common，就换成common协议方法
    private func isAppActive(gadgetContext: OPAPIContextProtocol?, location: CLLocation?) -> Bool {
        if let gadgetContext = gadgetContext {
            if BDPTaskManager.shared()?.getTaskWith(gadgetContext.uniqueID) != nil,
               let common = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID),
               common.isReady,
               common.isActive,
               location != nil {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    /** 原 OC 代码 （旧代码删除时删除本注释）
     - (NSDictionary *)dicFromLocation:(CLLocation *)location
                              accuracy:(BDPAccuracyAuthorization)accuracy {
         NSMutableDictionary *dic = NSMutableDictionary.dictionary;
         [dic setValue:@(location.coordinate.latitude) forKey:@"latitude"];
         [dic setValue:@(location.coordinate.longitude) forKey:@"longitude"];
         [dic setValue:@(location.speed) forKey:@"speed"];
         [dic setValue:@(location.altitude) forKey:@"altitude"];
         [dic setValue:@(location.horizontalAccuracy) forKey:@"accuracy"];
         [dic setValue:@(location.verticalAccuracy) forKey:@"verticalAccuracy"];
         [dic setValue:@(location.horizontalAccuracy) forKey:@"horizontalAccuracy"];
         [dic setValue:@((int64_t)(location.timestamp.timeIntervalSince1970 * 1000)) forKey:@"timestamp"];
         NSString *accuracyStr = [self getAccuracyAuthorizationString:accuracy];
         if (!BDPIsEmptyString(accuracyStr)) {
             [dic setValue:accuracyStr forKey:@"authorizationAccuracy"];
         } else {
             BDPLogError(@"Accuracy is nil.");
             NSAssert(NO, @"Location accuracy authorization is nil.");
         }
         return dic.copy;
     }
     */
    private func dic(context: OpenAPIContext, from location: CLLocation, accuracy: BDPAccuracyAuthorization) -> [String: Any] {
        var dic: [String: Any] = [:]
        dic["latitude"] = location.coordinate.latitude
        dic["longitude"] = location.coordinate.longitude
        dic["speed"] = location.speed
        dic["altitude"] = location.altitude
        dic["accuracy"] = location.horizontalAccuracy
        dic["verticalAccuracy"] = location.verticalAccuracy
        dic["horizontalAccuracy"] = location.horizontalAccuracy
        dic["timestamp"] = Int64(location.timestamp.timeIntervalSince1970 * 1000)
        let accuracyStr = getAccuracyAuthorizationString(auth: accuracy)
        if !BDPIsEmptyString(accuracyStr) {
            dic["authorizationAccuracy"] = accuracyStr
        } else {
            context.apiTrace.error("Accuracy is nil.")
            assertionFailure("Location accuracy authorization is nil.")
        }
        return dic
    }
    
    /** 原 OC 代码 （旧代码删除时删除本注释）
     // 通过枚举值匹配字符串
     - (NSString * _Nullable)getAccuracyAuthorizationString:(BDPAccuracyAuthorization)auth {
         switch (auth) {
             case BDPAccuracyAuthorizationFullAccuracy:
                 // 精确授权
                 return kAccuracyAuthorzationFull;
             case BDPAccuracyAuthorizationReducedAccuracy:
                 // 非精确授权
                 return kAccuracyAuthorzationReduced;
             case BDPAccuracyAuthorizationUnknown:
                 // unknown为精确授权
                 return kAccuracyAuthorzationFull;
             default:
                 return nil;
         }
     }
     */
    private func getAccuracyAuthorizationString(auth: BDPAccuracyAuthorization) -> String? {
        switch auth {
        case BDPAccuracyAuthorization.fullAccuracy:
            // 精确授权
            return kAccuracyAuthorzationFull
        case BDPAccuracyAuthorization.reducedAccuracy:
            // 非精确授权
            return kAccuracyAuthorzationReduced
        case BDPAccuracyAuthorization.unknown:
            // unknown为精确授权
            return kAccuracyAuthorzationFull
        default:
            return nil
        }
    }
    
    /** 原 OC 代码 （旧代码删除时删除本注释）
     - (BOOL)checkCLAuthoriztionStatus:(CLAuthorizationStatus)status {
         BOOL result = YES;
         if (status == kCLAuthorizationStatusNotDetermined || status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
             result = NO;
         }
         return result;
     }
     */
    private func checkCLAuthoriztionStatus(status: CLAuthorizationStatus) -> Bool {
        if status == CLAuthorizationStatus.notDetermined || status == CLAuthorizationStatus.restricted || status == CLAuthorizationStatus.denied {
            return false
        }
        return true
    }

    private func getContiuneLocationManager(_ uniqueID: OPAppUniqueID) -> OpenPluginContinueLocationManager {
        if let manager = continueLocationManager {
            return manager
        }
        let manager = OpenPluginContinueLocationManager(uniqueID: uniqueID)
        continueLocationManager = manager
        return manager
    }
}

fileprivate extension CLLocation {
    var dictionary: [String : Any] {
        var dic = [String : Any]()
        dic["latitude"] = self.coordinate.latitude
        dic["longitude"] = self.coordinate.longitude
        dic["verticalAccuracy"] = self.verticalAccuracy
        dic["horizontalAccuracy"] = self.horizontalAccuracy
        dic["timestamp"] = Int64(self.timestamp.timeIntervalSince1970 * 1000)
        dic["accuracy"] = max(self.horizontalAccuracy, self.verticalAccuracy)
        return dic
    }
}
