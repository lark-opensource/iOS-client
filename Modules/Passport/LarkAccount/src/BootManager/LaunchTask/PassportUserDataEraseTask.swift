//
//  PassportUserDataEraseTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/7.
//

import Foundation
import BootManager
import LKCommonsLogging
import LarkContainer
import LarkRustClient

//登出时的数据擦除任务
class PassportLogoutUserDataEraseTask: AsyncBootTask, Identifiable, UserDataEraserDelegate {

    static var identify = "PassportLogoutUserDataEraseTask"

    static let logger = Logger.log(PassportFirstRenderTask.self, category: "PassportLogoutUserDataEraseTask")

    var context: BootContext?

    override func execute(_ context: BootContext) {

        self.context = context

        ProbeDurationHelper.startDuration(MonitorEraseDataDurationFlow.erase.rawValue)
        PassportMonitor.flush(PassportMonitorMetaEraseData.eraser_start,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["type": 1],
                              context: UniContextCreator.create(.eraseData))

        let viewModel = UserDataEraserViewModel()
        let eraserVC = UserDataEraserViewController(viewModel: viewModel)
        eraserVC.delegate = self
        context.window?.rootViewController = eraserVC
    }

    // delegates
    func dataEraseSuccess() {
        //监控
        PassportMonitor.flush(PassportMonitorMetaEraseData.eraser_succ,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["type": 1,
                                                 "duration": ProbeDurationHelper.stopDuration(MonitorEraseDataDurationFlow.erase.rawValue)],
                              context: UniContextCreator.create(.eraseData))

       endTask()
    }

    func dataEraseFailed(with error: Error) {

        //监控
        let errorCode: String
        if let eraseError = error as? UserDataEraseError {
            errorCode = eraseError.errorCodes.map { String($0) }.joined(separator: ",")
        } else {
            errorCode = String((error as NSError).code)
        }
        PassportMonitor.flush(PassportMonitorMetaEraseData.eraser_fail,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["type": 1,
                                                 "duration": ProbeDurationHelper.stopDuration(MonitorEraseDataDurationFlow.erase.rawValue),
                                                 "error_code": errorCode],
                              context: UniContextCreator.create(.eraseData))

        let viewModel = DataEraseErrorRebootViewModel { [weak self] in
            //监控
            PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_cancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: ["type": 1],
                                  context: UniContextCreator.create(.eraseData))

            self?.endTask()
        }
        let noticeVC = PassportEmptyViewController(viewModel: viewModel)
        self.context?.window?.rootViewController = noticeVC
    }

    //AsyncBootTask 需要保证end异步执行, 同步执行end()，会导致当前flow被误认为执行完成
    private func endTask() {
        DispatchQueue.main.async {
            self.end()
        }
    }
}

//app启动时的数据擦除任务
class PassportBootupUserDataEraseForemostTask: BranchBootTask, Identifiable{

    static var identify = "PassportBootupUserDataEraseForemostTask"
    /**
        iPad 端启用分屏时，会构建一个新的window，
        同时会重新执行bootManager的所有流程，包括beforeLoginFlow.
        现在BootManager没有用于区分场景的标识，只能借用 runOnlyOnce() 达到类似的效果
     */
    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {

        //判断是否需要擦除数据, 如果需要，切换到数据擦除flow
        if UserDataEraserHelper.shared.needEraseDataForBootup() {
            flowCheckout(.dataEraseFlow)
        }
    }
}

class PassportBootupUserDataEraseTask: AsyncBootTask, Identifiable, UserDataEraserDelegate {
    static var identify = "PassportBootupUserDataEraseTask"

    var context: BootContext?
    /**
        iPad 端启用分屏时，会构建一个新的window，
        同时会重新执行bootManager的所有流程，包括beforeLoginFlow.
        现在BootManager没有用于区分场景的标识，只能借用 runOnlyOnce() 达到类似的效果
     */
    override var runOnlyOnce: Bool { return true }

    @Provider var rustService: GlobalRustService

    static let logger = Logger.log(PassportFirstRenderTask.self, category: "PassportLogoutUserDataEraseTask")

    override func execute(_ context: BootContext) {

        //初始化rustSDK，数据擦除依赖rustSDK初始化
        let _ = self.rustService

        self.context = context

        ProbeDurationHelper.startDuration(MonitorEraseDataDurationFlow.erase.rawValue)
        PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_start,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["type": 2],
                              context: UniContextCreator.create(.eraseData))

        let viewModel = UserDataEraseResumeViewModel()
        let eraserVC = UserDataEraserViewController(viewModel: viewModel)
        eraserVC.delegate = self
        context.window?.rootViewController = eraserVC

    }

    // delegates
    func dataEraseSuccess() {
        //监控
        PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_succ,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["type": 2,
                                                 "duration": ProbeDurationHelper.stopDuration(MonitorEraseDataDurationFlow.erase.rawValue)],
                              context: UniContextCreator.create(.eraseData))

        //结束bootup task
        endTask()
    }

    func dataEraseFailed(with error: Error) {

        //监控
        let errorCode: String
        if let eraseError = error as? UserDataEraseError {
            errorCode = eraseError.errorCodes.map { String($0) }.joined(separator: ",")
        } else {
            errorCode = String((error as NSError).code)
        }
        PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_fail,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: ["type": 2,
                                                 "duration": ProbeDurationHelper.stopDuration(MonitorEraseDataDurationFlow.erase.rawValue),
                                                 "error_code": errorCode],
                              context: UniContextCreator.create(.eraseData))

        let viewModel = DataEraseErrorResetViewModel { [weak self] in
            //监控
            PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_confirm_reset,
                                  eventName: ProbeConst.monitorEventName,
                                  context: UniContextCreator.create(.eraseData))

            let resetVC = DataResetViewController()
            if let window = self?.context?.window {
                window.rootViewController = resetVC
            } else {
                self?.endTask()
            }
        } cancellCallback: { [weak self] in
            //监控
            PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_cancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: ["type": 2],
                                  context: UniContextCreator.create(.eraseData))
            self?.endTask()
        }
        let noticeVC = PassportEmptyViewController(viewModel: viewModel)
        if let window = self.context?.window {
            window.rootViewController = noticeVC
        } else {
            endTask()
        }
    }

    //AsyncBootTask 需要保证end异步执行, 同步执行end()，会导致当前flow被误认为执行完成
    private func endTask() {
        DispatchQueue.main.async {
            self.end()
        }
    }
}
