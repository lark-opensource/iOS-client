//
//  WPBaseViewController+Tracker.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/28.
//

import Foundation

extension WPBaseViewController {
    /// 页面停留时间（四舍五入），单位：秒
    var pageStayDuration: Int {
        guard let end = pageLeaveTs, let start = pageEnterTs, end > start else {
            return 0
        }
        return Int(round(end - start))
    }
}
