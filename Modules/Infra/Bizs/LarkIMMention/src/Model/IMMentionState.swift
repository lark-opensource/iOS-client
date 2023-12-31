//
//  IMMentionViewModel.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/22.
//

import Foundation
import RxSwift
import UIKit
import SwiftUI

class IMMentionState: CustomStringConvertible {
    var isShowSkeleton = true
    var isMultiSelected = false
    var searchText: String = ""
    var isLoading: Bool = false
    // 是否重新加载数据,输入变化数据刷新此值为true，上拉刷新时此值应为false
    var isReloading: Bool = true
    var error: VMError?
    var hasMore: Bool = false
    // 名字索引数组
    var nameIndex: [String]?
    // 第几个section开始索引
    var nameIndexForm = 0
    var nameDict: [Int: Int] = [:]
    
    /// 是否展示隐私信息
    var isShowPrivacy: Bool = false
    var description: String {
        return "isShowSkeleton: \(isShowSkeleton), isLoading: \(isLoading) \(searchText), error: \(error.debugDescription)"
    }
    
    enum VMError: Error {
        case noResult
        case noRecommendResult
        case network(Error)
        
        var errorString: String {
            switch self {
            case .noResult:
                return BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text
            case .noRecommendResult:
                return BundleI18n.LarkIMMention.Lark_IM_Mention_NoRecommendsSearchDocs_EmptyState
            case .network(_):
                return BundleI18n.LarkIMMention.Lark_Mention_ErrorUnableToLoadNetworkError_Placeholder
            }
        }
    }
}

