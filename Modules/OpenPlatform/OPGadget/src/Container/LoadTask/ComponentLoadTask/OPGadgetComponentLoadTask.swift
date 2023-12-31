//
//  OPGadgetComponentLoadTask.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/9.
//

import Foundation
import OPSDK
import TTMicroApp
import OPFoundation
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPGadgetComponentLoadTask.self, category: "appLoad")

/// 加载流程-Component 加载任务
class OPGadgetComponentLoadTask: OPTask<OPGadgetComponentLoadTaskInput, OPGadgetComponentLoadTaskOutput>,
                                 OPComponentLifeCycleProtocol {
    
    weak var delegate: OPGadgetComponentLoadTaskDelegate?
    
    required init() {
        super.init(dependencyTasks: [])
    }
    
    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        super.taskDidStarted(dependencyTasks: dependencyTasks)
        
        // 校验入参是否合法
        guard let input = self.input else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            taskDidFailed(error: GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetComponentLoadTask invalid input, input is nil"))
            return
        }
        
        // TODO: 后续 Component 模式接入后直接请直接走 Component 事件监听，不要再通过这种监听 Notification 的方式来处理了
        setupObserver()
    }
    
    // MARK: - OPComponentLifeCycleProtocol
    
    public func onComponentReady() {
        taskDidSucceeded()
    }
    
    public func onComponentFail(err: OPError) {
        taskDidFailed(error: err)
    }
    
    private func setupObserver() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOnDocumentReady(notification:)),
            name: NSNotification.Name(rawValue: kBDPAppDocumentReadyNotification),
            object: nil
        )
        
    }
    
    @objc
    dynamic private func handleOnDocumentReady(notification: Notification) {
        
        guard let uniqueID = notification.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID, uniqueID == self.input?.containerContext.uniqueID else {
            return // 校验容器
        }
        
        guard let input = input, let task = input.task else {
            return // 校验输入
        }
        
        guard let appPageID = notification.userInfo?[kBDPAppPageIDUserInfoKey] as? Int, let appPage = OPUnsafeObject(task.pageManager?.appPage(withID: appPageID)) else {
            return
        }
        
        // 二级界面/非首页, 会先发OnAppRoute, 但因为event还没有fire, 会把isNeedRoute置为YES
        if appPage.isNeedRoute {
            OPUnsafeObject(appPage.parentController())?.onAppRoute(appPage.bdp_openType)
            appPage.isNeedRoute = false
        }
        
        
        // 谁先Ready, 谁就先fireEvent, 不用等. 如果是相互发消息, 另外一个没ready的自己也会存起来
        if appPage.isAppPageReady {
            appPage.isFireEventReady = true
        }
        
        guard let context = OPUnsafeObject(task.context) else {
            return
        }
        
        if context.isContextReady {
            if !context.isFireEventReady { // jsc ready了, 就可以发
                input.router?.notifyCurrentPageAppLaunch()
            }
            context.isFireEventReady = true
        }
        
        if appPage.isFireEventReady, context.isFireEventReady ,let common = input.common, !common.isReady {
            // 小程序首屏界面还是等JSC、webview都fireEvent后发才关Loading
            
            becomeReadyStatus(common: input.common)
        }
        
    }
        
    
}

extension OPGadgetComponentLoadTask {
    
    private func becomeReadyStatus(common: BDPCommon?) {
        logger.info("becomeReadyStatus")
        
        guard let common = common,
              let model = OPUnsafeObject(common.model),
              !model.offline,
              !common.isDestroyed
        else {
            logger.warn("becomeReadyStatus while common status invalid")
            return
        }
        
        // TODO: 清理位逻辑需要梳理
        //        if (self.removePkgBitMask == BDPRemovePkgFromTimeout) {
        //            self.removePkgBitMask = 0; // 如果仅是超时判断要删除, ready后重置掉这个判断
        //        }
        
        //        // 如果清理位被标记
        //        if (self.removePkgBitMask) {
        //            // 清理位非 version_state异常的情况, 都要出兜底页
        //            if (!(self.removePkgBitMask & BDPRemovePkgFromVersionStateAbnormal)) {
        //                if (self.loadResultType == GDMonitorCodeLaunch.unknown_error) {
        //                    if (self.launchError && self.launchError.opError) {
        //                        self.loadResultType = self.launchError.opError.monitorCode; // 从 Launch Error 中取出异常code
        //                    } else {
        //                        // 未找到有效异常 code
        //                        self.loadResultType = GDMonitorCodeLaunch.unknown_error;
        //                    }
        //                }
        //
        //                self.launchError = self.launchError ?: BDP_APP_LOAD_ERROR_TYPE_N(self.loadResultType, @"remove error", BDP_APP_LOAD_TYPE_PKG, nil);
        //                [self handleLoadFailedWithCode:self.loadResultType error:self.launchError useAlert:NO];
        //                return;
        //            }
        //        }
        
        // 非默认 或 加载成功, 说明中途加载失败了，不再设置ready
        if self.isFinished() {
            return
        }
        
        common.isReady = true
        
        // 加载成功
        taskDidSucceeded()
        
        // 还需要暂时保留老容器的产品埋点逻辑
        self.input?.router?.containerController.newContainerDidFirstContentReady()
        
        self.input?.router?.notifyOnLoadApp(error: nil)
        
        //        [self eventMpLoadResult:GDMonitorCodeLaunch.success errMsg:nil extraParams:param];
    }
}
