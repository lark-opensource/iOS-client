//
//  OPBlockComponentLoadTask.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/4.
//

import Foundation
import LarkOPInterface
import OPSDK
import OPBlockInterface
import ECOProbe
import LKCommonsLogging

/// 加载流程-Component 加载任务
class OPBlockComponentLoadTask: OPTask<OPBlockComponentLoadTaskInput, OPBlockComponentLoadTaskOutput>,
                                OPComponentLifeCycleProtocol {
    
    weak var delegate: OPBlockComponentLoadTaskDelegate?
    
    private let configParseTask: OPBlockConfigParseTask

    private let containerContext: OPContainerContext
    
    private var startTime: Date?

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    required init(configParseTask: OPBlockConfigParseTask, containerContext: OPContainerContext) {
        self.configParseTask = configParseTask
        self.containerContext = containerContext
        super.init(dependencyTasks: [configParseTask])
        name = "OPBlockComponentLoadTask uniqueID: \(containerContext.uniqueID)"
    }

    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        super.taskDidStarted(dependencyTasks: dependencyTasks)

        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.start_compoennt)
            .setUniqueID(containerContext.uniqueID)
            .tracing(containerContext.blockContext.trace)
            .flush()
        
        startTime = Date()
        
        let monitorCode = OPBlockitMonitorCodeMountLaunchComponent.component_fail
        let failMonitor = OPMonitor(name: String.OPBlockitMonitorKey.eventName, code: monitorCode)
                            .setResultTypeFail()
                            .tracing(containerContext.blockContext.trace)

        // 校验入参是否合法
        guard let input = self.input else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            let msg = "OPBlockComponentLoadTask.taskDidStarted error: input is nil"
            trace.error(msg)
            failMonitor
                .setErrorMessage(msg)
                .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.inputNil.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: msg))
            return
        }
        let uniqueID = input.containerContext.uniqueID

        trace.info("OPBlockComponentLoadTask.taskDidStarted")

        // 校验依赖任务输出是否满足要求
        guard let configParseTaskOutput = configParseTask.output else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            let msg = "OPBlockComponentLoadTask.taskDidStarted error: output of configParseTask is nil"
            trace.error(msg)
            failMonitor
                .setErrorMessage(msg)
                .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.invalidConfigTaskOutput.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: msg))
            return
        }

        guard let containerConfig = input.containerContext.containerConfig as? OPBlockContainerConfigProtocol else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            let msg = "OPBlockComponentLoadTask.taskDidStarted error: invalid containerConfig"
            trace.error(msg)
            failMonitor
                .setErrorMessage(msg)
                .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.invalidContainerConfig.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: msg))
            return
        }

        guard let meta = containerContext.meta as? OPBlockMeta else {
            let msg = "OPBlockComponentLoadTask.taskDidStarted error: invalid meta, meta is not block meta"
            trace.error(msg)
            failMonitor
                .setErrorMessage(msg)
                .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.invalidMeta.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: msg))
            return
        }

        let jsPath: String
        switch meta.extConfig.pkgType {
        case .offlineWeb:
            jsPath = configParseTaskOutput.blockConfig.htmlPath
        case .blockDSL:
            if containerConfig.blockLaunchMode == .creator,
               let creatorJSPath = configParseTaskOutput.blockConfig.creator?.jsPath,
               !creatorJSPath.isEmpty {
                // 启动 creator 页
                trace.info("OPBlockComponentLoadTask.taskDidStarted loading creator page")
                jsPath = creatorJSPath
            } else {
                // 启动 default 首页
                trace.info("OPBlockComponentLoadTask.taskDidStarted loading default page")
                jsPath = configParseTaskOutput.blockConfig.jsPath
            }
        }

        guard !jsPath.isEmpty else {
            let msg = "OPBlockComponentLoadTask.taskDidStarted error: invalid jsPath, jsPath is empty"
            trace.error(msg)
            failMonitor
                .setErrorMessage(msg)
                .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.invalidJsPath.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: msg))
            return
        }
        DispatchQueue.main.async {[weak self] in
            guard let `self` = self else {
                return
            }
            do {
                // 创建 Component
                let component = try input.router.createComponent(
                    fileReader: configParseTaskOutput.packageReader,
                    containerContext: input.containerContext)
                component.addLifeCycleListener(listener: self)
                self.delegate?.componentLoadStart(
                    task: self,
                    component: component,
                    jsPtah: jsPath)
            } catch {
                self.trace.error("OPBlockComponentLoadTask.taskDidStarted error: create component error \(error)")
                failMonitor
                    .setErrorMessage("OPBlockComponentLoadTask.taskDidStarted error: create component error")
                    .setError(error)
                    .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.createComponentFail.rawValue)")
                    .flush()
                self.taskDidFailed(error: error.newOPError(monitorCode: monitorCode))
            }
        }
    }

    // MARK: - OPComponentLifeCycleProtocol

    func onComponentReady() {
        trace.info("OPBlockComponentLoadTask.onReady")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.component_success)
            .addMetricValue("duration", Int(Date().timeIntervalSince(startTime ?? Date()) * 1000))
            .setResultTypeSuccess()
            .tracing(containerContext.blockContext.trace)
            .flush()
        taskDidSucceeded()
    }

    func onComponentFail(err: OPError) {
        trace.error("OPBlockComponentLoadTask.onFail error: \(err.localizedDescription)")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.component_fail)
            .setResultTypeFail()
            .setErrorMessage(err.localizedDescription)
            .setError(err)
            .tracing(containerContext.blockContext.trace)
            .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.fromFailListener.rawValue)")
            .flush()
        taskDidFailed(error: err)
    }
}
