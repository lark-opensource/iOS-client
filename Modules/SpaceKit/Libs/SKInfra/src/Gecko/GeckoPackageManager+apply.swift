//
//  GeckoPackageManager+apply.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/5/5.
//

import SKFoundation
import RxSwift
import RxRelay
import SpaceInterface

extension GeckoPackageManager {

    func tryApplyPackageProcess(item: DocsChannelInfo) {
        guard let version = geckoDownloadPathVersion(item) else {
            GeckoLogger.info("tryApplyPackageProcess, err return")
            return
        }

        markNextLauchApply(item, version: version)

        tryApplyPackageNowIfCould(item, version: version)
    }

    /// 能否马上热更资源包，需要在这个方法里面增加需要满足的条件
    func tryApplyPackageNowIfCould(_ item: DocsChannelInfo, version: String) {
        switch item.type {
            case .webInfo:
                GeckoLogger.info("webInfo channel begin watch condition")

                let browserVCEmpty = DocsContainer.shared.resolve(SKBrowserInterface.self)?.browsersStackIsEmptyObsevable ?? BehaviorRelay<Bool>(value: true)
                let offlineSynIdle = SKInfraConfig.shared.offlineSynIdle
                let driveStackEmpty = DocsContainer.shared.resolve(DrivePreviewRecorderBase.self)?.stackEmptyStateChanged ?? Observable<Bool>.never()
                // DrivePreviewRecorder.shared.stackEmptyStateChanged

                self.disposeBagForWebInfoApply = DisposeBag()
                Observable.combineLatest(browserVCEmpty, offlineSynIdle, driveStackEmpty)
                    .distinctUntilChanged({ (l, r) -> Bool in return l == r })
                    .observeOn(MainScheduler.instance)
                    .filter({ (isBrowserVCEmpty, isOfflineSynIdle, isDriveStackEmpty) -> Bool in
                          GeckoLogger.info("webInfo watch condition, isBrowserVCEmpty=\(isBrowserVCEmpty), offlineSynIdle=\(isOfflineSynIdle), driveStackEmpty=\(isDriveStackEmpty)")
                          return isBrowserVCEmpty && isOfflineSynIdle && isDriveStackEmpty
                      })
                    .take(1)
                    .subscribe(onNext: { (_, _, _) in
                        GeckoLogger.info("webInfo watch condition done, tryApplyPackage")
                        GeckoPackageManager.shared.asyncApplyPackage(item: item) {
                            self.removeNextLauchApply(item)
                            self.cancelFullPkgDownloadTaskLower(than: version)
                        }
                    }).disposed(by: self.disposeBagForWebInfoApply)
            case .bitable:
                GeckoLogger.info("bitable channel begin watch condition")
            default:
                GeckoLogger.warning("unsupport channel updated")
        }
    }

    private func markNextLauchApply(_ item: DocsChannelInfo, version: String) {
        var nextLauchUpdateChannels = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.geckoLauchUpdateChannels) ?? [:]
        nextLauchUpdateChannels.updateValue(version, forKey: item.type.identifier())
        GeckoLogger.info("markNextLauchShouldApplay, name=\(item.type.channelName()), version=\(version), dic=\(nextLauchUpdateChannels)")
        CCMKeyValue.globalUserDefault.setDictionary(nextLauchUpdateChannels, forKey: UserDefaultKeys.geckoLauchUpdateChannels)
    }

    private func removeNextLauchApply(_ item: DocsChannelInfo) {
        
        var nextLauchUpdateChannels = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.geckoLauchUpdateChannels) ?? [:]
        
        nextLauchUpdateChannels.removeValue(forKey: item.type.identifier())
        GeckoLogger.info("removeNextLauchShouldApplay, name=\(item.type.channelName()), dic=\(nextLauchUpdateChannels)")
        CCMKeyValue.globalUserDefault.setDictionary(nextLauchUpdateChannels, forKey: UserDefaultKeys.geckoLauchUpdateChannels)
    }
    
    // 取消版本号小于version的完整包下载任务
    private func cancelFullPkgDownloadTaskLower(than version: String) {
        pkgDownloadTasks.filter({ !$0.isGrayscale && $0.version.compare(version, options: .numeric) == .orderedAscending })
            .forEach { (task) in
                task.cancel()
                pkgDownloadTasks.removeAll(where: { $0 === task })
            }
    }

    /// 异步应用新资源包
    ///
    /// - Parameter type: channel name
    /// - Parameter completion: finish callback, dispatch on main thread
    func asyncApplyPackage(item: DocsChannelInfo, completion: (() -> Void)?) {
        GeckoLogger.info("willApplyPackage, name=\(item.type.channelName())")
        reportWillUpdate(type: item.type)
        DispatchQueue.global().async {
            self.tryMoveGeckoFromOriginalToBackup(channel: item, lauchUpdate: false)
            DispatchQueue.main.async {
                self.refreshOfflineResourceLocator(item)
                self.reportDidUpdate(type: item.type, finish: true, needReloadRN: true)
                completion?()
            }
        }
    }

    func reportWillUpdate(type: GeckoChannleType) {
        for obj in self.eventListeners.all {
            obj.packageWillUpdate(self, in: type)
        }
    }

    func reportDidUpdate(type: GeckoChannleType, finish: Bool, needReloadRN: Bool) {
        for obj in self.eventListeners.all {
            obj.packageDidUpdate(self, in: type, isSuccess: finish, needReloadRN: needReloadRN)
        }
    }

}
