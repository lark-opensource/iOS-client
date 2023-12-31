//
//  URLPreviewChatPinService.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/1.
//

import Foundation
import RustPB
import TangramService
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkOpenChat
import LarkSDKInterface
import LarkModel
import RxSwift
import RxCocoa
import LarkContainer

protocol URLPreviewChatPinModel: ChatPinPayload {
    var hangPoint: RustPB.Basic_V1_PreviewHangPoint { get }
    var urlPreviewEntity: URLPreviewEntity? { get set }
}

protocol URLPreviewChatPinService {
    func fetchNeedLazyLoadPreviews(previewIds: [String])
    func fetchMissingURLPreviews(models: [URLPreviewChatPinModel])
    func handleURLPreviews(entities: [URLPreviewEntity])
}

final class URLPreviewChatPinServiceImp: NSObject, URLPreviewChatPinService {
    private static let expireTime: TimeInterval = 0.3 // 0.3s后触发拉取
    private static let logger = Logger.log(URLPreviewChatPinServiceImp.self, category: "Module.IM.ChatPin")

    private var urlPreviewAPI: URLPreviewAPI?
    private let pushCenter: PushNotificationCenter
    private let disposeBag = DisposeBag()

    /// previewIDs
    private let requestBuffer = Set<String>() + .readWriteLock
    private var requestDelayed: Bool = false
    private let chatId: String

    init(pushCenter: PushNotificationCenter, urlPreviewAPI: URLPreviewAPI?, chatId: String) {
        self.pushCenter = pushCenter
        self.chatId = chatId
        self.urlPreviewAPI = urlPreviewAPI
    }

    /// 收到URL中台预览推送时，需要主动拉取懒加载的预览
    func fetchNeedLazyLoadPreviews(previewIds: [String]) {
        guard !previewIds.isEmpty else { return }
        Self.logger.info("chatPinCardTrace previewService \(self.chatId) fetchNeedLazyLoadPreviews \(previewIds)")
        requestBuffer.safeWrite { cache in
            cache.formUnion(Set(previewIds))
        }
        fetchURLPreviewsAfterDelayed()
    }

    /// 对缺失的entity && templates进行拉取
    func fetchMissingURLPreviews(models: [URLPreviewChatPinModel]) {
        guard !models.isEmpty else { return }
        let entities: [URLPreviewEntity] = models.compactMap { return $0.urlPreviewEntity }
        fetchLazyLoadURLPreviews(models: models, entities: entities)
        handleURLPreviews(entities: entities)
    }

    func handleURLPreviews(entities: [URLPreviewEntity]) {
        guard !entities.isEmpty else { return }
        var missingTemplateIDs: Set<String> = []
        entities.forEach { entity in
            missingTemplateIDs.formUnion(Set(entity.previewBody?.states.values.map({ $0.templateID }) ?? []))
        }
        Self.logger.info("chatPinCardTrace previewService \(self.chatId) handle missingTemplateIDs \(Array(missingTemplateIDs))")
        let push = URLPreviewTemplatePush(missingTemplateIDs: [self.chatId: missingTemplateIDs], sourceType: .pinCard)
        pushCenter.post(push)
    }

    private func fetchLazyLoadURLPreviews(models: [URLPreviewChatPinModel], entities: [URLPreviewEntity]) {
        let needReloadRequest = getNeedReloadRequest(entities: entities)
        let lazyLoadRequest = getLazyLoadRequest(models: models, entities: entities)
        guard !needReloadRequest.isEmpty || !lazyLoadRequest.isEmpty else { return }
        requestBuffer.safeWrite { cache in
            cache.formUnion(needReloadRequest)
            cache.formUnion(lazyLoadRequest)
        }
        fetchURLPreviewsAfterDelayed()
    }

    private func getNeedReloadRequest(entities: [URLPreviewEntity]) -> Set<String> {
        let previewIDs = Set(entities.filter({ $0.needReload }).map { $0.previewID })
        if !previewIDs.isEmpty {
            Self.logger.info("chatPinCardTrace previewService \(self.chatId) needReload previewIDs: \(previewIDs)")
        }
        return previewIDs
    }

    /// SDK未返回预览：HangPoint中isLazyLoad = true的需要主动拉取
    private func getLazyLoadRequest(models: [URLPreviewChatPinModel], entities: [URLPreviewEntity]) -> Set<String> {
        let existPreviewIDs = Set(entities.map({ $0.previewID }))
        var previewIDs: Set<String> = []
        models.forEach { model in
            let hangPoint = model.hangPoint
            if hangPoint.isLazyLoad, !existPreviewIDs.contains(hangPoint.previewID) {
                previewIDs.insert(hangPoint.previewID)
            }
        }
        if !previewIDs.isEmpty {
            Self.logger.info("chatPinCardTrace previewService \(self.chatId) lazyLoad previewIDs: \(previewIDs)")
        }
        return previewIDs
    }

    private func fetchURLPreviewsAfterDelayed() {
        mainOrAsync { [weak self] in
            guard let self = self else { return }
            if !self.requestDelayed {
                self.requestDelayed = true
                self.perform(#selector(self.fetchURLPreviews), with: nil, afterDelay: Self.expireTime)
            }
        }
    }
    private func mainOrAsync(task: @escaping () -> Void) {
        if Thread.isMainThread {
            task()
        } else {
            DispatchQueue.main.async { task() }
        }
    }

    @objc
    private func fetchURLPreviews() {
        requestDelayed = false
        var buffer: Set<String> = []
        requestBuffer.safeWrite { cache in
            // 保证read和remove原子
            buffer = cache
            cache.removeAll()
        }
        guard !buffer.isEmpty else { return }
        Self.logger.info("chatPinCardTrace previewService \(self.chatId) fetch lazy load previews start: \(buffer)")
        urlPreviewAPI?.getPreview(previewIDs: Array(buffer), syncDataStrategy: .forceServer)
            .subscribe(onNext: { [weak self] inlinePreviewEntities, urlPreviewEntities in
                guard let self = self else { return }
                let push = URLPreviewScenePush(
                    type: .client,
                    inlinePreviewEntities: inlinePreviewEntities,
                    urlPreviewEntities: urlPreviewEntities,
                    needLazyLoadPreviews: []
                )
                self.pushCenter.post(push)
            }).disposed(by: disposeBag)
    }
}
