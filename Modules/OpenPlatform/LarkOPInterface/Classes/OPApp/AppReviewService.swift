//
//  AppReviewService.swift
//  ECOInfra
//
//  Created by xiangyuanyuan on 2022/1/10.
//

import Foundation
import ECOInfra

public protocol AppReviewService: AnyObject {
    var opAppReviewConfig: OPAppReviewConfig? { get }
    func syncAppReview(appId: String, trace: OPTrace, callback: @escaping (_ reviewInfo: AppReviewInfo?, _ error: OPError?) -> Void)
    func getAppReviewLink(appLinkParams: AppLinkParams) -> URL?
    func isAppReviewEnable(appId: String) -> Bool
    func getAppReview(appId: String) -> AppReviewInfo?
}
