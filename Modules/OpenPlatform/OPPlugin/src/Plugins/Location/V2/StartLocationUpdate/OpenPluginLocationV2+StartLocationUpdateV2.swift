//
//  OpenPluginLocation+StartLocation.swift
//  OPPlugin
//
//  Created by zhangxudong on 4/20/22.
//

import OPSDK
import Swinject
import OPPluginManagerAdapter
import LarkSetting
import CoreLocation
import OPFoundation
import LarkContainer
import LarkOpenAPIModel
import LarkCoreLocation
import LarkPrivacySetting
import LarkOpenPluginManager


extension OpenPluginLocationV2 {
    /// startLocationUpdate 合规版本实现
    public func startLocationUpdateV2(params: OpenAPIStartLocationUpdateParamsV2,
                                      context: OpenAPIContext,
                                      callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("startLocationUpdateV2 enter params \(params)")
        guard let uniqueID = context.uniqueID else {
            let msg = "startLocationUpdateV2 context uniqueID is nil"
            context.apiTrace.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage(msg)
            callback(.failure(error: error))
            return
        }
        /// 请求权限
        let authorizationCallback: LocationAuthorizationCallback = { [weak self] error in
            context.apiTrace.info("requestWhenInUseAuthorization")
            guard let self = self else {
                let msg = "requestWhenInUseAuthorization complete callback but self is nil"
                context.apiTrace.error(msg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage(msg)
                callback(.failure(error: error))
                return
            }
            // 定位权限请求失败
            if let error = error {
                context.apiTrace.error("requestWhenInUseAuthorization complete:\(error)")
                let opError = self.transformAuthorization(error: error, context: context)
                callback(.failure(error: opError))
                return
            }
            
            if let appEnginePlugin = BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate,
               let preloadTask = appEnginePlugin.preloadManager?.preloadTask(with: .continueLocation) as? PreloadContinueLocation,
               let preloadCache = preloadTask.fetchAndCleanCache(uniqueID: uniqueID) {
                let result = OnLocationChangeResult(location: preloadCache, locations: [preloadCache])
                context.apiTrace.info("PreloadContinueLocation hit cache \(result) appID:\(uniqueID.appID)")
                self.fireLocationChange(result: result , context: context)
            }
            
            // 创建持续定位task
            let request = self.createContinueLocationRequest(params: params)
            context.apiTrace.info("createLocationRequest  params:\(params), request:\(request)")
            let task: ContinueLocationTask
            if let aTask = self.reuseContinueLocationTask(request: request, uniqueID: uniqueID) {
                context.apiTrace.info("reuseContinueLocationTask success")
                task = aTask
            } else {
                guard let aTask = self.createContinueLocationTask(request: request, uniqueID: uniqueID, context: context) else {
                    context.apiTrace.error("createContinueLocationTask failure")
                    callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.internalError)))
                    return
                }
                task = aTask
                // 定位过程中遇到的错误
                task.locationDidFailedCallback = {[weak self] task, error in
                    //补充逻辑
                    guard let self = self else { return }
                    let errno = self.transformOnLocationChange(locationError: error)
                    self.fireOnLocationChangeError(errno, context)
                }
                // 持续定位任务更新回调
                task.locationDidUpdateCallback = { [weak self] task, larkLocation, larkLocations in
                    context.apiTrace.info("continueLocationTask taskID: \(task.taskID) locationDidUpdateCallback larkLocation\(larkLocation)")
                    guard let self = self else {
                        let msg = "continueLocationTask taskID: \(task.taskID) location DidUpdateCallback but self is nil"
                        context.apiTrace.error(msg)
                        return
                    }
                    let result = OnLocationChangeResult(location: larkLocation, locations: larkLocations)
                    context.apiTrace.info("continueLocationTask taskID: \(task.taskID) fireLocationChange larkLocation\(larkLocation) fireLocation: \(result.toJSONDict())")
                    self.fireLocationChange(result: result , context: context)

                }
                task.locationStateDidChangedCallback = { [weak self, weak task] isLocating in
                    guard let self = self, let task = task else {
                        return
                    }
                    context.apiTrace.info("continueLocationTask taskID: \(task.taskID) locationStateDidChangedCallback isLocating \(isLocating)")
                    self.updateLocationAccessStatus(isUsing: isLocating)
                }

            }
            /// 开启定位
            do {
                try task.startLocationUpdate(forToken: OPSensitivityEntryToken.openPluginLocationV2StartLocationUpdateV2.psdaToken)
                // 添加监听
                self.addAppActivityListener()
                context.apiTrace.info("continueLocationTask taskID: \(task.taskID) startLocationUpdate")
                callback(.success(data: nil))
            } catch {
                let msg = "continueLocationTask taskID: \(task.taskID) startLocationUpdate failed, error is \(error)"
                assertionFailure(msg)
                context.apiTrace.error(msg)
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("user cancel")
                callback(.failure(error: apiError))

            }
        }
        
        locationAuth.requestWhenInUseAuthorization(forToken: OPSensitivityEntryToken.openPluginLocationV2StartLocationUpdateV2.psdaToken, complete: authorizationCallback)
    }

    private func createContinueLocationRequest(params: OpenAPIStartLocationUpdateParamsV2) -> ContinueLocationRequest {
        let request = ContinueLocationRequest(desiredAccuracy:  params.accuracy.coreLocationAccuracy,
                                              desiredServiceType: desiredServiceType)
        return request
    }

    private func reuseContinueLocationTask(request: ContinueLocationRequest,
                                             uniqueID: OPAppUniqueID)-> ContinueLocationTask? {
        if let task = continueLocationTask(for: uniqueID),
            task.request.desiredServiceType == request.desiredServiceType,
           request.desiredAccuracy >= task.request.desiredAccuracy {
            return task
        }
        return nil
    }

    /// 创建 持续定位任务
    private func createContinueLocationTask(request: ContinueLocationRequest,
                                            uniqueID: OPAppUniqueID,
                                            context: OpenAPIContext) -> ContinueLocationTask? {
        guard let task = try? userResolver.resolve(assert: ContinueLocationTask.self, argument: request) else {
            context.apiTrace.error("resolve ContinueLocationTask failed")
            return nil
        }
        addContinueLocationTask(task, for: uniqueID, context: context)
        return task
    }
    /// 转换定位权限错误
    private func transformAuthorization(error: LocationAuthorizationError, context: OpenAPIContext) -> OpenAPIError {
        context.apiTrace.info("start transformAuthorization error:\(error)")
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext,
                let controller = gadgetContext.controller else {
            let msg = "host controller is nil, has gadgetContext? \(context.gadgetContext != nil)"
            context.apiTrace.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
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
            self.alertUserDeniedOrLocDisable(context: context, isUserDenied: true, fromController: context.controller)
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
            if Int(Date().timeIntervalSince(startLocationUpdateToastDate)) >= gpsDisableSettings.toastDuration {
                LarkLocationAuthority.showDisableTip(on: controller.view)
                startLocationUpdateToastDate = Date()
            }
            opError = OpenAPIError(code: StartLocationUpdateErrorCode.adminDisabledGPS)
                .setErrno(OpenAPILocationErrno.adminDisabledGPS)
                .setMonitorMessage("transformAuthorization error:\(error)")
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
    /// 发送onLocationChange
    func fireLocationChange(result: OnLocationChangeResult, context: OpenAPIContext) {
        do {
            let resultData = result.toJSONDict()

            let fireEvent = try OpenAPIFireEventParams(event: "onLocationChange",
                                                       sourceID: NSNotFound,
                                                       data: resultData,
                                                       preCheckType: .shouldInterruption,
                                                       sceneType: .normal)
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            context.apiTrace.info("fire location changed success, result: \(resultData)")
        } catch {
            context.apiTrace.error("syncCall fireEvent onLocationChange error:\(error)")
        }
    }
    
    /// 转换onLocationChangeError
    func transformOnLocationChange(locationError error: LocationError) -> OpenAPILocationErrno {
        let errno: OpenAPILocationErrno
        switch error.errorCode {
        case .network:
            errno = .network
        case .authorization:
            errno = .locatingAuthorization
        default:
            errno = .locationFail
        }
        return errno
    }
    
    /// 发送onLocationChangeError
    func fireOnLocationChangeError(_ errno: OpenAPILocationErrno, _ context: OpenAPIContext) {
        do{
            let errorMessage = errno.onLocationChangeErrorToDictionary()
            let fireEvent = try OpenAPIFireEventParams(event: "onLocationChangeError",
                                                       sourceID: NSNotFound,
                                                       data: errorMessage,
                                                       preCheckType: .shouldInterruption,
                                                       sceneType: .normal)
            if case let .failure(error) = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context) {
                context.apiTrace.error("fire onLocationChangeError syncCall failed: \(error) ")
            } else {
                context.apiTrace.info("fire onLocationChangeError success, errorMessage: \(errorMessage)")
            }
        } catch {
            context.apiTrace.error("syncCall fireEvent onLocationChangeError error: \(error)")
        }
    }
    
    
}
extension OpenAPILocationErrno {
    /// onLocationChangeError To Dictionary
    func onLocationChangeErrorToDictionary() -> [AnyHashable : Any]{
        return ["errno": errno(),
                "errString": errString]
    }
}

