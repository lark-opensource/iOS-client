//
//  RecommendCacheManager.swift
//  LarkSearch
//
//  Created by chenziyue on 2021/11/4.
//

import Foundation
import RustPB
import ServerPB
import LarkSDKInterface
import RxSwift
import LarkSearchCore
import LarkSearch
import UniverseDesignToast
import EENavigator
import LarkAppLinkSDK
import LarkAlertController
import LarkUIKit
import RxRelay
import LKCommonsLogging
import LarkLocalizations

struct RecommendCacheKey: Hashable, Equatable {
    var userId: String
    var tenantId: String
    var currentTab: SearchTab
    var languageId: String

    init(tab: SearchTab, userId: String, tenantId: String) {
        self.currentTab = tab
        self.userId = userId
        self.tenantId = tenantId
        self.languageId = LanguageManager.currentLanguage.localeIdentifier
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.userId)
        hasher.combine(self.tenantId)
        hasher.combine(self.languageId)
        hasher.combine(self.currentTab.id)
    }
    var HashValue: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }
    var hashKey: String {
        return String(HashValue)
    }
    static func == (lhs: RecommendCacheKey, rhs: RecommendCacheKey) -> Bool {
        if lhs.userId != rhs.userId {
            return false
        } else if lhs.tenantId != rhs.tenantId {
            return false
        } else if lhs.currentTab.id != rhs.currentTab.id {
            return false
        } else if lhs.languageId != rhs.languageId {
            return false
        }
        return true
    }
}

final class RecommendCacheManager {
    private var cacheDict: [String: [UniversalRecommendSection]] = [String: [UniversalRecommendSection]]()
    static let shared = RecommendCacheManager()

    private init() {}
    func saveSections(sections: [UniversalRecommendSection], cacheKey: RecommendCacheKey) {
        var index = cacheKey.hashKey
        // TODO: 限制字典的大小，等以后有时间了手动实现一个LRU。
        if let data = self.cacheDict[index] {
            if data != sections {
                self.cacheDict[index] = sections
            }
            self.cacheDict[index] = sections
        } else {
            self.cacheDict[index] = sections
        }
    }
    func loadSections(cacheKey: RecommendCacheKey) -> [UniversalRecommendSection] {
        var index = cacheKey.hashKey
        if let data = self.cacheDict[index] {
            return data.map { section in
                if case let .chip(sectionData) = section {
                    sectionData.isFold = true
                    return .chip(sectionData)
                }
                return section
            }
        } else {
            return [UniversalRecommendSection]()
        }
    }
}
