//
//  OpenPluginHealth.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/9/16.
//  实现技术文档: https://bytedance.feishu.cn/docs/doccncrMPJpssTIO9tBswcJrbNb

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import CoreMotion
import ECOInfra
import UniverseDesignDialog
import OPFoundation
import OPPluginManagerAdapter
import LarkContainer
//import HealthKit

final class OpenPluginHealth: OpenBasePlugin {
    static let CMPermissionDenyCode = 105;

    // 已经开始查询步数信息
    var hasStartGetStepCount = false

    // 是否已经弹过去设置的弹窗
    var hasShowedOpenSettingsDialog = false

    private let pedometer = CMPedometer()

    func getStepCount(params: OpenAPIBaseParams,
                         context: OpenAPIContext,
                         callback: @escaping(OpenAPIBaseResponse<StepCountResult>) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            let error = OpenAPIError(code: GetStepCountErrorCode.notAvailable).setMonitorMessage("CMPedometer isStepCountingAvailable is false")
            callback(.failure(error: error))
            return
        }

        let authStatus = CMPedometer.authorizationStatus()

        if authStatus == .restricted || authStatus == .denied {
            showOpenSettingsDialog(context: context, fromController: context.controller)
            let errorMsg = authStatus == .restricted ? "restricted" : "denied"
            context.apiTrace.error(errorMsg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
            callback(.failure(error: error))
            return
        }

        if hasStartGetStepCount {
            context.apiTrace.error("get stepCount is already started")
            let error = OpenAPIError(code: GetStepCountErrorCode.alreadyStart)
            callback(.failure(error: error))
            return
        }

        hasStartGetStepCount = true

        let now = Date()
        let startDate = Calendar.current.startOfDay(for: now)

        //查询步数
        pedometer.queryPedometerData(from: startDate, to: now) {[weak self] pedometerData, error in
            self?.hasStartGetStepCount = false
            if let error = error {
                context.apiTrace.error("CMPedometer queryPedometerData failed: \(error)")
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                return
            }

            guard let stepCount = pedometerData?.numberOfSteps.intValue else {
                context.apiTrace.error("numberOfSteps from pedometerData is nil")
                let error = OpenAPIError(code: GetStepCountErrorCode.notAvailable)
                callback(.failure(error: error))
                return
            }
            callback(.success(data: StepCountResult(stepCount: stepCount)))
        }
    }

    // 提示用户去设置中开启权限(会切换到主线程进行弹窗)
    func showOpenSettingsDialog(context: OpenAPIContext, fromController: UIViewController?) {
        if hasShowedOpenSettingsDialog {
            context.apiTrace.info("has showed open setting Dialog before")
            return
        }

        hasShowedOpenSettingsDialog = true
        BDPExecuteOnMainQueue {
            let title = BDPI18n.permissions_no_access
            let appName = OPSafeObject(BDPSandBoxHelper.appDisplayName(), "")
            let description = String(format: BDPI18n.littleApp_StepsApi_PermissionRequestIos, appName)
            let dialog = UDDialog()
            dialog.setTitle(text: title ?? "")
            dialog.setContent(text: description )
            dialog.addSecondaryButton(text: BDPI18n.cancel)
            dialog.addPrimaryButton(text: BDPI18n.microapp_m_permission_go_to_settings, dismissCompletion: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                } else {
                    context.apiTrace.error("convert UIApplication.openSettingsURLString to URL failed")
                }
            })
            let window = fromController?.view.window ?? OPWindowHelper.fincMainSceneWindow()
            let topVC = OPNavigatorHelper.topMostVC(window: window)
            dialog.isAutorotatable = UDRotation.isAutorotate(from: topVC)
            topVC?.present(dialog, animated: true, completion: nil)
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "getStepCount", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: StepCountResult.self) { (this, params, context, callback) in
            
            this.getStepCount(params: params, context: context, callback: callback)
        }
    }
}


/**
 同时从HealthKit和CoreMotion中获取步数信息
 由于HealthKit的capacity还未申请, 这套方案暂时不用. 后续启用了HealthKit, 切换到这套实现
 */
//open class OpenPluginHealth: OpenBasePlugin {
//    private var trace: OPTrace?
//
//    static let CMPermissionDenyCode = 105;
//
//    private let healthStore = HKHealthStore()
//
//    private let pedometer = CMPedometer()
//
//    private let stepCountLock = NSLock()
//
//    var startGetStepCount = false
//
//    func getStepCount(params: OpenAPIBaseParams,
//                      context: OpenAPIContext,
//                      callback: @escaping(OpenAPIBaseResponse<StepCountResult>) -> Void) {
//        if startGetStepCount {
//            let error = OpenAPIError(code: GetStepCountErrorCode.alreadyStart)
//            callback(.failure(error: error))
//            return
//        }
//
//        startGetStepCount = true
//
//        trace = context.apiTrace
//
//        getStepCountFromHKAndCM(params: params, context: context, callback: callback)
//    }
//
//    required public init() {
//        super.init()
//        registerInstanceAsyncHandler(for: "getStepCount", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: StepCountResult.self) { (this, params, context, callback) in
//            
//            this.getStepCount(params: params, context: context, callback: callback)
//        }
//    }
//}
//
////MARK:计步Extension
//extension OpenPluginHealth {
//
//    /// 从"HealthKit"或者"CoreMotion"中获取步数
//    private func getStepCountFromHKAndCM(params: OpenAPIBaseParams,
//                                         context: OpenAPIContext,
//                                         callback: @escaping(OpenAPIBaseResponse<StepCountResult>) -> Void) {
//        guard getStepCountAvailable() else {
//            let error = OpenAPIError(code: GetStepCountErrorCode.notAvailable).setMonitorMessage("CoreMotion and HealthKit are both not available")
//            callback(.failure(error: error))
//            return
//        }
//
//        let now = Date()
//        let startDate = Calendar.current.startOfDay(for: now)
//
//        // 最终返回给用户的步数
//        var stepCount = 0
//
//        // 从HealthKit中获取步数是否成功
//        var getHKStepSuccess = false
//
//        // 从CoreMotion中获取步数是否成功
//        var getCMStepSuccess = false
//
//        // 是否有CoreMotion权限
//        var hasCMPermission = true
//
//        // 用来保证执行顺序
//        let dispatchGroup = DispatchGroup()
//
//        dispatchGroup.enter()
//        getHKStepCount(startDate: startDate, endDate: now) {[weak self] result in
//            switch result {
//            case .success(let value):
//                stepCount = self?.maxThreadSafe(stepCount, value) ?? stepCount
//                getHKStepSuccess = true
//            case .failure(_):
//                getHKStepSuccess = false
//            }
//            dispatchGroup.leave()
//        }
//
//        dispatchGroup.enter()
//        getCMStepCount(startDate: startDate, endDate: now) {[weak self] result in
//            switch result {
//            case .success(let value):
//                stepCount = self?.maxThreadSafe(stepCount, value) ?? stepCount
//                getCMStepSuccess = true
//                hasCMPermission = true
//            case .failure(let error):
//                getCMStepSuccess = false
//                if (error as NSError).code == Self.CMPermissionDenyCode {
//                    hasCMPermission = false
//                }
//            }
//            dispatchGroup.leave()
//        }
//
//        dispatchGroup.notify(queue: DispatchQueue.main) {
//            self.startGetStepCount = false
//            if !getHKStepSuccess && !getCMStepSuccess && !hasCMPermission {
//                //TODO:弹出授权弹窗
//                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
//                callback(.failure(error: error))
//                return
//            }
//
//            callback(.success(data: StepCountResult(stepCount: stepCount)))
//        }
//    }
//
//    /// 当前计步功能是否正常
//    private func getStepCountAvailable() -> Bool {
//        return getCMStepCountAvailable() || getHKStepCountAvailable()
//    }
//
//    /// 获取CoreMotion中的步数; 回调线程为非主线程;
//    private func getCMStepCount(startDate: Date,
//                                endDate: Date,
//                                completion: @escaping (_ result: Result<Int, Error>)->Void) {
//        guard getCMStepCountAvailable() else {
//            trace?.info("CMPedometer.isStepCountingAvailable is false")
//            completion(.failure(GetStepCountError.CMNotAvailable))
//            return
//        }
//
//        trace?.info("CMPedometer queryPedometerData from \(startDate) to \(endDate)")
//        pedometer.queryPedometerData(from: startDate, to: endDate) {[weak self] pedometerData, error in
//            if let error = error {
//                self?.trace?.error("CMPedometer queryPedometerData failed: \(error)")
//                completion(.failure(error))
//                return
//            }
//
//            guard let stepCount = pedometerData?.numberOfSteps.intValue else {
//                self?.trace?.error("pedometerData?.numberOfSteps value is nil")
//                completion(.failure(GetStepCountError.valueIsNil))
//                return
//            }
//
//            self?.trace?.info("get stepCount from CMPedometer: \(stepCount)")
//            completion(.success(stepCount))
//        }
//    }
//
//    /// 线程安全的max方法
//    private func maxThreadSafe(_ value1: Int, _ value2: Int) -> Int {
//        stepCountLock.lock()
//        let value = max(value1, value2)
//        stepCountLock.unlock()
//        return value
//    }
//
//    /// 获取HealthKit中的步数; 回调线程为非主线程;
//    private func getHKStepCount(startDate: Date,
//                                endDate: Date,
//                                completion: @escaping (_ result: Result<Int, Error>)->Void) {
//        guard getHKStepCountAvailable() else {
//            trace?.error("HKHealthStore.isHealthDataAvailable is false")
//            completion(.failure(GetStepCountError.HKNotAvailable))
//            return
//        }
//
//        trace?.info("HKHealthStore HKQuery predicateForSamples from \(startDate) to \(endDate)")
//
//        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) else {
//            trace?.error("get HKObjectType of stepCount failed")
//            completion(.failure(GetStepCountError.HKGetQuantityTypeFail))
//            return
//        }
//
//        let allType = Set([stepCount])
//        healthStore.requestAuthorization(toShare: nil, read: allType) {[weak self] success, error in
//            if let error = error {
//                self?.trace?.error("HealthKit requestAuthorization error: \(error)")
//                completion(.failure(error))
//                return
//            }
//
//            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//
//            let staticQuery = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predicate, options: .cumulativeSum) {[weak self] query, result, error in
//                if let error = error {
//                    self?.trace?.info("HKHealthStore execute query fail:\(error)")
//                    completion(.failure(error))
//                    return
//                }
//
//                guard let sumQuantity = result?.sumQuantity() else {
//                    self?.trace?.info("HKHealthStore query get nil value")
//                    completion(.failure(GetStepCountError.valueIsNil))
//                    return
//                }
//
//                let sum = sumQuantity.doubleValue(for: HKUnit.count())
//                self?.trace?.info("get stepCount from HKHealthStore: \(sum)")
//                completion(.success(Int(sum)))
//            }
//
//            self?.healthStore.execute(staticQuery)
//        }
//    }
//
//    private func getCMStepCountAvailable() -> Bool {
//        let available = CMPedometer.isStepCountingAvailable()
//        trace?.info("can get step count from CoreMotion is \(available)")
//        return available
//    }
//
//    private func getHKStepCountAvailable() -> Bool {
//        let available = HKHealthStore.isHealthDataAvailable()
//        trace?.info("can get step count from HealthKit is \(available)")
//        return available
//    }
//}
//
//fileprivate enum GetStepCountError: Error {
//    // CoreMotion not available
//    case CMNotAvailable
//
//    // HealthKit not available
//    case HKNotAvailable
//
//    // HK获取HKObjectType失败
//    case HKGetQuantityTypeFail
//
//    // 获取过来的值是nil
//    case valueIsNil
//}
