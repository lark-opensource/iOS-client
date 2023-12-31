//
//  AppFeedbackDefines.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/7/19.
//

import Foundation

enum AppFeedbackFailedType: String {
    case BuildQueryFailed = "build_query_failed"
    case BuildURLFailed = "build_url_failed"
    case NoPermission = "no_permission"
    case NavigatorMiss = "navigator_miss"
}
