//
//  GetStepCountHandler.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/10.
//

import CoreMotion
import WebBrowser
import LKCommonsLogging

class GetStepCountHandler: JsAPIHandler {

    private static let log = Logger.log(GetStepCountHandler.self)

    private let pedometer = CMPedometer()

    var needAuthrized: Bool {
        return true
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if !CMPedometer.isStepCountingAvailable() {
            GetStepCountHandler.log.error("GetStepCountHandler error, CMPedometer is not StepCountingAvailable")
            // 设备不支持计步
            callback.callbackFailure(param: NewJsSDKErrorAPI.GetStepCount.getStepCountDeviceNotSupport.description())
            return
        }

        pedometer.queryPedometerData(from: zeroDate(), to: Date()) { (pedometerData, error) in
            if let error = error {
                GetStepCountHandler.log.error("queryPedometerData error", error: error)
                callback.callbackFailure(param: NewJsSDKErrorAPI.GetUserInfo.getUserInfoFail.description())
                return
            }
            guard let num = pedometerData?.numberOfSteps.intValue else {
                GetStepCountHandler.log.error("queryPedometerData error, pedometerData has no numberOfSteps")
                // 获取步数失败
                callback.callbackFailure(param: NewJsSDKErrorAPI.GetUserInfo.getUserInfoFail.description())
                return
            }
            let successParam = [
                "stepcount": num
            ]
            callback.callbackSuccess(param: successParam)
        }
    }

    private func zeroDate() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return calendar.date(from: components) ?? Date()
    }
}
