//
//  AppReviewDataStore.swift
//  TTMicroApp
//
//  Created by xiangyuanyuan on 2021/12/27.
//

import Foundation
import LKCommonsLogging
import LarkOPInterface
import LarkStorage
import LarkSetting
import LarkContainer

final class AppReviewDataStore {
    
    static let logger = Logger.log(AppReviewDataStore.self, category: "LarkOpenPlatform")
    
    private static let store = KVStores.in(space: .global, domain: Domain.biz.microApp).udkv()
    
    public static func setAppReview(appId: String, userId: String, reviewInfo: AppReviewInfo) {
        do {
            let data = try JSONEncoder().encode(reviewInfo)
            LSUserDefault.standard.set(data, forKey: appIdAndUserId(appId: appId, userId: userId))
        } catch {
            logger.error("can not encode json dic with error: \(error)")
        }
    }
    
    public static func getAppReview(appId: String, userId: String) -> AppReviewInfo? {
        do {
            var data: Data? = LSUserDefault.standard.getData(forKey: appIdAndUserId(appId: appId, userId: userId))
            guard let data = data else {
                return nil
            }
            let appReviewInfo = try JSONDecoder().decode(AppReviewInfo.self, from: data)
            return appReviewInfo
        } catch {
            logger.error("can not decode json dic with error: \(error)")
            return nil
        }
    }
    
    private static func appIdAndUserId(appId: String, userId: String) -> String {
        "\(appId)_\(userId)"
    }
}
