//
//  FolderContentViewModel.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/4/16.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkCore
import RxRelay
import RxSwift
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import MobileCoreServices
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import LarkSetting
import LarkSDKInterface
import RustPB
import LarkAlertController

public class FolderContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext>: FileAndFolderBaseContentViewModel<M, D, C> {
    public override var identifier: String {
        return "folder"
    }

    var content: FolderContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return (self.message.content as? FolderContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    override var key: String {
        return content?.key ?? ""
    }

    override var name: String {
        return ((self.message.content as? FolderContent) ?? FolderContent.transform(pb: RustPB.Basic_V1_Message())).name
    }

    override var sizeValue: Int64 {
        return content?.size ?? 0
    }

    override var lastEditInfo: (time: Int64, userName: String)? {
        return nil
    }

    public override var icon: UIImage {
        return Resources.icon_folder_message
    }

    override var fileSource: Basic_V1_File.Source {
        return content?.fileSource ?? .unknown
    }

    public override var permissionPreview: (Bool, ValidateResult?) {
        return context.checkPermissionPreview(chat: metaModel.getChat(), message: metaModel.message)
    }
}

final class MergeForwardFolderContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext>: FolderContentViewModel<M, D, C> {
    // https://meego.feishu.cn/larksuite/issue/detail/16198371
    // 合并转发如果来自消息链接化，那合并转发详情页的文件等也需要屏蔽这些入口，此处其实有一些特化，正常应该遵循FileAndFolderConfig的配置
    private var isFromMessageLink: Bool {
        return !(content?.authToken?.isEmpty ?? true)
    }

    override var useLocalChat: Bool {
        if isFromMessageLink {
            return true
        }
        return fileAndFolderConfig.useLocalChat
    }

    override var canViewInChat: Bool {
        return fileAndFolderConfig.canViewInChat && !isFromMessageLink
    }

    override var canForward: Bool {
        return fileAndFolderConfig.canForward && !isFromMessageLink
    }

    override var canSearch: Bool {
        return fileAndFolderConfig.canSearch && !isFromMessageLink
    }

    override var canSaveToDrive: Bool {
        return fileAndFolderConfig.canSaveToDrive && !isFromMessageLink
    }

    override var canOfficeClick: Bool {
        return fileAndFolderConfig.canOfficeClick && !isFromMessageLink
    }
}
