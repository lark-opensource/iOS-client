//
//  DocsSessionManager.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/8.
//  封装Alamofire session和 rust session的初始化
// disable-lint: long parameters

import Foundation
import Alamofire
import SwiftyJSON
import LarkRustHTTP
import LarkContainer

public class DocsSessionManager {
    
    //MARK: header等不变的设置，是从NetWorkSession迁移过来的
    private static var isEnableRust: Bool {
        return SKFoundationConfig.shared.isEnableRustHttp
    }
    
    private static let defaultHTTPHeaders: HTTPHeaders = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            // disable-lint-next-line: magic number
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
        }.joined(separator: ", ")

        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        // Example: `iOS Example/1.0 (org.alamofire.iOS-Example; build:1; iOS 10.0.0) Alamofire/4.0.0`
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

                let osNameVersion: String = {
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

                    let osName: String = {
                        #if os(iOS)
                            return "iOS"
                        #elseif os(watchOS)
                            return "watchOS"
                        #elseif os(tvOS)
                            return "tvOS"
                        #elseif os(macOS)
                            return "OS X"
                        #elseif os(Linux)
                            return "Linux"
                        #else
                            return "Unknown"
                        #endif
                    }()

                    return "\(osName) \(versionString)"
                }()

                return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion))"
            }

            return "Alamofire"
        }()

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": userAgent
        ]
    }()
    
    public private(set) var useRust: Bool = false
    
    //Alamofire使用的 manager，用来创建Session等
    private let alamofireManager: SessionManager
    
    //rust使用的 manager，用来创建Session等
    private let rustManager: DocsRustSessionManager
    
    let userResolver: UserResolver
    
    //重试逻辑适配器
    var docRequestRetrier: DocRequestRetrier? {
        didSet {
            if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
                self.rustManager.delegate?.retrier = docRequestRetrier
            } else {
                self.alamofireManager.retrier = docRequestRetrier
            }
            
        }
    }

    public var httpCookieStorage: HTTPCookieStorage? {
        if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
            return self.rustManager.rustSession.configuration.httpCookieStorage
       
        } else {
            return self.alamofireManager.session.configuration.httpCookieStorage
            
        }
    }
    
    public func cancelAllTasks() {
        if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
            self.rustManager.rustSession.getAllTasks { tasks in
                tasks.forEach { $0.cancel() }
            }
        } else {
            self.alamofireManager.session.getAllTasks(completionHandler: { (tasks) in
                tasks.forEach { $0.cancel() }
            })
        }
    }
    
    public init(host: String, requestHeader: [String: String], timeoutInterval: TimeInterval = 8, userResolver: UserResolver) {
        self.userResolver = userResolver
        //MARK: Alamofire相关初始化，从NetWorkSession迁移过来的
        let configuration = URLSessionConfiguration.default
        if DocsSessionManager.isEnableRust {
            configuration.protocolClasses = [SKRustHTTPURLProtocol.self]
            useRust = true
        }
        DocsLogger.info("NetworkSession init, use rust=\(useRust), host=\(host), complexConnect=\(SKFoundationConfig.shared.useComplexConnectionForPost)")
        configuration.httpAdditionalHeaders = DocsSessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders?.merge(other: requestHeader)
        if useRust {
            configuration.timeoutIntervalForRequest = 60
        } else {
            configuration.timeoutIntervalForRequest = timeoutInterval
        }
        
        self.alamofireManager = SessionManager(configuration: configuration, delegate: DocSessionDelegate())
        alamofireManager.adapter = DocsRequestAdapter(userResolver: self.userResolver)
        
        
        //MARK: RustSession 相关初始化
        let rustConfiguration = RustHTTPSessionConfig.default
        rustConfiguration.httpAdditionalHeaders = DocsSessionManager.defaultHTTPHeaders
        rustConfiguration.httpAdditionalHeaders?.merge(other: requestHeader)

        rustManager = DocsRustSessionManager(configuration: rustConfiguration)
        
    }
    
    @discardableResult
    public func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeout: TimeInterval? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        forceComplexConnect: Bool = false,
        headers: HTTPHeaders? = nil,
        cachePolicy: URLRequest.CachePolicy)
    -> DocsInternalRequest {
        
        
        var internalRequest: DocsInternalRequest
        if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
            
            let urlRequest = SessionManager.request(url, method: method, parameters: parameters, encoding: encoding, forceComplexConnect: forceComplexConnect, headers: headers, cachePolicy: cachePolicy)
            
            internalRequest = DocsInternalRustRequest(urlRequest: urlRequest, rustManager: self.rustManager, userResolver: userResolver)
        } else {
            
            let alamofireRequest = self.alamofireManager.request(url, method: method, parameters: parameters, encoding: encoding, forceComplexConnect: forceComplexConnect, headers: headers, cachePolicy: cachePolicy)
            
            
            internalRequest = DocsInternalAlamofireRequest(alamofireRequest: alamofireRequest, useRust: useRust)
        }
        return internalRequest
    }
    
    
    @discardableResult
    public func request(_ urlRequest: URLRequestConvertible) -> DocsInternalRequest {
        var internalRequest: DocsInternalRequest
        if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
            internalRequest = DocsInternalRustRequest(urlRequest: urlRequest.urlRequest, rustManager: self.rustManager, userResolver: userResolver)
        } else {
            let alamofireRequest = self.alamofireManager.request(urlRequest)
            internalRequest = DocsInternalAlamofireRequest(alamofireRequest: alamofireRequest, useRust: useRust)
        }
        
        return internalRequest
    }
    
    //MARK: 上传文件
    public func docsUpload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        timeout: TimeInterval? = nil,
        rawResult: @escaping DRUploadRawResponse) {
            
            var internalRequest: DocsUploadInternalRequest
            if UserScopeNoChangeFG.HZK.enableNetworkDirectConnectRust {
                internalRequest = DocsUploadInternalRustRequest(rustSession: self.rustManager.rustSession, userResolver: userResolver)
            } else {
                internalRequest = DocsUploadInternalAlamofireRequest(manager: self.alamofireManager, useRust: self.useRust)
            }
            internalRequest.upload(multipartFormData: multipartFormData, usingThreshold: 0, to: url, method: method, headers: headers, timeout: timeout, rawResult: rawResult)
            
        }
    
    
    //MARK: 下载文件
    //下载接口现在基本都不会走到，只是Doc1.0而且drive下载附件 mountType == jianguoyun才会走到，先保持不变，使用Alamofire上传
    //调用链：UtilFilePreviewService ->  FilePreviewViewController -> FilePreviewService -> DocsDownloadRequest
    //如果需要使用这个接口，需要考虑使用RustHttpSession进行适配
    public func download(
        _ url: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?,
        to destination: DownloadRequest.DownloadFileDestination?)
    -> DownloadRequest {
        let downloadRequest = self.alamofireManager.download(url, method: method, parameters: parameters, encoding: encoding, headers: headers, to: destination)
        return downloadRequest
    }
    
}
