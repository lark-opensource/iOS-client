//
//  DriveDependencyImpl.swift
//  TodoMod
//
//  Created by baiyantao on 2022/12/27.
//

import Foundation
import TodoInterface
import Swinject
import RxSwift
import LarkUIKit
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkStorage
#if CCMMod
import SpaceInterface
#endif

final class DriveDependencyImpl: DriveDependency, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    private let mountPoint = "task"
    private let appId = "73"

    static let logger = Logger.log(DriveDependencyImpl.self, category: "Todo.DriveDependencyImpl")

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func upload(localPath: String, fileName: String) -> Observable<TaskUploadInfo> {
        #if CCMMod
        return (try? userResolver.resolve(assert: DocCommonUploadProtocol.self))?
            .upload(
                localPath: localPath,
                fileName: fileName,
                mountNodePoint: "",
                mountPoint: mountPoint,
                copyInsteadMoveAfterSuccess: true,
                priority: .default
            ).map { (uploadKey, progress, fileToken, status) -> TaskUploadInfo in
                let uploadStatus: TaskUploadStatus
                switch status {
                case .cancel:
                    uploadStatus = .cancel
                case .failed:
                    uploadStatus = .failed
                case .success:
                    uploadStatus = .success
                default:
                    uploadStatus = .uploading
                }
                return TaskUploadInfo(
                    uploadKey: uploadKey,
                    progress: progress,
                    fileToken: fileToken,
                    uploadStatus: uploadStatus
                )
            } ?? Observable.empty()
        #else
        return Observable.empty()
        #endif
    }

    func resumeUpload(key: String) -> Observable<TaskUploadInfo> {
        #if CCMMod
        (try? userResolver.resolve(assert: DocCommonUploadProtocol.self))?
            .resumeUpload(key: key, copyInsteadMoveAfterSuccess: false)
            .map { (uploadKey, progress, fileToken, status) -> TaskUploadInfo in
                let uploadStatus: TaskUploadStatus
                switch status {
                case .cancel:
                    uploadStatus = .cancel
                case .failed:
                    uploadStatus = .failed
                case .success:
                    uploadStatus = .success
                default:
                    uploadStatus = .uploading
                }
                return TaskUploadInfo(
                    uploadKey: uploadKey,
                    progress: progress,
                    fileToken: fileToken,
                    uploadStatus: uploadStatus
                )
            } ?? Observable.empty()
        #else
        Observable.empty()
        #endif
    }

    func cancelUpload(key: String) -> Observable<Bool> {
        #if CCMMod
        (try? userResolver.resolve(assert: DocCommonUploadProtocol.self))?.cancelUpload(key: key) ?? Observable.empty()
        #else
        Observable.empty()
        #endif
    }

    func deleteUploadResource(key: String) -> Observable<Bool> {
        #if CCMMod
        (try? userResolver.resolve(assert: DocCommonUploadProtocol.self))?.deleteUploadResource(key: key) ?? Observable.empty()
        #else
        Observable.empty()
        #endif
    }

    func previewFile(from: UIViewController, fileToken: String) {
        #if CCMMod
        userResolver.navigator.push(body: getPreviewFileBody(by: fileToken), from: from)
        #endif
    }

    func previewFileInPresent(from: UIViewController, fileToken: String) {
        #if CCMMod
        userResolver.navigator.present(
            body: getPreviewFileBody(by: fileToken),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
        #endif
    }

    #if CCMMod
    private func getPreviewFileBody(by fileToken: String) -> DriveSDKAttachmentFileBody {
        Self.logger.info("previewFile, token: \(fileToken)")
        let file = DriveSDKAttachmentFile(
            fileToken: fileToken,
            mountNodePoint: "",
            mountPoint: mountPoint,
            fileType: nil,
            name: nil,
            authExtra: nil,
            dependency: TaskFileDependencyImpl()
        )
        return DriveSDKAttachmentFileBody(
            files: [file],
            index: 0,
            appID: appId
        )
    }
    #endif

    func getUploadCachePath(with fileName: String) -> IsoPath {
        let path: IsoPath =
            .in(space: .user(id: userResolver.userID))
            .in(domain: Domain.biz.todo)
            .build(forType: .cache, relativePart: "upload_caches")
        try? path.createDirectoryIfNeeded()
        return path + fileName
    }
}

#if CCMMod
fileprivate struct TaskFileDependencyImpl: DriveSDKDependency {
    var actionDependency: DriveSDKActionDependency = ActionDependencyImpl()
    var moreDependency: DriveSDKMoreDependency = MoreDependencyImpl()

    // 配置外部控制事件
    struct ActionDependencyImpl: DriveSDKActionDependency {
        var closePreviewSignal: Observable<Void> { .never() }
        var stopPreviewSignal: Observable<Reason> { .never() }
    }
    // 配置更多功能选项
    struct MoreDependencyImpl: DriveSDKMoreDependency {
        var moreMenuVisable: Observable<Bool> { .just(true) }
        var moreMenuEnable: Observable<Bool> { .just(true) }
        var actions: [DriveSDKMoreAction] {
            [.saveToLocal(handler: { _, _  in }),
             .customOpenWithOtherApp(customAction: nil, callback: nil)]
        }
    }
}
#endif
