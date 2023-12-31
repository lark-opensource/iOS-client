//
//  WebNoAuthApi.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2020/12/14.
//

import Foundation

/// H5 免鉴权可调用的 API 列表，API 架构统一及分级逻辑完善后请记得迁移
/// 加入列表的要求:
/// - 不需要用户授权的基本能力
/// - API 实现中不调用授权相关的逻辑
/// - API 已完成对 H5 非应用模式的兼容
enum WebNoAuthApi: String {
    
    case showToast
    
    case showModal
    
}
