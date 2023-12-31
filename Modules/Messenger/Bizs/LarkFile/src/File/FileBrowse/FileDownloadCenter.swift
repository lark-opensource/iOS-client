//
//  FileDownloadCenter.swift
//  LarkFile
//
//  Created by SuPeng on 12/18/18.
//

import Foundation
import Reachability
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignToast
import LarkSDKInterface
import LarkAccountInterface
import EENavigator
import LarkContainer

/// 负责管理tasks, 监控网络状态，暂停或者开始task
final class FileDownloadCenter {
    private let reach: Reachability? = Reachability()

    static let autoDonwloadSize: Int64 = 100 * 1024 * 1024

    private let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        var oldConnection = reach?.connection ?? .none
        _ = NotificationCenter.default
            .rx
            .notification(Notification.Name.reachabilityChanged)
            .map { ($0.object as? Reachability)?.connection ?? .none }
            .subscribe(onNext: { [weak self] (connection) in
                guard let self = self else { return }

                defer { oldConnection = connection }

                if connection == .wifi {
                    if oldConnection == .none {
                        //无网变成wifi，所有下载失败的任务自动开始
                        self.downloadTasks.forEach { (task) in
                            switch task.currentStatus {
                            case .fail(error: let error):
                                if error.isAutoResumeable {
                                    task.start()
                                }
                            default:
                                break
                            }
                        }
                    } else if oldConnection == .cellular {
                        // 4G变wifi情况下，把所有的自动暂停的任务开始
                        self.downloadTasks.forEach { (task) in
                            if task.currentStatus == .pause(byUser: false) {
                                task.start()
                            }
                        }
                    }
                } else if connection == .cellular {
                    if oldConnection == .none {
                        // 无网络变为4G, 对于下载失败的文件，如果剩余文件大小小于100M,自动开始下载
                        self.downloadTasks.forEach { (task) in
                            switch task.currentStatus {
                            case .fail(error: let error):
                                if error.isAutoResumeable {
                                    if task.remainDownloadSize <= FileDownloadCenter.autoDonwloadSize {
                                        task.start()
                                    }
                                }
                            default:
                                break
                            }
                        }
                    } else if oldConnection == .wifi {
                        // wifi变为4G, 所有正在下载的任务，判断如果剩余文件大小大于100M,自动暂停
                        self.downloadTasks.forEach({ (task) in
                            if task.currentStatus.isDownloading {
                                if task.remainDownloadSize > FileDownloadCenter.autoDonwloadSize {
                                    task.toast?(BundleI18n.LarkFile.Lark_Legacy_SwitchedToMobileNetworkDownloadsupend)
                                    task.pause(byUser: false)
                                } else {
                                    task.toast?(BundleI18n.LarkFile.Lark_Legacy_SwitchedToMobileNetwork)
                                }
                            }
                        })
                    }
                } else if connection == .none {
                    let downloadingTasks = self.downloadTasks.filter { $0.currentStatus.isDownloading }
                    if !downloadingTasks.isEmpty {
                        // 所有正在下载的任务变成失败状态
                        downloadingTasks.forEach { $0.fail(reason: "cancel due to no network") }
                        if let topVC = userResolver.navigator.mainSceneWindow?.lu.visibleViewController() {
                            if !(topVC is FileBrowserController), let window = topVC.view.window {
                                UDToast.showTips(with: BundleI18n.LarkFile.Lark_Legacy_FileDownloadFail, on: window)
                            }
                        }
                    }
                }
            })
    }

    private var downloadTasks: [FileDownloadTask] = []

    func download(userID: String,
                  file: FileMessageInfo,
                  fileAPI: SecurityFileAPI,
                  sdkFileCacheStrategy: SDKFileCacheStrategy = .notUseSDKCache,
                  downloadFileDriver: Driver<PushDownloadFile>,
                  messageDriver: Driver<PushChannelMessage>) -> FileDownloadTask {
        let task = FileDownloadTask(userID: userID,
                                    file: file,
                                    fileAPI: fileAPI,
                                    sdkFileCacheStrategy: sdkFileCacheStrategy,
                                    downloadFileDriver: downloadFileDriver,
                                    messageDriver: messageDriver)

        return add(task: task)
    }

    @discardableResult
    func add(task: FileDownloadTask) -> FileDownloadTask {
        if let index = downloadTasks.firstIndex(of: task) {
            return downloadTasks[index]
        }
        downloadTasks.append(task)
        return task
    }

    func remove(task: FileDownloadTask) {
        task.dispose()
        downloadTasks.lf_remove(object: task)
    }
}
