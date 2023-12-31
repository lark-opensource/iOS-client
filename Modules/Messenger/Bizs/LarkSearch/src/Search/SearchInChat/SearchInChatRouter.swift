//
//  SearchInChatRouter.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/24.
//

import Foundation
import UIKit
import LarkContainer
import RxSwift
import LarkModel
import LarkCore
import Swinject
import EENavigator
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import UniverseDesignToast
import LarkKASDKAssemble
import RustPB
import LKCommonsTracker
import LarkSearchCore

protocol SearchInChatRouter: AnyObject {
    func pushFolderManagementViewController(messageId: String, firstLevelInformation: FolderFirstLevelInformation?, fromVC: UIViewController)
    func pushChatViewController(chatId: String, toMessagePosition: Int32, fromVC: UIViewController, extraInfo: [String: Any])
    func pushReplyInThreadDetailController(threadId: String,
                                           threadPosition: Int32,
                                           fromVC: UIViewController,
                                           extraInfo: [String: Any])
    func pushThreadDetailViewController(threadId: String, fromVC: UIViewController)
    func pushDocViewController(chatId: String, docUrl: String, fromVC: UIViewController)
    func pushFileBrowserViewController(chatId: String,
                                       messageId: String,
                                       fileInfo: FileContentBasicInfo?,
                                       isInnerFile: Bool,
                                       fromVC: UIViewController,
                                       operationEvent: @escaping (FileOperationEvent) -> Void)

    func assetBrowserViewController(
       assets: [SearchAssetInfo],
       currentAsset: Asset,
       chat: Chat,
       messageId: String,
       position: Int32,
       fromVC: UIViewController
    )

    func assetBrowserViewControllerForThread(
        assets: [SearchAssetInfo],
        currentAsset: Asset,
        chat: Chat,
        messageId: String,
        threadID: String,
        position: Int32,
        fromVC: UIViewController
    )

    func goToFileBrowserForOriginVideo(
        messageId: String,
        fromVC: UIViewController
    )
}

final class SearchInChatRouterImpl: SearchInChatRouter, UserResolverWrapper {

    private let disposeBag: DisposeBag = DisposeBag()
    static let logger = Logger.log(SearchInChatRouterImpl.self, category: "SearchInChatRouterImpl")

    @ScopedInjectedLazy private var fileDependency: DriveSDKFileDependency?

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func pushFolderManagementViewController(messageId: String, firstLevelInformation: FolderFirstLevelInformation?, fromVC: UIViewController) {
        SearchInChatRouterImpl.logger.info("SearchInChat pushFolderManagementVC \(messageId)")
        messageAPI?.fetchMessage(id: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard message.type == .folder, let folderContent = message.content as? FolderContent else { return }
                // 局域网文件夹不支持在移动端打开
                if folderContent.fileSource == .lanTrans {
                    UDToast.showTips(with: BundleI18n.LarkSearch.Lark_Message_file_lan_searchsendreceived, on: fromVC.view)
                    return
                }
                let body = FolderManagementBody(messageId: messageId, scene: .search, firstLevelInformation: firstLevelInformation)
                var params = NaviParams()
                params.forcePush = true
                self?.navigator.push(body: body, naviParams: params, from: fromVC)
            }).disposed(by: disposeBag)
    }

    func pushReplyInThreadDetailController(threadId: String,
                                           threadPosition: Int32,
                                           fromVC: UIViewController,
                                           extraInfo: [String: Any]) {
        SearchInChatRouterImpl.logger.info("SearchInChat pushReplyInThreadVC threadId \(threadId) threadPosition \(threadPosition)")
        if !threadId.isEmpty {
            let body = ReplyInThreadByIDBody(threadId: threadId,
                                             loadType: .position,
                                             position: threadPosition,
                                             sourceType: .search)
            navigator.push(body: body, from: fromVC)
        }
    }

    func pushChatViewController(chatId: String, toMessagePosition: Int32, fromVC: UIViewController, extraInfo: [String: Any]) {
        SearchInChatRouterImpl.logger.info("SearchInChat pushChatVC \(chatId) \(toMessagePosition)")
        let body = ChatControllerByIdBody(
            chatId: chatId,
            position: toMessagePosition,
            fromWhere: .search
        )
        /// 反复搜索容易造成导航栈溢出
        var params = NaviParams()
        params.forcePush = true
        navigator.push(body: body, naviParams: params, from: fromVC)
    }

    func pushThreadDetailViewController(threadId: String, fromVC: UIViewController) {
        SearchInChatRouterImpl.logger.info("SearchInChat pushThreadId \(threadId)")
        let body = ThreadDetailByIDBody(
            threadId: threadId,
            loadType: .root
        )
        navigator.push(body: body, from: fromVC)
    }

    func pushDocViewController(chatId: String, docUrl: String, fromVC: UIViewController) {
        guard let url = URL(string: docUrl) else {
            SearchRouter.log.error("传递的docUrl不对")
            return
        }
        navigator.push(url, context: [
            "infos": ["feed_id": chatId],
            "from": "group_tab_record_docs"
        ], from: fromVC)
    }

    @ScopedInjectedLazy var messageAPI: MessageAPI?
    func pushFileBrowserViewController(chatId: String,
                                       messageId: String,
                                       fileInfo: FileContentBasicInfo?,
                                       isInnerFile: Bool,
                                       fromVC: UIViewController,
                                       operationEvent: @escaping (FileOperationEvent) -> Void) {
        messageAPI?.fetchMessage(id: messageId).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC] (message) in
                guard let `self` = self, let fromVC = fromVC else { return }
                /// 局域网文件不支持在移动端打开
                if message.type == .file, let fileContent = message.content as? FileContent,
                   fileContent.fileSource == .lanTrans {
                    UDToast.showTips(with: BundleI18n.LarkSearch.Lark_Message_file_lan_searchsendreceived, on: fromVC.view)
                    return
                }
                /// 这里可能是子文件，需要判断下上层文件夹
                if message.type == .folder, let folderContent = message.content as? FolderContent,
                   folderContent.fileSource == .lanTrans {
                    UDToast.showTips(with: BundleI18n.LarkSearch.Lark_Message_file_lan_searchsendreceived, on: fromVC.view)
                    return
                }
                let body = MessageFileBrowseBody(messageId: messageId, fileInfo: fileInfo, isInnerFile: isInnerFile, scene: .search, operationEvent: operationEvent)
                self.navigator.push(body: body, from: fromVC)
            }).disposed(by: disposeBag)
    }

    func assetBrowserViewController(
        assets: [SearchAssetInfo],
        currentAsset: Asset,
        chat: Chat,
        messageId: String,
        position: Int32,
        fromVC: UIViewController
    ) {
        let scene = PreviewImagesScene.searchInChat(chatId: chat.id,
                                                    messageId: messageId,
                                                    position: position,
                                                    assetInfos: assets,
                                                    currentAsset: currentAsset)
        let canTranslate = SearchFeatureGatingKey.translateImageInOtherView.isUserEnabled(userResolver: userResolver)
        let body = PreviewImagesBody(assets: [currentAsset],
                                     pageIndex: 0,
                                     scene: scene,
                                     trackInfo: PreviewImageTrackInfo(scene: .Search, messageID: messageId),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     showImageOnly: false,
                                     canTranslate: canTranslate,
                                     translateEntityContext: (messageId, .other),
                                     canImageOCR: !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
                                     buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        navigator.present(body: body, from: fromVC)
    }

    func assetBrowserViewControllerForThread(
        assets: [SearchAssetInfo],
        currentAsset: Asset,
        chat: Chat,
        messageId: String,
        threadID: String,
        position: Int32,
        fromVC: UIViewController
    ) {
        let scene = PreviewImagesScene.searchInThread(
            chatId: chat.id,
            messageID: messageId,
            threadID: threadID,
            position: position,
            assetInfos: assets,
            currentAsset: currentAsset)
        let canTranslate = SearchFeatureGatingKey.translateImageInOtherView.isUserEnabled(userResolver: userResolver)
        let body = PreviewImagesBody(assets: [currentAsset],
                                     pageIndex: 0,
                                     scene: scene,
                                     trackInfo: PreviewImageTrackInfo(scene: .Search, messageID: messageId),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     showImageOnly: false,
                                     canTranslate: canTranslate,
                                     translateEntityContext: (messageId, .other),
                                     canImageOCR: !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
                                     buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        navigator.present(body: body, from: fromVC)
    }

    func goToFileBrowserForOriginVideo(
        messageId: String,
        fromVC: UIViewController
    ) {
        var startTime = CACurrentMediaTime()
        messageAPI?.fetchMessage(id: messageId).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (message) in
                guard let `self` = self else { return }
                let fileMessage = message.transformToFileMessageIfNeeded()
                self.fileDependency?.openSDKPreview(
                    message: fileMessage,
                    chat: nil,
                    fileInfo: nil,
                    from: fromVC,
                    supportForward: true,
                    canSaveToDrive: true,
                    browseFromWhere: .file(extra: [:])
                )
                Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                    "result": 1,
                    "cost_time": (CACurrentMediaTime() - startTime) * 1000
                ]))
            }, onError: { error in
                Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                    "result": 0,
                    "cost_time": (CACurrentMediaTime() - startTime) * 1000,
                    "errorMsg": "\(error)"
                ]))
            }).disposed(by: disposeBag)
    }
}
