//
//  CCMMagicShareDowngradeService.swift
//  SpaceInterface
//
//  Created by ByteDance on 2023/12/17.
//

import Foundation
import RxSwift

/// 会中妙享性能信息
public struct CCMMagicSharePerfInfo {
    /// 妙享性能表现总评分
    public var level: CGFloat
    /// 系统负载开关评分
    public var systemLoadScore: CGFloat
    /// 系统负载动态评分
    public var dynamicScore: CGFloat
    /// 设备温度评分
    public var thermalScore: CGFloat
    /// 创建文档频率评分
    public var openDocScore: CGFloat
    
    public init(level: CGFloat, systemLoadScore: CGFloat, dynamicScore: CGFloat, thermalScore: CGFloat, openDocScore: CGFloat) {
        self.level = level
        self.systemLoadScore = systemLoadScore
        self.dynamicScore = dynamicScore
        self.thermalScore = thermalScore
        self.openDocScore = openDocScore
    }
}

/// MagicShare场景功耗降级服务
public protocol CCMMagicShareDowngradeService {
    
    /// 当前性能数据
    var currentPerfInfo: CCMMagicSharePerfInfo? { get }
    
    /// 降级信息Observable
    var perfInfoObservable: Observable<CCMMagicSharePerfInfo> { get }
    
    /// MS开始
    func startMeeting()
    
    /// MS结束
    func stopMeeting()
}
