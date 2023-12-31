//
//  PreviewImageHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import EEMicroAppSDK
import LKCommonsLogging
import WebBrowser

class PreviewImageHandler: JsAPIHandler {
    static let log = Logger.log(PreviewImageHandler.self, category: "Module.JSSDK")
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        let urls = args["urls"] as? [String]
        let requests = args["requests"] as? [[String: Any]]
        PreviewImageHandler.log.info("H5HSAPI-previewImage：call native begin")
        if urls == nil,
            requests == nil {
            callback.callbackFailure(param: NewJsSDKErrorAPI.PreviewImage.urlsAndRequestsIsEmpty.description())
            PreviewImageHandler.log.error("H5HSAPI-previewImage：urls & requests is empty")
            return
        }
        if urls != nil,
            requests != nil {
            callback.callbackFailure(param: NewJsSDKErrorAPI.PreviewImage.urlsAndRequestsIsMutuallyExclusive.description())
            PreviewImageHandler.log.error("H5HSAPI-previewImage：urls & requests is mutually exclusive")
            return
        }
        var useurls: Bool = false
        var tempurls: [String] = []
        var urlRequests: [URLRequest] = []
        var errorDictionary: [String: Any]?
        if let urls = urls {
            useurls = true
            guard !urls.isEmpty else {
                callback.callbackFailure(param: NewJsSDKErrorAPI.PreviewImage.urlIsEmpty.description())
                PreviewImageHandler.log.error("H5HSAPI-previewImage：urls is empty")
                return
            }
            urlRequests = urls.map({ (urlstr) -> URLRequest? in
                guard errorDictionary == nil else {
                    PreviewImageHandler.log.error("H5HSAPI-previewImage：errorDictionary not nil")
                    return nil
                }
                guard !urlstr.isEmpty else {
                    errorDictionary = NewJsSDKErrorAPI.PreviewImage.urlIsEmpty.description()
                    PreviewImageHandler.log.error("H5HSAPI-previewImage：url is empty")
                    return nil
                }
                guard let url = URL(string: urlstr) else {
                    errorDictionary = NewJsSDKErrorAPI.PreviewImage.invaildurl.description()
                    PreviewImageHandler.log.error("H5HSAPI-previewImage：url is invaild")
                    return nil
                }
                tempurls.append(urlstr)
                return URLRequest(url: url)
            }).compactMap { $0 }
        }
        if useurls {
            PreviewImageHandler.log.info("H5HSAPI-previewImage：use urls")
            if urlRequests.isEmpty {
                callback.callbackFailure(param: NewJsSDKErrorAPI.PreviewImage.urlIsEmpty.description())
                PreviewImageHandler.log.error("H5HSAPI-previewImage：urls is empty")
                return
            }
            if let errorDictionary = errorDictionary {
                PreviewImageHandler.log.error("H5HSAPI-previewImage：errorDictionary not nil")
                callback.callbackFailure(param: errorDictionary)
                return
            }
        }
        if let requests = requests {
            useurls = false
            PreviewImageHandler.log.info("H5HSAPI-previewImage：use requests")
            guard !requests.isEmpty else {
                callback.callbackFailure(param: NewJsSDKErrorAPI.PreviewImage.requestIsEmpty.description())
                PreviewImageHandler.log.error("H5HSAPI-previewImage：requests is empty")
                return
            }
            urlRequests = requests.map({ (requestDictionary) -> URLRequest? in
                guard errorDictionary == nil else {
                    return nil
                }
                guard let urlstr = requestDictionary["url"] as? String,
                    let url = URL(string: urlstr) else {
                        errorDictionary = NewJsSDKErrorAPI.PreviewImage.invaildurl.description()
                        PreviewImageHandler.log.error("H5HSAPI-previewImage：url:\(requestDictionary["url"] ?? "") is invaild")
                        return nil
                }
                var request = URLRequest(url: url)
                if let header = requestDictionary["header"] as? [String: String] {
                    request.allHTTPHeaderFields = header
                }
                if let method = requestDictionary["method"] as? String {
                    let vaildMethodSet: Set = ["GET", "POST"]
                    guard vaildMethodSet.contains(method) else {
                        errorDictionary = NewJsSDKErrorAPI.PreviewImage.invaildMethod.description()
                        PreviewImageHandler.log.error("H5HSAPI-previewImage：method is invaild,not GET or POST")
                        return nil
                    }
                    request.httpMethod = method
                }
                if let body = requestDictionary["body"] as? [String: Any] {
                    guard JSONSerialization.isValidJSONObject(body),
                        let httpbody = try? JSONSerialization.data(withJSONObject: body) else {
                            errorDictionary = NewJsSDKErrorAPI.PreviewImage.invaildBody.description()
                            PreviewImageHandler.log.error("H5HSAPI-previewImage：body is invaild")
                            return nil
                    }
                    request.httpBody = httpbody
                }
                tempurls.append(urlstr)
                return request
            }).compactMap { $0 }
        }
        guard !urlRequests.isEmpty else {
            callback.callbackFailure(param: NewJsSDKErrorAPI.PreviewImage.requestIsEmpty.description())
            PreviewImageHandler.log.error("H5HSAPI-previewImage：requests is empty")
            return
        }
        if let errorDictionary = errorDictionary {
            PreviewImageHandler.log.error("H5HSAPI-previewImage：errorDictionary not nil")
            callback.callbackFailure(param: errorDictionary)
            return
        }
        var index: UInt = 0
        if let current = args["current"] as? String,
            let tempxIndex = tempurls.firstIndex(of: current) {
            index = UInt(tempxIndex)
        }
        /// 这里是预览到最后，如果出现一张照片失败，那么就会走fail回调
        let previewImageErrorCode = 1016
        let vc = EMAPhotoScrollViewController(
            requests: urlRequests,
            startWith: index,
            placeholderImages: nil,
            placeholderTags: nil,
            originImageURLs: nil,
            delegate: nil,
            success: { [weak self, weak api] in
                callback.callbackSuccess(param: [String: Any]())
                PreviewImageHandler.log.info("H5HSAPI-previewImage：callback success")
            }) { [weak self, weak api] (msg) in
            let args: [String : Any] = [
                "errorCode": previewImageErrorCode,
                "errorMessage": msg ?? ""
                ]
            callback.callbackFailure(param: args)
                PreviewImageHandler.log.error("H5HSAPI-previewImage：callback fail: \(args)")
        }
        vc.presentPhotoScrollView(api.view.window)
        PreviewImageHandler.log.info("H5HSAPI-previewImage：call end")
    }
}
