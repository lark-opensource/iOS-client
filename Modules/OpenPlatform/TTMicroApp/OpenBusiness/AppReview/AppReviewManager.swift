//
//  AppReview.swift
//  TTMicroApp
//
//  Created by xiangyuanyuan on 2021/12/20.
//

import Foundation
import OPSDK
import LKCommonsLogging
import LarkOpenAPIModel
import LarkContainer
import LarkAccountInterface
import LarkOPInterface
import LarkFeatureGating
import OPFoundation

/// 日志
private let logger = Logger.log(AppReviewManager.self, category: "LarkOpenPlatform")

extension Notification.Name {
    public static let storeAppReview = Notification.Name(rawValue: "appReview.storeAppReview")
}
/// 评分SDK
public final class AppReviewManager: AppReviewService {
    
    /// 开放平台评分配置：提供 applink
    public let opAppReviewConfig: OPAppReviewConfig? = {
        @Provider var service: ECOConfigService
        guard let config = service.getDictionaryValue(for: OPAppReviewConfig.ConfigName) else {
            return nil
        }
        return OPAppReviewConfig(config: config)
    }()

    public init() {}
    
    /// 存储评分记录
    private func storeAppReviewInfo(appId: String, reviewInfo: AppReviewInfo) {
        guard let userId = AccountServiceAdapter.shared.foregroundUser?.userID else {
            logger.error("storeAppReviewRecord fail, userId is nil")
            return
        }
        AppReviewDataStore.setAppReview(appId: appId, userId: userId, reviewInfo: reviewInfo)
        NotificationCenter.default.post(name: Notification.Name.storeAppReview,
                                        object: nil,
                                        userInfo: ["userId": userId, "reviewInfo": reviewInfo])
    }

    /// 从本地获取评分
    public func getAppReview(appId: String) -> AppReviewInfo? {
        guard let userId = AccountServiceAdapter.shared.foregroundUser?.userID else {
            logger.error("getAppReview fail, userId is nil")
            return nil
        }
        return AppReviewDataStore.getAppReview(appId: appId, userId: userId)
    }

    /// 拉取评分记录--网络接口
    public func syncAppReview(
        appId: String,
        trace: OPTrace,
        callback: @escaping (_ reviewInfo: AppReviewInfo?, _ error: OPError?) -> Void
    ) {
        let completionHandler: ([AnyHashable: Any]?, Error?) -> Void = { [weak self] (result, error) in
            
            guard let self = self else{
                logger.error("self is nil", error: error)
                callback(nil, OPError.error(monitorCode: CommonMonitorCode.fail))
                return
            }
            guard error == nil else {
                logger.error("network internal error", error: error)
                callback(nil, OPError.error(monitorCode: CommonMonitorCode.fail))
                return
            }
            guard let result = result, let code = result["code"] as? Int else {
                logger.error("internal json error")
                callback(nil, OPError.error(monitorCode: CommonMonitorCode.fail))
                return
            }
            // code为0 说明请求成功
            guard code == 0 else {
                let errorMsg = "requst syncAppReview error"
                let additionalData = ["code": "\(result["code"])", "msg": "\(result["msg"])"]
                logger.error(errorMsg, additionalData: additionalData)
                callback(nil, OPError.error(monitorCode: CommonMonitorCode.fail))
                return
            }
            guard let data = result["data"] as? [AnyHashable: Any],
                  let score = data["score"] as? Float,
                  let isReviewed = data["scoreStatus"] as? Int else {
                      logger.error("wrong data format")
                      callback(nil, OPError.error(monitorCode: CommonMonitorCode.fail))
                      return
                  }
            // scoreStatus: 1-尚未评分 2-展示具体评分
            let appReviewInfo = AppReviewInfo(score: score,
                                              isReviewed: isReviewed == 2,
                                              lastTestSyncTime: Date().timeIntervalSince1970)
            // 同步到本地
            self.storeAppReviewInfo(appId: appId, reviewInfo: appReviewInfo)
            callback(appReviewInfo, nil)
        }
        // 创建网络请求需要的context
        let context = AppReviewContext(appId: appId, trace: trace)
        SyncAppReviewNetworkInterface.syncAppReview(with: context, parameters: [:], completionHandler: completionHandler)
    }

    /// appLink拼接
    public func getAppReviewLink(appLinkParams: AppLinkParams) -> URL? {
        guard let appReviewConfig = opAppReviewConfig else {
            logger.error("appReviewConfig is nil")
            return nil
        }
        // 提取 applink, 添加 bdp_launch_query 参数
        guard var applinkComponents = URLComponents(string: appReviewConfig.baseAppLink),
              let launchQuery = tryBuildAppReviewLaunchQuery(appLinkParams: appLinkParams) else {
            logger.error("build launch query failed")
            return nil
        }
        var queryItems = applinkComponents.queryItems ?? []
        queryItems.append(launchQuery)
        applinkComponents.queryItems = queryItems
        return applinkComponents.url
    }
    
    private func tryBuildAppReviewLaunchQuery(appLinkParams: AppLinkParams) -> URLQueryItem? {
        var params: [String: AnyHashable] = [
            "app_id": appLinkParams.appId,
            "app_icon": appLinkParams.appIcon,
            "app_name": appLinkParams.appName,
            "app_type": appLinkParams.appType.rawValue,
            "app_version": appLinkParams.appVersion,
            "page_path": appLinkParams.pagePath,
            "from_type": appLinkParams.fromType.rawValue,
            "trace": appLinkParams.trace
        ]
        /// 被评分应用的 Scene 值，仅小程序包含
        if appLinkParams.appType == .gadget {
            params["orig_scene_type"] = appLinkParams.origSeneType
        }
        guard JSONSerialization.isValidJSONObject(params) else {
            logger.error("params is invalid")
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: params)
            guard !data.isEmpty else {
                logger.error("data is empty!")
                return nil
            }
            return URLQueryItem(name: "bdp_launch_query", value: String(data: data, encoding: .utf8))
        } catch {
            logger.error("parse json failed!", error: error)
            return nil
        }
    }
    
    public func isAppReviewEnable(appId: String) -> Bool {
        // 判断评分入口是否显示
        guard LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.appreview.show") else {
            return false
        }
        guard let config = opAppReviewConfig else {
            return false
        }
        // 判断是否在黑名单中
        if config.appBlackList.contains(appId){
            return false
        }
        // open_to_all为true 或者 open_to_all为false 但是appid在白名单中
        if config.openToAll || (!config.openToAll && config.appWhiteList.contains(appId)) {
            return true
        }
        return false
    }
}

public final class AppReviewContext: ECONetworkServiceContext {

    public let trace: OPTrace
    // 提供path拼接的参数
    public let appId: String
    
    public init(appId: String, trace: OPTrace) {
        self.appId = appId
        self.trace = trace
    }
    
    public func getTrace() -> OPTrace {
        return self.trace
    }

    public func getSource() -> ECONetworkRequestSourceWapper? {
        return ECONetworkRequestSourceWapper(source: .api)
    }
}
