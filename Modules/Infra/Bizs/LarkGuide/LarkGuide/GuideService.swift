//
//  LarkInterface+Guide.swift
//  LarkInterface
//
//  Created by lichen on 2018/4/26.
//

import Foundation
import RxSwift

/// 废弃，用NewGuideService
public protocol GuideService {
    func needShowGuide(key: String) -> Bool
    func showGuide<T: Decodable>(key: String) -> T?
    func setShowGuide<T: Encodable>(key: String, object: T)
    func didShowGuide(key: String)
    func asyncUpdateProductGuideList()
    func clearProductGuideList()
    func setGuideIsShowing(isShow: Bool)// 此方法成对出现 true/false 否则阻断引导展示
    func getGuideIsShowing() -> Bool

    /// 特殊场景下，锁住GuideService，只允许白名单内的key正常使用GuideService，即：
    ///   * `needShowGuide(key:)`返回false
    ///   * `setGuideIsShowing(isShow:)`屏蔽
    ///   * `getGuideIsShowing`返回true
    /// 示例场景：
    ///   * 匿名会议期间只允许现实匿名会议相关引导，待匿名会议结束后走Onboarding流程，结束后可以显示其他引导
    ///   * Onboarding期间不允许其他引导出现
    /// 整体只允许只有一个lock
    ///
    /// - Parameter exceptKeys: guideKey白名单
    func tryLockGuide(exceptKeys: [String]) -> Bool
    func unlockGuide()
}
