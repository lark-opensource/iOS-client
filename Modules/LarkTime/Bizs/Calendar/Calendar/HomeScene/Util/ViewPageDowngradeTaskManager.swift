//
//  ViewPageDowngradeTaskManager.swift
//  Calendar
//
//  Created by JackZhao on 2023/4/27.
//


import Foundation
import LarkSetting
import LarkDowngrade
import LarkContainer
import LKCommonsLogging

// 降级场景概览
enum ViewPageDowngradeScene: String {
    // switchMetting场景: 改变tab的日期图
    case switchMettingChangeDateImage = "calendar_calendar_switchMettingChangeDateImage"
    // setupController场景: 改变tab的日期图
    case setVCChangeDateImage = "calendar_calendar_setVCChangeDateImage"
    // 时区场景: 改变tab的日期图
    case timeZoneChangeDateImage = "calendar_calendar_timeZoneChangeDateImage"
    // 添加日程按钮的阴影
    case addButtonShadow = "calendar_calendar_addButtonShadow"
    // 加载本地日历任务
    case localCalendarLoad = "calendar_calendar_addButtonShadow_localCalendarLoad"
    // 更新本地日历
    case updateEKCalendars = "calendar_calendar_updateEKCalendars"
    // 更新月的展示
    case changeMonthButton = "calendar_calendar_changeMonthButton"
}

// 视图页降级框架管理器
class ViewPageDowngradeTaskManager {
    private static let logger = LKCommonsLogging.Logger.log(ViewPageDowngradeTaskManager.self, category: "Calendar")
    // iPhone 8的机型评分为8.4+(基本不会变), < 8.3 会对iPhone 8及以下的机型进行降级
    private static let lowDeviceFraction = 8.3

    // 是否是低端机的判断
    static func getIsLowDevice(settingService: LarkSetting.SettingService?) -> Bool {
        guard let settingService = settingService else { return false }
        let isLowDevice: Bool
        // 目前对iPhone 8及以下视为低端机
        if let deviceClassify = try? settingService.setting(with: UserSettingKey.make(userKeyLiteral: "get_device_classify")),
           let score = deviceClassify["cur_device_score"] as? Double, score < lowDeviceFraction {
            isLowDevice = true
        } else {
            isLowDevice = false
        }
        return isLowDevice
    }

    // 输入 = scene: 降级场景
    //       way: 预期降级策略
    // 输出 = 降级任务添加结果
    @discardableResult
    static func addTask(scene: ViewPageDowngradeScene,
                        way: TaskWay,
                        _ handler: @escaping (TaskResult) -> Void) -> TaskAddedResult {
        // 1. 初始化降级规则
        let rule = LarkDowngradeRuleInfo(ruleList: [.lowDevice: lowDeviceFraction],
                                         time: 0.0)
        let rules = LarkDowngradeRule(rules: [.overload: [rule]])
        let config = LarkDowngradeConfig(rules: [rules])

        if case .delay1s = way {
            let start = CACurrentMediaTime()
            // 2.1 通过LarkDowngradeService添加降级任务
            LarkDowngradeService.shared.Downgrade(key: scene.rawValue, config: config) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Self.logger.info("\(scene.rawValue) downgradeSuccess, cost = \(CACurrentMediaTime() - start)")
                    handler(.downgradeSuccess)
                }
            } doNormal: { _ in
                Self.logger.info("\(scene.rawValue) executed success by normal")
                handler(.normal)
            }
            return .success
        }
        // 2 返回不执行
        Self.logger.info("\(scene.rawValue) add fail")
        return .fail(isFallback: false)
    }
    
    // MARK: 输入和输出的模型
    // 降级策略
    enum TaskWay {
        // 尝试延迟1s
        case delay1s
    }

    // 降级任务结果
    enum TaskResult {
        // 直接执行
        case normal
        // 成功降级
        case downgradeSuccess
        // 回退，直接执行
        case fallback
    }

    // 添加降级任务结果
    enum TaskAddedResult {
        // 添加降级任务成功
        case success
        // 添加失败(是否回退，即直接执行)
        case fail(isFallback: Bool)
    }
}
