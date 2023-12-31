//
//  SettingConfigKeyDefine.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/11/3.
//

import Foundation
public enum DomainConfigKey: String {
    case previousDomainReg // 路由层，对文档打开url，进行正则匹配
    case newDomainReplacement // 路由层，对文档打开url，进行正则匹配成功后，做的替换处理
}

