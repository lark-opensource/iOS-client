//
//  UploadFileNetworkService.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/12/2.
//

import RxSwift
import SKFoundation
import ThreadSafeDataStructure
import SpaceInterface
import SKInfra

class UploadFileNetworkService {

    private let disposeBag = DisposeBag()
    private let newCacheAPI: NewCacheAPI

    // 用来保存上传到 Drive 的task
    private let driveUploadTaskDic: SafeDictionary<String, [UploadFileTaskInfo]> = [:] + .readWriteLock

    // 保存文档token信息
    private let objTokenMap: SafeDictionary<String, String> = [:] + .readWriteLock

    private let driveUploader = DocsContainer.shared.resolve(DriveRustRouterBase.self)

    private lazy var offlineSyncManager = DocsContainer.shared.resolve(DocsOfflineSyncManager.self)

    init(_ resolver: DocsResolver = DocsContainer.shared) {
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
        DocsContainer.shared.resolve(DriveUploadCallbackServiceBase.self)?.addObserver(self)
        DocsLogger.info("UploadFileNetworkService init - \(addressOf(self))")
    }

    deinit {
        DocsLogger.info("UploadFileNetworkService deinit - \(addressOf(self))")
    }

    func addressOf<T: AnyObject>(_ o: T) -> String {
        let addr = unsafeBitCast(o, to: Int.self)
        return String(format: "%p", addr)
    }


    func uploadFile(localPath: SKFilePath,
                    uuid: String,
                    fileName: String,
                    contentType: SKPickContentType,
                    params: [String: AnyHashable],
                    progress: UploadFileTaskProgress? = nil,
                    completion: @escaping UploadFileTaskCompletion) {

        let task = UploadFileTaskInfo(
            contentType: contentType,
            uuid: uuid,
            fileName: fileName,
            localPath: localPath,
            params: params,
            progress: progress,
            completion: completion
        )

        innerUploadFile(task)
    }


    /// 取消所有任务
    func cancelAllTask() {
        let offlineUploadArray = offlineSyncManager?.uploadUUids ?? []
        DocsLogger.info("UploadFileNetworkService 取消所有任务, count=\(driveUploadTaskDic.count), offlineCount=\(offlineUploadArray.count)", component: LogComponents.uploadFile)

        //取消drive通道请求
        // Rust同步接口放入子线程
        DispatchQueue.global(qos: .userInteractive).async {
            self.driveUploadTaskDic.forEach { (key, taskArray) in
                if let firstTask = taskArray.first, offlineUploadArray.contains(firstTask.uuid) {
                    //离线正在上传不取消
                    DocsLogger.debug("UploadFileNetworkService, uuid=\(firstTask.uuid.encryptToken),离线正在上传不取消", component: LogComponents.uploadFile)
                } else {
                    _ = self.driveUploader?.cancelUpload(key: key)

                }
            }
            self.driveUploadTaskDic.removeAll()
        }
    }

    /// 删除任务
    func deleteTask(uuid: String, localPath: SKFilePath) {
        DocsLogger.info("deleteTask, uuid=\(uuid.encryptToken)", component: LogComponents.uploadFile)
        let assetInfo = newCacheAPI.getAssetWith(uuids: [uuid], objToken: nil).first
        if let assetInfo = assetInfo, assetInfo.uploadKey.isEmpty == false {
            DispatchQueue.global(qos: .userInteractive).async {
                self.driveUploadTaskDic.removeValue(forKey: assetInfo.uploadKey)
                _ = self.driveUploader?.deleteUploadResource(key: assetInfo.uploadKey)
                do {
                    try localPath.removeItem()
                } catch {
                    DocsLogger.error("[SKFilePath] deleteTask fail.")
                }
            }
        }
    }

    private func getAssetWith(uuid: String, objToken: String) -> SKAssetInfo? {
        guard let assetInfo = newCacheAPI.getAssetWith(uuids: [uuid], objToken: objToken).first else {
            return nil
        }
        return assetInfo
    }
}

extension UploadFileNetworkService: DriveUploadCallback {
    func onFailed(key: String, mountPoint: String, scene: DriveUploadScene, errorCode: Int, fileSize: Int64) {
        if let taskArray = self.driveUploadTaskDic[key] {
            DocsLogger.info("UploadFileNetworkService, onFailed,key=\(key) code=\(errorCode)", component: LogComponents.uploadFile)
            taskArray.forEach({ (driveTask) in
                driveTask.completion(.failure(.driveError(errorCode)))
            })
            self.driveUploadTaskDic.removeValue(forKey: key)
        }
    }

    func updateProgress(context: DriveUploadContext) {
        let key = context.key
        let status = context.status
        if let taskArray = self.driveUploadTaskDic[key] {
            if status != .inflight && status != .queue {
                DocsLogger.info("UploadFileNetworkService, updateProgress,key=\(key),status=\(status)", component: LogComponents.uploadFile)
            }
            var uuid: String = ""
            taskArray.forEach { (task) in
                uuid = task.uuid
                if status == .success {
                    task.completion(.success((uuid, task.fileSize, ["token": context.fileToken])))
                } else if status == .inflight {
                    task.progress?((context.bytesTransferred, context.bytesTotal))
                }
            }
            if status == .success, !uuid.isEmpty {
                let objToken = self.objTokenMap[key]
                newCacheAPI.updateFileToken(uuid: uuid, fileToken: context.fileToken, objToken: objToken ?? context.mountNodePoint)
                self.driveUploadTaskDic.removeValue(forKey: key)
            }
        }
    }
}

extension UploadFileNetworkService {
    func innerUploadFile(_ inTask: UploadFileTaskInfo) {
        guard
            let mountPoint = inTask.params?["mount_point"] as? String,
            let mountNodePoint = inTask.params?["mount_node_token"] as? String
            else {
                DocsLogger.info("UploadFileNetworkService, paramErr, uuid=\(inTask.uuid.encryptToken)", extraInfo: inTask.params, component: LogComponents.uploadFile)
                return
        }
        var task = inTask

        let objType = task.params?["obj_type"] as? Int32
        let localPath = task.localPath
        let contentType = task.contentType
        let uuid = task.uuid
        let fileName = task.fileName
        let extraParams = task.params?["extraParams"] as? [String: String]
        let extRust = task.params?["extRust"] as? [String: String]
        let isFolderBlockScene = task.params?["isFolderBlockScene"] as? Bool

        var resumeKey: String = ""
        var objToken = mountNodePoint
        if let docxObjToken = extraParams?["drive_route_token"] {
            // 1.0文档mountNodePoint就是文档token, docx的文档token在extraParams.drive_route_token
            objToken = docxObjToken
        }
        var assetInfo = getAssetWith(uuid: uuid, objToken: objToken)
        if isFolderBlockScene == true {
            //文件及block场景下不能依赖token取，因为下发的是wikiToken，存的是objToken，换种方式取DB数据
            assetInfo = newCacheAPI.getAssetWith(uuids: [uuid], objToken: nil).first
        }

        if let assetInfo = assetInfo {
            task.fileSize = assetInfo.fileSize
            guard assetInfo.fileToken.isEmpty else {
                DocsLogger.error("UploadFileNetworkService, uuid=\(task.uuid.encryptToken), already had token, return", component: LogComponents.uploadFile)
                task.completion(.success((uuid, assetInfo.fileSize, ["token": assetInfo.fileToken])))
                return
            }
            resumeKey = assetInfo.uploadKey
            DocsLogger.error("UploadFileNetworkService, uuid=\(task.uuid.encryptToken), resumeKey = \(resumeKey), localPath=\(localPath.pathString)",
                             component: LogComponents.uploadFile)
        } else {
            DocsLogger.error("UploadFileNetworkService, uuid=\(task.uuid.encryptToken), getAssetWith error",
                             component: LogComponents.uploadFile)
        }

        if !localPath.exists {
            DocsLogger.error("UploadFileNetworkService, uuid=\(task.uuid.encryptToken), file does not exist, localPath=\(localPath.pathString)",
                             component: LogComponents.uploadFile)
        }

        // 使用 Drive 上传
        DispatchQueue.global(qos: .userInteractive).async {
            guard let driveUploader = self.driveUploader else {
                DocsLogger.error("UploadFileNetworkService, driveUploader nil, uuid=\(task.uuid.encryptToken)", component: LogComponents.uploadFile)
                return
            }
            self.resumeOrUploadObservabel(uploader: driveUploader,
                                          resumeKey: resumeKey,
                                          taskUUID: task.uuid,
                                          contentType: contentType,
                                          localPath: localPath.pathString,
                                          fileName: fileName,
                                          mountNodePoint: mountNodePoint,
                                          mountPoint: mountPoint,
                                          objType: objType,
                                          extraParams: extraParams,
                                          extRust: extRust).subscribe(onNext: { [weak self] key in
                                            guard let self = self else { return }
                                            if var assetInfo = assetInfo, assetInfo.uploadKey != key {
                                                assetInfo.uploadKey = key
                                                self.newCacheAPI.updateAsset(assetInfo)
                                            }
                                            DocsLogger.info("UploadFileNetworkService, uuid=\(task.uuid.encryptToken) upload, withKey=\(key)",
                                                            component: LogComponents.uploadFile)
                                            var taskArray = self.driveUploadTaskDic[key] ?? []
                                            taskArray.append(task)
                                            self.driveUploadTaskDic.updateValue(taskArray, forKey: key)
                                            self.objTokenMap.updateValue(objToken, forKey: key)
                                            self.reportStartUpload(for: task.params ?? [:], uploadKey: key)
                                        }).disposed(by: self.disposeBag)

        }
    }

    func resumeOrUploadObservabel(uploader: DriveRustRouterBase,
                                  resumeKey: String,
                                  taskUUID: String,
                                  contentType: SKPickContentType,
                                  localPath: String,
                                  fileName: String,
                                  mountNodePoint: String,
                                  mountPoint: String,
                                  objType: Int32?,
                                  extraParams: [String: String]?,
                                  extRust: [String: String]?) -> Observable<String> {
        var apiType: DriveUploadRequest.ApiType = (contentType == .image) ? .img : .drive
        if mountPoint == DriveConstants.wikiMountPoint {
            // wiki场景下走分片上传流程，多个文件同时上传走直传会触发后端锁资源问题导致上传失败
            apiType = .drive
        }
        let context = DriveUploadRequestContext(localPath: localPath,
                                                fileName: fileName,
                                                mountNodePoint: mountNodePoint,
                                                mountPoint: mountPoint,
                                                uploadCode: nil,
                                                scene: .unknown,
                                                objType:  objType,
                                                apiType: apiType,
                                                priority: .defaultHigh,
                                                extraParams: extraParams ?? [:],
                                                extRust: extRust ?? [:])
        let uploadObservable = uploader.upload(context: context)
        if resumeKey.isEmpty {
            return uploadObservable
        } else {
            return uploader.resumeUpload(key: resumeKey).flatMap { (result) -> Observable<String> in
                DocsLogger.info("UploadFileNetworkService, uuid=\(taskUUID.encryptToken), resume, withKey =\(resumeKey), resumeResult=\(result) ",
                                component: LogComponents.uploadFile)
                if result == -1 {
                    return uploadObservable
                } else {
                    DocsLogger.info("UploadFileNetworkService, uuid=\(taskUUID.encryptToken) upload, withKey=\(resumeKey)",
                                    component: LogComponents.uploadFile)
                    return .just(resumeKey)
                }
            }
        }
    }

    private func reportStartUpload(for params: [String: Any], uploadKey: String) {
        if let objType = params["obj_type"] as? Int {
            let docsType = DocsType(rawValue: objType)
            let module: String = docsType.statisticModule.rawValue
            DocsContainer.shared.resolve(UploadAndDownloadStastis.self)?.recordUploadInfo(module: module, uploadKey: uploadKey, isDriveSDK: true)
        }
    }
}
