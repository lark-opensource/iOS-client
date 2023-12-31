//
//  SandboxDetection.swift
//  TTMicroApp
//
//  Created by Meng on 2021/7/28.
//

import Foundation
import OPSDK
import ECOInfra
import ECOProbe
import ECOProbeMeta
import RxSwift

@objc
public final class SandboxDetection: NSObject {
    private static let enableFGKey = "ecosystem.open_app.sandbox.info.monitor"

    /// 异步探测 H5 沙箱结构内容并上报
    @objc public class func asyncDetectAndReportH5SandboxInfo(appId: String) {
        /// 仅兼容 H5 埋点上报场景使用
        let uniqueId = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp)
        asyncDetectAndReportSandboxInfo(uniqueId: uniqueId)
    }

    /// 异步探测沙箱结构内容并上报
    @objc public class func asyncDetectAndReportSandboxInfo(uniqueId: OPAppUniqueID) {
        guard EMAFeatureGating.boolValue(forKey: enableFGKey) else {
            return
        }

        let monitor = OPMonitor(EPMClientOpenPlatformInfraFileSystemCode.open_app_sandbox_info)
            .setUniqueID(uniqueId)
            .timing()

        /// 获取 storageModule
        let module = BDPModuleManager(of: uniqueId.appType).resolveModule(with: BDPStorageModuleProtocol.self)
        guard let storageModule = module as? BDPStorageModuleProtocol else {
            monitor
                .setResultTypeFail()
                .setErrorMessage("resolve storage module failed")
                .timing()
                .flush()
            return
        }

        /// 获取 sandbox
        let sandbox = storageModule.minimalSandbox(with: uniqueId)
        guard let userPath = sandbox.userPath() else {
            monitor
                .setResultTypeFail()
                .setErrorMessage("result userPath failed")
                .timing()
                .flush()
            return
        }

        /// 探测沙箱结构
        var disposeBag = DisposeBag()
        Observable<Void>.create { (observer) -> Disposable in
            do {
                try detectSandboxInfo(userPath: userPath, monitor: monitor)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            disposeBag = DisposeBag()                                       /// 执行完释放 Observer
            return Disposables.create()
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(queue: .global()))    /// 异步线程执行
        .observeOn(MainScheduler.instance)
        .timeout(.seconds(15), scheduler: MainScheduler.instance)           /// 超时 15s
        .subscribe(onError: { error in
            monitor.setResultTypeFail().setError(error)                     /// 超时/执行异常上报
        }, onDisposed: {
            monitor.timing().setResultTypeSuccess().flush()
        })
        .disposed(by: disposeBag)
    }

    private class func detectSandboxInfo(userPath: String, monitor: OPMonitor) throws {
        let fileNames = try LSFileSystem.contentsOfDirectory(dirPath: userPath)
        let userDepth = (userPath as NSString).pathComponents.count

        /// 目录总大小
        var userTotalSize: UInt64 = 0
        /// 目录最大深度
        var userMaxDepth: Int = 0
        /// 目录最大文件大小
        var userMaxFileSize: UInt64 = 0
        /// 目录文件最长名称长度
        var userFileNameMaxLength: Int = fileNames.map({ $0.count }).max() ?? 0
        /// 文件路径最大长度
        var userPathMaxLength: Int = userPath.count
        /// 目录文件数量
        var userFileNumber: Int = 0

        var paths = fileNames.map({ (userPath as NSString).appendingPathComponent($0) })
        while !paths.isEmpty {
            let currentPath = paths.removeFirst()

            var isDirObjc = false
            let exists = LSFileSystem.fileExists(filePath: currentPath, isDirectory: &isDirObjc)
            /// 当前目录不存在直接推出
            if !exists {
                continue
            }

            /// 更新最大目录深度
            let currentDepth = (currentPath as NSString).pathComponents.count - userDepth
            userMaxDepth = max(currentDepth, userMaxDepth)

            /// 更新路径最大长度
            userPathMaxLength = max(currentPath.count, userPathMaxLength)

            /// 判断是否文件夹
            if isDirObjc {
                /// 将文件夹子文件添加到 paths 继续迭代
                let subFileNames = try LSFileSystem.contentsOfDirectory(dirPath: currentPath)
                let subPaths = subFileNames.map({ (currentPath as NSString).appendingPathComponent($0) })
                paths.append(contentsOf: subPaths)

                /// 更新最大文件名称长度
                let subFileNameMaxLength = subFileNames.map({ $0.count }).max() ?? 0
                userFileNameMaxLength = max(subFileNameMaxLength, userFileNameMaxLength)
            } else {
                /// 更新目录文件大小和文件数量
                let attributes = try LSFileSystem.attributesOfItem(atPath: currentPath) as NSDictionary
                let fileSize = attributes.fileSize()
                userMaxFileSize = max(fileSize, userMaxFileSize)
                userTotalSize += fileSize
                userFileNumber += 1
            }
        }

        monitor
            .addCategoryValue("user_total_size", userTotalSize)
            .addCategoryValue("user_max_depth", userMaxDepth)
            .addCategoryValue("user_max_file_size", userMaxFileSize)
            .addCategoryValue("user_file_name_max_length", userFileNameMaxLength)
            .addCategoryValue("user_path_max_length", userPathMaxLength)
            .addCategoryValue("user_file_num", userFileNumber)
    }
}
