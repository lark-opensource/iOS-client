//
//  DocsIconRequest.swift
//  LarkDocsIcon
//
//  Created by ByteDance on 2023/6/29.
//

import Foundation
import LarkRustClient
import RxSwift
import RustPB
import ServerPB
import LarkContainer
import LarkAccountInterface
import LarkStorage
import LarkEnv

enum DocsIconRequestError: Error {
    case JSONFormatFail
    case serviceFail
}

typealias SendHttpRequest = RustPB.Basic_V1_SendHttpRequest
typealias SendHttpResponse = RustPB.Basic_V1_SendHttpResponse

public class DocsIconRequest: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    
    @ScopedProvider private var client: RustService?
    @ScopedProvider private var passport: PassportUserService?
    @ScopedProvider private var iconCache: DocsIconCache?
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func sendAsyncHttpRequest(token: String, type: CCMDocsType) -> Observable<[String: Any]?> {
        
        guard let client = client else {
            DocsIconLogger.logger.error("RustService client is nil")
            return .just(nil)
        }
        
        var req = SendHttpRequest()
        let param = "?type=\(type.rawValue)&token=\(token)"
        req.url = "https://\(DocsIconDomain.docsDomain)/space/api/icon/pack/" + param
        req.method = .get
        
        var header: [String: String] = [:]
        let sessionStr = "session=" + (passport?.user.sessionKey ?? "")
        header["Cookie"] = sessionStr
        
        if EnvManager.env.type == .staging {
            if let boeFeatureEnv = KVPublic.Common.ttenv.value(), boeFeatureEnv.isEmpty == false {
                header["x-tt-env"] = boeFeatureEnv
            }
        }
        req.headers = header
        
        return client.sendAsyncRequest(req) { (resp: SendHttpResponse) -> [String: Any]? in
            
            guard let json = try? JSONSerialization.jsonObject(with: resp.body, options: []) else {
                DocsIconLogger.logger.error("sendAsyncRequestDocsIcon resp.body error: \(resp.body)")
                return nil
            }
            
            guard let map = json as? [String: Any] else {
                DocsIconLogger.logger.error("sendAsyncRequestDocsIcon json error: \(json)")
                return nil
            }
            return map
        }
        
    }
    
    func sendAsyncRequestDocsIcon(token: String, type: CCMDocsType) -> Observable<String?> {
        
        self.sendAsyncHttpRequest(token: token, type: type).map { [weak self] res in
        
            guard let strJson = res else {
                DocsIconLogger.logger.error("sendAsyncRequestDocsIcon json error: \(res)")
                return nil
            }
            guard let dataMap = strJson["data"] as? [String: Any] else {
                DocsIconLogger.logger.error("sendAsyncRequestDocsIcon dataMap error: \(strJson)")
                return nil
            }
            
            if let icon_info = dataMap["icon_info"] as? String {
                //缓存的信息
                self?.iconCache?.saveMetaInfo(docsToken: token, iconInfo: icon_info)
                return icon_info
            } else {
                DocsIconLogger.logger.error("sendAsyncRequestDocsIcon icon_info error")
                
                //icon_info为空，走兜底数据
                guard let objType = dataMap["obj_type"] as? Int else {
                    DocsIconLogger.logger.error("sendAsyncRequestDocsIcon icon_info error and obj_type nil")
                    return nil
                }
                
                let title = dataMap["title"] as? String ?? ""
                let token = dataMap["token"] as? String ?? ""
                let version = dataMap["version"] as? Int ?? 0
                
                let docsType = CCMDocsType(rawValue: objType)
                var fileType = ""
                if docsType == .file {
                    fileType = DocsIconInfo.getFileExtension(from: title) ?? ""
                }
                
                //兜底转成字符串返回，这里处理看起来很lower很lower，原因是前期没有跟后端沟通好兜底的逻辑，最后给了这个临时的方案
                let iconInfo = "{\"type\":\(0),\"obj_type\":\(objType),\"file_type\":\"\(fileType)\",\"token\":\"\(token)\",\"version\":\(version)}"
                
                // 改动上面iconInfo json，需要验证下json转DocsIconInfo是否成功
                // let info =  DocsIconInfo.createDocsIconInfo(json: iconInfo)
                
                //缓存的信息
                self?.iconCache?.saveMetaInfo(docsToken: token, iconInfo: iconInfo)
                
                return iconInfo
            }
        }
        
    }
    
    
}
