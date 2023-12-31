//
//  GadgetWebpHandler.swift
//  TTMicroApp
//
//  Created by justin on 2023/7/26.
//

import Foundation
import WebKit
import OPFoundation
import BDWebImage
import UIKit
import ECOProbe
import LKCommonsLogging

@objc
public final class GadgetWebpHandler: NSObject, WKURLSchemeHandler {
    static let logger = Logger.oplog("GadgetURLSchemeHandler", category: "WebpHandler")
    weak var curDataTask: URLSessionDataTask?
    
    // MARK: - WKURLSchemeHandler method
    @objc
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        
        #if DEBUG || ALPHA
        let requestUrlStr = safeStr(urlSchemeTask.request.url?.absoluteString)
        Self.logger.info("webp request ulr:\(requestUrlStr)")
        #endif
        
        
        let urlRequest = self.canonicalRequest(url: urlSchemeTask)
        
        let webpDataTask = URLSession.shared.dataTask(with: urlRequest) { [weak urlSchemeTask] (data, response, error) in
            guard let urlSchemeTask = urlSchemeTask  else {
                return
            }
            
            if let responeError = error {
                let resultError = responeError.newOPError(monitorCode: GadgetSchemeHandlerCode.webpResponseError)
                urlSchemeTask.didFailWithError(resultError)
                return
            }
            
            guard let safeResponse = response , let responseUrl = safeResponse.url else {
                let respError = OPError.error(monitorCode: GadgetSchemeHandlerCode.webpResponeInvalid)
                urlSchemeTask.didFailWithError(respError)
                return
            }
            
            let resultData = Self.processImageData(data, url: responseUrl)
            guard let receiveData = resultData else {
                let dataError = OPError.error(monitorCode: GadgetSchemeHandlerCode.webpDataInvalid)
                urlSchemeTask.didFailWithError(dataError)
                return
            }
            
            var resultResponse = safeResponse
            if  safeResponse.mimeType != "image/png" {
                resultResponse = URLResponse(url: responseUrl, mimeType: "image/png", expectedContentLength: receiveData.count, textEncodingName: nil)
            }
            urlSchemeTask.didReceive(resultResponse)
            urlSchemeTask.didReceive(receiveData)
            urlSchemeTask.didFinish()
        }
        webpDataTask.resume()
        curDataTask = webpDataTask
    }
    
    @objc
    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
    }
    
    // MARK: - start webp request
    
    /// transform ttwebp(s) url to canonical http(s) url
    /// - Parameter schemaTask: request task
    /// - Returns: canonical http(s) url
    func canonicalRequest(url schemaTask: WKURLSchemeTask) -> URLRequest {
        var mutableReqeust = schemaTask.request
        guard let url = mutableReqeust.url,  var components = URLComponents.init(url: url, resolvingAgainstBaseURL: true) else {
            return schemaTask.request
        }
        
        if components.scheme == "ttwebps" {
            components.scheme = "https"
        }else if components.scheme == "ttwebp" {
            components.scheme = "http"
        }
        mutableReqeust.url = components.url
        
        //webp如果本地有缓存，修改为local url
        if let mutableUrl = mutableReqeust.url, Self.isWebpUrl(mutableReqeust.url) {
            let path = Self.webpCachePath(mutableUrl.absoluteString)
            if FileManager.default.fileExists(atPath: path) {
                mutableReqeust.url = URL.init(fileURLWithPath: path)
            }
        }
        return mutableReqeust
    }
    
    /// process image data
    /// - Parameters:
    ///   - data: respsonse image data
    ///   - url: response url
    /// - Returns: if webp url , get UIImage, return png data; not, return response data
    static func processImageData(_ data: Data?, url: URL?) -> Data? {
        if !self.isWebpUrl(url) {
            return data
        }
        
        guard let resultData = data else {
            return data
        }
        
        var imageData: UIImage?
        if NSData.isWebpData(resultData) {
            if #available(iOS 16.0, *), EMAFeatureGating.boolValue(forKey: "openplatform.api.fix_image_component_ios16_webp") {
                imageData = UIImage.bd_image(with: resultData)
            }else {
                imageData = UIImage.init(webPData: resultData)
            }
        }else {
            imageData = UIImage.init(data: resultData)
        }
        
        let pngData = imageData?.pngData()
        if pngData != nil,  let safeUrl = url?.absoluteString {
            let cachePath = Self.webpCachePath(safeUrl)
            do {
                try pngData?.write(to: URL.init(fileURLWithPath: cachePath), options: Data.WritingOptions.atomic)
            } catch  {
                logger.error("write data to file is error:\(error), url:\(safeUrl)")
            }
        }
        return pngData
    }
    
    // MARK: -  webp Util Method
    
    /// check url is webp format
    /// - Parameter url: can optional
    /// - Returns: webp is true , not false
    static func isWebpUrl(_ url: URL?) -> Bool {
        guard let webpUrl = url else {
            return false
        }
        return webpUrl.pathExtension.caseInsensitiveCompare("webp") == .orderedSame
    }
    
    
    /// webp image cache path
    /// - Parameter url: url absoluteString
    /// - Returns: cache path string.
    static func webpCachePath(_ url: String) -> String {
        let fileName = String(format: "%ld.png", url.hash)
        let tempFileUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        let webFilePath = tempFileUrl.appendingPathComponent(fileName)
        return webFilePath.path
    }
}
