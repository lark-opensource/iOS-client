//
//  FactorsController.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/9.
//

import Foundation
import LarkSnCService

final class FactorsController {
    let service: SnCService

    init(service: SnCService) {
        self.service = service
    }

    func checkPointcutIsControlledByFactors(requestMap: [String: CheckPointcutRequest],
                                                   callback: ((_ retMap: [String: Bool]) -> Void)?) {
        let mapList = requestMap.chunked(into: 100)
        var responseMap = [String: Bool]()

        let group = DispatchGroup()
        mapList.forEach { map in
            group.enter()
            queryFactorsControlInfo(requestMap: map) { [weak self] retMap, err in
                guard let retMap = retMap else {
                    if let err = err {
                        self?.service.logger?.error("queryFactorsControlInfo return 0 item, error: \(err)")
                    }
                    group.leave()
                    return
                }
                responseMap.merge(retMap, uniquingKeysWith: { first, _ in return first })
                group.leave()
            }
        }
        group.notify(queue: PolicyEngineQueue.queue) {
            callback?(responseMap)
        }
    }

    private func queryFactorsControlInfo(requestMap: [String: CheckPointcutRequest],
                                         callback: ((_ retMap: [String: Bool]?, Error?) -> Void)?) {
        let requestMapDict = requestMap.mapValues({ request in
            let jsonData = (try? JSONSerialization.data(withJSONObject: request.entityJSONObject)) ?? Data()
            let jsonStr = String(data: jsonData, encoding: .utf8) ?? ""
            return [
                "pointcutKey": request.pointKey,
                "checkContext": jsonStr,
                "factors": request.factors
            ]
        })

        struct CheckPointcutIsControlledBySpecificFactorsModel: Codable {
            let isUnderControlled: [String: Bool]
        }

        let url = "/lark/scs/guardian/pointcut/control_check"

        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set domain before use policy engine.")
            assertionFailure("lost domain，please set domain")
            DispatchQueue.main.async {
                callback?(nil, CustomStringError("lost domain，please set domain"))
            }
            return
        }

        var request = HTTPRequest(domain, path: url, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)
        request.data = ["params": requestMapDict]

        service.logger?.info("Begin remote validate request, params:\(request.data ?? [:])")
        service.client?.request(request, dataType: ResponseModel<CheckPointcutIsControlledBySpecificFactorsModel>.self, completion: { result in
            switch result {
            case .success(let resp):
                guard resp.code.isZeroOrNil,
                      let data = resp.data else {
                    DispatchQueue.main.async {
                        callback?(nil, CustomStringError(resp.msg ?? ""))
                    }
                    return
                }
                DispatchQueue.main.async {
                    callback?(data.isUnderControlled, nil)
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    callback?(nil, err)
                }
            }
        })
    }
}
