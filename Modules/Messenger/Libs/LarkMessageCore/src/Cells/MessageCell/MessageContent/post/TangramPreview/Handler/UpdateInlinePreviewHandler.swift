//
//  UpdateInlinePreviewHandler.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/6/10.
//

import Foundation
import RustPB
import LarkCore
import LarkModel
import LarkContainer
import TangramService
import LKCommonsTracker
import LarkSDKInterface
import RxSwift

final class UpdateInlinePreviewHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return UpdateInlinePreviewHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

// Inline更新：有的业务方只接入了Inline
final class UpdateInlinePreviewHandler: PushHandler {
    let inlinePreviewVM: MessageInlineViewModel
    @ScopedInjectedLazy var urlPreviewService: MessageURLPreviewService?
    let disposeBag: DisposeBag = DisposeBag()

    override init(needCachePush: Bool, userResolver: UserResolver) {
        inlinePreviewVM = MessageInlineViewModel()
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve() throws {
        inlinePreviewVM.subscribePush { [weak self] push in
            self?.perform { [weak self] in
                let pair = push.inlinePreviewEntityPair
                var updatedSourceIDs = [String]()
                self?.dataSourceAPI?.update(
                    original: { [weak self] data in
                        let message = data.message
                        // 合并转发消息需要递归更新内层
                        guard let self = self, (message.type == .mergeForward || !message.urlPreviewHangPointMap.isEmpty) else { return nil }
                        // 当前使用到了的需要重新拉取的ID
                        let needLoadIDs = self.inlinePreviewVM.getNeedLoadIDs(message: message, needLoadIDs: push.needLoadIDs)
                        updatedSourceIDs.append(contentsOf: needLoadIDs)
                        if let body = self.inlinePreviewVM.getInlinePreviewBody(message: message, pair: pair),
                           !body.isEmpty,
                           self.inlinePreviewVM.update(message: message, body: body) {
                            updatedSourceIDs.append(message.id)
                            return data
                        }
                        return nil
                    },
                    completion: { [weak self] _ in
                        // 只有SDK推送的数据才需要判断是否重新拉取；当updatedSourceIDs为空，表示当前没有使用到
                        // 有时候长文类预览后端生成比较慢，forceServer拉取时可能拉不到，后续后端会给Push，重新触发拉取（needLoadIDs标识）
                        guard push.type == .sdk, !updatedSourceIDs.isEmpty, !push.needLoadIDs.isEmpty else { return }
                        var needLoadIDs = [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]()
                        updatedSourceIDs.forEach { needLoadIDs[$0] = push.needLoadIDs[$0] }
                        self?.urlPreviewService?.fetchNeedReloadURLPreviews(needLoadIDs: needLoadIDs)
                    }
                )
            }
        }

        try self.userResolver.userPushCenter
            .observable(for: URLPreviewScenePush.self)
            .subscribe(onNext: { [weak self] (push) in
                self?.perform { [weak self] in
                    self?.dataSourceAPI?.update(
                        original: { data in
                            let message = data.message
                            if let aiPreviewID = message.thread?.aiChatModeURLPreviewHangPoint.previewID {
                                let inlinePreviewEntities = push.inlinePreviewEntities.filter({
                                    return $0.key == aiPreviewID
                                })
                                if !inlinePreviewEntities.isEmpty {
                                    message.aiChatModeInlinePreviewEntities += inlinePreviewEntities
                                    return data
                                }
                            }
                            return nil
                        }
                    )
                }
            }).disposed(by: self.disposeBag)
    }
}
