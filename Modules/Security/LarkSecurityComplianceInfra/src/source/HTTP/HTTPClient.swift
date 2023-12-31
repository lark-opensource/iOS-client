//
//  HTTP.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/13.
//

import RxSwift
import LarkRustHTTP
import SwiftyJSON
import LarkSetting

public protocol HTTPClient {
    func request<T: Decodable>(_ req: Request) -> Observable<T>
    func request(_ req: Request) -> Observable<Data>
}

public final class HTTPClientImp: HTTPClient {
    
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.protocolClasses = [RustHttpURLProtocol.self]
        let session = URLSession(configuration: config)
        return session
    }()
    
    private static var shouldMonitorRequest: Bool {
        !FeatureGatingManager.shared.featureGatingValue(with: "scs.http_request_monitor_disabled") // Global
    }

    public init() {}

    public func request<T>(_ req: Request) -> Observable<T> where T: Decodable {
        return self.request(req).map { data -> T in
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        }
    }

    public func request(_ req: Request) -> Observable<Data> {
        monitorRequestIfNeeded(req)
        do {
            let request = try req.asURLRequest()
            return Observable<Data>.create { observer in
                let task = Self.session.dataTask(with: request) { data, response, error in
                    var extra = req.desc
                    if let httpResponse = response as? HTTPURLResponse {
                        extra["x-tt-logid"] = httpResponse.allHeaderFields["x-tt-logid"] ?? ""
                    }
                    if let err = error {
                        let httpResponse = response as? HTTPURLResponse
                        Logger.error("API ERROR: \(err), request: \(req) response: \(Self.logDescription(from: httpResponse))")
                        SCMonitor.error(singleEvent: .network_state_monitor,
                                        error: err,
                                        extra: extra)

                        observer.onError(err)
                        return
                    }
                    if let httpResp = response as? HTTPURLResponse, httpResp.statusCode != 200 {
                        Logger.error("Server ERROR, request: \(req) response: \(Self.logDescription(from: httpResp))")
                        var body: JSON?
                        if let data = data {
                            do {
                                body = try JSON(data: data)
                            } catch {
                                Logger.info("serialization failed: \(data)")
                            }
                        }
                        let error = LSCError.httpStatusError(httpResp.statusCode, bodyJson: body)
                        SCMonitor.error(singleEvent: .network_state_monitor,
                                        error: error,
                                        extra: extra)
                        observer.onError(error)
                    } else if let data = data {
                        observer.onNext(data)
                        observer.onCompleted()
                    } else {
                        SCMonitor.error(singleEvent: .network_state_monitor,
                                        error: LSCError.dataIsNil,
                                        extra: extra)
                        observer.onError(LSCError.dataIsNil)
                    }
                }
                task.resume()
                return Disposables.create {
                    task.cancel()
                }
            }

        } catch {
            Logger.error("API ERROR: \(error), request: \(req)")
            SCMonitor.error(singleEvent: .network_state_monitor,
                            error: error,
                            extra: req.desc)
            return Observable.error(error)
        }
    }

    private static func logDescription(from response: HTTPURLResponse?) -> String {
        let allowKeys = ["x-net-info.remoteaddr",
                         "x-request-id",
                         "x-tt-logid",
                         "x-tt-trace-id",
                         "x-cache-remote"]
        let headers = response?.allHeaderFields as? [String: Any]
        var result = headers?.filter({ allowKeys.contains($0.key.lowercased()) }) ?? [:]
        result["status-code"] = response?.statusCode ?? 0
        return result.description
    }
}

extension HTTPClientImp {
    private static var blockList: [String]? {
        guard let scSettingDict = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")), // Global
              let blockList = scSettingDict["network_monitor_blocklist"] as? [String] 
        else {
            Logger.error("get monitor blockList failed")
            return nil
        }
        return blockList
    }
    
    private func monitorRequestIfNeeded(_ req: Request) {
        guard Self.shouldMonitorRequest,
              let path = req.desc["path"] as? String,
              let blkList = Self.blockList,
              !blkList.contains(path) else { return }
        SCMonitor.info(singleEvent: .network_request_monitor, category: req.desc)
    }
}
