//
//  DownloadModel.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/3/13.
//

import Foundation
import WebKit
import LarkStorage
import LarkCache
import LarkAccountInterface

class WebDownloadModel {
    let request: URLRequest?
    let response: URLResponse?
    let cookieStore: WKHTTPCookieStore?
    let filename: String?
    let fileExtension: String?
    let isSupportPreview: Bool?
    var localPath: String?
    var totalBytes: Int64?
    
    init(request: URLRequest? = nil,
         response: URLResponse? = nil,
         cookieStore: WKHTTPCookieStore? = nil,
         filename: String? = nil,
         fileExtension: String? = nil,
         preview: Bool? = nil) {
        self.request = request
        self.response = response
        self.cookieStore = cookieStore
        self.filename = filename
        self.fileExtension = fileExtension
        self.isSupportPreview = preview
    }
}

struct WebDownloadStorage {
    static func set(model: WebDownloadModel) {
        guard let url = model.request?.url?.absoluteString,
              let path = model.localPath as? NSString,
              let type = model.fileExtension,
              let isPreview = model.isSupportPreview else {
            WebBrowser.logger.info("OPWDownload download storage model invalid")
            return
        }
        let filename = path.lastPathComponent
        let value: NSDictionary = ["filename": filename,
                                   "type": type,
                                   "preview": String(isPreview)]
        Self.kvCache().setObject(value, forKey: url)
        WebBrowser.logger.info("OPWDownload download storage set key-value")
    }
    
    static func get(url: String) -> [String: String]? {
        if let obj: NSCoding = Self.kvCache().object(forKey: url),
           let dict = obj as? NSDictionary,
           let value = dict as? Dictionary<String, String> {
            WebBrowser.logger.info("OPWDownload download storage get value")
            return value
        }
        WebBrowser.logger.info("OPWDownload download storage get is nil")
        return nil
    }
    
    static func space() -> LarkStorage.Space {
        return .user(id: AccountServiceAdapter.shared.currentAccountInfo.userID)
    }
    
    static func kvCache() -> LarkCache.Cache {
        let space = Self.space()
        let isoPath = IsoPath.in(space: space, domain: Domain.biz.webApp).build(forType: .cache, relativePart: "Downloads")
        return CacheManager.shared.cache(rootPath: isoPath, cleanIdentifier: "library/Caches/WebApp/Downloads/kvCache")
    }
}
