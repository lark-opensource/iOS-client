//
//  LocationAccessStatusChange.swift
//  OPPlugin
//
//  Created by zhangxudong on 5/7/22.
//

import TTMicroApp
/// 小程序定位状态图标
protocol LocationAccessStatusChange {}

extension LocationAccessStatusChange {
    func updateLocationAccessStatus(isUsing: Bool) {
        OPLocationPrivacyAccessStatusManager.shareInstance().updateSingleLocationAccessStatus(isUsing)
    }
}
