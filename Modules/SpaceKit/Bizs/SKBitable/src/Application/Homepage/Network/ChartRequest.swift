//
//  ChartRequest.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/11/14.
//

import Foundation
import UIKit
import SKCommon
import SKFoundation
import SKInfra
import SwiftyJSON

class ChartRequest {
    
    /// 获取图表骨架数据
    /// - Parameter completion: 回调结果,网络请求成功时返回 ChartResponse
    static func requestHomePageChartData(with completion: @escaping (ChartResponse?, Error?) -> Void) {
        DocsLogger.info("Chart request start", component: LogComponents.baseChart)
        DocsRequest<JSON>(path: OpenAPI.APIPath.homePageChart, params: nil)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .set(timeout: 30)
            .makeSelfReferenced()
            .start(rawResult: { (data, resp, error) in
                DocsLogger.info("Chart response recieved \(String(describing: error))", component: LogComponents.baseChart)
                if let data = data, error == nil {
                    if let json = data.json, DocsNetworkError.isSuccess(json["code"].int)  {
                        completion(ChartResponse(json["data"]), nil)
                        // 无论是否返回charts，都是用户数据，都要缓存
                        if let _ = json["data"]["charts"].array {
                            DispatchQueue.global().async {
                                if let toCacheObj = json["data"].dictionaryObject {
                                    do {
                                        let data = try JSONSerialization.data(withJSONObject: toCacheObj, options: [])
                                        ChartRequestCache.shared.saveCache(data) { result in
                                            DocsLogger.info("Chart cache saved \(result)", component: LogComponents.baseChart)
                                        }
                                    } catch {
                                        DocsLogger.info("Chart cache saved serialization failed", component: LogComponents.baseChart)
                                    }
                                }
                            }
                        }
                    } else {
                        var userInfo: [String: Any] = [:]
                        userInfo["request_id"] = (resp?.allHeaderFields["request-id"] as? String) ?? ""
                        completion(nil, NSError(domain: "baseNetworkParseError", code: -1, userInfo: userInfo))
                    }
                } else {
                    completion(nil , error)
                }
            })
    }
    
    static func updateUserChartData(_ param:UpdateChartRequestParam, with completion: @escaping (Bool, Error?) -> Void) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.homePageChart, params: param.transformToDict())
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .makeSelfReferenced()
            .start(rawResult: { (data, resp, error) in
                if let data = data, error == nil {
                    if let json = data.json, DocsNetworkError.isSuccess(json["code"].int)  {
                        completion(true, nil)
                    } else {
                        var userInfo: [String: Any] = [:]
                        userInfo["request_id"] = (resp?.allHeaderFields["request-id"] as? String) ?? ""
                        completion(false, NSError(domain: "baseNetworkParseError", code: -1, userInfo: userInfo))
                    }
                } else {
                    completion(false , error)
                }
            })
    }
    
    static func requestChartSlice(_ param: ChartSliceRequestParam, with completion: @escaping (chartLynxData?, Error?) -> Void) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.chartSliceData, params: param.transformToDict())
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .makeSelfReferenced()
            .start(rawResult: { (data, resp, error) in
                if let data = data, error == nil {
                    if let json = data.json,
                       let lynxData = json.dictionaryObject {
                        completion(lynxData,nil)
                    } else {
                        var userInfo: [String: Any] = [:]
                        userInfo["request_id"] = (resp?.allHeaderFields["request-id"] as? String) ?? ""
                        completion(nil, NSError(domain: "baseNetworkParseError", code: -1, userInfo: userInfo))
                    }
                } else {
                    completion(nil , error)
                }
            })
    }
    
    static func requestChartsInDashboard(_ param: SkeletonRequestParam, with completion: @escaping (DashboardResponse?, Error?) -> Void) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.chartInsertInDashboard, params: param.transformToDict())
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .makeSelfReferenced()
            .start(rawResult: { (data, resp, error) in
                if let data = data, error == nil {
                    if let json = data.json, DocsNetworkError.isSuccess(json["code"].int)  {
                        completion(DashboardResponse(json["data"]), nil)
                    } else {
                        var userInfo: [String: Any] = [:]
                        userInfo["request_id"] = (resp?.allHeaderFields["request-id"] as? String) ?? ""
                        completion(nil, NSError(domain: "baseNetworkParseError", code: -1, userInfo: userInfo))
                    }
                } else {
                    completion(nil , error)
                }
            })
    }
}

class ChartRequestCache {
    static let shared :ChartRequestCache = ChartRequestCache()
    
    private let cacheName: String = "Charts"
    private let cachePathIdentifier = "BaseChart"
    // 用户数据的废弃,当新版本不能兼容老版本的数据时,那么需要升级version. 例如V1->V2
    private let cacheVersion: String = "V1"
    
    private let lock: NSLock = NSLock()
    
    private let cacheFileBasePath = SKFilePath.globalSandboxWithCache.appendingRelativePath("Base")
    
    func saveCache(_ data:Data, result: @escaping ((Bool) -> Void)) {
        lock.lock(); defer { lock.unlock() }
        if let userFilePath = userRelatedFilePath() {
            createRecommendFileIfNeeded()
            guard let fileHandle = try? FileHandle.getHandle(forWritingAtPath: userFilePath) else {
                DocsLogger.error("create fileHandle fail", component: LogComponents.baseChart)
                result(false)
                return
            }
            fileHandle.seek(toFileOffset: 0)
            fileHandle.write(data)
            fileHandle.truncateFile(atOffset: UInt64(data.count))
            result(true)
        } else {
            DocsLogger.warning("Save cache failed of invalid userID", component: LogComponents.baseChart)
            result(false)
        }
    }
    
    func loadCache(_ maxAge: TimeInterval, completion: @escaping (ChartResponse?, Error?) -> Void) {
        lock.lock(); defer { lock.unlock() }
        if let userFilePath = userRelatedFilePath() {
            //检查缓存是否过期，过期则不使用
            guard checkCacheIsValid(maxAge) else {
                DocsLogger.warning("Load cache failed of cache expired")
                completion(nil, NSError(domain: "baseModelCacheExpiredError", code: -1, userInfo: nil))
                return
            }
            if let cacheData = userFilePath.contentsAtPath(),
               let json = cacheData.json  {
                completion(ChartResponse(json), nil)
            } else {
                DocsLogger.warning("Load cache failed of parse error", component: LogComponents.baseChart)
                completion(nil, NSError(domain: "baseModelParseError", code: -1, userInfo: nil))
            }
        } else {
            DocsLogger.warning("Load cache failed of invalid userID", component: LogComponents.baseChart)
            completion(nil, NSError(domain: "PathError", code: -2, userInfo: nil))
        }
    }
    
    func loadCacheSync() -> ChartResponse? {
        lock.lock(); defer { lock.unlock() }
        if let userFilePath = userRelatedFilePath() {
            if let cacheData = userFilePath.contentsAtPath(),
               let json = cacheData.json  {
                return ChartResponse(json)
            } else {
                DocsLogger.warning("Load cache sync failed of parse error", component: LogComponents.baseChart)
                return nil
            }
        } else {
            DocsLogger.warning("Load cache sync failed of invalid userID", component: LogComponents.baseChart)
            return nil
        }
    }
    
    func checkCacheIsValid(_ maxAge: TimeInterval) -> Bool {
        // 检查文档更新时间，超过有效期，清理文档
        guard let userFilePath = userRelatedFilePath(),
              let modification = userFilePath.fileAttribites[FileAttributeKey.modificationDate] as? NSDate else {
            DocsLogger.btInfo("readPermission file'time error")
            return false
        }
        // 权限缓存有效期配置下发
        if (NSDate().timeIntervalSince1970 - modification.timeIntervalSince1970) >= maxAge {
            DocsLogger.btInfo("readPermission remove cacheFile for time‘s out")
            return false
        }
        return true
    }
    
    func userRelatedFilePath() -> SKFilePath? {
        if let userRelatedFileRoot = userRelatedFileRoot() {
            return userRelatedFileRoot.appendingRelativePath(cacheName)
        }
        return nil
    }
    
    func userRelatedFileRoot() -> SKFilePath? {
        if let userId = User.current.info?.userID as? String, !userId.isEmpty {
            return SKFilePath.bitableUserSandboxWithCache(userId).appendingRelativePath(cachePathIdentifier).appendingRelativePath(cacheVersion)
        }
        return nil
    }
    
    private func createRecommendFileIfNeeded() {
        if let directoryPath = userRelatedFileRoot(), !directoryPath.exists {
            do {
                try directoryPath.createDirectory(withIntermediateDirectories: true)
                DocsLogger.info("create directory:\(directoryPath) success", component: LogComponents.baseChart)
            } catch {
                DocsLogger.error("create directory error:\(error)", component: LogComponents.baseChart)
            }
        }
        if let filePath = userRelatedFilePath(), !filePath.exists {
            do {
                let isSuccess = filePath.createFile(with: nil)
                DocsLogger.debug("create file:\(filePath) success:\(isSuccess)", component: LogComponents.baseChart)
            } catch {
                DocsLogger.error("create file error:\(error)", component: LogComponents.baseChart)
            }
        }
    }
}

extension ChartRequestCache {
    func updateCache(_ charts:[Chart]) {
        if let orginCache = loadCacheSync() {
            orginCache.updateCharts(charts)
            if let newCacheData = orginCache.toJsonData() {
                self.saveCache(newCacheData) { finished in
                    DocsLogger.info("Chart cache update \(finished)", component: LogComponents.baseChart)
                }
            }
        }
    }
}
