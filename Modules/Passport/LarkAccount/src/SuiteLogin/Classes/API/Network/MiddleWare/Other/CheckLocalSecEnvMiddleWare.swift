//
//  CheckLocalSecEnvMiddleWare.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2022/12/15.
//

import Foundation
import RxSwift
import SecSDK
import LKCommonsLogging
import ECOProbeMeta

class CheckLocalSecEnvMiddleWare: HTTPMiddlewareProtocol {

    let helper: V3APIHelper
    static let logger = Logger.log(ToastMessageMiddleWare.self, category: "SuiteLogin.CheckLocalSecEnvMiddleWare")

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func config() -> HTTPMiddlewareConfig {
        [
            .request: .high
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        checkSecLocalEnv { riskJson in

            let jsonData: Data = riskJson.data(using: .utf8)!
            let decoder = JSONDecoder()
            let riskData = try? decoder.decode(RiskData.self, from: jsonData)
            var riskDetail = riskData?.detail
            var riskList = riskData?.riskList

            var reqParams = request.body.getParams()
            if let detail = riskDetail,let riskList = riskList{
                //一键登录的数据格式与人脸不一样
                if request.appId == .v4OneKeyLogin {
                    reqParams["risk"] = riskList
                    reqParams["detail"] = detail
                } else {
                    reqParams["sec_risk"] = riskJson
                }
                if let uniContext = request.context.uniContext {
                    PassportMonitor.flush(EPMClientPassportMonitorLoginCode.mobile_security_scan_succ,
                              context: uniContext )
                }
            } else {
                var reason = riskJson
                if riskJson == "" {
                    reason = "ScanFail"
                }
                if let uniContext = request.context.uniContext {
                    PassportMonitor.flush(EPMClientPassportMonitorLoginCode.mobile_security_scan_fail,
                              categoryValueMap: ["reason": riskJson],
                              context: uniContext )
                }
            }
            request.body = reqParams

            complete()
        }
    }

    func checkSecLocalEnv(_ callback: @escaping (String) -> Void) {
        Observable<String>.create { ob in
            DispatchQueue.global().async {
                Self.logger.info("n_action_secLocalEnv_start")
                var riskJson = SecLocalEnv()
                ob.onNext(riskJson)
                ob.onCompleted()

            }
            return Disposables.create()
        }.timeout(1, scheduler: MainScheduler.instance)
         .subscribe(onNext: { resp in
             Self.logger.info("n_action_secLocalEnv_fisish")
             callback(resp ?? "ScanFail")
         },onError:{ error in
             Self.logger.info("n_action_secLocalEnv_error_\(error)")
             callback("Timeout")
             
         })
    }

    struct RiskData: Codable {
        var detail: String?
        var riskList: [String]?

        enum CodingKeys: String, CodingKey {
            case detail = "detail"
            case riskList = "risk"
        }
    }

}
