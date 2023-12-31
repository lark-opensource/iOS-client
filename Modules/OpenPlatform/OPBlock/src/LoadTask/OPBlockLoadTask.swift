//
//  OPBlockLoadTask.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/10.
//

import Foundation
import OPSDK
import OPBlockInterface
import LarkOPInterface
import ECOProbe
import LKCommonsLogging
import LarkContainer

/// 应用启动加载任务
class OPBlockLoadTask: OPTask<OPBlockLoadTaskInput, OPBlockLoadTaskOutput>, OPBlockBundleLoadTaskDelegate {
    
    weak var delegate: OPBlockLoadTaskDelegate?

    // 只跟trace有关系，taskinput的containerContext仍由input提供
    private let containerContext: OPContainerContext
    private let userResolver: UserResolver

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    required init(containerContext: OPContainerContext) {
        self.containerContext = containerContext
        // OPSDK 未完整适配用户态隔离
        self.userResolver = Container.shared.getCurrentUserResolver()
        super.init(dependencyTasks: [])
        name = "OPBlockLoadTask uniqueID: \(containerContext.uniqueID)"
    }

    override func taskWillStart() -> OPError? {
        trace.info("OPBlockLoadTask.taskWillStart")

        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunch.start_launch_block)
            .setUniqueID(containerContext.uniqueID)
            .tracing(containerContext.blockContext.trace)
            .flush()

        guard let input = input else {
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountLaunch.internal_error)
                .setErrorMessage("OPBlockLoadTask invalid input, input is nil")
                .addCategoryValue("biz_error_code", "\(OPBlockitLaunchInternalErrorCode.invalidLoadTaskInput.rawValue)")
                .setResultTypeFail()
                .tracing(containerContext.blockContext.trace)
                .flush()
            trace.error("OPBlockLoadTask.taskWillStart error: OPBlockLoadTask invalid input, input is nil")
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            return OPBlockitMonitorCodeMountLaunch.internal_error.error(message: "OPBlockLoadTask invalid input, input is nil")
        }

        // 初始化 GuideInfoLoadTask （后端以人力不足为由放弃使用 meta 方案，并且缺少完善的缓存设计，这里只能增加一次请求对齐 Android）
        let guideInfoLoadTask = OPBlockGuideInfoLoadTask(
            userResolver: userResolver, containerContext: containerContext
        )
        guideInfoLoadTask.input = OPBlockGuideInfoLoadTaskInput(
            containerContext: input.containerContext,
            serviceContainer: input.serviceContainer
        )
        trace.info("OPBlockLoadTask.taskWillStart guideinfoloadtask initialized")

        // 初始化 bundleLoadTask
        let bundleLoadTask = OPBlockBundleLoadTask(
            userResolver: userResolver,
            guideInfoLoadTask: guideInfoLoadTask,
            containerContext: containerContext
        )
        bundleLoadTask.input = OPBlockBundleLoadTaskInput(containerContext: input.containerContext)

        let tempTrace = trace
        bundleLoadTask.taskDidFinshedBlock = { [weak self, weak bundleLoadTask] (task, state, error) in
            guard let self = self else {
                tempTrace.error("OPBlockLoadTask.taskWillStart.bundleLoadTask.taskDidFinshedBlock error: self is released")
                return
            }
            guard state == .succeeded else {
                self.trace.error("OPBlockLoadTask.taskWillStart.bundleLoadTask.taskDidFinshedBlock error: state != succeeded")
                return
            }
            guard let packageReader = bundleLoadTask?.output?.packageReader else {
                self.trace.error("OPBlockLoadTask.taskWillStart.bundleLoadTask.taskDidFinshedBlock error: packageReader is nil")
                return
            }
            // 将 meta 信息设置给 containerContext
            self.input?.containerContext.meta = bundleLoadTask?.output?.meta
            self.delegate?.packageReaderReady(packageReader: packageReader)
        }
        bundleLoadTask.delegate = self
        trace.info("OPBlockLoadTask.taskWillStart bundleloadtask initialized")
        
        // 初始化 configParseTask
        let configParseTask = OPBlockConfigParseTask(bundleLoadTask: bundleLoadTask, containerContext: containerContext)
        configParseTask.taskDidFinshedBlock = { [weak self] (task, state, error) in
            guard let self = self else {
                tempTrace.error("OPBlockLoadTask.taskWillStart.configParseTask.taskDidFinshedBlock error: self is released")
                return
            }
            guard state == .succeeded else {
                self.trace.error("OPBlockLoadTask.taskWillStart.configParseTask.taskDidFinshedBlock error: state != succeeded")
                return
            }
            guard let projectConfig = configParseTask.output?.projectConfig else {
                self.trace.error("OPBlockLoadTask.taskWillStart.configParseTask.taskDidFinshedBlock error: projectConfig is nil")
                return
            }
            guard let blockConfig = projectConfig.blocks?.first else {
                self.trace.error("OPBlockLoadTask.taskWillStart.configParseTask.taskDidFinshedBlock error: blockConfig is nil")
                return
            }
            self.delegate?.configReady(projectConfig: projectConfig, blockConfig: blockConfig)
        }
        trace.info("OPBlockLoadTask.taskWillStart configParseTask initialized")
        
        // 初始化 componentTask
        let componentTask = OPBlockComponentLoadTask(configParseTask: configParseTask, containerContext: containerContext)
        componentTask.delegate = self
        componentTask.input = OPBlockComponentLoadTaskInput(
            containerContext: input.containerContext,
            router: input.router)
        
        addDependencyTask(dependencyTask: componentTask)
        trace.info("OPBlockLoadTask.taskWillStart componentTask initialized")
        
        return super.taskWillStart()
    }
    
    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        trace.info("OPBlockLoadTask.taskDidStarted")

        super.taskDidStarted(dependencyTasks: dependencyTasks)
        // 这里暂时没有其他事情直接返回成功(后续如果增加其他逻辑则需要调整)
        taskDidSucceeded()
    }

    func onBundleUpdateSuccess(info: OPBlockUpdateInfo) {
        trace.info("OPBlockLoadTask.onBundleUpdateSuccess")
        delegate?.bundleUpdateSuccess(info: info)
    }
    
    // meta 加载成功
    func onMetaLoadSuccess(meta: OPBizMetaProtocol) {
        trace.info("OPBlockLoadTask.onMetaLoadSuccess")
        delegate?.metaLoadSuccess(meta: meta)
    }
}

extension OPBlockLoadTask: OPBlockComponentLoadTaskDelegate {
    
    func componentLoadStart(
        task: OPBlockComponentLoadTask,
        component: OPComponentProtocol,
        jsPtah: String) {

        trace.info("OPBlockLoadTask.componentLoadStart")
  
        delegate?.componentLoadStart(
            task: self,
            component: component,
            jsPtah: jsPtah)
    }
}
