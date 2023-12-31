//
//  DocsType+FG.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/3/13.
//  

import Foundation
import SKFoundation
import LarkAppConfig
import SpaceInterface
import SKInfra

extension DocsType {

    /// 为了保证所有地方读到的值一致，这里需要确保当前用户的账号周期内都不会改变取值
    private(set) public static var mindnoteEnabled: Bool = false

    /// 在用户登录后调用此方法更新 mindnote FG 的值
    public static func updateMindnoteEnabled() {

        if DomainConfig.envInfo.isFeishuBrand {
            // mindnote 国内已经GA, 如果需要改动此处逻辑，请先 找周源 or mindnote 团队的同学 review
            DocsLogger.info("DocsType.mindnote.fg --- updating mindnote fg final using value: \(true), using env config not isOversea")
            mindnoteEnabled = true
            return 
        }
        let cacheValue = LKFeatureGating.mindnoteEnable
        DocsLogger.info("DocsType.mindnote.fg --- updating mindnote fg final using value: \(cacheValue)")
        mindnoteEnabled = cacheValue
    }
}
