//
//  ClippingNetSubPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/4.
//  


import UIKit
import SKFoundation
import SwiftyJSON
import LarkWebViewContainer
import SKInfra

class ClippingNetSubPlugin {

    enum NetworkError: Int {
        case unKnown    = -3
        case overtime   = -2
        case noNet      = -1
    }
    
    let secretKey: String
    
    weak var fileService: ClippingDocFileSubPlugin?
    
    weak var tracker: ClippingDocReport?
    
    var traceId: String?
    
    init(secretKey: String, traceId: String?) {
        self.secretKey = secretKey
        self.traceId = traceId
    }
    
    var domain: String {
        OpenAPI.docs.currentNetScheme + "://" + OpenAPI.docs.host
    }
    
    func handleFetch(params: [String: Any], callback: APICallbackProtocol?) {
        guard let model: ClippingFetchModel = params.mapModel() else {
            DocsLogger.info("mapModel FetchModel error", component: LogComponents.clippingDoc, traceId: self.traceId)
            return
        }
        // 1. 检查密钥，防止第三方调用
        guard model.secretKey == secretKey else {
            DocsLogger.info("secretKey not supported", component: LogComponents.clippingDoc, traceId: self.traceId)
            return
        }
        var url = model.url
        
        // 2. 构造request
        let measure = ClipTimeMeasure()
        let trafficType: NetConfigTrafficType = (model.file != nil) ? .upload : .default
        
        if !url.hasPrefix("http") {
            if !url.hasPrefix("/") {
                url = domain + "/" + url
            } else {
                url = domain + url
            }
        }
        let request = DocsRequest<JSON>(url: url,
                                        params: model.params,
                                        trafficType: trafficType)
        let timeout: Double = model.timeout > 0 ? model.timeout : 60
        
        DocsLogger.info("begin fetch url:\(model.url) timeout:\(timeout)", component: LogComponents.clippingDoc, traceId: self.traceId)
        DocsLogger.debug("begin fetch header:\(model.headers) params:\(model.params) realHeader: \(params["headers"])", component: LogComponents.clippingDoc, traceId: self.traceId)
        // 3.请求
        if let file = model.file { // 文件上传
            self.fileService?.getFileData(result: { [weak self] data in
                guard let self = self else { return }
                let size = data.count
                DocsLogger.info("begin uploadFile size:\(size)", component: LogComponents.clippingDoc, traceId: self.traceId)
                
                var contentType = "multipart/form-data"
                if let type = model.headers?["Content-Type"] as? String {
                    contentType = type
                    DocsLogger.info("upload contentType \(contentType)", component: LogComponents.clippingDoc, traceId: self.traceId)
                }
                request.set(method: model.method.docMethod)
                       .set(timeout: timeout)
                       .set(encodeType: .urlEncodeDefault)
                       .makeSelfReferenced()
                request.set(headers: model.headers ?? [:])
                request.upload(multipartFormData: { [weak self] formData in
                    guard let self = self else { return }
                    let name = file.paramName ?? "file"
                    let params = model.params ?? [:]
                    params.forEach({ (key, value) in
                        guard key != "file" else { return }
                        guard let data = "\(value)".data(using: .utf8, allowLossyConversion: false) else {
                            spaceAssertionFailure("parse value to utf8 data failure when upload image")
                            return
                        }
                        formData.append(data, withName: key)
                    })
                    formData.append(data, withName: "\(name)", fileName: "\(file.title)", mimeType: contentType)
                }, rawResult: { [weak self] (data, response, error) in
                    guard let self = self else { return }
                    self.handleResponse(data: data, response: response, error: error, callback: callback, model: model, measure: measure, fileSize: size)
                })
            })
        } else {  // 普通请求
            request.set(method: model.method.docMethod)
                   .set(timeout: timeout)
                   .set(encodeType: model.encodingType)
                   .set(needVerifyData: false)
                   .makeSelfReferenced()
            request.set(headers: model.headers ?? [:])
            request.start(rawResult: { [weak self] (data, response, error) in
                guard let self = self else { return }
                self.handleResponse(data: data, response: response, error: error, callback: callback, model: model, measure: measure, fileSize: nil)
            })
        }
        
    }
    
    private func handleResponse(data: Data?,
                                response: URLResponse?,
                                error: Error?,
                                callback: APICallbackProtocol?,
                                model: ClippingFetchModel,
                                measure: ClipTimeMeasure,
                                fileSize: Int?) {
        var dict = [String: Any]()
        // data
        if let jsonObj = data?.jsonObject {
            //json类型数据
            dict["data"] = jsonObj
        } else if let data = data {
            //非json类型数据
            dict["data"] = String(data: data, encoding: .utf8)
        } else {
            DocsLogger.error("response data is nil", component: LogComponents.clippingDoc, traceId: self.traceId)
        }
        // code
        let code = self.getCallBackCode(response: response, error: error)
        dict["code"] = code
        DocsLogger.info("fetch result code:\(code)", component: LogComponents.clippingDoc, traceId: self.traceId)
        
        // headers
        if let allHeaderFields = response?.allHeaderFields {
            var headers: [String: Any] = [:]
            for (key, value) in allHeaderFields {
                if let k = key as? String {
                    headers[k] = value
                }
            }
            dict["headers"] = headers
        }
        
        if let err = error {
            dict["message"] = err.localizedDescription
            DocsLogger.error("fetch error:\(error)", component: LogComponents.clippingDoc, traceId: self.traceId)
        }
        if code == 0 {
            tracker?.record(stage: .fetch(url: model.url, fileSize: fileSize), cost: measure.end())
        }
        DocsLogger.debug("url:\(response?.url?.absoluteString) callback result:\(dict)", component: LogComponents.clippingDoc, traceId: self.traceId)
        callback?.callbackSuccess(param: dict)
    }
                                                      

    private func getCallBackCode(response: URLResponse?, error: Error?) -> Int {
        var returnCode = NetworkError.unKnown.rawValue
        if let error = error {
            if let urlError = error as? URLError {
                if urlError.code == URLError.timedOut {
                    returnCode = NetworkError.overtime.rawValue
                } else if urlError.code == URLError.notConnectedToInternet {
                    returnCode = NetworkError.noNet.rawValue
                } else {
                    DocsLogger.error("unknow error:\(urlError)", component: LogComponents.clippingDoc, traceId: self.traceId)
                }
            } else {
                DocsLogger.error("error is not urlError", component: LogComponents.clippingDoc, traceId: self.traceId)
            }
        } else {
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    returnCode = 0
                } else {
                    returnCode = -httpResponse.statusCode
                }
            } else {
                DocsLogger.error("response is not HTTPURLResponse", component: LogComponents.clippingDoc, traceId: self.traceId)
            }
        }
        return returnCode
    }
                                                      
                                                    
}
