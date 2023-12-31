//
//  OPBlockBundleLoadTask.swift
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
import LKCommonsTracker
import LarkContainer
import LarkSetting

/// 启动流程-应用资源加载流程
class OPBlockBundleLoadTask: OPTask<OPBlockBundleLoadTaskInput, OPBlockBundleLoadTaskOutput>, OPBlockLoaderMetaAndPackageEvent {
    
    weak var delegate: OPBlockBundleLoadTaskDelegate?
    
    private var loader: OPBlockLoader?

    private let containerContext: OPContainerContext

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    private var startTime: Date?
    
    private var startLoadTime: Date?
    
    private var pkgInstalled: Bool?

    private let userResolver: UserResolver

    required init(
        userResolver: UserResolver,
        guideInfoLoadTask: OPBlockGuideInfoLoadTask,
        containerContext: OPContainerContext
    ) {
        self.userResolver = userResolver
        self.containerContext = containerContext
        super.init(dependencyTasks: [guideInfoLoadTask])
        output = OPBlockBundleLoadTaskOutput()
        name = "OPBlockBundleLoadTask uniqueID: \(containerContext.uniqueID)"
    }
    
    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        super.taskDidStarted(dependencyTasks: dependencyTasks)
        trace.info("OPBlockBundleLoadTask.taskDidStarted")
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchMeta.start_load_meta_pkg)
            .setUniqueID(containerContext.uniqueID)
            .tracing(containerContext.blockContext.trace)
            .flush()
        startLoadTime = Date()
        // 校验入参合法
        guard let input = self.input else {
            trace.error("OPBlockBundleLoadTask.taskDidStarted error: input is nil")
            let monitorCode = OPBlockitMonitorCodeMountLaunch.internal_error
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .tracing(containerContext.blockContext.trace)
                .setErrorMessage("OPBlockBundleLoadTask.taskDidStarted error: input is nil")
                .addCategoryValue("biz_error_code", "\(OPBlockitLaunchInternalErrorCode.invalidBundleTaskInput.rawValue)")
                .flush()
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            taskDidFailed(error: monitorCode.error(message: "OPBlockBundleLoadTask invalid input, input is nil"))
            return
        }

        // 构造 AppLoader
        loader = OPBlockLoader(
            containerContext: containerContext,
            previewToken: input.containerContext.containerConfig.previewToken ?? ""
        )

        loader?.loadMetaAndPackage(listener: self)
    }

    // cancelLoad终止整个流程
    override func taskDidCancelled(error: OPError) {
        trace.error("OPBlockBundleLoadTask.taskDidCancelled error: \(error.localizedDescription)")

        super.taskDidCancelled(error: error)
        loader?.cancelLoadMetaAndPackage()
    }
    
    // MARK: - OPAppLoaderMetaAndPackageEvent
    func onMetaLoadStarted(strategy: OPAppLoaderStrategy) {
        // op_common_load_meta_start
        OPMonitor("op_common_load_meta_start")
            .setUniqueID(containerContext.uniqueID)
            .flush()
        trace.info("OPBlockBundleLoadTask.onMetaLoadStarted strategy: \(strategy.rawValue)")

        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onMetaLoadStarted state != executing or strategy != normal")
            return
        }

        updateProgress(progress: Int64(OPBlockBundleLoadTaskProgress.metaStart.rawValue))
        delegate?.onMetaLoadStart()
    }

    func onMetaLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float) {
        trace.info("OPBlockBundleLoadTask.onMetaLoadProgress strategy: \(strategy.rawValue), current:\(current), total:\(total)")

        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onMetaLoadProgress state != executing or strategy != normal")
            return
        }

        let progress = (current / total) * Float(OPBlockBundleLoadTaskProgress.metaSuccess.rawValue - OPBlockBundleLoadTaskProgress.metaStart.rawValue) + Float(OPBlockBundleLoadTaskProgress.metaStart.rawValue)
        updateProgress(progress: Int64(progress))
        delegate?.onMetaLoadProgress(current: current, total: total)
    }

    func onMetaLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, meta: OPBizMetaProtocol?, error: OPError?, fromCache: Bool) {
        if success {
            trace.info("OPBlockBundleLoadTask.onMetaLoadComplete strategy: \(strategy.rawValue) successful")
        } else {
            trace.error("OPBlockBundleLoadTask.onMetaLoadComplete strategy: \(strategy.rawValue) unsuccessful error: \(String(describing: error))")
        }


        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onMetaLoadComplete state != executing or strategy != normal")
            return
        }

        if success, let meta = meta {
            output?.meta = meta
            updateProgress(progress: Int64(OPBlockBundleLoadTaskProgress.metaSuccess.rawValue))
            delegate?.onMetaLoadSuccess(meta: meta)
            checkLoadSuccess(.meta)
            pkgInstalled = loader?.packageInstalled(meta: meta)
        } else {
            // meta目前仅向外透传OPSDKMonitorCodeLoader.get_meta_biz_error以方便宿主做逻辑，其他情况不透传底层error，使用统一的load_meta_fail
            var err: OPError
            var monitorMap: [String: Any] = [:]
            if let metaError = error,
                metaError.monitorCode == OPSDKMonitorCodeLoader.get_meta_biz_error {
                err = metaError
            } else {
                err = OPBlockitMonitorCodeMountLaunchMeta.load_meta_fail.error()
                monitorMap["biz_error_code"] = "\(OPBlockitLoadMetaFailErrorCode.noMeta.rawValue)"
            }
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: err.monitorCode)
                .setResultTypeFail()
                .setError(err)
                .setErrorMessage(err.localizedDescription)
                .addMap(monitorMap)
                .tracing(containerContext.blockContext.trace)
                .flush()
            trace.error("OPBlockBundleLoadTask.onMetaLoadComplete error: \(err.localizedDescription)")
            delegate?.onMetaLoadFailed(error: err)
            taskDidFailed(error: err)
        }
        OPMonitor("op_common_load_meta_result")
            .setUniqueID(containerContext.uniqueID)
            .flush()
    }

    func onPackageLoadStart(strategy: OPAppLoaderStrategy) {
        OPMonitor("op_common_load_package_start")
            .setUniqueID(containerContext.uniqueID)
            .flush()
        trace.info("OPBlockBundleLoadTask.onPackageLoadStart strategy: \(strategy.rawValue)")

        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onPackageLoadStart state != executing or strategy != normal")
            return
        }

        updateProgress(progress: Int64(OPBlockBundleLoadTaskProgress.packageStart.rawValue))
        delegate?.onPackageLoadStart()
    }

    func onPackageReaderReady(strategy: OPAppLoaderStrategy, reader: OPPackageReaderProtocol) {
        trace.info("OPBlockBundleLoadTask.onPackageReaderReady strategy: \(strategy.rawValue)")

        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onPackageReaderReady state != executing or strategy != normal")
            return
        }

        output?.packageReader = reader
        updateProgress(progress: Int64(OPBlockBundleLoadTaskProgress.packageReaderReady.rawValue))
        delegate?.onPackageReaderReady(packageReader: reader)
    }

    func onPackageLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float) {
        trace.info("OPBlockBundleLoadTask.onPackageLoadProgress strategy: \(strategy.rawValue), current: \(current), total: \(total)")

        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onPackageLoadProgress state != executing or strategy != normal")
            return
        }

        let progress = (current / total) * Float(OPBlockBundleLoadTaskProgress.packageSuccess.rawValue - OPBlockBundleLoadTaskProgress.packageStart.rawValue) + Float(OPBlockBundleLoadTaskProgress.packageStart.rawValue)
        updateProgress(progress: Int64(progress))
        delegate?.onPackageLoadProgress(current: current, total: total)
    }

    func onPackageLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, error: OPError?) {
        trace.info("OPBlockBundleLoadTask.onPackageLoadComplete strategy: \(strategy.rawValue)")

        guard state == .executing, strategy == .normal else {
            // 其他状态表示已终止，不要再继续改变状态了
            trace.info("OPBlockBundleLoadTask.onPackageLoadComplete state != executing or strategy != normal")
            return
        }

        if success {
            trace.info("OPBlockBundleLoadTask.onPackageLoadComplete success")
            delegate?.onPackageLoadSuccess()
            checkLoadSuccess(.package)
        } else {
            // package暂不透传底层error，使用统一的load_package_fail
            let err = OPBlockitMonitorCodeMountLaunchPackage.load_package_fail.error()
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: err.monitorCode)
                .setResultTypeFail()
                .setError(error)
                .setErrorMessage(error?.localizedDescription)
                .tracing(containerContext.blockContext.trace)
                .flush()
            trace.error("OPBlockBundleLoadTask.onPackageLoadComplete error: \(err.localizedDescription)")
            delegate?.onPackageLoadFailed(error: err)
            taskDidFailed(error: err)
        }
        let endTime = Date()
        if let start = startTime {
            let duration = endTime.timeIntervalSince(start)

            OPMonitor("op_common_load_package_result")
                .setUniqueID(containerContext.uniqueID)
                .flush()
        }
    }

    func onBundleUpdateSuccess(info: OPBlockUpdateInfo) {
        delegate?.onBundleUpdateSuccess(info: info)
    }
}

// 私有的方法
extension OPBlockBundleLoadTask {

    private var isCheckSDKVersionEnable: Bool {
        userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableBasicLibVersionCheck.key)
    }

    private enum OPBundleLoadStage {
        case meta
        case package
    }

    private func checkLoadSuccess(_ stage: OPBundleLoadStage) {
        trace.info("OPBlockBundleLoadTask.checkLoadSuccess")

        let id = input?.containerContext.uniqueID
        let monitorCode = OPBlockitMonitorCodeMountLaunchMeta.load_meta_fail
        guard let metaData = output?.meta as? OPBlockMeta else {
            trace.error("OPBlockBundleLoadTask.checkLoadSuccess output.meta == nil or casting OPBlockMeta failed")
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .setErrorMessage("output meta invalid type, is nil \(output == nil)")
                .tracing(containerContext.blockContext.trace)
                .addCategoryValue("biz_error_code", "\(OPBlockitLoadMetaFailErrorCode.outputMetaInvalidType.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: "output meta invalid type, is nil \(output == nil))"))
            return
        }

        if isCheckSDKVersionEnable && !OPBlockSDK.isLegalVersion(metaData.basicLibVersion) {
            let msg = "OPBlockBundleLoadTask.checkLoadSuccess client need update: isCheckSDKVersionEnable \(isCheckSDKVersionEnable), basicLibVersion \(metaData.basicLibVersion ?? "nil"), runtimeSDKVersion \(OPBlockSDK.runtimeSDKVersion)"
            trace.error(msg)
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .addMap([
                    "app_version": metaData.appVersion,
                    "pkg_type": metaData.extConfig.pkgType.rawValue,
                    "runtime_sdk_version": OPBlockSDK.runtimeSDKVersion,
                    "basic_lib_version": metaData.basicLibVersion,
                    "biz_error_code": "\(OPBlockitLoadMetaFailErrorCode.illegalMetaVersion.rawValue)"
                ])
                .setErrorMessage(msg)
                .tracing(containerContext.blockContext.trace)
                .flush()
            taskDidFailed(error: monitorCode.error(message: msg))
            return
        }

        // meta 阶段成功无需检查 pkg，这个方法后面如果继续膨胀可以分拆下
        if stage == .meta {
            trace.info("OPBlockBundleLoadTask.checkLoadSuccess meta success")
            return
        }

        guard let _ = output?.packageReader else {
            trace.error("OPBlockBundleLoadTask.checkLoadSuccess package download failed")
            let monitorCode = OPBlockitMonitorCodeMountLaunchPackage.load_package_fail
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .setErrorMessage("output package reader is nil")
                .tracing(containerContext.blockContext.trace)
                .flush()
            taskDidFailed(error: monitorCode.error(message: "output package reader is nil"))
            return
        }
        trace.info("OPBlockBundleLoadTask.checkLoadSuccess bundle load success")
        let duration = Int(Date().timeIntervalSince(startLoadTime ?? Date()) * 1000)
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchMeta.load_meta_pkg_success)
            .tracing(containerContext.blockContext.trace)
            .setResultTypeSuccess()
            .addMap(["app_version": metaData.appVersion,
                     "pkg_type": metaData.extConfig.pkgType.rawValue,
                     "runtime_sdk_version": OPBlockSDK.runtimeSDKVersion,
                     "basic_lib_version": metaData.basicLibVersion,
                     "has_local_pkg": pkgInstalled,
                     "pkg_urls": metaData.packageUrls.map({ $0.md5() })])
            .addMetricValue("duration", duration)
            .flush()
        taskDidSucceeded()
    }

    private func updateProgress(progress: Int64) {
        guard progress < self.progress.totalUnitCount, progress > self.progress.completedUnitCount else {
            trace.error("OPBlockBundleLoadTask.updateProgress error: progress unit count wrong")
            // 进度不会回退
            return
        }
        self.progress.completedUnitCount = progress
    }
}

/// 进度阶段定义
enum OPBlockBundleLoadTaskProgress: Int {
    case metaStart = 5                  // meta 任务开始
    case metaSuccess = 30               // meta 任务完成
    case packageStart = 35              // package 任务开始
    case packageReaderReady = 40        // packageReader 准备就绪
    case packageSuccess = 95            // package 任务完成
}
