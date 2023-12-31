//
//  MessageURLPreviewServiceImp.swift
//  LarkSDK
//
//  Created by 袁平 on 2022/2/9.
//

import Foundation
import RustPB
import RxSwift
import LarkCore
import LarkModel
import LarkContainer
import TangramService
import LarkSDKInterface
import LKCommonsLogging
import ThreadSafeDataStructure

final class MessageURLPreviewServiceImp: NSObject, MessageURLPreviewService {
    static let expireTime: TimeInterval = 0.3 // 0.3s后触发拉取
    static let logger = Logger.log(MessageURLPreviewServiceImp.self, category: "MessageURLPreviewServiceImp")

    private let urlPreviewAPI: URLPreviewAPI
    private let pushCenter: PushNotificationCenter
    private let disposeBag = DisposeBag()

    // sourceID: previewIDs
    private let requestBuffer = [String: Set<String>]() + .readWriteLock
    private var requestDelayed: Bool = false

    init(urlPreviewAPI: URLPreviewAPI, pushCenter: PushNotificationCenter) {
        self.urlPreviewAPI = urlPreviewAPI
        self.pushCenter = pushCenter
    }

    /// pullMessage & pushMessage时：对缺失的entity & templates进行拉取
    func fetchMissingURLPreviews(messages: [Message]) {
        guard !messages.isEmpty else { return }
        fetchLazyLoadURLPreviews(messages: messages)
        let entities = messages.flatMap({ $0.urlPreviewEntities.values })
        handleURLPreviews(entities: entities)
    }

    // Push到的Entity需要处理缺失的template
    func handleURLPreviews(entities: [URLPreviewEntity]) {
        guard !entities.isEmpty else { return }
        let missingTemplateIDs = entities.reduce([String: Set<String>]()) { result, entity in
            let templateIDs = entity.previewBody?.states.values.map({ $0.templateID }) ?? []
            guard !templateIDs.isEmpty else { return result }
            var result = result
            var tmpIDs = result[entity.sourceID] ?? Set()
            tmpIDs.formUnion(templateIDs)
            result[entity.sourceID] = tmpIDs
            return result
        }
        let push = URLPreviewTemplatePush(missingTemplateIDs: missingTemplateIDs, sourceType: .message)
        pushCenter.post(push)
    }

    /// 处理从Message接口同步返回的预览数据
    func handleURLTemplates(templates: [String: Basic_V1_URLPreviewTemplate]) {
        guard !templates.isEmpty else { return }
        let push = URLPreviewTemplatePush(templates: templates, missingTemplateIDs: [:], sourceType: .message)
        self.pushCenter.post(push)
    }

    @objc
    private func fetchURLPreviews() {
        requestDelayed = false
        var buffer: [String: Set<String>] = [:]
        requestBuffer.safeWrite { cache in
            // 保证read和remove原子
            buffer = cache
            cache.removeAll()
        }
        guard !buffer.isEmpty else { return }
        Self.logger.info("[URLPreview] fetch lazy load previews start: \(buffer)")
        var requests = [String: Im_V1_GetMessagePreviewsRequest.PreviewPair]()
        buffer.forEach { sourceID, previewIDs in
            var pair = Im_V1_GetMessagePreviewsRequest.PreviewPair()
            pair.previewIds = Array(previewIDs)
            requests[sourceID] = pair
        }
        urlPreviewAPI.getMessagePreviews(messagePreviewMap: requests, syncDataStrategy: .forceServer)
            .subscribe(onNext: { [weak self] inlineEntityPair, urlPreviewEntityPair, messageLinks in
                guard let self = self else { return }
                let push = URLPreviewPush(type: .client,
                                          inlinePreviewEntityPair: inlineEntityPair,
                                          urlPreviewEntityPair: urlPreviewEntityPair,
                                          messageLinks: messageLinks,
                                          needLoadIDs: [:])
                self.pushCenter.post(push)
            }).disposed(by: disposeBag)
    }
}

// MARK: - 懒加载
/// 消息中的URL预览超大群下支持懒加载
/// https://bytedance.feishu.cn/wiki/wikcnkdLT65cfgdlYCwpZEWvMPc
extension MessageURLPreviewServiceImp {
    /// 收到URL中台预览推送时，需要主动拉取懒加载的预览
    func fetchNeedReloadURLPreviews(needLoadIDs: [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]) {
        guard !needLoadIDs.isEmpty else { return }
        let needReloadRequest: [String: Set<String>] = needLoadIDs.compactMapValues { pair in
            let previewIDs = pair.previewIds
            return previewIDs.isEmpty ? nil : Set(previewIDs)
        }
        guard !needReloadRequest.isEmpty else { return }
        requestBuffer.safeWrite { cache in
            cache += needReloadRequest
        }
        fetchURLPreviewsAfterDelayed()
    }

    /// pullMessage & pushMessage时
    /// 1. 若SDK返回预览，需要主动拉取needReload = true的预览
    /// 2. 若SDK未返回预览，需要主动拉取isLazyLoad = true的预览
    private func fetchLazyLoadURLPreviews(messages: [Message]) {
        let inlines = getInlinePreviewBody(messages: messages)
        let needReloadRequest = getNeedReloadRequest(inlines: inlines)
        let lazyLoadRequest = getLazyLoadRequest(messages: messages, inlines: inlines)
        guard !needReloadRequest.isEmpty || !lazyLoadRequest.isEmpty else { return }
        requestBuffer.safeWrite { cache in
            cache += needReloadRequest
            cache += lazyLoadRequest
        }
        fetchURLPreviewsAfterDelayed()
    }

    // Inline中needReload = true的需要主动拉取
    private func getNeedReloadRequest(inlines: InlinePreviewEntityBody) -> [String: Set<String>] {
        let inlines = Array(inlines.values)
        let needReloadInlines = inlines.filter({ $0.needReload })
        var requests = [String: Set<String>]()
        needReloadInlines.forEach { inline in
            let sourceID = inline.sourceID
            var previewIDs = requests[sourceID] ?? Set()
            previewIDs.insert(inline.previewID)
            requests[sourceID] = previewIDs
        }
        if !requests.isEmpty { Self.logger.info("[URLPreview] needReload request: \(requests)") }
        return requests
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

    private func getInlinePreviewBody(messages: [Message]) -> InlinePreviewEntityBody {
        var inlines = InlinePreviewEntityBody()
        messages.forEach { inlines += MessageInlineViewModel.getInlinePreviewBody(message: $0) }
        return inlines
    }

    // SDK未返回预览：HangPoint中isLazyLoad = true的需要主动拉取
    private func getLazyLoadRequest(messages: [Message], inlines: InlinePreviewEntityBody) -> [String: Set<String>] {
        var requests = [String: Set<String>]()
        messages.forEach { message in
            message.urlPreviewHangPointMap.forEach { _, hangPoint in
                if hangPoint.isLazyLoad, inlines[hangPoint.previewID] == nil {
                    var previewIDs = requests[message.id] ?? Set()
                    previewIDs.insert(hangPoint.previewID)
                    requests[message.id] = previewIDs
                }
            }
            if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
                requests += getLazyLoadRequest(messages: content.messages, inlines: inlines)
            }
        }
        if !requests.isEmpty { Self.logger.info("[URLPreview] lazyLoad request: \(requests)") }
        return requests
    }
}

private func mainOrAsync(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async { task() }
    }
}

private func +=<Element: Hashable>(_ left: inout [String: Set<Element>], _ right: [String: Set<Element>]) {
    right.forEach { key, value in
        var temp = left[key] ?? Set()
        temp = temp.union(value)
        left[key] = temp
    }
}
