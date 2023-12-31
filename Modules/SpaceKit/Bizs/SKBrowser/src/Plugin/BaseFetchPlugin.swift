//
//  BaseFetchPlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/14.
//  

import SKFoundation
import SwiftyJSON
import SKCommon
import SKInfra

struct SKBaseFetchPluginConfig {
    //swiftlint:disable identifier_name
    let NetServiceType: SKNetRequestServcie.Type
    //swiftlint:enable identifier_name
    weak var executeJsService: SKExecJSFuncService?
    init(netServiceType: SKNetRequestServcie.Type, execJSService: SKExecJSFuncService) {
        self.NetServiceType = netServiceType
        self.executeJsService = execJSService
    }
}

protocol SKBaseFetchPluginProtocol: AnyObject {
    var editorIdentity: String { get }
    var additionalRequestHeader: [String: String] { get }
    func didStartFetch(_ request: URLRequest)
    func didEndFetch(_ response: URLResponse?, errorCode: Int)
    func modifiedUrlFor(_ url: URL) -> URL
}

class NetRequestWrapper {
    let task: SKNetRequestServcie
    init(_ task: SKNetRequestServcie) {
        self.task = task
    }
}

class SKBaseFetchPlugin: JSServiceHandler {
    /// 仅用于和H5通信
    enum NetworkError: Int {
        case iframeforbidden   = -4
        case unKnown           = -3
        case overtime          = -2
        case noNet             = -1
    }
    var logPrefix: String = ""
    private let config: SKBaseFetchPluginConfig
    weak var pluginProtocol: SKBaseFetchPluginProtocol?
    private var currentTasks = [String: NetRequestWrapper]()
    private static let agentToFrontJframeJsbCheck = "aWZyYW1lSnNiQ2hlY2s="

    init(_ config: SKBaseFetchPluginConfig) {
        self.config = config
    }

    func cancelAllTask() {
        synchronized(self) {
            for task in currentTasks.values {
                (task as? NetRequestWrapper)?.task.cancel()
            }
            currentTasks.removeAll()
        }
    }

    var editorIdentity: String {
        return logPrefix
    }

    var handleServices: [DocsJSService] {
        return [.utilFetch]
    }
    
    /// 检查iframeJsbCheck字段,FG下发开启时才做检查
    private func checkFecthCallEnableAndReport(_ fetchParams: FetchParams) -> Bool {
        
        if LKFeatureGating.docsCheckIframeJsbEnable {
            var checkValue: String
            if OpenAPI.docs.isAgentToFrontEndActive {
                checkValue = SKBaseFetchPlugin.agentToFrontJframeJsbCheck
            } else {
                checkValue = self.editorIdentity
            }
            
            if fetchParams.iframeJsbCheck != checkValue {
                // 异常的上报
                let param: [String: Any] = ["url": fetchParams.url,
                                            "nativeValue": self.editorIdentity,
                                            "webValue": fetchParams.iframeJsbCheck ?? "",
                                            "webProxy": OpenAPI.docs.isAgentToFrontEndActive ? "1":"0",
                                            "packageVersion": DocsSDK.offlineResourceVersion() ?? ""
                                            ]
                DocsTracker.newLog(enumEvent: .docsIframeJsbForbidden, parameters: param)
                return false
            }
        }
        
        return true
    }

    internal func handle(params: [String: Any], serviceName: String) {
        guard var fetchParams = FetchParams(form: params) else {
            skError("fetch parse error", extraInfo: ["identifier": editorIdentity, "event": serviceName], error: nil, component: nil)
            skAssertionFailure()
            return
        }
        
        // 检查调用是否合法
        if !checkFecthCallEnableAndReport(fetchParams) {
            skError("fetch checkiframeJsbCheck error iframeJsbCheck: \(String(describing: fetchParams.iframeJsbCheck)) , editorIdentity: \(self.editorIdentity)")
            skError("fetch checkiframeJsbCheck error url: \(fetchParams.url)")
            skAssertionFailure()
            
            self.config.executeJsService?.callFunction(DocsJSCallBack(fetchParams.callback),
                                              params: ["code": NetworkError.iframeforbidden.rawValue,
                                                       "message": "iframeJsbCheck verification failed！"],
                                              completion: nil)
            return
        }

        fetchParams = fetchParams.urlModifiedParams { (url) -> URL in
            skDebug("before modify ,url is \(url)")
            return pluginProtocol?.modifiedUrlFor(url) ?? url
        }
        skDebug("after modify ,url is \(fetchParams.url)")

        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            self.fetchWith(params: fetchParams, completionHandler: { (paramDic) in
                self.updateWebWith(callback: fetchParams.callback, parmasDic: paramDic)
            })
        }
    }

    private func fetchWith(params: FetchParams, completionHandler: @escaping ([String: Any]) -> Void) {
        guard var request = URLRequest(method: params.method.rawValue, url: params.url.absoluteString, body: params.bodyData) else {
            skError(logPrefix + "get request fail for \(params.url.absoluteString)" )
            skAssertionFailure()
            return
        }
        params.headers?.forEach({ (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        })
        if let reqId = params.requestId, reqId.isEmpty == false {
            request.setValue(reqId, forHTTPHeaderField: "request-id")
        }

        var additionalHeader = pluginProtocol?.additionalRequestHeader
        //cookie底层会加，这里加可能和请求的url不一致
        additionalHeader?.removeValue(forKey: "Cookie")
        additionalHeader?.forEach({ (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        })
        request.setValue(DocsCustomHeaderValue.fromMobileWeb, forHTTPHeaderField: DocsCustomHeader.fromSource.rawValue)
        pluginProtocol?.didStartFetch(request)
        let netTask = config.NetServiceType.init(skRequest: request)
        //设置重试次数
        if let retryCount = params.retryCount {
            netTask.set(retryCount: retryCount)
        }
        if params.isFetchClientVar {
            netTask.set(forceComplexConnect: true)
            netTask.set(needFilterBOMChar: true)
        }
        // FIXME: @lizechuang
        // spaceAssert((params.requestId?.isEmpty ?? true) == false, "request is is empty")
        var additionalStatisTics: [String: Any] = ["docs_request_id": params.requestId ?? "noid"]
        additionalStatisTics["docs_request_priority"] = params.priority ?? -1

        DocsLogger.info("start fetchWith\(params.url.absoluteString.encryptToShort), callback:\(params.callback)")

        netTask.set(additionalStatistics: additionalStatisTics).start {[weak self] (data, response, error) in
            guard let self = self else { return }
            let errorCode = self.getCallBackCode(request: request, response: response, error: error)
            var dict = [String: Any]()
            dict["code"] = errorCode
            dict["message"] = error?.localizedDescription ?? ""
            // "data" 字段不能为nil
            dict["data"] = [:].json?.jsonObject
            if let data = data, data.isEmpty == false {
                if let jsonObj = data.jsonObject {
                    //json类型数据
                    dict["data"] = jsonObj
                } else {
                    //非json类型数据
                    dict["data"] = String(data: data, encoding: .utf8)
                }
            }
            DocsLogger.info(self.logPrefix + "fetchWith request finish for \(params.url.absoluteString.encryptToShort), errcode is \(errorCode)" )
            completionHandler(dict)
            self.pluginProtocol?.didEndFetch(response, errorCode: errorCode)
            synchronized(self) {
                self.currentTasks.removeValue(forKey: netTask.requestID)
            }
        }
        synchronized(self) {
            currentTasks.updateValue(NetRequestWrapper(netTask), forKey: netTask.requestID)
        }
    }

    func updateWebWith(callback: String, parmasDic: [String: Any]) {
        DispatchQueue.main.async {
            guard let service = self.config.executeJsService else {
                DocsLogger.error("fetchWith callback but serivce is nil")
                return
            }
            DocsLogger.info("fetch callback \(callback)")
            service.callFunction(DocsJSCallBack(callback), params: parmasDic, completion: { (_, error) in
                DocsLogger.info("fetch callback completion \(callback)")
                if let resultErr = error {
                    skError("fetch callback error", extraInfo: ["identifier": self.editorIdentity], error: resultErr, component: nil)
                }
            })
        }
    }

    private func getCallBackCode(request: URLRequest?, response: URLResponse?, error: Error?) -> Int {
        var returnCode = NetworkError.unKnown.rawValue
        let logInfo = ["delegateID": editorIdentity]
        if let error = error {
            if let urlError = error as? URLError {
                if urlError.code == URLError.timedOut {
                    returnCode = NetworkError.overtime.rawValue
                } else if urlError.code == URLError.notConnectedToInternet {
                    returnCode = NetworkError.noNet.rawValue
                } else {
                    skError("unknow error", extraInfo: logInfo, error: nil, component: LogComponents.net)
                }
            } else {
                skError("error is not urlError", extraInfo: logInfo, error: nil, component: LogComponents.net)
            }
        } else {
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    returnCode = 0
                } else {
                    returnCode = -httpResponse.statusCode
                }
            } else {
                skError("response is not HTTPURLResponse", extraInfo: logInfo, error: nil, component: LogComponents.net)
            }
        }
        return returnCode
    }
}

internal extension SKBaseFetchPlugin {
    struct FetchParams {
        var url: URL
        let method: DocsHTTPMethod
        let callback: String
        let rawDict: [String: Any]
        let bodyData: Data
        let headers: [String: String]?
        let requestId: String?
        let retryCount: UInt?
        let priority: Int?
        let key: String?
        let iframeJsbCheck: String?    // 需要检查这个字段是否是native传入的，目前使用的是editorIdentify

        init?(form dict: [String: Any]) {
            rawDict = dict
            let data = JSON(dict)

            guard let url = URL(string: data["url"].stringValue) else {
                skAssertionFailure("fetch init url failure")
                return nil
            }

            guard let method = DocsHTTPMethod(rawValue: data["method"].stringValue) else {
                skAssertionFailure("fetch init method failure")
                return nil
            }

            guard let callback = data["callback"].string else {
                skAssertionFailure("fetch init callback failure")
                return nil
            }

            self.url = url
            self.method = method
            self.callback = callback
            self.bodyData = data["body"].stringValue.data(using: .utf8, allowLossyConversion: false) ?? Data()
            self.headers = data["headers"].dictionaryObject as? [String: String]
            self.requestId = {
                let prefix = "request_id="
                guard let context = data["headers"]["Context"].string,
                    let component = context.components(separatedBy: ";").first(where: { $0.hasPrefix("request_id=") }) else {
                        if let header = data["headers"].dictionaryObject as? [String: String] {
                            return header["request-id"]
                        }
                        return nil
                }
                return String(component[prefix.endIndex...])
            }()
            self.retryCount = data["retryCount"].uInt
            self.priority = data["priority"].int
            self.key = data["key"].string
            self.iframeJsbCheck = data["iframeJsbCheck"].string
        }

        var isFetchClientVar: Bool {
            return key == "CLIENT_VARS"
        }

        func urlModifiedParams(_ adapter: (_ url: URL) -> URL) -> FetchParams {
            var newInstance = self
            newInstance.url = adapter(url)
            return newInstance
        }
    }
}
