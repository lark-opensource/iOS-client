//
//  WADataSession+Cache.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/27.
//

import Foundation
import SKFoundation
import LarkWebViewContainer
import LarkRustHTTP

extension WADataSession {
    
    func tryReadFromCache(url: URL) -> Data? {
        let ext = url.pathExtension
        let path = url.path
        if self.filetype.contains(ext),
            let (remotePathPattern, localPathPattern) = self.tryGetCachePath(path: url.path),
           let lastPath = url.pathComponents.last {
            
            guard let startRange = path.range(of: remotePathPattern), let endRange = path.range(of: lastPath) else {
                return nil
            }
            let startIndex = path.distance(from: path.startIndex, to: startRange.lowerBound)
            let endIndex =  path.distance(from: path.startIndex, to: endRange.upperBound)
            guard startIndex < endIndex else {
               return nil
            }
            var localPath = String(path[startIndex..<endIndex])
            localPath = localPath.replacingOccurrences(of: remotePathPattern, with: localPathPattern)
            let fileName = (localPath as NSString).deletingPathExtension
            Self.logger.info("intercept,cache tryReadFromCache: \(fileName), remote:\(path)", tag: LogTag.net.rawValue)
            
            if let data = self.delegate?.readData(for: localPath) {
                return data
            }
        } else if let templatePath = self.delegate?.appConfig.resInterceptConfig?.rootHtml,
                  matchRootHtml(url) {
            let necessaryCookieKeys = self.delegate?.appConfig.resInterceptConfig?.necessaryCookieKeys
            guard WAContainerPreloader.checkCookieFor(url.absoluteString, checkCookies: necessaryCookieKeys) else {
                Self.logger.error("intercept, check cookie failed, dont inject roothtml, key: \(String(describing: necessaryCookieKeys))", tag: LogTag.net.rawValue)
                return nil
            }
            
            let fileName = templatePath
            Self.logger.info("intercept try read root html:\(templatePath)", tag: LogTag.net.rawValue)
            if let data = self.delegate?.readData(for: fileName) {
                return data
            }
        } else {
            Self.logger.info("intercept path mismatch", tag: LogTag.net.rawValue)
        }
        return nil
    }
    
    func matchRootHtml(_ url: URL) -> Bool {
        //正式url或预加载url是否匹配
        if let curUrl = self.delegate?.container?.hostURL, url.path == curUrl.path {
            return true
        }
        if let preloadUrl = self.delegate?.container?.loader?.preloadURL, url.path == preloadUrl.path {
            return true
        }
        return false
    }
    
    func tryGetCachePath(path: String) -> (String, String)? {
        guard let mapPattern = self.delegate?.appConfig.resInterceptConfig?.mapPattern,
                !mapPattern.isEmpty else {
            return nil
        }
        for (remote, local) in mapPattern {
            if path.contains(remote) {
                return (remote, local)
            }
        }
        return nil
    }
    
    class func mimeTypeFor(_ request: URLRequest) -> String? {
        guard let originUrl = request.url else {
            return nil
        }
        if let mimeType = MIMETypes[originUrl.pathExtension], !mimeType.isEmpty {
            return mimeType
        } else if let acceptField = request.allHTTPHeaderFields?["Accept"],
                  let mimeType = acceptField.components(separatedBy: ",").first {
            return mimeType
        }
        return nil
    }
}
