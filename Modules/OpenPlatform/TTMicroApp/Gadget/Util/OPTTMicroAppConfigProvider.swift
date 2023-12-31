//
//  OPTTMicroAppConfigProvider.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/6/6.
//

import Foundation
// 提供外部依赖注入工具类
public final class OPTTMicroAppConfigProvider {
    // 注入OPDynamicComponentManagerProtocol对象
    public static var dynamicComponentManagerProvider: (() -> OPDynamicComponentManagerProtocol?)?
}
