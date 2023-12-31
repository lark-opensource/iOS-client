//
//  ChatAPIDefine.swift
//  EEMicroAppSDK
//
//  Created by zhaojingxin on 2023/4/25.
//

import Foundation

public enum OpenAPIChooseContactAPIExEmployeeFilterType: String, RawRepresentable, CaseIterable {
    /// 既包含在职人员，也包含离职人员
    case all = "all"
    /// 只包含离职人员
    case exEmployee = "ex-employee"
    /// 只包含在职人员
    case employee = "employee"
}
