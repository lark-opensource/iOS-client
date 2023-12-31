//
//  SearchInChatCellViewModel.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/23.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import CryptoSwift
import LarkSearchCore
import LarkSearchFilter
import LarkTag
import LKCommonsLogging
import LarkContainer

final class SearchInChatViewModelContext {
    struct ClickInfo {
        let sessionId: String?
        let imprId: String?
        let query: String?
        let searchLocation: String?
        let filters: [SearchFilter]
        let tableView: UITableView?
    }

    let chatId: String
    let chatType: Chat.TypeEnum?
    var clickInfo: (() -> (ClickInfo))?

    let userResolver: UserResolver
    init(userResolver: UserResolver, chatId: String, chatType: Chat.TypeEnum?) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.chatType = chatType
    }
}

final class SearchInChatCellViewModel: UserResolverWrapper {
    static let logger = Logger.log(SearchInChatCellViewModel.self, category: "Module.IM.Search")

    let data: SearchResultType?
    let chatId: String
    let chatAPI: ChatAPI
    let isSearchingResult: Bool
    let context: SearchInChatViewModelContext
    var indexPath: IndexPath?
    private let router: SearchInChatRouter
    let enableThreadMiniIcon: Bool
    let enableDocCustomAvatar: Bool
    var useHotData: Bool?
    weak var fromVC: UIViewController?

    var avatarID: String {
        switch data?.meta {
        case .message(let message): return message.fromID // 会话内搜索message，始终展示消息发送方的消息
        default: return data?.avatarID ?? ""
        }
    }

    let userResolver: UserResolver
    // isSearchingResult是否是搜索结果(还可能是首屏默认数据)打点使用
    init(userResolver: UserResolver,
         chatId: String,
         chatAPI: ChatAPI,
         data: SearchResultType?,
         router: SearchInChatRouter,
         isSearchingResult: Bool,
         enableThreadMiniIcon: Bool,
         enableDocCustomAvatar: Bool,
         context: SearchInChatViewModelContext,
         useHotData: Bool? = nil) {
        self.userResolver = userResolver
        self.data = data
        self.router = router
        self.chatId = chatId
        self.chatAPI = chatAPI
        self.isSearchingResult = isSearchingResult
        self.enableThreadMiniIcon = enableThreadMiniIcon
        self.enableDocCustomAvatar = enableDocCustomAvatar
        self.context = context
        self.useHotData = useHotData
    }

    func goNextPage() {
        let isThread = (chatAPI.getLocalChat(by: self.chatId)?.chatMode ?? .default) == .threadV2
        let operationEvent: (FileOperationEvent) -> Void = { [weak self] event in
            let searching = self?.isSearchingResult ?? false
            switch event {
            case .downloadFile:
                SearchTrackUtil.trackClickChatHistoryResults(
                    type: .file,
                    isThread: isThread,
                    isSearchResult: searching,
                    action: .downloadFile
                )
            case .openFile:
                SearchTrackUtil.trackClickChatHistoryResults(
                    type: .file,
                    isThread: isThread,
                    isSearchResult: searching,
                    action: .openFile
                )
            case .saveToDrive:
                SearchTrackUtil.trackClickChatHistoryResults(
                    type: .file,
                    isThread: isThread,
                    isSearchResult: searching,
                    action: .saveToDrive
                )
            case .viewFileInChat:
                SearchTrackUtil.trackClickChatHistoryResults(
                    type: .file,
                    isThread: isThread,
                    isSearchResult: searching,
                    action: .viewInChat
                )
            }
        }
        guard let fromVC = self.fromVC else {
            assertionFailure("fromVC not set")
            return
        }
        switch data?.meta {
        case .doc(let docMeta):
            router.pushDocViewController(chatId: self.chatId, docUrl: docMeta.url, fromVC: fromVC)
            var additionInfo: [String: Any] = docSearchClickInfo(docMeta: docMeta)
            additionInfo = additionInfo.lf_update(["search_id": data?.contextID ?? ""])
            SearchTrackUtil.trackClickChatHistoryResults(
                type: .doc,
                isThread: isThread,
                isSearchResult: isSearchingResult,
                action: .openDocs,
                additionInfo: additionInfo
            )
        case .wiki(let wikiMeta):
            router.pushDocViewController(chatId: self.chatId, docUrl: wikiMeta.url, fromVC: fromVC)
            SearchTrackUtil.trackClickChatHistoryResults(
                type: .wiki,
                isThread: isThread,
                isSearchResult: isSearchingResult,
                action: .openWiki
            )
        case .message(let messageMeta):
            // 对于文件和文件夹类型，判断权限
            if messageMeta.contentType == .folder || (messageMeta.hasFileMeta && !messageMeta.fileMeta.name.isEmpty) {
                if !messageMeta.isFileAccessAuth {
                    let alertController = SearchNoPermissionPreviewAlert.getAlertViewController(.file)
                    navigator.present(alertController, from: fromVC)
                    return
                }
            }
            if messageMeta.contentType == .folder {
                router.pushFolderManagementViewController(messageId: messageMeta.id, firstLevelInformation: nil, fromVC: fromVC)
            } else if messageMeta.hasFileMeta, !messageMeta.fileMeta.name.isEmpty {
                // 跳转到filebrowser
                router.pushFileBrowserViewController(chatId: chatId, messageId: messageMeta.id, fileInfo: nil, isInnerFile: false, fromVC: fromVC, operationEvent: operationEvent)
            } else {
                SearchTrackUtil.trackClickChatHistoryResults(type: .message, isSearchResult: isSearchingResult, action: .viewInChat)
                if let chat = chatAPI.getLocalChat(by: messageMeta.chatID) {
                    if chat.chatMode == .threadV2 {
                        let body = ThreadDetailByIDBody(threadId: messageMeta.threadID,
                                                    loadType: .position,
                                                    position: messageMeta.threadPosition)
                        navigator.push(body: body, from: fromVC)
                        return
                    }
                }
                self.pushToChatOrReplyInThreadController(chatId: self.chatId,
                                              toMessagePosition: messageMeta.position,
                                              threadId: messageMeta.threadID,
                                              threadPosition: messageMeta.threadPosition,
                                              fromVC: fromVC,
                                              extraInfo: [:])
            }
        case .messageFile(let messageFileMeta):
            // 对于文件和文件夹类型，判断权限
            if !messageFileMeta.isFileAccessAuth {
                let alertController = SearchNoPermissionPreviewAlert.getAlertViewController(.file)
                navigator.present(alertController, from: fromVC)
                return
            }

            if messageFileMeta.fileType == .folder {
                router.pushFolderManagementViewController(
                    messageId: messageFileMeta.messageID,
                    firstLevelInformation: FolderFirstLevelInformation(
                        key: messageFileMeta.fileMeta.key,
                        authToken: nil,
                        authFileKey: messageFileMeta.fileMeta.key,
                        name: messageFileMeta.fileMeta.name,
                        size: messageFileMeta.fileMeta.size
                    ),
                    fromVC: fromVC
                )
            } else if messageFileMeta.hasFileMeta, !messageFileMeta.fileMeta.name.isEmpty {
                // 跳转到filebrowser
                var fileInfo: FileInfo?
                if messageFileMeta.isInnerFile {
                    fileInfo = FileInfo(
                        key: messageFileMeta.fileMeta.key,
                        authToken: nil,
                        authFileKey: "",
                        size: messageFileMeta.fileMeta.size,
                        name: messageFileMeta.fileMeta.name,
                        filePreviewStage: .normal
                    )
                }
                router.pushFileBrowserViewController(
                    chatId: chatId,
                    messageId: messageFileMeta.messageID,
                    fileInfo: fileInfo,
                    isInnerFile: messageFileMeta.isInnerFile,
                    fromVC: fromVC,
                    operationEvent: operationEvent
                )
            }

        case .link(let linkMeta):
            URL(string: linkMeta.originalURL)?.lf.toHttpUrl().flatMap {
                navigator.push($0, from: fromVC)
            }
            SearchTrackUtil.trackClickChatHistoryResults(type: .url, isSearchResult: isSearchingResult, action: .openURL)
        default: break
        }
    }

    func gotoChat() {
        guard let fromVC = self.fromVC else {
            assertionFailure("fromVC not set")
            return
        }
        switch data?.meta {
        case .doc(let docMeta):
            SearchTrackUtil.trackClickChatHistoryResults(type: .message, isSearchResult: isSearchingResult, action: .viewInChat)

            if let chat = chatAPI.getLocalChat(by: docMeta.chatID) {
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: docMeta.threadID,
                                                loadType: .position,
                                                position: docMeta.threadPosition)
                    navigator.push(body: body, from: fromVC)
                    return
                }
            }
            self.pushToChatOrReplyInThreadController(chatId: self.chatId,
                                          toMessagePosition: docMeta.position,
                                          threadId: docMeta.threadID,
                                          threadPosition: docMeta.threadPosition,
                                          fromVC: fromVC,
                                          extraInfo: ["docUrl": docMeta.url])
        case .message(let messageMeta):
            if let chat = chatAPI.getLocalChat(by: messageMeta.chatID) {
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: messageMeta.threadID,
                                                loadType: .position,
                                                position: messageMeta.threadPosition)
                    navigator.push(body: body, from: fromVC)
                } else {
                    self.pushToChatOrReplyInThreadController(chatId: chatId,
                                                  toMessagePosition: messageMeta.position,
                                                  threadId: messageMeta.threadID,
                                                  threadPosition: messageMeta.threadPosition,
                                                  fromVC: fromVC,
                                                  extraInfo: [:])
                }
            } else {
                self.pushToChatOrReplyInThreadController(chatId: chatId,
                                              toMessagePosition: messageMeta.position,
                                              threadId: messageMeta.threadID,
                                              threadPosition: messageMeta.threadPosition,
                                              fromVC: fromVC,
                                              extraInfo: [:])
            }
        case .messageFile(let fileMeta):
            if let chat = chatAPI.getLocalChat(by: fileMeta.chatID) {
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: fileMeta.threadID,
                                                loadType: .position,
                                                position: fileMeta.threadPosition)
                    navigator.push(body: body, from: fromVC)
                } else {
                    self.pushToChatOrReplyInThreadController(chatId: chatId,
                                                  toMessagePosition: fileMeta.messagePosition,
                                                  threadId: fileMeta.threadID,
                                                  threadPosition: fileMeta.threadPosition,
                                                  fromVC: fromVC,
                                                  extraInfo: [:])
                }
            } else {
                self.pushToChatOrReplyInThreadController(chatId: chatId,
                                              toMessagePosition: fileMeta.messagePosition,
                                              threadId: fileMeta.threadID,
                                              threadPosition: fileMeta.threadPosition,
                                              fromVC: fromVC,
                                              extraInfo: [:])
            }
        case .link(let linkMeta):
            if let chat = chatAPI.getLocalChat(by: linkMeta.chatID) {
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: linkMeta.threadID,
                                                loadType: .position,
                                                position: linkMeta.threadPosition)
                    navigator.push(body: body, from: fromVC)
                } else {
                    self.pushToChatOrReplyInThreadController(chatId: chatId,
                                                  toMessagePosition: linkMeta.position,
                                                  threadId: linkMeta.threadID,
                                                  threadPosition: linkMeta.threadPosition,
                                                  fromVC: fromVC,
                                                  extraInfo: [:])
                }
            } else {
                self.pushToChatOrReplyInThreadController(chatId: chatId,
                                              toMessagePosition: linkMeta.position,
                                              threadId: linkMeta.threadID,
                                              threadPosition: linkMeta.threadPosition,
                                              fromVC: fromVC,
                                              extraInfo: [:])
            }
        case .wiki(let wikiMeta):
            SearchTrackUtil.trackClickChatHistoryResults(type: .wiki, isSearchResult: isSearchingResult, action: .viewInChat)
            if let chat = chatAPI.getLocalChat(by: wikiMeta.docMetaType.chatID) {
                if chat.chatMode == .threadV2 {
                    let body = ThreadDetailByIDBody(threadId: wikiMeta.docMetaType.threadID,
                                                loadType: .position,
                                                position: wikiMeta.docMetaType.threadPosition)
                    navigator.push(body: body, from: fromVC)
                    return
                }
            }
            self.pushToChatOrReplyInThreadController(chatId: self.chatId,
                                          toMessagePosition: wikiMeta.docMetaType.position,
                                          threadId: wikiMeta.docMetaType.threadID,
                                          threadPosition: wikiMeta.docMetaType.threadPosition,
                                          fromVC: fromVC,
                                          extraInfo: ["docUrl": wikiMeta.url])
        default: break
        }
    }

    private func pushToChatOrReplyInThreadController(chatId: String,
                                toMessagePosition: Int32,
                                threadId: String,
                                threadPosition: Int32,
                                fromVC: UIViewController,
                                extraInfo: [String: Any]) {
        /// 如果toMessagePosition == replyInThreadMessagePosition，往chat内跳转的话，无法定位到消息
        /// 需要pushReplyInThreadDetailController
        if toMessagePosition == replyInThreadMessagePosition, !threadId.isEmpty {
            router.pushReplyInThreadDetailController(threadId: threadId,
                                                     threadPosition: threadPosition,
                                                     fromVC: fromVC,
                                                     extraInfo: extraInfo)
        } else {
            router.pushChatViewController(chatId: chatId,
                                          toMessagePosition: toMessagePosition,
                                          fromVC: fromVC,
                                          extraInfo: extraInfo)
        }

    }

    func docMeta() -> SearchMetaDocType? {
        switch data?.meta {
        case .doc(let meta): return meta
        case .wiki(let wiki): return wiki.docMetaType
        default: return nil
        }
    }

    func docSearchClickInfo(docMeta: SearchMetaDocType) -> [String: String] {
        return ["file_id": SearchTrackUtil.encrypt(id: docMeta.id),
                "file_type": docType(type: docMeta.type)]
    }

    private func docType(type: Basic_V1_Doc.TypeEnum) -> String {
        switch type {
        case .unknown:
            return "unknown"
        case .doc:
            return "doc"
        case .sheet:
            return "sheet"
        case .bitable:
            return "bitable"
        case .mindnote:
            return "mindnote"
        case .file:
            return "file"
        case .slide:
            return "slide"
        case .slides:
            return "slides"
        case .docx:
            return "docx"
        case .wiki:
            return "wiki"
        case .folder, .catalog, .shortcut:
            fallthrough // use unknown default setting to fix warning
        @unknown default:
            assert(false, "new value")
            return "unknown"
        }
    }

    func showCustomTag(tagView: TagWrapperView) {
        guard let result = data as? Search.Result else { return }
        var customTags: [Tag] = []
        for tag in result.explanationTags {
            switch tag.tagStyle {
            case .text:
                guard !tag.text.isEmpty, !tag.tagType.isEmpty else {
                    Self.logger.error("textTag's text or type is empty!, tag's text: \(tag.text), tag's type: \(tag.tagType)")
                    continue
                }
                customTags.append(Tag(title: tag.text,
                                      style: SearchResultNameStatusView.getTagColor(withTagType: tag.tagType),
                                  type: .customTitleTag))
            case .crypto:
                customTags.append(Tag(type: .crypto))
            case .shield:
                customTags.append(Tag(type: .isPrivateMode))
            case .helpDesk:
                customTags.append(Tag(type: .oncall))
            case .officialDoc:
                break
            case .unknown:
                Self.logger.error("Tag's style is unknown!, tag's text: \(tag.text), tag's type: \(tag.tagType)")
            @unknown default:
                Self.logger.error("Tag's style is unknown default!, tag's text: \(tag.text), tag's type: \(tag.tagType)")
            }
        }
        tagView.maxTagCount = 4
        tagView.setElements(customTags, autoSort: false)
        tagView.isHidden = customTags.isEmpty
    }
}

private struct FileInfo: FileContentBasicInfo {
    let key: String
    let authToken: String?
    let authFileKey: String
    let size: Int64
    let name: String
    let cacheFilePath: String = ""
    let filePreviewStage: Basic_V1_FilePreviewStage
}
