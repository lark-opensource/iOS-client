//
//  DocsIconManager+UrlParse.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/30.
//

import Foundation
import RxSwift
import LarkContainer

extension DocsIconManager {
    
    ///通过token和type，进行下载icon信息
    func parseDocsToken(token: String,
                        type: CCMDocsType,
                        shape: IconShpe,
                        container: ContainerInfo?) -> Observable<UIImage> {
        
        guard !token.isEmpty else {
            DocsIconLogger.logger.error("url get fileInfo error, token: \(String(describing: token)), type: \(String(describing: type))")
            return .just(DocsIconInfo.defultUnknowIcon(docsType: type, shape: shape, container: container))
        }
        
        //1. 先判断本地是否有缓存，有则先返回缓存，再走下载图片
        let checkLocalCacheObserve = self.checkLocalCache(token: token, type: type, shape: shape, container: container)
        
        guard let iconRequest = iconRequest else {
            DocsIconLogger.logger.error("iconRequest is nil")
            return checkLocalCacheObserve
        }
        
        //2. 再返回下载的
        let requestDocIconObserve = iconRequest
            .sendAsyncRequestDocsIcon(token: token, type: type)
            .flatMap({ iconInfo -> Observable<UIImage> in
                
                guard let iconInfo = iconInfo else {
                    DocsIconLogger.logger.error("request docs icon info nil")
                    return self.checkLocalCache(token: token, type: type, shape: shape, container: container)
                }
                
                return self.createLocalIcon(iconInfo: iconInfo, shape: shape, container: container)
                    .asObservable()
                    .catchError { error in
                        if let error = error as? DocsIconError {
                            switch error {
                                //走下载逻辑
                            case.iconInfoNeedDownload(let iconEntry):
                                
                                return self.downloadIcon(iconInfo: iconEntry,
                                                         shape: shape,
                                                         container: container)
                                
                            default:
                                DocsIconLogger.logger.error("createLocalIcon no handle error : \(error)")
                                break
                            }
                        }
                        return .just(DocsIconInfo.defultUnknowIcon(docsType: type, shape: shape, container: container))
                    }
                
            }).catchError { error in
                DocsIconLogger.logger.error("request docs icon info error: \(error)")
                return self.checkLocalCache(token: token, type: type, shape: shape, container: container)
            }
        
        return checkLocalCacheObserve.concat(requestDocIconObserve)
    }
    
    ///通过文档url，进行下载icon信息
    func parseDocsUrl(_ url: String,
                      shape: IconShpe,
                      container: ContainerInfo?) -> Observable<UIImage> {
        
        
        guard let url = URL(string: url) else {
            DocsIconLogger.logger.error("url parse error:\(url)")
            return .just(DocsIconInfo.defultUnknowIcon(docsType: .unknownDefaultType, shape: shape, container: container))
        }
        //通过url，解析token和type
        let fileInfo = iconUrlUtil?.getFileInfoNewFrom(url)
        
        return self.parseDocsToken(token: fileInfo?.token ?? "" ,
                                   type: fileInfo?.type ?? .unknownDefaultType,
                                   shape: shape,
                                   container: container)
    }
    
    
    //先返回本地占位图
    private func checkLocalCache(token: String,
                                 type: CCMDocsType,
                                 shape: IconShpe,
                                 container: ContainerInfo?) -> Observable<UIImage> {
        
        //1. 查询本地mata信息
        guard let localMetaInfo = self.iconCache?.getMetaInfoForKey(Key: token) else {
            return DocsIconInfo.defultUnknowIconObserve(docsType: type, shape: shape, container: container)
        }
        
        //2. 本地meta解析失败
        guard DocsIconInfo.createDocsIconInfo(json: localMetaInfo) != nil else {
            return DocsIconInfo.defultUnknowIconObserve(docsType: type, shape: shape, container: container)
        }
        
        //3. 返回本地图片
        return self.createLocalIcon(iconInfo: localMetaInfo, shape: shape, container: container)
            .asObservable()
            .catchError { error in
                if let error = error as? DocsIconError {
                    switch error {
                        //走下载逻辑
                    case.iconInfoNeedDownload(let iconEntry):
                        
                        return self.downloadIcon(iconInfo: iconEntry,
                                                 shape: shape,
                                                 container: container)
                        
                    default:
                        //其他错误场景不用处理
                        DocsIconLogger.logger.error("createLocalIcon no handle error : \(error)")
                    }
                }
                return .just(DocsIconInfo.defultUnknowIcon(docsType: type, shape: shape, container: container))
            }
    }
    
}
