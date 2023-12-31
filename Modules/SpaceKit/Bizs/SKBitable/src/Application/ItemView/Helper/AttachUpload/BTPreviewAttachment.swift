//
//  BTPreviewAttachment.swift
//  SKBitable
//
//  Created by qiyongka on 2022/8/19.
//

import UIKit
import HandyJSON
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import LarkUIKit
import UniverseDesignColor
import Foundation
import EENavigator
import RxSwift
import UniverseDesignToast
import UniverseDesignDialog
import SpaceInterface
import LarkLocationPicker
import SwiftUI

final class BTAttachmentsPreview {
    public static func attachmentsPreview(hostVC: UIViewController,
                                          driveDelegate: DriveSDKAttachmentDelegate,
                                          spaceFollowAPIDelegate: SpaceFollowAPIDelegate?,
                                          previewAttachmentsModel: AttachmentsPreviewParams) {


        guard let result = attachmentsPreviewBody(
            hostVC: hostVC,
            spaceFollowAPIDelegate: spaceFollowAPIDelegate,
            previewAttachmentsModel: previewAttachmentsModel
        ) else {
            DocsLogger.btError("[ACTION] attachmentsPreviewBody is nil")
            return
        }
        var body = result.body
        let curAttachment = result.curAttachment
        body.attachmentDelegate = driveDelegate

        let attachFileParams: [String: Any] =
        ["bussinessId": "bitable_attach",
         "file_token": curAttachment.attachmentToken,
         "mount_node_token": curAttachment.mountToken,
         "mount_point": curAttachment.mountPointType,
         "file_size": curAttachment.size,
         "file_mime_type": curAttachment.mimeType,
         "extra": curAttachment.extra,
         "fieldId": previewAttachmentsModel.fieldID,
         "index": previewAttachmentsModel.atIndex,
         "table_id": previewAttachmentsModel.tableID,
         "recordId": previewAttachmentsModel.recordID,
         "from": previewAttachmentsModel.attachFrom]

        show(body: body, from: hostVC, completion: { _, rsp in
            // 配置 mountToken 以支持附件 Follow
            if let blockVC = rsp.resource as? DriveFileBlockVCProtocol {
                blockVC.fileBlockMountToken = FollowModule.boxPreview.rawValue
            }
            if let vc = rsp.resource as? FollowableViewController {
                spaceFollowAPIDelegate?.currentFollowAttachMountToken = FollowModule.boxPreview.rawValue
                spaceFollowAPIDelegate?.follow(hostVC as? FollowableViewController, add: vc)
                spaceFollowAPIDelegate?.follow(nil, onOperate: .vcOperation(value: .openOrCloseAttachFile(isOpen: true)))
                spaceFollowAPIDelegate?.follow(vc, onOperate: .nativeStatus(funcName: DocsJSCallBack.notifyAttachFileOpen.rawValue,
                                                                             params: attachFileParams))
            }
        })
    }

    private static func show<T: Body>(body: T, from: NavigatorFrom, completion: Handler? = nil) {
        if !UserScopeNoChangeFG.YY.bitablePreviewFileFullscreenDisable {
            Navigator.shared.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .overFullScreen }, completion: completion)
        } else {
            Navigator.shared.push(body: body, from: from, completion: completion)
        }
    }
    
    static func attachmentsPreview(
        hostVC: UIViewController,
        spaceFollowAPIDelegate: SpaceFollowAPIDelegate?,
        previewAttachmentsModel: AttachmentsPreviewParams
    ) {
        guard let result = BTAttachmentsPreview.attachmentsPreviewBody(
            hostVC: hostVC,
            spaceFollowAPIDelegate: spaceFollowAPIDelegate,
            previewAttachmentsModel: previewAttachmentsModel
        ) else {
            DocsLogger.btError("[ACTION] previewAttachments body is nil")
            return
        }
        show(body: result.body, from: hostVC)
    }
    
    private static func attachmentsPreviewBody(
        hostVC: UIViewController,
        spaceFollowAPIDelegate: SpaceFollowAPIDelegate?,
        previewAttachmentsModel: AttachmentsPreviewParams
    ) -> (body: DriveSDKAttachmentFileBody, curAttachment: BTAttachmentModel)? {
        guard !previewAttachmentsModel.attachments.isEmpty else {
            DocsLogger.btError("[ACTION] previewAttachmentsModel is empty")
            return nil
        }
        DocsLogger.btInfo("[ACTION] previewAttachments \(previewAttachmentsModel.atIndex)/\(previewAttachmentsModel.attachments.count)")
        var index = previewAttachmentsModel.atIndex
        if previewAttachmentsModel.atIndex < 0 || previewAttachmentsModel.atIndex >= previewAttachmentsModel.attachments.count {
            spaceAssertionFailure("[ACTION] previewAttachments index is invalid")
            index = 0
        }

        let curAttachment = previewAttachmentsModel.attachments[index]
        var previewAttachments = previewAttachmentsModel.attachments
        if !curAttachment.fileType.isImage, !curAttachment.fileType.isVideo {
            //非视频&图片不支持多附件预览
            previewAttachments = [curAttachment]
            index = 0
            DocsLogger.btInfo("previewAttachments with file")
        } else {
            //过滤掉非非视频&图片的附件
            previewAttachments = previewAttachmentsModel.attachments.filter { $0.fileType.isImage || $0.fileType.isVideo }
            index = previewAttachments.firstIndex(of: curAttachment) ?? 0
            DocsLogger.btInfo("previewAttachments with image/video \(index)/\(previewAttachments.count)")
        }

        let files = previewAttachments.map { attachment in
            return DriveSDKAttachmentFile(fileToken: attachment.attachmentToken,
                                          hostToken: previewAttachmentsModel.permissionToken,
                                          mountNodePoint: attachment.mountToken,
                                          mountPoint: attachment.mountPointType,
                                          fileType: nil,
                                          name: attachment.name,
                                          authExtra: attachment.extra,
                                          urlForSuspendable: nil, // 不支持悬浮窗
                                          dependency: CCMFileDependencyImpl())
        }

        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
        var body = DriveSDKAttachmentFileBody(files: files,
                                              index: index,
                                              appID: DKSupportedApp.bitable.rawValue,
                                              isCCMPremission: false,
                                              isInVCFollow: spaceFollowAPIDelegate != nil,
                                              naviBarConfig: naviBarConfig)
        body.tenantID = previewAttachmentsModel.hostTenantID
        return (body, curAttachment)
    }
}
