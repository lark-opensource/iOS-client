//
//  PrivateHostChecker.swift
//  SKCommon
//
//  Created by lijuyou on 2023/11/29.
//

import Foundation
import SKFoundation
import LarkSetting
import LarkContainer
import LarkRustClient
import RustPB

/// 内网检测
/// 技术方案： https://bytedance.larkoffice.com/docx/P84PdQpWVo58R1x8oDgc8afKnUd
/// 测试文档： https://bytedance.larkoffice.com/docx/ZdVeduMLHoxDjgx2zpZcTrJfncb
public class PrivateHostChecker {
    public static let privateHostError = -100000
    
    public static func checkIsPrivateIfNeed(resolver: UserResolver,
                                            frameHost: String,
                                            checkIP: Bool,
                                            completion: @escaping (Bool) -> Void) {
        let isReachable = DocsNetStateMonitor.shared.isReachable
        DocsLogger.info("[iframecheck] start checkHostIsPrivate \(frameHost), reachable:\(isReachable)")
        
        //1. setting白名单检测
        if let settings = try? resolver.settings.setting(with: .make(userKeyLiteral: "openplatform_error_page_info")),// user:global
           let privateHost = settings["privateHost"] as? Array<String>,
           let url = URL(string: frameHost) {
            let noScheme: Bool = (url.scheme == nil)
            var httpScheme: Bool = false
            if let scheme = url.scheme {
                httpScheme = scheme.hasPrefix("http")
            }
            // 若scheme不存在或scheme为http/https
            if noScheme || httpScheme {
                for host in privateHost {
                    guard !host.isEmpty else { continue }
                    if checkPrivateURL(url, host: host) {
                        DocsLogger.info("[iframecheck] hostIsPrivate check white list \(frameHost) is true, private:\(isReachable)")
                        completion(isReachable)
                        return
                    }
                }
            }
        }
        guard checkIP else {
            completion(false) //耗时原因可以不检测IP
            return
        }
        //2. 调用RustSDK判定内网IP
        var request = Openplatform_V1_IsSiteLocalAddrRequest()
        request.host = frameHost
        guard let rustService =  try? resolver.resolve(assert: RustService.self) else {
            completion(false)
            return
        }
        DocsLogger.info("[iframecheck] start checkHostIsPrivate in rust")
        rustService.async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<RustPB.Openplatform_V1_IsSiteLocalAddrResponse>) -> Void in
            do {
                let value = try responsePacket.result.get().isLocal
                let isPrivate = value && isReachable
                DocsLogger.info("[iframecheck] IsSiteLocalAddrReq for \(frameHost) val:\(value),isPrivate:\(isPrivate)")
                completion(isPrivate)
            } catch {
                DocsLogger.error("[iframecheck] IsSiteLocalAddrReq error", error: error)
                completion(false)
            }
        }
    }
    
    public static func isNetError(code: Int) -> Bool {
        //NSURLErrorTimedOut  -1001
        //NSURLErrorCannotFindHost -1003
        //NSURLErrorCannotConnectToHost -1004
        if  code == URLError.timedOut.rawValue || code == URLError.cannotFindHost.rawValue || code == URLError.cannotConnectToHost.rawValue {
            return true
        }
        return false
    }
    
    private static func checkPrivateURL(_ url: URL, host: String) -> Bool {
        guard !host.isEmpty else {
            return false
        }
        // 若为URL
        if url.scheme != nil, let anotherURL = URL(string: host), anotherURL.scheme != nil {
            guard let host1 = url.host, let host2 = anotherURL.host else {
                return false
            }
            // 完全匹配
            if host1 == host2 {
                return true
            }
            // 通配符需符合二级及以上域名
            if host2.components(separatedBy: ".").count < 2 {
                return false
            }
            return host1.hasSuffix("." + host2)
        }
        // 若为host
        // 完全匹配
        if url.absoluteString == host {
            return true
        }
        // 通配符需符合二级及以上域名
        if host.components(separatedBy: ".").count < 2 {
            return false
        }
        return url.absoluteString.hasSuffix("." + host)
    }
}
