//
//  URLPreviewChatPinCardListService.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/8/1.
//

import Foundation
import RustPB
import TangramService
import LarkContainer
import LarkCore
import LarkOpenChat
import DynamicURLComponent
import LarkModel
import RxSwift
import RxCocoa

final class URLPreviewChatPinCardListService {

    private let disposeBag = DisposeBag()

    private init(context: ChatPinCardContext) {
        context.pushCenter.observable(for: URLPreviewScenePush.self)
            .subscribe(onNext: { [weak context] push in
                guard let context = context else { return }

                var updatedEntities = [URLPreviewEntity]()
                var dataSourcePreviewIDs: Set<String> = []

                context.update(doUpdate: { payload in
                    guard var previewPayload = payload as? URLPreviewChatPinModel else { return nil }
                    let previewID = previewPayload.hangPoint.previewID
                    dataSourcePreviewIDs.insert(previewID)

                    if let newEntity = push.urlPreviewEntities[previewID] {
                        if let oldEntity = previewPayload.urlPreviewEntity {
                            if newEntity.version >= oldEntity.version {
                                previewPayload.urlPreviewEntity = newEntity
                                updatedEntities.append(newEntity)
                                return previewPayload
                            }
                        } else {
                            previewPayload.urlPreviewEntity = newEntity
                            updatedEntities.append(newEntity)
                            return previewPayload
                        }
                    }
                    return nil
                }, completion: { [weak context] _ in
                    let previewService = try? context?.userResolver.resolve(assert: URLPreviewChatPinService.self)
                    previewService?.handleURLPreviews(entities: updatedEntities)
                    guard push.type == .sdk else { return }
                    let previewIDs = push.needLazyLoadPreviews
                        .filter { $0.appID == URLPreviewChatPinSceneConfig.appID
                            && $0.appSceneType == URLPreviewChatPinSceneConfig.appSceneType
                            && dataSourcePreviewIDs.contains($0.previewID)
                        }
                        .map { return $0.previewID }
                    previewService?.fetchNeedLazyLoadPreviews(previewIds: previewIDs)
                })
            }).disposed(by: self.disposeBag)
    }

    static func setup(context: ChatPinCardContext, chatId: String) {
        let urlPreviewAPI = try? context.userResolver.resolve(assert: URLPreviewAPI.self)

        if (try? context.userResolver.resolve(type: URLPreviewChatPinService.self)) == nil {
            let previewServiceImp = URLPreviewChatPinServiceImp(
                pushCenter: context.pushCenter,
                urlPreviewAPI: urlPreviewAPI,
                chatId: chatId
            )
            context.container.register(URLPreviewChatPinService.self) { _ -> URLPreviewChatPinService in
                return previewServiceImp
            }
        }

        if (try? context.userResolver.resolve(type: URLTemplateChatPinService.self)) == nil {
            let templateServiceImp = URLTemplateChatPinServiceImp(
                chatId: chatId,
                pushCenter: context.pushCenter,
                updateHandler: { [weak context] missingTemplateIDs in
                    guard let context = context else { return }
                    let missingTemplateIDSet = Set(missingTemplateIDs)
                    context.update(doUpdate: { payload in
                        guard let previewBody = (payload as? URLPreviewChatPinModel)?.urlPreviewEntity?.previewBody else { return nil }
                        let needUpdate = previewBody.states.values.contains {
                            return missingTemplateIDSet.contains($0.templateID)
                        }
                        return needUpdate ? payload : nil
                    }, completion: nil)
                },
                urlAPI: urlPreviewAPI
            )
            context.container.register(URLTemplateChatPinService.self) { _ -> URLTemplateChatPinService in
                return templateServiceImp
            }
        }

        if (try? context.userResolver.resolve(type: URLCardService.self)) == nil {
            let userID = context.userID
            context.container.register(URLCardService.self) { _ in
                return URLCardService(userID: userID)
            }.inObjectScope(.container)
        }

        if (try? context.userResolver.resolve(type: URLPreviewChatPinCardListService.self)) == nil {
            let pinCardListServiceImp = URLPreviewChatPinCardListService(context: context)
            context.container.register(URLPreviewChatPinCardListService.self) { _ -> URLPreviewChatPinCardListService in
                return pinCardListServiceImp
            }
        }
    }
}
