//
//  PreviewImagePlugin.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/11/21.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import LarkAssetsBrowser
import Kingfisher
import EEMicroAppSDK

extension OpenPluginImage {
    public func previewImageV2(
        with jsonParams: OpenAPIPreviewImageParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        guard let uniqueId = context.uniqueID else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("resolve uniqueId failed")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return 
        }
        context.apiTrace.info("start call previewImageV2")

        do {
            let paramModel = try PreviewImageModel(with: jsonParams.toJSONDict())
            
            let isValidUrls = (paramModel.urls != nil && !paramModel.urls!.isEmpty)
            let isValidRequests = (paramModel.requests != nil && !paramModel.requests!.isEmpty)
            //urls和requests不能同时为空
            if !isValidUrls, !isValidRequests {
                //旧实现会把业务errCode都转化为unknown，这里保持一致，errno正常，以下同理
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("urls and requests is empty.")
                    .setErrno(OpenAPIImageErrno.urlsAndRequestsAllEmpty)
                callback(.failure(error: error))
                return
            }
            
            //都不为空也不可以，两个参数互斥
            if isValidUrls, isValidRequests {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("urls and requests is mutually exclusive.")
                    .setErrno(OpenAPIImageErrno.urlsAndRequestsMutuallyExclusive)
                callback(.failure(error: error))
                return
            }
            let shouldShowSaveOption = paramModel.shouldShowSaveOption
            if let requests = paramModel.requests, !requests.isEmpty {//只有requests
                let urlRequestArray = try buildUrlRequests(requests: requests, context: context)
                showPreviewImageVC(requests: urlRequestArray,
                                   pageIndex: 0,
                                   shouldShowSaveOption: shouldShowSaveOption,
                                   context: context,
                                   uniqueID: uniqueId)
                //新逻辑在VC弹出后，即callBack success，跟Android对齐
                callback(.success(data: nil))
            }else if let urls = paramModel.urls, !urls.isEmpty{//只有urls
                let urlRequestArray = try buildUrlRequests(urls: urls, header: paramModel.header, originUrls: paramModel.originUrls, context: context, uniqueID: uniqueId)
                let pageIndex = pageIndex(from: paramModel.current, requests: urlRequestArray)
                showPreviewImageVC(requests: urlRequestArray,
                                   pageIndex: pageIndex,
                                   shouldShowSaveOption: shouldShowSaveOption,
                                   context: context,
                                   uniqueID: uniqueId)
                callback(.success(data: nil))
            }else {
                //正常不会走到这里
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("requests and urls mutuallyExclusive error")
                    .setErrno(OpenAPICommonErrno.unknown)
                callback(.failure(error: error))
            }
        } catch let error as OpenAPIError {
            callback(.failure(error: error))
        } catch {
            let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage(error.localizedDescription)
                .setMonitorMessage("previewimage paramsInvalid or bulidRequest error")
                .setError(error)
            callback(.failure(error: err))
        }
        
    }
    
    //隐藏参数request构建URLRequest
    func buildUrlRequests(requests:[PreviewRequestsItem],
                          context: OpenAPIContext) throws -> [PreviewImageRequestModel]{
        return try requests.map { request in
            guard let url = URL(string: request.url) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Invaild url.")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "url")))
                throw error
            }
            var urlRequest = URLRequest(url: url)
            
            //header
            if let header = request.header, !header.isEmpty  {
                let destHeader = header.mapValues {
                    String(describing: $0)
                }
                urlRequest.allHTTPHeaderFields = destHeader
            }
            
            //body
            if let body = request.body, !body.isEmpty, JSONSerialization.isValidJSONObject(body) {
                if let httpBody = try? JSONSerialization.data(withJSONObject: body) {
                    urlRequest.httpBody = httpBody
                }else{
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("Invaild body.")
                    .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "body")))
                    throw error
                }
            }
            let requestModel = PreviewImageRequestModel(baseUrl: request.url, request: urlRequest)
            return requestModel
        }
    }
    
    //url+header构建URLRequest
    func buildUrlRequests(urls: [String],
                          header: [String:Any]?,
                          originUrls: [String]?,
                          context: OpenAPIContext,
                          uniqueID: OPAppUniqueID) throws -> [PreviewImageRequestModel]{
        var urlRequestArray:[PreviewImageRequestModel] = []
        for (index, urlStr) in urls.enumerated() {
            guard !urlStr.isEmpty else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("url is empty.")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "urls")))
                throw error
            }
            //urlStr如果是ttfile，转真实路径
            guard let realUrl = buildRealUrl(from: urlStr, uniqueID: uniqueID, context: context), let url = URL(string: realUrl) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("previewImage Invaild url.")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "urls")))
                throw error
            }
            var urlRequest = URLRequest(url: url)
            if let header = header, !header.isEmpty {
                let destHeader = header.mapValues {
                    String(describing: $0)
                }
                urlRequest.allHTTPHeaderFields = destHeader
            }
            let originUrl = (originUrls?.count ?? 0) > index ? originUrls?[index]:nil
            let requestModel = PreviewImageRequestModel(baseUrl: urlStr, request: urlRequest)
            //替换原图
            requestModel.originUrl = originUrl
            urlRequestArray.append(requestModel)
        }
        return urlRequestArray
    }

    func buildRealUrl(from urlString: String, uniqueID: OPAppUniqueID, context: OpenAPIContext) ->String? {
        do {
            context.apiTrace.info("buildRealUrl from:\(urlString)")
            let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: nil, tag: "previewImage")
            guard let file = try? FileObject(rawValue: urlString) else{
                if urlString.hasPrefix("http") || urlString.hasPrefix("https") {
                    return urlString
                }else {
                    return nil
                }
            }
            let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)
            let fileURL = URL(fileURLWithPath: systemFilePath)
            return fileURL.absoluteString
        } catch let error {
            context.apiTrace.error("getSystemFile error:\(error)")
            return nil
        }
    }
    
    func pageIndex(from current: String?, requests: [PreviewImageRequestModel]) ->Int {
        guard let current = current else {
            return 0
        }
        return requests.firstIndex { $0.baseUrl == current } ?? 0
    }
    
    func showPreviewImageVC(requests: [PreviewImageRequestModel],
                            pageIndex: Int,
                            shouldShowSaveOption: Bool,
                            context: OpenAPIContext,
                            uniqueID: OPAppUniqueID) {
        let byteWebImageEnable = EMAImageUtils.byteWebImageEnable
        context.apiTrace.info("showPreviewImageVC pageIndex:\(pageIndex), requests:\(requests), shouldShowSaveOption:\(shouldShowSaveOption),byteWebImageEnable:\(byteWebImageEnable)")
        let displayAssets: [LKAsset] = requests.map {
            if byteWebImageEnable {
                return OpenPluginPreviewImageAssetV2(requestModel: $0)
            }
            return OpenPluginPreviewImageAsset(requestModel: $0)
        }
        let browser = LKAssetBrowser()
        browser.displayAssets = displayAssets
        browser.pageIndicator = LKAssetDefaultPageIndicator()
        browser.currentPageIndex = pageIndex
        var plugins = [
            PreviewImageQRCodeDetectionPlugin(uniqueID: uniqueID),//二维码识别
            PreviewImageOriginImagePlugin(),//显示原图
        ]
        if shouldShowSaveOption {
            if PreviewImageConfig.settingsConfig().ignoreCipherCheck {
                plugins.insert(LKAssetBrowserSaveImagePlugin(), at: 0)//保存图片
            }else {
                plugins.insert(LKAssetBrowserRestrictedSaveImagePlugin(), at: 0)//带有安全管控保存图片
            }
        }
        browser.plugins = plugins
        browser.show()
    }
    
}

final class PreviewImageRequestModel: NSObject {
    var baseUrl: String
    var request: URLRequest
    var hasUseOriginUrl: Bool = false
    ///原图替换条件：
    ///本地缓存中存在originUrl图片，且url和originUrl不相同，则直接替换request.url,长按"显示原图"按钮不再展示
    var originUrl: String? {
        didSet {
            if let originUrl = originUrl, EMAImageUtils.isCached(key: originUrl), originUrl != request.url?.absoluteString, let newUrl = URL(string: originUrl) {
                request.url = newUrl
                hasUseOriginUrl = true
            }
        }
    }
    
    public override var description: String {
        return "PreviewImageRequestModel<url:\(request.url?.safeURLString), header:\(request.allHTTPHeaderFields), method:\(request.httpMethod)>"
    }
    
    public init(baseUrl: String, request: URLRequest) {
        self.baseUrl = baseUrl
        self.request = request
    }
    
}
 
