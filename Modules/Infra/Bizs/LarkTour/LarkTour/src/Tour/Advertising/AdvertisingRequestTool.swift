//
//  AdvertisingRequestTool.swift
//  LarkTour
//
//  Created by Meng on 2020/4/22.
//

import Foundation
import RxSwift
import LarkContainer
import LarkSetting
import LKCommonsLogging
import AppReciableSDK

struct InstallSourceConfig {
    var source: String
    var configs: [String: String]
}

enum ActivityURLPath {
    static let installSource: String = "/ug/source/config"
}

final class AdvertisingRequestTool {
    static let logger = Logger.log(AdvertisingRequestTool.self, category: "Tour")

    func fetchInstallSource(deviceId: String, rawAF: String) -> Observable<InstallSourceConfig?> {
        let disposeKey = AppReciableSDK.shared.start(biz: .UserGrowth,
                                                     scene: .OnBoarding,
                                                     event: .getSourceEvent,
                                                     page: nil)

        guard let url = requestURL(for: ActivityURLPath.installSource) else {
            Self.logger.info("skip request install source", additionalData: ["domain": domain ?? ""])
            reportFetchInstallSourceResult(statusCode: -200, hasConfig: false, cost: 0, disposeKey: disposeKey)
            return .just(nil)
        }
        let request = installSourceRequst(for: url, deviceId: deviceId, rawAF: rawAF)
        let startTime = TourMetric.timeCostStart()
        return URLSession.shared.rx
            .response(request: request)
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .flatMap({ (response, data) -> Observable<InstallSourceConfig?> in
                let cost = TourMetric.timeCostEnd(for: startTime)
                if 200..<300 ~= response.statusCode {
                    Self.logger.info("fetch install source succeed", additionalData: ["statusCode": "\(response.statusCode)"])
                    let config = self.parseInstallSourceConfigData(data)
                    self.reportFetchInstallSourceResult(
                        statusCode: response.statusCode,
                        hasConfig: config != nil,
                        cost: cost,
                        disposeKey: disposeKey
                    )
                    return .just(config)
                } else {
                    Self.logger.error("fetch install source failed", additionalData: ["statusCode": "\(response.statusCode)"])
                    self.reportFetchInstallSourceResult(
                        statusCode: response.statusCode,
                        hasConfig: false,
                        cost: cost,
                        disposeKey: disposeKey
                    )
                    return .just(nil)
                }
            }).catchError({ error -> Observable<InstallSourceConfig?> in
                Self.logger.error("fetch install source failed", error: error)
                let cost = TourMetric.timeCostEnd(for: startTime)
                self.reportFetchInstallSourceResult(
                    statusCode: -203 /* 其他错误 */,
                    hasConfig: false,
                    cost: cost,
                    errorMsg: error.localizedDescription,
                    disposeKey: disposeKey
                )
                return .just(nil)
            })
    }
}

// fetch install source
extension AdvertisingRequestTool {
    private func installSourceRequst(for url: URL, deviceId: String, rawAF: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "device_id": deviceId,
            "terminal_type": 4, /* iOS = 4 */
            "raw_af": rawAF
        ]
        request.httpBody =
            try? JSONSerialization.data(withJSONObject: body, options: [])
        return request
    }

    private func parseInstallSourceConfigData(_ data: Data) -> InstallSourceConfig? {
        guard let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            else {
                Self.logger.error("parse install source failed")
                return nil
        }
        if let source = result["source"] as? String {
            let configs = result["launch_conf"] as? [String: String]
            return InstallSourceConfig(source: source, configs: configs ?? [:])
        }
        Self.logger.info("parse install source failed", additionalData: ["result": "\(result)"])
        return nil
    }

    private func reportFetchInstallSourceResult(statusCode: Int,
                                                hasConfig: Bool,
                                                cost: Int64,
                                                errorMsg: String? = nil,
                                                disposeKey: DisposedKey) {
        if 200..<300 ~= statusCode {
            let code = hasConfig ? -202 /* 反序列化失败 */ : statusCode
            TourMetric.fetchInstallSourceEvent(succeed: true, errorCode: code, cost: cost)
            AppReciableSDK.shared.end(key: disposeKey)
        } else {
            TourMetric.fetchInstallSourceEvent(succeed: false, errorCode: statusCode, cost: cost)
            AppReciableSDK.shared.error(params: ErrorParams(biz: .UserGrowth,
                                                            scene: .OnBoarding,
                                                            errorType: .Network,
                                                            errorLevel: .Exception,
                                                            userAction: nil,
                                                            page: nil,
                                                            errorMessage: errorMsg))
        }
    }
}

extension AdvertisingRequestTool {
    private var domain: String? {
        return DomainSettingManager.shared.currentSetting[.ugActivity]?.first
    }

    private func requestURL(for path: String) -> URL? {
        guard let domain = domain, !domain.isEmpty else {
            return nil
        }
        return URL(string: "https://\(domain)\(path)")
    }
}
