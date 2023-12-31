//
//  ChatTabSearchFileRouter.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/23.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import EENavigator
import UniverseDesignToast
import LarkKASDKAssemble
import Homeric
import LKCommonsTracker
import LKCommonsLogging

protocol ChatTabSearchFileRouter: AnyObject {
    func pushFolderManagementViewController(messageId: String, firstLevelInformation: FolderFirstLevelInformation?, fromVC: UIViewController)
    func pushFileBrowserViewController(chatId: String, messageId: String, fileInfo: FileContentBasicInfo?, isInnerFile: Bool, fromVC: UIViewController)
    func pushToChatOrReplyInThreadController(chatId: String,
                                             toMessagePosition: Int32,
                                             threadId: String,
                                             threadPosition: Int32,
                                             fromVC: UIViewController,
                                             isFolder: Bool)
}

final class DefaultChatTabSearchFileRouter: ChatTabSearchFileRouter, UserResolverWrapper {
    let userResolver: UserResolver

    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var fileUtil: FileUtilService?
    @ScopedInjectedLazy private var driveSDKFileDependency: DriveSDKFileDependency?
    private static let logger = Logger.log(DefaultChatTabSearchFileRouter.self, category: "DefaultChatTabSearchFileRouter")
    private let disposeBag: DisposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func pushFolderManagementViewController(messageId: String, firstLevelInformation: FolderFirstLevelInformation?, fromVC: UIViewController) {
        self.messageAPI?.fetchMessage(id: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak fromVC, userResolver] message in
                guard let fromVC = fromVC, message.type == .folder, let folderContent = message.content as? FolderContent else { return }
                // 局域网文件夹不支持在移动端打开
                if folderContent.fileSource == .lanTrans {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_Message_file_lan_searchsendreceived, on: fromVC.view)
                    return
                }
                let body = FolderManagementBody(messageId: messageId, scene: .fileTab, firstLevelInformation: firstLevelInformation)
                userResolver.navigator.push(body: body, from: fromVC)
                FileTabTracker.FileListClickFile(isFolder: true)
            }).disposed(by: disposeBag)
    }

    func pushFileBrowserViewController(chatId: String, messageId: String, fileInfo: FileContentBasicInfo?, isInnerFile: Bool, fromVC: UIViewController) {
        self.messageAPI?.fetchMessage(id: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC] (message) in
                guard let self, let fromVC else { return }
                /// 局域网文件不支持在移动端打开
                if message.type == .file, let fileContent = message.content as? FileContent,
                   fileContent.fileSource == .lanTrans {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_Message_file_lan_searchsendreceived, on: fromVC.view)
                    return
                }
                /// 这里可能是子文件，需要判断下上层文件夹
                if message.type == .folder, let folderContent = message.content as? FolderContent,
                   folderContent.fileSource == .lanTrans {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_Message_file_lan_searchsendreceived, on: fromVC.view)
                    return
                }

                let body = MessageFileBrowseBody(messageId: messageId, fileInfo: fileInfo, isInnerFile: isInnerFile, scene: .fileTab)
                self.navigator.push(body: body, from: fromVC)
                FileTabTracker.FileListClickFile(isFolder: false)
            }).disposed(by: disposeBag)
    }

    func pushToChatOrReplyInThreadController(chatId: String,
                                             toMessagePosition: Int32,
                                             threadId: String,
                                             threadPosition: Int32,
                                             fromVC: UIViewController,
                                             isFolder: Bool) {
        /// 如果toMessagePosition == replyInThreadMessagePosition，往chat内跳转的话，无法定位到消息
        if toMessagePosition == replyInThreadMessagePosition, !threadId.isEmpty {
            Self.logger.info("chatFileTab chatId \(chatId) pushReplyInThreadVC threadId \(threadId) threadPosition \(threadPosition)")
            let body = ReplyInThreadByIDBody(threadId: threadId,
                                             loadType: .position,
                                             position: threadPosition)
            navigator.push(body: body, from: fromVC)
        } else {
            let body = ChatControllerByIdBody(
                chatId: chatId,
                position: toMessagePosition
            )
            navigator.push(body: body, from: fromVC)
        }
        FileTabTracker.FileListClickToChat(isFolder: isFolder)
    }
}

struct FileTabTracker {
    enum clickType {
        case search
        case single_file
        case jump_to_chat
    }
    static let CommonParams: [AnyHashable: Any] = ["page_type": "main_view",
                                                   "source": "from_file_tab"]

    static func FileListClickFile(isFolder: Bool) {
        let file_type = isFolder ? "folder" : "file"
        var params = CommonParams
        params += ["click": "single_file",
                  "file_type": file_type,
                  "target": "none"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                              params: params))
    }

    static func FileListClickSearch() {
        var params = CommonParams
        params += ["click": "search",
                            "target": "none"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                              params: params))
    }

    static func FileListClickToChat(isFolder: Bool) {
        var params = CommonParams
        params += ["click": "jump_to_chat",
                   "file_type": isFolder ? "folder" : "file",
                   "target": "im_chat_main_view"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                              params: params))
    }

    static func FileListView() {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_VIEW,
                              params: CommonParams))
    }
}
