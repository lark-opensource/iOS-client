//
//  RequestCostMiddleWare.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/4/22.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkPerf
import LKCommonsLogging

private extension String {
    static let startTime: String = "request_start_time"
}

class RequestCostMiddleWare: HTTPMiddlewareProtocol {
    static let logger = Logger.plog(RequestCostMiddleWare.self, category: "SuiteLogin.RequestCostMiddleWare")

    func config() -> HTTPMiddlewareConfig {
        [
            .request: .lowest,
            .response: .highest,
            .error: .highest
        ]
    }

    let helper: V3APIHelper

    init(helper: V3APIHelper) {
        self.helper = helper
    }

    func handle<ResponseData: ResponseV3>(request: PassportRequest<ResponseData>, complete: @escaping () -> Void) {
        switch request.context.state {
        case .noTriger:
            request.context.extra[.startTime] = CFAbsoluteTimeGetCurrent()
        case .running:
            break
        case .finish:
            recordForSlardar(request)
        }
        complete()
    }

    func recordForSlardar<ResponseData: ResponseV3>(_ request: PassportRequest<ResponseData>) {
        guard var sceneInfo = request.sceneInfo else {
            return
        }
        if let startTime = request.context.extra[.startTime] as? CFAbsoluteTime {
            let stopTime = CFAbsoluteTimeGetCurrent()
            let cost = (stopTime - startTime) * 1000

            if let error = request.context.error {
                switch error {
                case .badServerCode, .fetchDeviceIDFail, .badResponse, .server:
                    sceneInfo[MultiSceneMonitor.Const.result.rawValue] = "error"

                    Self.logger.error("scene: \(sceneInfo[MultiSceneMonitor.Const.scene.rawValue] ?? ""), status: error, description: \(error)")
                case .clientError, .transformJSON, .badLocalData, .networkNotReachable, .networkTimeout, .toastError, .resetEnvFail, .accountAppeal, .userCanceled, .alertError:
                    sceneInfo[MultiSceneMonitor.Const.result.rawValue] = "other"

                    Self.logger.error("scene: \(sceneInfo[MultiSceneMonitor.Const.scene.rawValue] ?? ""), status: other, description: \(error)")
                }
            }

            guard let sceneString = sceneInfo[MultiSceneMonitor.Const.scene.rawValue],
                let scene = MultiSceneMonitor.Scene(rawValue: sceneString) else {
                return
            }

            MultiSceneMonitor.shared.record(
                scene: scene,
                categoryInfo: sceneInfo,
                metricInfo: [
                    sceneString: cost,
                    MultiSceneMonitor.MetricKey.timespend.rawValue: cost
            ])
        }
    }
}
