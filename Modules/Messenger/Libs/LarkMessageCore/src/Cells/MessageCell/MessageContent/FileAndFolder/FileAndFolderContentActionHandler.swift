//
//  FileAndFolderContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/21.
//

import RxSwift
import RxRelay
import LarkModel
import LarkContainer
import LarkMessageBase
import LarkSDKInterface
import UniverseDesignToast
import LarkMessengerInterface

public class FileAndFolderContentActionHandler<C: PageContext>: ComponentActionHandler<C> {
    let disposeBag = DisposeBag()

    public func open(
        chat: Chat,
        message: Message,
        useLocalChat: Bool,
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool,
        canSaveToDrive: Bool,
        canOfficeClick: Bool
    ) {
        assertionFailure("need be override")
    }

    // swiftlint:disable function_parameter_count
    public func tapAction(
        chat: Chat,
        message: Message,
        isLan: Bool,
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        useLocalChat: Bool,
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool,
        canSaveToDrive: Bool,
        canOfficeClick: Bool
    ) {
        guard let window = self.context.targetVC?.view.window else { return }
        // 局域网文件/文件夹不能交互
        if isLan {
            return
        }
        switch message.fileDeletedStatus {
        case .normal:
            break
        case .recoverable:
            var authToken: String?
            if message.type == .file {
                authToken = (message.content as? FileContent)?.authToken
            } else if message.type == .folder {
                authToken = (message.content as? FolderContent)?.authToken
            }
            // 被管理员临时删除后可能会恢复，需要调用getFileState主动获取push，保证下次的状态是最新的
            self.context.fileAPI?.getFileStateRequest(messageId: message.id,
                                                      sourceType: message.sourceType,
                                                      sourceID: message.sourceID,
                                                      authToken: authToken,
                                                      downloadFileScene: context.downloadFileScene)
            .subscribe().disposed(by: self.disposeBag)
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, on: window)
            return
        case .unrecoverable:
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, on: window)
            return
        case .recalled:
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Legacy_FileWithdrawTip, on: window)
            return
        case .freedUp:
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
            return
        @unknown default:
            fatalError("unknown enum")
        }

        if message.localStatus != .success {
            return
        }
        self.open(
            chat: chat,
            message: message,
            useLocalChat: useLocalChat,
            canViewInChat: canViewInChat,
            canForward: canForward,
            canSearch: canSearch,
            canSaveToDrive: canSaveToDrive,
            canOfficeClick: canOfficeClick
        )
    }
    // swiftlint:enable function_parameter_count

    // Office文件类型的鉴权涉及其他业务，消息链接化场景暂时屏蔽Office文件类型的点击事件（三端对齐）
    func isOfficeFile(fileName: String) -> Bool {
        let officeExtensions = [".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".csv"]
        return officeExtensions.contains(where: { fileName.hasSuffix($0) })
    }
}
