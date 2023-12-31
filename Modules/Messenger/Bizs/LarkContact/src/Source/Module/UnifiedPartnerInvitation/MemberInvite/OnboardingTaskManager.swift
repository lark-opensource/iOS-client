//
//  OnboardingTaskManager.swift
//  LarkContact
//
//  Created by bytedance on 2022/7/4.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import LKCommonsLogging
import LarkUIKit
import LarkAccountInterface

enum OnboardingTaskType {
    case memberInvite
    case register
    case onboarding
}

final class OnboardingTask {
    var taskType: OnboardingTaskType
    var url: String?
    var extraInfo: [String: Any]?
    public init(taskType: OnboardingTaskType, url: String? = nil, extraInfo: [String: Any]? = nil) {
        self.taskType = taskType
        self.url = url
        self.extraInfo = extraInfo
    }
}

final class OnboardingTaskManager {
    static let logger = Logger.log(OnboardingTaskManager.self, category: "LarkContact.OnboardingTaskManager")
    private static var shared: OnboardingTaskManager?
    var taskQueue: [OnboardingTask] = []
    var currentTaskIndex = 0
    var taskFinish: Bool {
        return currentTaskIndex >= taskQueue.count
    }

    public static func getSharedInstance() -> OnboardingTaskManager {
        if let shared = Self.shared {
            return shared
        }
        let temp = OnboardingTaskManager()
        Self.shared = temp
        return temp
    }

    private func destory() {
        Self.shared = nil
    }

    public func addTasks(tasks: [OnboardingTask]) {
        self.taskQueue.append(contentsOf: tasks)
    }

    public func removeAllTasks() {
        self.currentTaskIndex = 0
        self.taskQueue.removeAll()
    }

    // 如果任务已经执行完，会释放单例对象
    public func executeNextTask() {
        guard currentTaskIndex < taskQueue.count else {
            self.destory()
            return
        }
        let task = self.taskQueue[currentTaskIndex]
        currentTaskIndex += 1
        switch task.taskType {
        case .memberInvite:
            if !AccountServiceAdapter.shared.isFeishuBrand { //Global
                // lark
                pushToMemberGuidePage(inviteType: .split)
            } else {
                pushToMemberGuidePage(inviteType: .qrcode)
            }
        case .register:
            guard let url = task.url, !url.isEmpty else {
                self.executeNextTask()
                return
            }
            pushToRegisterPage(url: url)
        case .onboarding:
            guard let url = task.url, !url.isEmpty else {
                self.executeNextTask()
                return
            }
            let isFullScreen = task.extraInfo?["isFullScreen"] as? Bool ?? false
            pushToOnboardingPage(url: url, isFullScreen: isFullScreen)
        }
    }

    private func pushToMemberGuidePage(inviteType: MemberInviteGuideType) {
        guard let window = Navigator.shared.mainSceneWindow else { //Global
            return
        }
        Self.logger.info("push to member invite page")
        let memberInviteGuideBody = MemberInviteGuideBody(inviteType: inviteType)
        Navigator.shared.present( //Global
            body: memberInviteGuideBody,
            wrap: LkNavigationController.self,
            from: window,
            prepare: {
                $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            }
        )
    }

    private func pushToRegisterPage(url: String) {
        Self.logger.info("show register with url: \(url)")
        UGBrowserTool.checkURLReceivable(url: url) { [weak self] receivable in
            guard let url = URL(string: url),
                  let window = Navigator.shared.mainSceneWindow, //Global
                  receivable else {
                      Self.logger.error("register url unreceivable")
                      self?.executeNextTask()
                      return
            }
            Self.logger.info("register url receivable")
            let body = UGBrowserBody(url: url, stepInfo: nil, fallback: {
                self?.executeNextTask()
            })
            Navigator.shared.push(body: body, from: window) //Global
        }
    }

    private func pushToOnboardingPage(url: String, isFullScreen: Bool) {
        Self.logger.info("show new onboarding with url: \(url) isFullScreen: \(isFullScreen)")
        UGBrowserTool.checkURLReceivable(url: url) { [weak self] receivable in
            guard let guideURL = URL(string: url),
                  let window = Navigator.shared.mainSceneWindow, //Global
                  receivable else {
                      Self.logger.error("new onboarding url unreceivable")
                      self?.executeNextTask()
                      return
            }
            Self.logger.info("new onboarding url receivable")
            let body = SMBGuideBody(url: guideURL, isFullScreen: isFullScreen)
            Navigator.shared.present(body: body, from: window, prepare: { //Global
                $0.modalPresentationStyle = Display.pad ? .formSheet : .overFullScreen
            })
        }
    }

}
