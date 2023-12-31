//
//  NewGuideService.swift
//  LarkGuide
//
//  Created by zhenning on 2020/6/28.
//

import UIKit
import Foundation
import LarkGuideUI

/// 接入说明文档： https://bytedance.feishu.cn/docs/doccnpWGStxVhkWh6kAOIMuhuJb
/// warning: 业务接入请联系@maozhenning，确认后需录入登记表 https://bytedance.feishu.cn/sheets/shtcnCBh3IT5BvHAq7AZBZF1mib

public protocol NewGuideService: AnyObject {

// MARK: - Regist Guide Task

    /// 展示气泡
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: dismissHandler 引导关闭后
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 dismissHandler: TaskDismissHandler?)
    /// 展示Dialog
    /// @params: guideKey 引导的key
    /// @params: dialogConfig 引导配置
    /// @params: dismissHandler 引导关闭后
    func showDialogGuideIfNeeded(guideKey: String,
                                 dialogConfig: DialogConfig,
                                 dismissHandler: TaskDismissHandler?)
    /// Guide显示
    /// 展示自定义视图引导
    /// @params: guideKey 引导的key
    /// @params: customConfig 引导配置
    /// @params: dismissHandler 引导关闭后
    func showCustomGuideIfNeeded(guideKey: String,
                                 customConfig: GuideCustomConfig,
                                 dismissHandler: TaskDismissHandler?)

// MARK: -

    /// 展示气泡
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: canReplay 默认引导关闭后上报，如果为true则跳过上报，重复展示
    /// @params: dismissHandler 引导关闭后
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 canReplay: Bool?,
                                 dismissHandler: TaskDismissHandler?)
    /// 展示Dialog
    /// @params: guideKey 引导的key
    /// @params: dialogConfig 引导配置
    /// @params: canReplay 默认引导关闭后上报，如果为true则跳过上报，重复展示
    /// @params: dismissHandler 引导关闭后
    func showDialogGuideIfNeeded(guideKey: String,
                                 dialogConfig: DialogConfig,
                                 canReplay: Bool?,
                                 dismissHandler: TaskDismissHandler?)
    /// Guide显示
    /// 展示自定义视图引导
    /// @params: guideKey 引导的key
    /// @params: customConfig 引导配置
    /// @params: canReplay 默认引导关闭后上报，如果为true则跳过上报，重复展示
    /// @params: dismissHandler 引导关闭后
    func showCustomGuideIfNeeded(guideKey: String,
                                 customConfig: GuideCustomConfig,
                                 canReplay: Bool?,
                                 dismissHandler: TaskDismissHandler?)

// MARK: -

    /// 展示气泡
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: viewTapHandler 引导点击回调
    /// @params: dismissHandler 引导关闭后
    /// @params: didAppearHandler 引导已显示
    /// @params: willAppearHandler 引导即将显示
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 viewTapHandler: GuideViewTapHandler?,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?)
    /// 展示气泡
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: customWindow 自定义window容器
    /// @params: dismissHandler 引导关闭后
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 customWindow: UIWindow?,
                                 dismissHandler: TaskDismissHandler?)

    /// 展示气泡(兼容旧的API)
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: dismissHandler 引导关闭后
    /// @params: didAppearHandler 引导已显示
    /// @params: willAppearHandler 引导即将显示
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?)

    /// 展示Dialog
    /// @params: guideKey 引导的key
    /// @params: dialogConfig 引导配置
    /// @params: dismissHandler 引导关闭后
    /// @params: didAppearHandler 引导已显示
    /// @params: willAppearHandler 引导即将显示
    func showDialogGuideIfNeeded(guideKey: String,
                                 dialogConfig: DialogConfig,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?)
    /// Guide显示
    /// 展示自定义视图引导
    /// @params: guideKey 引导的key
    /// @params: customConfig 引导配置
    /// @params: dismissHandler 引导关闭后
    /// @params: didAppearHandler 引导已显示
    /// @params: willAppearHandler 引导即将显示
    func showCustomGuideIfNeeded(guideKey: String,
                                 customConfig: GuideCustomConfig,
                                 dismissHandler: TaskDismissHandler?,
                                 didAppearHandler: TaskDidAppearHandler?,
                                 willAppearHandler: TaskWillAppearHandler?)

// MARK: - Expansion Ability

    /// 拉取更新本地引导配置
    func fetchUserGuideInfos(finish: (() -> Void)?)

    /// 根据key查询是否应该显示该引导，如已展示则返回false
    func checkShouldShowGuide(key: String) -> Bool

    /// 上报引导到服务端，已经展示过
    func didShowedGuide(guideKey: String)

    /// 关闭当前在展示的Guide（气泡、弹窗等，将引导UI从当前视图中移除）
    func closeCurrentGuideUIIfNeeded()

    /// 获取当前是否有引导正在显示, 返回是否有引导正在显示
    func checkIsCurrentGuideShowing() -> Bool

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
    func tryLockNewGuide(lockExceptKeys: [String]) -> Bool
    func unlockNewGuide()

    /// 移除指定的引导任务, 由于会影响到队列后续的引导，请谨慎调用
    func removeGuideTasksIfNeeded(keys: [String])

    // 设置、更新key缓存配置
    func setGuideConfig<T: Encodable>(key: String, object: T)

    // 获取当前key的缓存配置
    func getGuideConfig<T: Decodable>(key: String) -> T?

// MARK: - For Debug

    /// 展示气泡
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: isMock 为了方便调试，打开mock后，无须关心本地数据，直接展示
    /// @params: dismissHandler 引导关闭后
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 isMock: Bool?,
                                 dismissHandler: TaskDismissHandler?)

    /// 获取本地引导配置缓存
    func getLocalUserGuideInfoCache() -> [GuideDebugInfo]

    /// 设置本地内存态的引导配置
    /// @params: guideKey 当前引导
    /// @params: canShow 是否显示
    /// @params: 返回是否设置成功
    func setGuideInfoOfLocalCache(guideKey: String, canShow: Bool) -> Bool
}
