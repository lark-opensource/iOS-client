//
//  BTJSService+OpenCoverFiles.swift
//  SKBitable
//
//  Created by qiyongka on 2022/8/14.
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

struct AttachmentsPreviewParams {
    var atIndex: Int = 0
    var fieldID: String = ""
    var recordID: String = ""
    var tableID: String = ""
    var attachments: [BTAttachmentModel] = []
    var attachFrom: String = ENativeOpenAttachFrom.cardAttachPreview.rawValue
    var permissionToken: String? //宿主文档token(在refer_base@docx中应当是base token 而不是 docx token)
    var hostTenantID: String? //宿主文档 token 对应所属的 tenantID，透传给 drive 附件预览使用
}

// 打开附件的两种来源： 画册面板，卡片附件
enum ENativeOpenAttachFrom: String {
    case coverPreview
    case cardAttachPreview
}

struct Attachment: HandyJSON {
    var file_mime_type: String = ""
    var mount_node_token: String = ""
    var file_name: String = ""
    var file_token: String = ""
    var file_size: Int = 0
    var mount_point: String = ""
    var bussinessId: String = ""
    var extra: String = ""
}

struct OpenCoverFilesParams: HandyJSON {
    var showIndex: Int = 0
    var fieldId: String = ""
    var recordId: String = ""
    var tableId: String = ""
    var attachments: [Attachment] = []
}


extension BTJSService {

    func handleOpenCoverFilesService(_ params: [String: Any]) {
        DocsLogger.btInfo("[SYNC] handleOpenCoverFilesService params \(String(describing: params.jsonString?.encryptToShort))")
        
        guard let browerVc = navigator?.currentBrowserVC as? BrowserViewController else {
            DocsLogger.btError("[SYNC] handleOpenCoverFilesService get browerVc error")
            return
        }
        
        guard let openCoverFilesParams = OpenCoverFilesParams.deserialize(from: params), !openCoverFilesParams.attachments.isEmpty else {
            DocsLogger.btError("[SYNC] handleOpenCoverFilesService insufficient params \(String(describing: params.toJSONString()))")
            return
        }
        self.previewAttachmentsModel = AttachmentsPreviewParams(
            atIndex: openCoverFilesParams.showIndex,
            fieldID: openCoverFilesParams.fieldId,
            recordID: openCoverFilesParams.recordId,
            tableID: openCoverFilesParams.tableId,
            attachFrom: ENativeOpenAttachFrom.coverPreview.rawValue)
            
        self.previewAttachmentsModel.attachments = openCoverFilesParams.attachments.map({ (attachment: Attachment) -> BTAttachmentModel in
            return BTAttachmentModel(attachmentToken: attachment.file_token,
                                     id: attachment.bussinessId,
                                     mimeType: attachment.file_mime_type,
                                     name: attachment.file_name,
                                     size: attachment.file_size,
                                     mountPointType: attachment.mount_point,
                                     mountToken: attachment.mount_node_token,
                                     extra: attachment.extra)
        })
        
        // 调用公共接口打开面板与预览
        BTAttachmentsPreview.attachmentsPreview(hostVC: browerVc,
                                               driveDelegate: self,
                                               spaceFollowAPIDelegate: browerVc.spaceFollowAPIDelegate,
                                               previewAttachmentsModel: self.previewAttachmentsModel)
        
    }
}

extension BTJSService: DriveSDKAttachmentDelegate {
    
    public func onAttachmentClose() {
        DocsLogger.btInfo("[ACTION] onAttachmentClose")
    }
    
    public func onAttachmentSwitch(to index: Int, with fileID: String) {
        DocsLogger.btInfo("[ACTION] onAttachmentSwitch: \(index)")

        //MagicShare兼容旧版本逻辑，因为旧版本不支持一次打开多个附件，这里在切换附件时模拟一个一个打开
        
        //1.先关闭前一个附件
        guard let indexInAttachment = self.previewAttachmentsModel.attachments.firstIndex(where: { $0.attachmentToken == fileID }) else {
            DocsLogger.btError("[ACTION] cannot find current attachment")
            return
        }
        let currentAttachment = self.previewAttachmentsModel.attachments[indexInAttachment]
        self.previewAttachmentsModel.atIndex = indexInAttachment
        model?.jsEngine.callFunction(DocsJSCallBack.onAttachFileExit, params: [:], completion: nil)

        //2.打开新的附件
        let attachFileParams: [String: Any] =
            ["bussinessId": "bitable_attach",
             "file_token": currentAttachment.attachmentToken,
             "mount_node_token": currentAttachment.mountToken,
             "mount_point": currentAttachment.mountPointType,
             "file_size": currentAttachment.size,
             "file_mime_type": currentAttachment.mimeType,
             "extra": currentAttachment.extra,
             "fieldId": self.previewAttachmentsModel.fieldID,
             "index": self.previewAttachmentsModel.atIndex,
             "recordId": self.previewAttachmentsModel.recordID,
             "table_id": self.previewAttachmentsModel.tableID,
             "from": ENativeOpenAttachFrom.coverPreview.rawValue
            ]
        
        guard let browerVc = navigator?.currentBrowserVC as? BrowserViewController else {
            DocsLogger.btError("[ACTION] cannot find current Vc")
            return
        }
        browerVc.spaceFollowAPIDelegate?.follow(
            browerVc, onOperate: .nativeStatus(funcName: DocsJSCallBack.notifyAttachFileOpen.rawValue, params: attachFileParams))
    }
}
