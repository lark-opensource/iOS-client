//
//  FreshnessService.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/6/15.
//  

import SKFoundation
import SpaceInterface
import SKInfra
import RxSwift
import RxCocoa
import SwiftyJSON

public final class FreshnessService {

    /// 反馈文档过期
    static func feedbackExpired(objToken: String, objType: DocsType, feedbackNote: String?) -> Completable {
        let apiPath = OpenAPI.APIPath.feedbackFreshStatus
        var params: [String: Any] = [String: Any]()
        params["obj_token"] = objToken
        params["obj_type"] = objType.rawValue
        if let note = feedbackNote {
            params["feedback_note"] = note
        }
        let request = DocsRequest<JSON>(path: apiPath, params: params)
            .set(encodeType: .urlEncodeAsQuery)
            .set(method: .POST)
        return request.rxStart().asCompletable()
    }

    /// 设置文档新鲜度
    static func updateFreshStatus(info: FreshInfo, objToken: String, objType: DocsType) -> Completable {
        let apiPath = OpenAPI.APIPath.updateFreshStatus
        var params: [String: Any] = [String: Any]()
        params["obj_token"] = objToken
        params["obj_type"] = objType.rawValue
        params["fresh_status"] = info.freshStatus.rawValue
        params["deadline_time"] = info.deadlineTime
        let request = DocsRequest<JSON>(path: apiPath, params: params)
            .set(encodeType: .urlEncodeAsQuery)
            .set(method: .POST)
        return request.rxStart().asCompletable()
    }

    static let timeInterval_three_month: TimeInterval = 3 * 30 * 24 * 60 * 60

    /// 判断是否需要展示"提示文档过期"的onboarding
    public static func shouldShowReportOutdateTips(docsInfo: DocsInfo) -> Bool {
        guard UserScopeNoChangeFG.ZYP.docFreshnessEnable else { return false }
        guard docsInfo.isSameTenantWithOwner else { return false }

        // 非文档owner，且新鲜度不为"已是最新"或者"已过期"
        guard let freshStatus = docsInfo.freshInfo?.freshStatus else { return false }
        guard !docsInfo.isOwner && freshStatus.shouldShowFeedbackEntry else { return false }

        // 判断文档上次更新是不是3个月前
        guard let editTime = docsInfo.editTime else { return false }
        if Date().timeIntervalSince1970 - editTime >= timeInterval_three_month {
            DocsLogger.info("FreshnessService: shouldShowReportOutdateTips, editTime: \(editTime)")
            return true
        }
        return false
    }
}
