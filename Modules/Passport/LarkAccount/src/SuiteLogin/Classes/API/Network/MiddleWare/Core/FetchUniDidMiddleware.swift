//
//  FetchUniDidMiddleware.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/9.
//

import Foundation
import ECOProbeMeta

class FetchUniDidMiddleware: HTTPMiddlewareProtocol {

    let helper: V3APIHelper
    
    
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
        
        //上报获取统一did开始
        PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_fetch_uni_did_start,
                                   eventName: ProbeConst.monitorEventName,
                                   context: UniContextCreator.create(.didUpgrade))
        
        let fetchStartTime = Date().timeIntervalSince1970
        
        PassportUniversalDeviceService.shared.fetchDeviceId({ (res) in
            switch res {
            case .success(let deviceInfo):
                request.add(headers: [CommonConst.universalDeviceId: deviceInfo.deviceId])
                complete()
                
                //上报统一did获取成功埋点
                let fetchSuccTime = Date().timeIntervalSince1970
                PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_fetch_uni_did_succ,
                                           eventName: ProbeConst.monitorEventName,
                                           categoryValueMap: ["cost": fetchSuccTime - fetchStartTime],
                                           context: UniContextCreator.create(.didUpgrade))
                
            case .failure(let error):
                request.context.error = .fetchDeviceIDFail(error.localizedDescription)
                complete()
                
                //上报统一did获取失败
                PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_fetch_uni_did_fail,
                                           eventName: ProbeConst.monitorEventName,
                                           categoryValueMap: ["error_code": (error as NSError).code],
                                           context: UniContextCreator.create(.didUpgrade),
                                           error: error)
            }
        })
    }
}
