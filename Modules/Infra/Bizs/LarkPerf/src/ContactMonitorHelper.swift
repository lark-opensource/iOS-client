//
//  ContactMonitorHelper.swift
//  LarkPerf
//
//  Created by 姚启灏 on 2020/6/23.
//

import Foundation

public enum ContactMetricKey: String {
    /// profile metric
    case profile = "user_profile_load_time"
    case profileAvatar = "user_image_empty_cost"
}

public enum ContactLogKey: String {
    /// profile metric
    case profile = "eesa_user_profile_load_time"
    case profileAvatar = "eesa_user_image_empty_cost"
}
