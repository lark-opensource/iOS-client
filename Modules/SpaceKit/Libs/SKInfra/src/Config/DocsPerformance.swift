//
//  DocsPerformance.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/4/4.
//

import Foundation

// From DocsPerformanceDefine.swift
public final class DocsPerformance {
    public static var initTime: TimeInterval = 0 // DocSDK初始化时间
    //标记是第几次打开文档
    public static var openTimes: Int = 0
}
