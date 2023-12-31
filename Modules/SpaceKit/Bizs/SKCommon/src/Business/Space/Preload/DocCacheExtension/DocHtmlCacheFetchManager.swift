//
//  DocHtmlCacheFetchManager.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/9/8.
//
// 用来专门提前拉取SSR，并缓存的服务

import Foundation
import LarkContainer
import SpaceInterface
import SKFoundation
import SKInfra
import LKCommonsTracker

public typealias HtmlCacheResult = (_ data: H5DataRecord?, _ error: Error?) -> Void

public enum HtmlCacheRequestState {
    case beginRequet //正在请求中
    case ok(H5DataRecord) //请求成功
}

public class DocHtmlCacheFetchManager: UserResolverWrapper {
    
    public var userResolver: LarkContainer.UserResolver
    private var taskQueue: DispatchQueue = DispatchQueue(label: "DocHtmlCacheFetchManagerDispatchQueue")
    //记录需要回调数组
    private var callBackMap = [String: [HtmlCacheResult]]()
    
    // resolve NewCacheAPI
    lazy private var newCache: NewCacheAPI? = userResolver.resolve(NewCacheAPI.self)
    
    // 是否请求成功记录
    private var htmlCacheStateList = [String: HtmlCacheRequestState]()
    
    // 用来wiki文档或者真实文档token和type
    lazy private var wikiStorageAPI = DocsContainer.shared.resolve(WikiStorageBase.self)
    
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    //是否有正在请求ssr的文档
    public func hasFetchSSR(token: String) -> Bool {
        return htmlCacheStateList[token] != nil
    }
    
    // 是否需要提前下载ssr
    public func fetchDocHtmlCacheIfNeed(url: URL) {
        //订阅的文档没有ssr，不处理
        guard !DocsUrlUtil.isSubscription(url: url) else {
            return
        }
        let info = DocsUrlUtil.getFileInfoFrom(url)
        guard let token = info.token, let type = info.type else {
            return
        }
        fetchDocHtmlCacheIfNeed(token: token, type: type)
    }
    
    // 如果是wiki需要拉取下文档token+type
    private func fetchDocHtmlCacheIfNeed(token: String, type: DocsType) {
        //如果是wiki，需要多拉取一次wikiInfo
        if type == .wiki {
            guard let wikiStorage = wikiStorageAPI else {
                return
            }
            
            //从缓存读到wikiInfo
            if let wikiInfo = wikiStorage.getWikiInfo(by: token) {
                self.fetchDocHtmlCacheIfNeed(realToken: wikiInfo.objToken, realType: wikiInfo.docsType)
                return
            }
            
            //网络请求wikiInfo
            wikiStorage.setWikiMeta(wikiToken: token) { wikiInfo, _ in
                guard let wikiInfo = wikiInfo else {
                    return
                }
                self.fetchDocHtmlCacheIfNeed(realToken: wikiInfo.objToken, realType: wikiInfo.docsType)
            }
            
        } else {
            self.fetchDocHtmlCacheIfNeed(realToken: token, realType: type)
        }
    }
    
    
    private func fetchDocHtmlCacheIfNeed(realToken token: String, realType type: DocsType) {
        
        //只有docx才进行拉取ssr
        guard type == .docX else {
            DocsLogger.warning("only docx need fetch ssr, current type: \(type)", component: LogComponents.fetchSSR)
            return
        }
        
        //        //判断本地是否存有ssr
        guard let renderKey = type.htmlCachedKey,
              let prefix = User.current.info?.cacheKeyPrefix else {
            DocsLogger.warning("renderKey or prefix is nil", component: LogComponents.fetchSSR)
            return
        }
        
        if let record = newCache?.getH5RecordBy(H5DataRecordKey(objToken: token, key: prefix + renderKey)),
           record.payload != nil {
            DocsLogger.info("cache has ssr, without network request", component: LogComponents.fetchSSR)
            return
        }
        
        taskQueue.async {[weak self] in
            guard let self = self else {
                return
            }
            //先判断是否已经请求过：正在请求 or 请求完成
            if self.htmlCacheStateList[token] != nil {
                DocsLogger.info("ssr record in htmlCacheStateList，is requesting or request done，tokne：\(token)", component: LogComponents.fetchSSR)
                return
            }
            //记录正在请求中
            self.htmlCacheStateList[token] = .beginRequet
            DocsLogger.info("begin request ssr，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
            var preloadKey = PreloadKey(objToken: token, type: type)
            preloadKey.fromSource = PreloadFromSource(.fetchBeforeRender) //用做埋点
            var htmlTask = NativePerloadHtmlTask(key: preloadKey, taskQueue: self.taskQueue)
            htmlTask.start { result in
                
                self.taskQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let result):
                        DocsLogger.info("ssr request success，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                        if let record = result as? H5DataRecord {
                            //判断是否需要记录数据
                            //如果已经有注入回调了，就直接回调就可以，如果没有就记录下数据
                            if let callBack = self.callBackMap[token] {
                                
                                callBack.forEach { call in
                                    call(record, nil)
                                }
                                DocsLogger.info("ssr request success，and callback surccess，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                                //移除记录
                                self.htmlCacheStateList.removeValue(forKey: token)
                                self.callBackMap.removeValue(forKey: token)
                            } else { //记录数据
                                DocsLogger.info("ssr request success，but callback is nil，save data to htmlCacheStateList，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                                self.htmlCacheStateList[token] = .ok(record)
                            }
                            
                        } else {
                            //没有数据，移除请求记录
                            if let callBack = self.callBackMap[token] {
                                callBack.forEach { call in
                                    call(nil, nil) //TODO：看下error是否处理
                                }
                            }
                            DocsLogger.error("ssr request success，but result is nil，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                            self.htmlCacheStateList.removeValue(forKey: token)
                            self.callBackMap.removeValue(forKey: token)
                        }
                        
                    case .failure(let code):
                        DocsLogger.error("ssr request failure，code：\(code)，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                        //请求失败，异常请求记录
                        if let callBack = self.callBackMap[token] {
                            callBack.forEach { call in
                                call(nil, nil) //TODO：看下error是否处理
                            }
                        }
                        self.htmlCacheStateList.removeValue(forKey: token)
                        self.callBackMap.removeValue(forKey: token)
                    }
                }
            }
        }
    }
    
    //
    public func getDocHtmlCache(realToken token: String, realType type: DocsType, callBack: @escaping HtmlCacheResult) {
        taskQueue.async { [weak self] in
            guard let self = self else {
                callBack(nil, nil)
                return
            }
            if let state = self.htmlCacheStateList[token] {
                switch state {
                case .beginRequet:
                    DocsLogger.info("get SSR result: request not returned ，wating，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                    //正在请求中，记录回调等待
                    if var resultArr = self.callBackMap[token] {
                        resultArr.append(callBack)
                    } else {
                        self.callBackMap[token] = [callBack]
                    }
                case .ok(let record): //已经请求成功，返回ssr数据
                    callBack(record, nil)
                    DocsLogger.info("get SSR result: request success，return ssr，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                    //移除记录
                    self.htmlCacheStateList.removeValue(forKey: token)
                    self.callBackMap.removeValue(forKey: token)
                }
                
            } else { //没有正在请求，返回错误
                DocsLogger.error("get SSR result: no record，return error，token：\(token.encryptToken)", component: LogComponents.fetchSSR)
                callBack(nil, nil) //TODO: ERROR处理  1
            }
        }
    }
    
    //⚠️：用这个判断，需要自行判断docx和 wiki docx才能使用
    public static func fetchSSRBeforeRenderEnable() -> Bool {
        
        if !LKFeatureGating.docxSSREnable && !UserScopeNoChangeFG.HZK.enableIpadSSR {
            return false
        }
        
        guard UserScopeNoChangeFG.HZK.docsFetchSSRBeforeRender else {
            return false
        }
 
        
#if DEBUG
        return true
#else
        if let abEnable = Tracker.experimentValue(key: "docs_fetch_ssr_before_render_enable", shouldExposure: true) as? Int, abEnable == 1 {
            return true
        }
        return false
#endif
    }
    
}
