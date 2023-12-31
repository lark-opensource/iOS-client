//
//  OpenPluginLocation+GetLocation.swift
//  OPPlugin
//
//  Created by zhangxudong on 4/18/22.
//

import OPSDK
import Swinject
import LarkSetting
import CoreLocation
import OPFoundation
import LarkContainer
import OPPluginManagerAdapter
import LarkCoreLocation
import LarkOpenAPIModel
import LarkPrivacySetting
import LarkOpenPluginManager
extension OpenPluginLocationV2 {
    /// getLocation 合规版本实现
    public func getLocationV2(params: OpenAPIGetLocationParamsV2,
                              context: OpenAPIContext,
                              callback: @escaping (OpenAPIBaseResponse<OpenAPIGetLocationResultV2>) -> Void) {
        context.apiTrace.info("getLocationV2 enter params:\(params)")
        // 请求定位权限
        context.apiTrace.info("requestWhenInUseAuthorization")
        let callback: LocationAuthorizationCallback = { [weak self ] error in
            guard let self = self else {
                let msg = "requestWhenInUseAuthorization complete callback self is nil"
                context.apiTrace.error(msg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage(msg)
                callback(.failure(error: error))
                return
            }
            if let error = error {
                let msg = "requestWhenInUseAuthorization complete error:\(error)"
                context.apiTrace.error(msg)
                let opError = self.transformAuthorization(error: error, context: context).setMonitorMessage(msg)
                callback(.failure(error: opError))
                return
            }
            // 创建定位任务
            guard let task = self.createSingleLocationTask(params: params, trace: context.apiTrace) else {
                context.apiTrace.error("createSingleLocationTask failure")
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.internalError)))
                return
            }
            self.addSingleLocationTask(task)
            context.apiTrace.info("create SingleLocationTask taskId:\(task.taskID)")
            task.locationStateDidChangedCallback = { [weak self] isLocating in
                context.apiTrace.info("SingleLocationTask taskId:\(task.taskID) updateLocationAccessStatus: \(isLocating)")
                self?.updateLocationAccessStatus(isUsing: isLocating)
            }
            // 原逻辑中在单次定位中依然会将定位更新通知到js，不知开发者会不会有这样的依赖。为了不产生BK这里也加上此逻辑。
            task.locationDidUpdateCallback = { [weak self] task, larkLocation in
                context.apiTrace.info("singleLocationTask taskID: \(task.taskID) locationDidUpdateCallback larkLocation\(larkLocation)")
                let result = OnLocationChangeResult(location: larkLocation, locations: [larkLocation])
                context.apiTrace.info("singleLocationTask taskID: \(task.taskID) fireLocationChange larkLocation\(larkLocation) fireLocation: \(result)")
                self?.fireLocationChange(result: result , context: context)
            }

            task.locationCompleteCallback = { [weak self] aTask, result in
                guard let self = self else {
                    let msg = "singleLocationTask: taskID:\(aTask.taskID) complete callback self is nil"
                    context.apiTrace.error(msg)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage(msg)
                    callback(.failure(error: error))
                    return
                }
                defer {
                    self.deleteSingleLocationTask(task)
                }
                switch result {
                case .success(let larkLocation):
                    let result = OpenAPIGetLocationResultV2(larkLocation: larkLocation)
                    context.apiTrace.info("singleLocationTask: taskID:\(aTask.taskID) complete location:\(larkLocation) result:\(result)")
                    callback(.success(data: result))
                case .failure(let error):
                    context.apiTrace.error("singleLocationTask: taskID:\(aTask.taskID) complete error:\(error)")
                    let opError = self.transformLocation(error: error)
                    context.apiTrace.error("transformLocation error:\(error) result:\(opError)")
                    callback(.failure(error: opError))
                }
            }

            context.apiTrace.info("singleLocationTask: taskID:\(task.taskID) resume")
            do {
                // 开启定位请求
                try task.resume(forToken: OPSensitivityEntryToken.openPluginLocationV2GetLocationV2.psdaToken)
                
            } catch {
                    let msg = "singleLocationTask taskID: \(task.taskID) resume failed, error is \(error)"
                    assertionFailure(msg)
                    context.apiTrace.error(msg)
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    callback(.failure(error: apiError))

            }
        }
        
        locationAuth.requestWhenInUseAuthorization(forToken: OPSensitivityEntryToken.openPluginLocationV2GetLocationV2.psdaToken, complete: callback)
    }
    /// 创建定位task
    private func createSingleLocationTask(params: OpenAPIGetLocationParamsV2, trace: OPTrace) -> SingleLocationTask? {
        let request = SingleLocationRequest(desiredAccuracy: params.accuracy.coreLocationAccuracy,
                                            desiredServiceType: desiredServiceType,
                                            timeout: TimeInterval(params.timeout),
                                            cacheTimeout: TimeInterval(params.cacheTimeout))
        let task = try? userResolver.resolve(assert: SingleLocationTask.self, argument: request)
        if task == nil { trace.error("resolve SingleLocationTask failed") }
        return task
    }
    /// 转换定位权限请求错误
    private func transformAuthorization(error: LocationAuthorizationError, context: OpenAPIContext) -> OpenAPIError {
        context.apiTrace.info("start transformAuthorization error:\(error)")
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext,
              let controller = gadgetContext.controller else {
                  let msg = "host controller is nil, has gadgetContext? \(context.gadgetContext != nil)"
                  context.apiTrace.error(msg)
                  let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                      .setMonitorMessage(msg)
                  return error
              }
        let opError: OpenAPIError
        switch error {
        case .denied:
            // 弹出提示框
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: true, fromController: context.controller)
            opError = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                .setMonitorMessage(BDPI18n.unable_access_location)
                .setOuterMessage(BDPI18n.unable_access_location)
        case .restricted:
            // 弹出提示框
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: false, fromController: context.controller)
            opError = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                .setMonitorMessage(BDPI18n.unable_access_location)
                .setOuterMessage(BDPI18n.unable_access_location)
        case .serviceDisabled:
            // 弹出提示框
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: false, fromController: context.controller)
            opError = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                .setMonitorMessage(BDPI18n.unable_access_location)
                .setOuterMessage(BDPI18n.unable_access_location)
        case .adminDisabledGPS:
            // gps toast 频控
            if Int(Date().timeIntervalSince(getLocationGpsToastDate)) >= gpsDisableSettings.toastDuration {
                context.apiTrace.info("show admin disabled gps tip view")
                LarkLocationAuthority.showDisableTip(on: controller.view)
                startLocationUpdateToastDate = Date()
            }
            let msg = "request authorization admin disabled gps"
            opError = OpenAPIError(code: GetLocationErrorCode.adminDisabledGPS)
                .setErrno(OpenAPILocationErrno.adminDisabledGPS)
                .setMonitorMessage(msg)
        case .notDetermined:
            let msg = "request authorization should not be notDetermined"
            assertionFailure(msg)
            context.apiTrace.error(msg)
            opError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setOuterMessage(msg)
        case .psdaRestricted:
            // 被权限管控, 走errno internalError
            let monitorMessage = error.localizedDescription
            opError = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage(monitorMessage)
            context.apiTrace.error(monitorMessage, error: opError)
        @unknown default:
            let msg = "request authorization error is should not be unknown"
            assertionFailure(msg)
            context.apiTrace.error(msg)
            opError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setOuterMessage(msg)
        }
        context.apiTrace.error("transformAuthorization error:\(error) result:\(opError)")
        return opError
    }
    /// 转换定位结束遇到的错误
    private func transformLocation(error: LocationError) -> OpenAPIError {
        let opError: OpenAPIError
        switch error.errorCode {
        case .authorization:
            opError = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                .setErrno(OpenAPILocationErrno.locatingAuthorization)
        case .timeout:
            opError = OpenAPIError(code: GetLocationErrorCode.locationFail)
                .setErrno(OpenAPILocationErrno.timeout)
        case .locationUnknown:
            opError = OpenAPIError(code: GetLocationErrorCode.locationFail)
                .setErrno(OpenAPILocationErrno.locationFail)
        case .network:
            opError = OpenAPIError(code: GetLocationErrorCode.locationFail)
                .setErrno(OpenAPILocationErrno.network)
        case .unknown, .riskOfFakeLocation:
            opError = OpenAPIError(code: GetLocationErrorCode.locationFail)
                .setErrno(OpenAPILocationErrno.locationFail)
        case .psdaRestricted:
            // 被权限管控, 走errno internalError
            opError = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage(error.localizedDescription)
        @unknown default:
            opError = OpenAPIError(code: GetLocationErrorCode.locationFail)
                .setErrno(OpenAPILocationErrno.locationFail)
        }
        opError.setMonitorMessage(String(describing: error.rawError))
        return opError
    }
}

fileprivate extension OpenAPIGetLocationResultV2 {
    convenience init(larkLocation: LarkLocation) {
        let location = larkLocation.location
        let coordinate = location.coordinate
        let authorizationAccuracy: OpenAPIGetLocationResultV2.AuthorizationAccuracy
        switch larkLocation.authorizationAccuracy {
        case .unknown, .full:
            authorizationAccuracy = .full
        case .reduced:
            authorizationAccuracy = .reduced
        @unknown default:
            authorizationAccuracy = .full
        }
        self.init(latitude: coordinate.latitude,
                  longitude: coordinate.longitude,
                  altitude: location.altitude,
                  locationType: larkLocation.locationType.opLocationType,
                  accuracy: location.horizontalAccuracy,
                  verticalAccuracy: location.verticalAccuracy,
                  horizontalAccuracy: location.horizontalAccuracy,
                  time: location.timestamp,
                  authorizationAccuracy: authorizationAccuracy)
    }
}

extension OpenPluginLocationV2 {
    var desiredServiceType: LocationServiceType {
        if userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api_amap_location.disable") {
            return .apple
        }
        return .aMap
    }
}

