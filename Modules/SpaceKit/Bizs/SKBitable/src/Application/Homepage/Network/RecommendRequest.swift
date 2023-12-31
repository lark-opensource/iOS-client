//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/9/4.
//

import Foundation
import UIKit
import SKCommon
import SKFoundation
import SKInfra
import SwiftyJSON

public class RecommendRequest {
    
    /// 加载首页瀑布流
    /// - Parameters:
    ///   - param: 请求入参
    ///   - completion: 数据响应回调
    static func requestRecommendData(_ param:RecommendRequestParam, context: BaseHomeContext, with completion: @escaping (RecommendResponse?, Error?) -> Void) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.homePageRecommend, params: param.transformToDict())
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .makeSelfReferenced()
            .start(rawResult: { (data, resp, error) in
                if let data = data, error == nil {
                    if let json = data.json, DocsNetworkError.isSuccess(json["code"].int)  {
                        let trackingParams = TrackingParams(requestId: (resp?.allHeaderFields["request-id"] as? String) ?? "",
                                                            baseHPFrom: param.baseHPFrom,
                                                            isRefresh: param.isRefresh)
                        completion(RecommendResponse(json["data"], trackingParams: trackingParams, context: context), nil)

                        // 满足返回内容个数>=请求个数的才会存储
                        if param.needCache && json["data"]["contents"].arrayValue.count >= RecommendConfig.shared.recommenChunkSize {
                            DispatchQueue.global().async {
                                RecommendRequestCache.shared.saveCache(data) { result in
                                    DocsLogger.info("Recommend chache saved \(result)", component: LogComponents.baseRecommend)
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
    
    static func batchReportData(_ param:BacthReportRequestParam) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.homePageRecommendReport, params: param.transformToDict())
            .set(method: .POST)
            .set(encodeType: .urlEncodeDefault)
            .makeSelfReferenced()
            .start(rawResult: { (data, _, error) in
                if let data = data, error == nil {
                    if let json = data.json, DocsNetworkError.isSuccess(json["code"].int)  {
                        DocsLogger.info("Recommend batchReportData success", component: LogComponents.baseRecommend)
                    } else {
                        DocsLogger.error("Recommend batchReportData biz error", component: LogComponents.baseRecommend)
                    }
                } else {
                    DocsLogger.error("Recommend batchReportData net error", component: LogComponents.baseRecommend)
                }
            })
    }
    
    /// 加载首页默认展示tab分流
    /// - Parameters:
    ///   - completion: 数据响应回调
    public static func requestHomeDiversion(with completion: @escaping (DiversionResponse?, Error?) -> Void) {
        DocsRequest<JSON>(path: OpenAPI.APIPath.homePageDiversion, params: nil)
            .set(method: .POST)
            .set(encodeType: .urlEncodeDefault)
            .makeSelfReferenced()
            .start(rawResult: { (data, _, error) in
                
//                let json = JSON(parseJSON: "{\"tab\":{\"default\":\"my\",\"expire_time\":1694495109}}")
//                completion(DiversionResponse(json), nil)
                
                if let data = data, error == nil {
                    if let json = data.json, DocsNetworkError.isSuccess(json["code"].int)  {
                        completion(DiversionResponse(json["data"]), nil)
                    } else {
                        completion(nil, NSError(domain: "baseNetworkParseError", code: -1, userInfo: nil))
                    }
                } else {
                    completion(nil , error)
                }
            })
    }
}

class RecommendRequestCache {
    static let shared :RecommendRequestCache = RecommendRequestCache()
    
    private let cacheName: String = "Recommends"
    private let cachePathIdentifier = "BaseRecommend"
    // 用户数据的废弃,当新版本不能兼容老版本的数据时,那么需要升级version. 例如V1->V2
    private let cacheVersion: String = "V1"
    
    private let lock: NSLock = NSLock()
    
    private let cacheFileBasePath = SKFilePath.globalSandboxWithCache.appendingRelativePath("Base")
    
    func saveCache(_ data:Data, result: @escaping ((Bool) -> Void)) {
        lock.lock(); defer { lock.unlock() }
        if let userFilePath = userRelatedFilePath() {
            createRecommendFileIfNeeded()
            guard let fileHandle = try? FileHandle.getHandle(forWritingAtPath: userFilePath) else {
                DocsLogger.error("create fileHandle fail", component: LogComponents.baseRecommend)
                result(false)
                return
            }
            fileHandle.seek(toFileOffset: 0)
            fileHandle.write(data)
            fileHandle.truncateFile(atOffset: UInt64(data.count))
            result(true)
        } else {
            DocsLogger.warning("Save cache failed of invalid userID", component: LogComponents.baseRecommend)
            result(false)
        }
    }
    
    func loadCache(context: BaseHomeContext, completion: @escaping (RecommendResponse?, Error?) -> Void) {
        lock.lock(); defer { lock.unlock() }
        if let userFilePath = userRelatedFilePath() {
            if let cacheData = userFilePath.contentsAtPath(),
               let json = cacheData.json,
               DocsNetworkError.isSuccess(json["code"].int)  {
                completion(RecommendResponse(json["data"], trackingParams: nil, context: context), nil)
            } else {
                DocsLogger.warning("Load cache failed of parse error", component: LogComponents.baseRecommend)
                completion(nil, NSError(domain: "baseModelParseError", code: -1, userInfo: nil))
            }
        } else {
            DocsLogger.warning("Load cache failed of invalid userID", component: LogComponents.baseRecommend)
            completion(nil, NSError(domain: "PathError", code: -2, userInfo: nil))
        }
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
                DocsLogger.info("create directory:\(directoryPath) success", component: LogComponents.baseRecommend)
            } catch {
                DocsLogger.error("create directory error:\(error)", component: LogComponents.baseRecommend)
            }
        }
        if let filePath = userRelatedFilePath(), !filePath.exists {
            do {
                let isSuccess = filePath.createFile(with: nil)
                DocsLogger.debug("create file:\(filePath) success:\(isSuccess)", component: LogComponents.baseRecommend)
            } catch {
                DocsLogger.error("create file error:\(error)", component: LogComponents.baseRecommend)
            }
        }
    }
}

class RecommendUserBehaviorBatchReporter {
    static let shared :RecommendUserBehaviorBatchReporter = RecommendUserBehaviorBatchReporter()
    private let reportQueue = DispatchQueue(label: "RecommendUserBehaviorBatchReporter.serialQueue", qos: .default)
    private var reportTasks: [String] = []
    
    func reportExpose(_ contentId:String) {
        reportQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.reportTasks.isEmpty {
                let reportInterval = TimeInterval(Float(RecommendConfig.shared.recommendViewReportInterval) / 1000.0)
                self.reportQueue.asyncAfter(deadline: .now() + reportInterval) { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    if !self.reportTasks.isEmpty {
                        let contentIds = self.reportTasks.map { contentId in
                            return contentId
                        }
                        RecommendRequest.batchReportData(BacthReportRequestParam(contentIds: contentIds,activityType: 1))
                        self.reportTasks = []
                    }
                }
            }
            self.reportTasks.append(contentId)
        }
    }
    
    func reportClick(_ contentId:String) {
        RecommendRequest.batchReportData(BacthReportRequestParam(contentIds: [contentId],activityType: 2))
    }
}
