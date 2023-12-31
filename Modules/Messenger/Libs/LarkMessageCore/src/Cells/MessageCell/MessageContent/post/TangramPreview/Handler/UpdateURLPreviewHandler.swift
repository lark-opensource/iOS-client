//
//  UpdateURLPreviewHandler.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/5/18.
//

import RustPB
import RxSwift
import LarkCore
import LarkModel
import Foundation
import LarkContainer
import TangramService
import LKCommonsLogging
import LarkSDKInterface

final class UpdateURLPreviewHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return UpdateURLPreviewHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

// Inline + Card更新：为了避免Inline和Card引起多次Cell更新，将两个合并
final class UpdateURLPreviewHandler: PushHandler {
    static let logger = Logger.log(UpdateURLPreviewHandler.self, category: "LarkMessageCore.UpdateURLPreviewHandler")

    let disposeBag: DisposeBag = DisposeBag()
    let inlinePreviewVM: MessageInlineViewModel = MessageInlineViewModel()
    @ScopedInjectedLazy var urlPreviewService: MessageURLPreviewService?

    override func startObserve() throws {
        try self.userResolver.userPushCenter.observable(for: URLPreviewPush.self).subscribe(onNext: { [weak self] push in
            guard !push.inlinePreviewEntityPair.inlinePreviewEntities.isEmpty ||
                    !push.urlPreviewEntityPair.urlPreviewEntities.isEmpty ||
                    !push.needLoadIDs.isEmpty ||
                    !push.messageLinks.isEmpty else { return }
            self?.perform { [weak self] in
                let urlPreviewEntities = push.urlPreviewEntityPair.urlPreviewEntities
                let inlinePreviewEntityPair = push.inlinePreviewEntityPair
                var messageLinks: [String: MessageLink] = [:]
                push.messageLinks.forEach { (previewID, messageLink) in
                    messageLinks[previewID] = MessageLink.transform(previewID: previewID, messageLink: messageLink)
                }
                var updatedSourceIDs = [String]()
                var updatedEntities = [URLPreviewEntity]()

                self?.dataSourceAPI?.update(
                    original: { [weak self] data in
                        let message = data.message
                        guard let self = self,
                              (message.type == .mergeForward || // 合并转发消息需要递归更新内层
                               !message.urlPreviewHangPointMap.isEmpty ||
                               !(message.parentMessage?.urlPreviewHangPointMap.isEmpty ?? true)) // 回复消息也要刷新
                        else { return nil }
                        var urlPreviewNeedUpdate = false
                        var inlineNeedUpdate = false
                        // 回复消息的Inline是否更新
                        var replyInlineNeedUpdate = false
                        let body = urlPreviewEntities[message.id] ?? [:]
                        // 只更新需要展示的
                        let newEntities = body.filter({ message.orderedPreviewIDs.contains($0.key) })
                        if !newEntities.isEmpty {
                            message.urlPreviewEntities += newEntities
                            urlPreviewNeedUpdate = true
                            updatedEntities.append(contentsOf: message.urlPreviewEntities.values)
                        }
                        // 更新MessageLink
                        var newMessageLinks = [String: MessageLink]()
                        message.urlPreviewHangPointMap.values.forEach { hangPoint in
                            newMessageLinks[hangPoint.previewID] = messageLinks[hangPoint.previewID]
                        }
                        if !newMessageLinks.isEmpty {
                            urlPreviewNeedUpdate = true
                            message.messageLinks += newMessageLinks
                        }
                        if let body = self.inlinePreviewVM.getInlinePreviewBody(message: message, pair: inlinePreviewEntityPair), !body.isEmpty {
                            inlineNeedUpdate = self.inlinePreviewVM.update(message: message, body: body)
                        }
                        if let parentMessage = message.parentMessage,
                           let inlines = inlinePreviewEntityPair.inlinePreviewEntities[parentMessage.id],
                           !inlines.isEmpty,
                           self.inlinePreviewVM.update(message: parentMessage, body: inlines) {
                            replyInlineNeedUpdate = true
                            updatedSourceIDs.append(parentMessage.id)
                        }
                        // 当SDK本地没有缓存时（urlPreviewEntities为空），可能只会推needLoadIDs的值到客户端
                        // 当前使用到了的需要重新拉取的ID
                        let needLoadIDs = self.inlinePreviewVM.getNeedLoadIDs(message: message, needLoadIDs: push.needLoadIDs)
                        updatedSourceIDs.append(contentsOf: needLoadIDs)
                        if urlPreviewNeedUpdate || inlineNeedUpdate {
                            updatedSourceIDs.append(message.id)
                        }
                        return (urlPreviewNeedUpdate || inlineNeedUpdate || replyInlineNeedUpdate) ? data : nil
                    },
                    completion: { [weak self] _ in
                        self?.urlPreviewService?.handleURLPreviews(entities: updatedEntities)
                        // 只有SDK推送的数据才需要判断是否重新拉取；当updatedSourceIDs为空，表示当前没有使用到
                        // 有时候长文类预览后端生成比较慢，forceServer拉取时可能拉不到，后续后端会给Push，重新触发拉取（needLoadIDs标识）
                        guard push.type == .sdk, !updatedSourceIDs.isEmpty, !push.needLoadIDs.isEmpty else { return }
                        var needLoadIDs = [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]()
                        updatedSourceIDs.forEach { needLoadIDs[$0] = push.needLoadIDs[$0] }
                        self?.urlPreviewService?.fetchNeedReloadURLPreviews(needLoadIDs: needLoadIDs)
                    }
                )
            }
        }).disposed(by: disposeBag)
    }
}
