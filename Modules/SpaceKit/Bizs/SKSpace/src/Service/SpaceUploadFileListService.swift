//
//  SpaceUploadFileListService.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/10/24.
// swiftlint:disable function_parameter_count

import Foundation
import SKFoundation
import SKCommon
import SwiftyJSON
import SpaceInterface
import SKInfra

// 负责在 drive 上传成功后，将数据本地插入到列表中 https://bytedance.feishu.cn/docx/LXjydGAzQoMVg5xwekAcKToKnmf
class SpaceUploadFileListService: DriveUploadCallback {

    private let dataManager: SKDataManager

    init(dataManager: SKDataManager, uploadService: DriveUploadCallbackServiceBase) {
        self.dataManager = dataManager
        uploadService.addObserver(self)
    }

    func updateProgress(context: DriveUploadContext) {
        // 只处理上传成功事件
        guard case .success = context.status else { return }
        // 只处理 Space 和 Wiki
        switch context.mountPoint {
        case DriveConstants.driveMountPoint:
            // Space 文档
            handleSpaceUploadComplete(parentFolderToken: context.mountNodePoint,
                                      objToken: context.fileToken,
                                      nodeToken: context.nodeToken,
                                      fileName: context.fileName)
        case DriveConstants.wikiMountPoint:
            // Wiki 文档
            handleWikiUploadComplete(objToken: context.fileToken,
                                     wikiToken: context.nodeToken,
                                     spaceID: context.mountNodePoint,
                                     fileName: context.fileName)
        default:
            return
        }
    }

    private func handleSpaceUploadComplete(parentFolderToken: String, objToken: String, nodeToken: String, fileName: String) {
        guard let userID = User.current.info?.userID else {
            DocsLogger.error("userID found nil when handle space upload complete event")
            return
        }
        let curTime = Date().timeIntervalSince1970
        let nodeInfo: [String: Any] = ["name": fileName,
                                       "obj_token": objToken,
                                       "token": nodeToken,
                                       "create_uid": userID,
                                       "owner_id": userID,
                                       "edit_uid": userID,
                                       "edit_time": curTime,
                                       "add_time": curTime,
                                       "create_time": curTime,
                                       "open_time": curTime,
                                       "activity_time": curTime,
                                       "my_edit_time": curTime,
                                       "parent": parentFolderToken,
                                       "type": DocsType.file.rawValue,
                                       "url": DocsUrlUtil.url(type: .file, token: objToken).absoluteString,
                                       "node_type": 0]
        // fakeFileEntry 的 ownerType 需要与 parent 一致，此处缺少上下文，延后到 dataManager 内处理
        let fakeFileEntry = SpaceEntryFactory.createEntry(type: .file, nodeToken: nodeToken, objToken: objToken)
        guard let driveEntry = fakeFileEntry as? DriveEntry else {
            DocsLogger.error("create fake drive entry failed")
            return
        }
        driveEntry.updatePropertiesFrom(JSON(nodeInfo))
        let fileType = SKFilePath.getFileExtension(from: fileName)
        driveEntry.updateFileType(fileType)
        dataManager.insertUploadedFileEntry(driveEntry, folderToken: parentFolderToken)
    }

    private func handleWikiUploadComplete(objToken: String, wikiToken: String, spaceID: String, fileName: String) {
        guard let userID = User.current.info?.userID else {
            DocsLogger.error("userID found nil when handle space upload complete event")
            return
        }
        let curTime = Date().timeIntervalSince1970
        let nodeInfo: [String: Any] = ["name": fileName,
                                       "obj_token": wikiToken,
                                       "token": wikiToken,
                                       "create_uid": userID,
                                       "owner_id": userID,
                                       "edit_uid": userID,
                                       "edit_time": curTime,
                                       "add_time": curTime,
                                       "create_time": curTime,
                                       "open_time": curTime,
                                       "activity_time": curTime,
                                       "my_edit_time": curTime,
                                       "type": DocsType.wiki.rawValue,
                                       "url": DocsUrlUtil.url(type: .wiki, token: wikiToken).absoluteString,
                                       "node_type": 0]
        // fakeFileEntry 的 ownerType 需要与 parent 一致，此处缺少上下文，延后到 dataManager 内处理
        let fakeFileEntry = SpaceEntryFactory.createEntry(type: .wiki, nodeToken: wikiToken, objToken: wikiToken)
        guard let wikiEntry = fakeFileEntry as? WikiEntry else {
            DocsLogger.error("create fake wiki entry failed")
            return
        }
        wikiEntry.updatePropertiesFrom(JSON(nodeInfo))
        let wikiInfo = WikiInfo(wikiToken: wikiToken, objToken: objToken, docsType: .file, spaceId: spaceID)
        wikiEntry.update(wikiInfo: wikiInfo)
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataManager.insertUploadedWikiEntry(wikiEntry)
    }

    // 失败事件暂不处理
    func onFailed(key: String, mountPoint: String, scene: DriveUploadScene, errorCode: Int, fileSize: Int64) {}
}
