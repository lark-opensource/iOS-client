//
//  OPBlockConfigParseTask.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import OPSDK
import OPBlockInterface
import ECOProbe
import LKCommonsLogging

class OPBlockConfigParseTask: OPTask<OPBlockConfigParseTaskInput, OPBlockConfigParseTaskOutput> {

    private let bundleLoadTask: OPBlockBundleLoadTask
    
    private let containerContext: OPContainerContext

    private var trace: BlockTrace {
        containerContext.blockTrace
    }
    
    required init(bundleLoadTask: OPBlockBundleLoadTask, containerContext: OPContainerContext) {
        self.bundleLoadTask = bundleLoadTask
        self.containerContext = containerContext
        super.init(dependencyTasks: [bundleLoadTask])
        name = "OPBlockConfigParseTask uniqueID: \(containerContext.uniqueID)"
    }
    
    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        super.taskDidStarted(dependencyTasks: dependencyTasks)
        trace.info("OPBlockConfigParseTask.taskDidStarted")

        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchPackage.start_parse_pkg)
            .setUniqueID(containerContext.uniqueID)
            .tracing(containerContext.blockContext.trace)
            .flush()

        // 校验依赖任务输出是否满足要求
        guard let bundleTaskOutput = bundleLoadTask.output,
        let packageReader = bundleTaskOutput.packageReader else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            trace.error("OPBlockConfigParseTask.taskDidStarted error: invalid input, packageReader is nil")
            let monitorCode = OPBlockitMonitorCodeMountLaunchPackage.parse_pkg_result
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .setErrorMessage("OPBlockConfigParseTask invalid input, packageReader is nil")
                .addCategoryValue("biz_error_code", "\(OPBlockitParsePkgFailErrorCode.noPackageReader.rawValue)")
                .tracing(containerContext.blockContext.trace)
                .flush()
            taskDidFailed(error: monitorCode.error(message: "OPBlockConfigParseTask invalid input, packageReader is nil"))
            return
        }

        let tempTrace = trace
        let blockContext = containerContext.blockContext
        // 读取 Creator 配置，异步线程读取
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                tempTrace.error("OPBlockConfigParseTask.taskDidStarted error: self is released")
                return
            }
            let projectConfig = OPBlockProjectConfig(basePath: "project.config", reader: packageReader)
            guard let blockConfig = projectConfig.blocks?.first else {
                self.trace.error("OPBlockConfigParseTask.taskDidStarted error: block config not found")
                let monitorCode = OPBlockitMonitorCodeMountLaunchPackage.parse_pkg_result
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: monitorCode)
                    .setResultTypeFail()
                    .setErrorMessage("OPBlockConfigParseTask.taskDidStarted error: block config not found")
                    .addCategoryValue("biz_error_code", "\(OPBlockitParsePkgFailErrorCode.blockConfigNotFound.rawValue)")
                    .tracing(blockContext.trace)
                    .flush()
                self.taskDidFailed(error: monitorCode.error(message: "OPBlockConfigParseTask block config not found"))
                return
            }

            self.output = .init(
                projectConfig: projectConfig,
                blockConfig: blockConfig,
                packageReader: packageReader)

            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountLaunchPackage.parse_pkg_result)
                .setResultTypeSuccess()
                .tracing(blockContext.trace)
                .flush()

            self.taskDidSucceeded()

            // 延迟异步预解析配置
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                _ = projectConfig.preParsePropeties()
            }
        }
    }
}
