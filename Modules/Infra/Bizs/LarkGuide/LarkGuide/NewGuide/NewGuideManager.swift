//
//  NewGuideManager.swift
//  LarkGuide
//
//  Created by zhenning on 2020/6/28.
//

import Foundation
import LKCommonsLogging
import RxSwift
import LarkGuideUI
import UIKit
import LarkSetting

/// 接入说明文档： https://bytedance.feishu.cn/docs/doccnco32SuN90KoNLrCh93uPMd#WWs1aJ
/// warning: 业务接入请联系@maozhenning，确认后需录入登记表 https://bytedance.feishu.cn/sheets/shtcnCBh3IT5BvHAq7AZBZF1mib

final class NewGuideManager: NewGuideService {
    private static let logger = Logger.log(NewGuideService.self, category: "NewGuideService")

    private lazy var taskManager: GuideTaskManager = {
        let taskManager = GuideTaskManager()
        taskManager.taskManagerDelegate = self
        return taskManager
    }()
    private lazy var dataManager: GuideDataManager = {
        let dataManager = GuideDataManager(pushGuideObservable: pushGuideObservable, currentUserId: currentUserId)
        return dataManager
    }()
    private lazy var guideUIManager: GuideUIManager = {
        let guideUIManager = GuideUIManager()
        return guideUIManager
    }()
    private let pushGuideObservable: Observable<PushUserGuideUpdatedMessage>
    private let currentUserId: String

    init(pushGuideObservable: Observable<PushUserGuideUpdatedMessage>,
         currentUserId: String) {
        self.pushGuideObservable = pushGuideObservable
        self.currentUserId = currentUserId
        bindObservables()
        Self.logger.debug("[LarkGuide]: NewGuideManager init",
                          additionalData: ["currentUserId": "\(currentUserId)"])
    }

    func bindObservables() {
        // make sure update task in main thread (driver)
        DispatchQueue.main.async {
            // update task queue
            self.dataManager.pushUpdateTasksDriver.drive(onNext: { [weak self] keys in
                self?.taskManager.removeTasksInQueueByKeys(removeKeys: keys)
            }).disposed(by: self.dataManager.disposeBag)
        }
    }

    /// 拉取更新本地引导配置
    func fetchUserGuideInfos(finish: (() -> Void)?) {
        // 增加fg控制走新老拉取方法
        if FeatureGatingManager.shared.featureGatingValue(with: "ug.guide.guide_key_support_ccm") {
            self.dataManager.fetchUserGuideNew(finish: finish)
        } else {
            self.dataManager.fetchUserGuide(finish: finish)
        }
    }

    /// 清除本地引导缓存
    func clearUserGuideCache() {
        self.dataManager.clearUserGuideCache()
    }

    /// 根据key查询是否应该显示该引导，如已展示则返回false
    func checkShouldShowGuide(key: String) -> Bool {
        let shouldShowGuide = self.dataManager.shouldShowGuide(key: key)
        Self.logger.debug("[LarkGuide]: checkShouldShowGuide",
                          additionalData: [
                            "shouldShowGuide": "\(shouldShowGuide)",
                            "key": "\(key)"
                          ])
        return shouldShowGuide
    }

    // 获取当前是否有引导正在显示, 返回是否有引导正在显示
    func checkIsCurrentGuideShowing() -> Bool {
        return self.dataManager.getIsGuideShowing()
    }

    func tryLockNewGuide(lockExceptKeys: [String]) -> Bool {
        return self.dataManager.tryLockNewGuide(lockExceptKeys: lockExceptKeys)
    }

    func unlockNewGuide() {
        self.dataManager.unlockNewGuide()
    }

    /// 移除指定的引导任务, 谨慎调用
    func removeGuideTasksIfNeeded(keys: [String]) {
        guard !keys.isEmpty else { return }

        // 1. 先移除队列中的引导任务
        self.taskManager.removeTasks(keys: keys)
        // 2. 关闭正在显示的引导
        if let currShowingGuideKey = self.taskManager.currShowingGuideKey,
           keys.contains(currShowingGuideKey) {
            self.closeCurrentGuideUIIfNeeded()
        }

        Self.logger.debug("[LarkGuide]: removeGuideTasksIfNeeded",
                          additionalData: [
                            "removeKeys": "\(keys)"
                          ])
    }
}

// MARK: - Register Guide Task

extension NewGuideManager {

    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String, bubbleType: BubbleType, dismissHandler: TaskDismissHandler?) {
        self.showBubbleGuideIfNeeded(guideKey: guideKey, bubbleType: bubbleType, canReplay: nil, dismissHandler: dismissHandler)
    }

    /// 展示气泡-带tapHandler
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 viewTapHandler: GuideViewTapHandler?,
                                 dismissHandler: TaskDismissHandler?) {
        self.showBubbleGuideIfNeeded(guideKey: guideKey,
                                     bubbleType: bubbleType,
                                     canReplay: nil,
                                     viewTapHandler: viewTapHandler,
                                     dismissHandler: dismissHandler)
    }

    /// 展示气泡-带自定义window
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 customWindow: UIWindow?,
                                 dismissHandler: TaskDismissHandler?) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .bubbleType(bubbleType),
                                       customWindow: customWindow,
                                       dismissHandler: dismissHandler)
    }

    /// 展示Dialog
    func showDialogGuideIfNeeded(guideKey: String, dialogConfig: DialogConfig, dismissHandler: TaskDismissHandler?) {
        self.showDialogGuideIfNeeded(guideKey: guideKey, dialogConfig: dialogConfig, canReplay: nil, dismissHandler: dismissHandler)
    }

    /// 展示自定义视图引导
    func showCustomGuideIfNeeded(guideKey: String, customConfig: GuideCustomConfig, dismissHandler: TaskDismissHandler?) {
        self.showCustomGuideIfNeeded(guideKey: guideKey, customConfig: customConfig, canReplay: nil, dismissHandler: dismissHandler)
    }

    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 canReplay: Bool?,
                                 dismissHandler: TaskDismissHandler?) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .bubbleType(bubbleType),
                                       canReplay: canReplay,
                                       dismissHandler: dismissHandler)
    }

    /// 展示气泡
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 canReplay: Bool?,
                                 viewTapHandler: GuideViewTapHandler?,
                                 dismissHandler: TaskDismissHandler?) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .bubbleType(bubbleType),
                                       canReplay: canReplay,
                                       viewTapHandler: viewTapHandler,
                                       dismissHandler: dismissHandler)
    }

    /// 展示Dialog，带是否可以重放
    func showDialogGuideIfNeeded(guideKey: String,
                                 dialogConfig: DialogConfig,
                                 canReplay: Bool?,
                                 dismissHandler: TaskDismissHandler?) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .dialogConfig(dialogConfig),
                                       canReplay: canReplay,
                                       dismissHandler: dismissHandler)
    }

    /// 展示自定义视图引导，带是否可以重放
    func showCustomGuideIfNeeded(guideKey: String,
                                 customConfig: GuideCustomConfig,
                                 canReplay: Bool?,
                                 dismissHandler: TaskDismissHandler?) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .customConfig(customConfig),
                                       canReplay: canReplay,
                                       dismissHandler: dismissHandler)
    }

    /// 展示气泡,带更多时机回调，带是否可以重放
    public func showBubbleGuideIfNeeded(guideKey: String,
                                        bubbleType: BubbleType,
                                        viewTapHandler: GuideViewTapHandler? = nil,
                                        dismissHandler: TaskDismissHandler? = nil,
                                        didAppearHandler: TaskDidAppearHandler? = nil,
                                        willAppearHandler: TaskWillAppearHandler? = nil) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .bubbleType(bubbleType),
                                       viewTapHandler: viewTapHandler,
                                       dismissHandler: dismissHandler,
                                       didAppearHandler: didAppearHandler,
                                       willAppearHandler: willAppearHandler)

    }

    /// 展示气泡，兼容旧接口
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 dismissHandler: TaskDismissHandler? = nil,
                                 didAppearHandler: TaskDidAppearHandler? = nil,
                                 willAppearHandler: TaskWillAppearHandler? = nil) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .bubbleType(bubbleType),
                                       dismissHandler: dismissHandler,
                                       didAppearHandler: didAppearHandler,
                                       willAppearHandler: willAppearHandler)
    }

    /// 展示Dialog,带更多时机回调
    public func showDialogGuideIfNeeded(guideKey: String,
                                        dialogConfig: DialogConfig,
                                        dismissHandler: TaskDismissHandler? = nil,
                                        didAppearHandler: TaskDidAppearHandler? = nil,
                                        willAppearHandler: TaskWillAppearHandler? = nil) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .dialogConfig(dialogConfig),
                                       dismissHandler: dismissHandler,
                                       didAppearHandler: didAppearHandler,
                                       willAppearHandler: willAppearHandler)
    }

    /// 展示自定义视图引导,带更多时机回调
    public func showCustomGuideIfNeeded(guideKey: String,
                                        customConfig: GuideCustomConfig,
                                        dismissHandler: TaskDismissHandler? = nil,
                                        didAppearHandler: TaskDidAppearHandler? = nil,
                                        willAppearHandler: TaskWillAppearHandler? = nil) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .customConfig(customConfig),
                                       dismissHandler: dismissHandler,
                                       didAppearHandler: didAppearHandler,
                                       willAppearHandler: willAppearHandler)

    }
}

// MARK: - Expansion Ability

extension NewGuideManager {

    /// 关闭当前在展示的Guide UI
    public func closeCurrentGuideUIIfNeeded() {
        self.guideUIManager.closeGuideViewsIfNeeded()
    }

    // 设置、更新key缓存配置
    func setGuideConfig<T: Encodable>(key: String, object: T) {
        dataManager.setGuideConfig(key: key, object: object)
    }

    // 获取当前key的缓存配置
    func getGuideConfig<T: Decodable>(key: String) -> T? {
        return dataManager.getGuideConfig(key: key)
    }
}

// MARK: - For Debug

extension NewGuideManager {

    /// 展示气泡
    /// @params: guideKey 引导的key
    /// @params: bubbleType 引导配置
    /// @params: isMock 为了方便调试，打开mock后，无须关心本地数据，直接展示, 提交时记得删除
    /// @params: dismissHandler 引导关闭后
    func showBubbleGuideIfNeeded(guideKey: String,
                                 bubbleType: BubbleType,
                                 isMock: Bool? = nil,
                                 dismissHandler: TaskDismissHandler? = nil) {
        self.showGuideByConfigIfNeeded(guideKey: guideKey,
                                       guideUIType: .bubbleType(bubbleType),
                                       isMock: isMock,
                                       dismissHandler: dismissHandler)
    }

    /// 获取本地引导配置缓存
    func getLocalUserGuideInfoCache() -> [GuideDebugInfo] {
        return self.dataManager.getCurrentUserGuideCache()
    }

    /// 设置本地内存态的引导配置
    /// @params: guideKey 当前引导
    /// @params: canShow 是否显示
    /// @params: 返回是否设置成功
    func setGuideInfoOfLocalCache(guideKey: String, canShow: Bool) -> Bool {
        return self.dataManager.updateGuideMemoryCache(guideKey: guideKey, canShow: canShow)
    }
}

// MARK: - Private Method

extension NewGuideManager {

    /// 注册引导视图
    private func showGuideByConfigIfNeeded(guideKey: String,
                                           guideUIType: GuideUIType,
                                           canReplay: Bool? = nil,
                                           isMock: Bool? = nil,
                                           customWindow: UIWindow? = nil,
                                           viewTapHandler: GuideViewTapHandler? = nil,
                                           dismissHandler: TaskDismissHandler? = nil,
                                           didAppearHandler: TaskDidAppearHandler? = nil,
                                           willAppearHandler: TaskWillAppearHandler? = nil) {
        self.addGuideTask(guideKey: guideKey,
                          guideConfigProvider: {
                            return guideUIType
                          },
                          canReplay: canReplay,
                          isMock: isMock,
                          customWindow: customWindow,
                          viewTapHandler: viewTapHandler,
                          dismissHandler: dismissHandler,
                          didAppearHandler: didAppearHandler,
                          willAppearHandler: willAppearHandler)
    }

    // 添加引导key任务
    private func addGuideTask(guideKey: String,
                              guideConfigProvider: @escaping GuideConfigProvider,
                              canReplay: Bool? = nil,
                              isMock: Bool? = nil,
                              customWindow: UIWindow? = nil,
                              viewTapHandler: GuideViewTapHandler? = nil,
                              dismissHandler: TaskDismissHandler? = nil,
                              didAppearHandler: TaskDidAppearHandler? = nil,
                              willAppearHandler: TaskWillAppearHandler? = nil) {
        Self.logger.debug("[LarkGuide]: addGuideTask",
                          additionalData: [
                            "guideKey": "\(guideKey)",
                            "shouldShowGuide": "\(self.shouldShowGuide(guideKey: guideKey))"
                          ])
        let isMockData = isMock ?? false
        if isMockData {
            // debug
            // 1. mock guide task
            let mockGuideTask = GuideTask(key: "guideMockKey",
                                          priority: 0,
                                          viewAreaKey: "viewAreaKey",
                                          guideConfigProvider: guideConfigProvider,
                                          canShow: true,
                                          canReplay: true,
                                          customWindow: nil,
                                          viewTapHandler: viewTapHandler,
                                          dismissHandler: dismissHandler,
                                          didAppearHandler: didAppearHandler,
                                          willAppearHandler: willAppearHandler)
            // 2. add task to queue
            self.taskManager.addTask(guideTask: mockGuideTask)
        } else {
            // check should show guide
            guard self.shouldShowGuide(guideKey: guideKey),
                  let guideKeyInfo: GuideKeyInfo = self.dataManager.getGuideKeyInfoByKey(key: guideKey) else {
                return
            }

            // 1. map to guide task
            let guideTask = GuideTask(key: guideKey,
                                      priority: guideKeyInfo.priority,
                                      viewAreaKey: guideKeyInfo.viewArea.key,
                                      guideConfigProvider: guideConfigProvider,
                                      canShow: guideKeyInfo.canShow,
                                      canReplay: canReplay,
                                      customWindow: customWindow,
                                      viewTapHandler: viewTapHandler,
                                      dismissHandler: dismissHandler,
                                      didAppearHandler: didAppearHandler,
                                      willAppearHandler: willAppearHandler)
            // 2. add task to queue
            self.taskManager.addTask(guideTask: guideTask)
        }

        self.taskManager.excuteGuideTaskIfNeeded(isGuideShowing: self.dataManager.getIsGuideShowing(),
                                                 taskExcutingHandler: { isShowing in
                                                    self.dataManager.setIsGuideShowing(isShow: isShowing)
                                                 })
    }

    /// 是否显示引导
    private func shouldShowGuide(guideKey: String) -> Bool {
        return self.dataManager.shouldShowGuide(key: guideKey)
    }

    /// 上报引导到服务端，已经展示过
    public func didShowedGuide(guideKey: String) {
        self.dataManager.didShowedGuide(key: guideKey)
    }

    private func didFinshedGuideTask(guideTask: GuideTask) {
        // 不再显示guide
        self.dataManager.setIsGuideShowing(isShow: false)
        // 是否可以跳过状态更新
        let shouldSkipUpdateGuideStatus: Bool = guideTask.canReplay ?? false
        if !shouldSkipUpdateGuideStatus {
            // 更新引导状态
            self.didShowedGuide(guideKey: guideTask.key)
        }
        // 执行回调
        if let dismissHandler = guideTask.dismissHandler {
            dismissHandler()
        }
        // 执行下一个引导
        self.taskManager.excuteGuideTaskIfNeeded(isGuideShowing: self.dataManager.getIsGuideShowing(),
                                                 taskExcutingHandler: { isExcuting in
                                                    self.dataManager.setIsGuideShowing(isShow: isExcuting)
                                                 })
    }
}

// MARK: - Delegate

extension NewGuideManager: GuideTaskManagerDelegate {
    func onExcuteGuideTask(guideTask: GuideTask, finishHandler: @escaping () -> Void) {
        switch guideTask.guideConfigProvider() {
        case let .bubbleType(bubbleType):
            guideUIManager.displayBubble(bubbleType: bubbleType,
                                         customWindow: guideTask.customWindow,
                                         viewTapHandler: guideTask.viewTapHandler,
                                         dismissHandler: { [weak self] in
                                            self?.didFinshedGuideTask(guideTask: guideTask)
                                            finishHandler()
                                            Self.logger.debug("[LarkGuide]: dismissHandler bubbleType",
                                                              additionalData: ["guideTask": "\(guideTask)"])
                                         })
        case let .dialogConfig(dialogConfig):
            guideUIManager.displayDialog(dialogConfig: dialogConfig,
                                         dismissHandler: { [weak self] in
                                            self?.didFinshedGuideTask(guideTask: guideTask)
                                            finishHandler()
                                            Self.logger.debug("[LarkGuide]: dismissHandler dialogType",
                                                              additionalData: ["guideTask": "\(guideTask)"])
                                         })
        case let .customConfig(customConfig):
            guideUIManager.displayCustomView(customConfig: customConfig,
                                             dismissHandler: { [weak self] in
                                                self?.didFinshedGuideTask(guideTask: guideTask)
                                                finishHandler()
                                                Self.logger.debug("[LarkGuide]: dismissHandler customType",
                                                                  additionalData: ["guideTask": "\(guideTask)"])
                                             })
        }
        Self.logger.debug("[LarkGuide]: onExcuteGuideTask", additionalData: ["guideTask": "\(guideTask)"])
    }
}
