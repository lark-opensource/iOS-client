//
//  GadgetFileHandler.swift
//  TTMicroApp
//
//  Created by justin on 2023/7/26.
//

import Foundation
import WebKit
import OPFoundation
import LarkStorage
import ECOProbe
import LKCommonsLogging


@available(iOS 11.0, *)
extension WKWebView {
    static func swizzHandlesURLScheme() {
        if
            case let cls = WKWebView.self,
            let m1 = class_getClassMethod(cls, NSSelectorFromString("handlesURLScheme:")),
            let m2 = class_getClassMethod(cls, #selector(WKWebView.swizzHandlesURLScheme(urlScheme:)))
        {
            method_exchangeImplementations(m1, m2)
        }
    }
    /// 返回true如果WKWebview支持处理这种协议, 但WKWebview默认支持file，所以返回false支持用自定义的file Handlers
    /// NOTE: 如果不在configuration里注册file handlers, 则仍然会用WKWebView默认的HTTP进行处理
    @objc dynamic
    private static func swizzHandlesURLScheme(urlScheme: String) -> Bool {
        if urlScheme == "file" { return false }
        return self.swizzHandlesURLScheme(urlScheme: urlScheme)
    }
}

typealias LoadCompletion = (_ data: NSData?, _ error: Error?) -> Void

@objc
public final class GadgetFileHandler: NSObject, WKURLSchemeHandler {
    
    static let logger = Logger.oplog("GadgetURLSchemeHandler", category: "FileHandler")
    
    static var hadSwizze = false
    static let logExtension = ["js", "json"]
    
    static let requestInfoCache: NSCache<NSString, BDPAppLoadURLInfo>  = {
        let cache = NSCache<NSString, BDPAppLoadURLInfo>()
        cache.countLimit = 10
        return cache
    }()
    
    @objc
    public override init() {
        if !Self.hadSwizze {
            WKWebView.swizzHandlesURLScheme()
            Self.hadSwizze = true
        }
        super.init()
    }
    
    @objc
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        #if DEBUG || ALPHA
        let requestUrlStr = safeStr(urlSchemeTask.request.url?.absoluteString)
        Self.logger.info("file request ulr:\(requestUrlStr)")
        #endif
        
        let requestInfo = Self.getLoadUrlInfo(urlRequest: urlSchemeTask.request)
        guard let loadUrlInfo = requestInfo else {
            let urlStr = urlSchemeTask.request.url?.absoluteString ?? ""
            Self.logger.error("GadgetFileHandler is nil for request:\(urlStr)")
            let urlInfoError = OPError.error(monitorCode: GadgetSchemeHandlerCode.fileAppLoadURLInfoNull)
            urlSchemeTask.didFailWithError(urlInfoError)
            return
        }
        
        Self.startLoad(info: loadUrlInfo, urlSchemeTask: urlSchemeTask) { [weak urlSchemeTask] (data, error) in
            guard let urlSchemeTask = urlSchemeTask  else {
                return
            }
            Self.handleResponeData(info: loadUrlInfo, urlSchemeTask: urlSchemeTask, data: data, error: error)
        }
    }
    
    @objc
    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
    }
    
    
    
    /// get `BDPAppLoadURLInfo` with URLRequest, if cache exit, return cache; or create request with URLRequest
    /// - Parameter urlSchemeTask: current WKURLSchemeTask
    /// - Returns: `BDPAppLoadURLInfo` or nil
    static func getLoadUrlInfo(urlRequest: URLRequest) -> BDPAppLoadURLInfo? {
        let infoKey = BDPAppLoadURLInfo.uniqueKey(for: urlRequest) as NSString
        guard let cacheInfo =  Self.requestInfoCache.object(forKey: infoKey) else {
            let requestInfo = BDPURLProtocolManager.shared().info(of: urlRequest)
            if let resultInfo = requestInfo {
                Self.requestInfoCache.setObject(resultInfo, forKey: infoKey)
            }
            return requestInfo
        }
        return cacheInfo
    }
    
    
    
    /// start load WKURLSchemeTask data
    /// - Parameters:
    ///   - info: request url BDPAppLoadURLInfo
    ///   - urlSchemeTask: schema task
    static func startLoad(info: BDPAppLoadURLInfo, urlSchemeTask: WKURLSchemeTask, completion: @escaping LoadCompletion) {
       switch info.folder {
       case .TTPKG:
           Self.loadTTPKGData(info: info, urlSchemeTask: urlSchemeTask) { data, error in
               completion(data, error)
           }
       case .JSSDK:
           Self.loadJSSDKData(info: info, urlSchemeTask: urlSchemeTask) { data, error in
               completion(data, error)
           }
       case .sandBox:
           Self.loadSandboxData(info: info, urlSchemeTask: urlSchemeTask) { data, error in
               completion(data, error)
           }
       default:
           let error = OPError.error(monitorCode: GadgetSchemeHandlerCode.fileAppInfoTypeInvalid)
           completion(nil, error)
       }
    }
    
    
    /// load data from ttpkg
    /// - Parameters:
    ///   - info: BDPAppLoadURLInfo from url
    ///   - urlSchemeTask: original request task
    ///   - completion: load finish block
    static func loadTTPKGData(info: BDPAppLoadURLInfo, urlSchemeTask: WKURLSchemeTask, completion: @escaping LoadCompletion) {
        
        logger.debug("[GadgetFileHandler] startLoading \(safeStr(urlSchemeTask.request.url?.absoluteString)), \(safeDict(urlSchemeTask.request.allHTTPHeaderFields)), \(safeStr(info.appID)), \(info.folder.rawValue), \(safeStr(info.pkgName)), \(safeStr(info.realPath))")
        
        let begin: Date? = Self.logExtension.contains((safeStr(info.realPath) as NSString).pathExtension) ? Date() : nil
        
        var pkgReader: BDPPkgFileReader? = BDPAppLoadManager.shareService().tryGetReaderInMemory(with: info.uniqueID)
        if pkgReader == nil {
            pkgReader = BDPAppLoadManager.shareService().tryGetReaderInMemory(withAppID: info.appID, pkgName: info.pkgName)
        }
        
        // sub package may have sepeator reader
        if let common = BDPCommonManager.shared().getCommonWith(info.uniqueID), common.isSubpackageEnable() {
            let subReader = BDPSubPackageManager.shared().getFileReader(withPackageName: info.pkgName)
            if let safeSubReader = subReader , let safePkgReader = pkgReader, ObjectIdentifier(safeSubReader) != ObjectIdentifier(safePkgReader) {
                pkgReader = subReader
            }
        }
        
        guard let dataReader = pkgReader else {
            let error = OPError.error(monitorCode: GDMonitorCode.try_get_reader_failed)
            completion(nil, error)
            return
        }
        let uniqueID = dataReader.basic().uniqueID
        dataReader.readData(withFilePath: info.realPath, syncIfDownloaded: true, dispatchQueue: nil) { (error, _, data) in
            let resultError = error?.newOPError(monitorCode: GadgetSchemeHandlerCode.filePkgReadFail)
            completion(data as? NSData, resultError)
            if begin != nil {
                let extra = ["file_path" : safeStr(info.realPath)]
                BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_end", extra: extra, uniqueId: uniqueID)
            }
        }
        
        if  begin != nil {
            let extra = ["file_path" : safeStr(info.realPath)]
            BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_begin", extra: extra, date: begin, uniqueId: uniqueID)
        }
    }
    
    
    /// load file from jssdk file
    /// - Parameters:
    ///   - info: BDPAppLoadURLInfo from url
    ///   - urlSchemeTask: original request task
    ///   - completion: load finish block
    static func loadJSSDKData(info: BDPAppLoadURLInfo, urlSchemeTask: WKURLSchemeTask, completion: @escaping LoadCompletion) {
        let module = BDPModuleManager(of: .gadget).resolveModule(with: BDPStorageModuleProtocol.self)
        guard let storageModule = module as? BDPStorageModuleProtocol else {
            let moduleError = OPError.error(monitorCode: GadgetSchemeHandlerCode.fileStorageModuleInvalid)
            completion(nil, moduleError)
            return
        }
        let absFilePath = storageModule.sharedLocalFileManager().path(for: .jsLib).appendingPathComponent(safeStr(info.realPath))
        
        let data: NSData?
        do {
             data = try NSData.lssSmartRead(from: absFilePath, options: NSData.ReadingOptions.mappedIfSafe)
        }catch {
            data = nil
            let resultError = error.newOPError(monitorCode: GadgetSchemeHandlerCode.fileJSSDKReadFail)
            completion(data, resultError)
            return
        }
        completion(data, nil)
    }
    
    
    /// load file data form sand box Data
    /// - Parameters:
    ///   - info: BDPAppLoadURLInfo from url
    ///   - urlSchemeTask: original request task
    ///   - completion: load finish block
    static func loadSandboxData(info: BDPAppLoadURLInfo, urlSchemeTask: WKURLSchemeTask, completion: @escaping LoadCompletion) {
        let absPath = safeStr(info.realPath)
        let data: NSData?
        do {
             data = try NSData.lssSmartRead(from: absPath, options: NSData.ReadingOptions.mappedIfSafe)
        }catch {
            data = nil
            let resultError = error.newOPError(monitorCode: GadgetSchemeHandlerCode.fileSandboxReadFail)
            completion(data, resultError)
            return
        }
        completion(data, nil)
    }
    
    
    static func handleResponeData(info: BDPAppLoadURLInfo, urlSchemeTask: WKURLSchemeTask, data: NSData?, error: Error?) {
        if let resultError = error {
            urlSchemeTask.didFailWithError(resultError)
            return
        }
        
        guard let resultData = data as? Data else {
            let dataError = OPError.error(monitorCode: GadgetSchemeHandlerCode.fileLoadDataNull)
            urlSchemeTask.didFailWithError(dataError)
            return
        }
        
        let mineType = BDPMIMETypeOfFilePath(info.realPath)
        var response: URLResponse?
        if info.folder == .sandBox , info.requestURL.scheme == "ttfile" {
            var components = URLComponents.init(string: safeStr(urlSchemeTask.request.url?.absoluteString))
            components?.scheme = "https"
            response = self.makeResponse(url: components?.url, mimeType: mineType)
        }else if (info.folder == .JSSDK && safeStr(info.requestURL.query) == "from=ttjssdk") || mineType.hasPrefix("image") {
            response = self.makeResponse(url: info.requestURL, mimeType: mineType)
        }else {
            var components = URLComponents.init(string: safeStr(urlSchemeTask.request.url?.absoluteString))
            components?.scheme = "https"
            if let safeUrl = components?.url {
                response = URLResponse.init(url: safeUrl, mimeType: mineType, expectedContentLength: resultData.count, textEncodingName: nil)
            }
        }
        
        guard let resultRespone = response else {
            let respError = OPError.error(monitorCode: GadgetSchemeHandlerCode.fileResponseNull)
            urlSchemeTask.didFailWithError(respError)
            return
        }
        
        urlSchemeTask.didReceive(resultRespone)
        urlSchemeTask.didReceive(resultData)
        urlSchemeTask.didFinish()
    }
    
    
    static func makeResponse(url: URL?, mimeType: String) -> HTTPURLResponse? {
        guard let resultURL = url else {
            return nil
        }
        let headFilds = ["Access-Control-Allow-Origin": "*",
                         "Content-Type": "\(mimeType); charset=utf-8"]
        return HTTPURLResponse.init(url: resultURL, statusCode: 200, httpVersion: "1.1", headerFields: headFilds)
    }
}
