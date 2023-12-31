//
//  MessageTextToInlineService.swift
//  LarkCore
//
//  Created by 袁平 on 2021/8/2.
//

import UIKit
import Foundation
import RustPB
import Homeric
import LarkModel
import LarkContainer
import AppReciableSDK
import TangramService
import LKCommonsTracker
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkMessengerInterface

public struct ParseTextLinkResult {
    public var attriubuteText: NSMutableAttributedString
    public var urlRangeMap: [NSRange: URL]
    /// 1. 有些字符串服务端认为是链接, 但无法转化成真正 URL
    /// 2. 也包含url转换后的可点击title
    public var textUrlRangeMap: [NSRange: String]

    public init(attriubuteText: NSMutableAttributedString,
                urlRangeMap: [NSRange: URL],
                textUrlRangeMap: [NSRange: String]) {
        self.attriubuteText = attriubuteText
        self.urlRangeMap = urlRangeMap
        self.textUrlRangeMap = textUrlRangeMap
    }
}

public struct ParseDescriptionLinkResult {
    public var attriubuteText: NSMutableAttributedString
    public var urlRangeMap: [NSRange: (URL, InlinePreviewEntity)]
    /// 1. 有些字符串服务端认为是链接, 但无法转化成真正 URL
    /// 2. 也包含url转换后的可点击title
    public var textUrlRangeMap: [NSRange: String]

    public init(attriubuteText: NSMutableAttributedString,
                urlRangeMap: [NSRange: (URL, InlinePreviewEntity)],
                textUrlRangeMap: [NSRange: String]) {
        self.attriubuteText = attriubuteText
        self.urlRangeMap = urlRangeMap
        self.textUrlRangeMap = textUrlRangeMap
    }
}

// https://bytedance.feishu.cn/docs/doccnpSrc2yA2rSuQ8dKvySIWfd
public final class MessageTextToInlineService: NSObject, UserResolverWrapper {
    public let userResolver: UserResolver
    static let logger = Logger.log(MessageTextToInlineService.self, category: "LarkCore.MessageTextToInlineService")
    static let maxRequest = 5
    static let expireTime: TimeInterval = 0.1 // seconds

    public typealias Completion = (_ result: ParseTextLinkResult,
                                   _ sourceID: String,
                                   _ sourceText: String,
                                   _ sourceType: InlineSourceType) -> Void

    private var inlineService: InlineCacheService
    private var completionStore = [String: [Completion]]()
    private var requestBuffer = [String: (sourceText: String, attributes: [NSAttributedString.Key: Any], request: Url_V1_GetUrlPreviewRequest)]()
    private var identifier: String?
    // Inline渲染耗时埋点，比较频繁，每个签名仅上报一次即可
    // 主线程访问，不加锁
    private var trackedKeys: Set<String> = Set()

    public init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        inlineService = try userResolver.resolve(assert: InlineCacheService.self) // swiftlint:disable:this all
    }
    deinit {
        if let identifier = identifier {
            inlineService.unregisterPush(identifier: identifier)
        }
    }

    public func subscribePush(handler: @escaping InlineCacheService.PushHandler) {
        if let identifier = identifier {
            inlineService.unregisterPush(identifier: identifier)
        }
        identifier = inlineService.registerPush(handler: handler)
    }

    /// 替换sourceText中链接为inline，优先使用内存数据，若内存缓存命中，则不再触发SDK拉取；
    /// 若内存缓存未命中，会缓存request（避免同时触发多个请求），100ms或超过5个之后触发拉取。
    /// 为避免加锁，需要在主线程触发。
    ///
    /// - Parameters:
    ///     - completion: 主线程回调
    public func replaceWithInlineTryBuffer(sourceID: String,
                                           sourceText: String,
                                           type: Url_V1_UrlPreviewSourceType,
                                           attributes: [NSAttributedString.Key: Any],
                                           completion: @escaping Completion) {
        // 为了避免加锁，预加载需要在主线程调用
        assert(Thread.isMainThread, "preload must on Main Thread to avoid lock")
        guard containValidURL(text: sourceText) else {
            let result = self.replaceWithInline(text: sourceText,
                                                inline: .init(sourceID: sourceID,
                                                              sourceType: type,
                                                              textMD5: sourceText,
                                                              entries: []),
                                                attributes: attributes)
            completion(result, sourceID, sourceText, .memory)
            return
        }

        let sourceTextMd5 = sourceText.md5()
        var request = Url_V1_GetUrlPreviewRequest()
        request.sourceID = sourceID
        request.sourceTextMd5 = sourceTextMd5
        request.sourceType = type
        if let inline = inlineService.getInlineInMemory(request: request) {
            let result = self.replaceWithInline(text: sourceText, inline: inline, attributes: attributes)
            completion(result, sourceID, sourceText, .memory)
            return
        }

        let storeKey = Self.storeKey(sourceID, sourceTextMd5)
        // 请求已发出，缓存completion，请求回来统一回调
        if var completions = completionStore[storeKey] {
            completions.append(completion)
            completionStore[storeKey] = completions
            return
        } else { // 请求未发出，缓存到requestBuffer，超时或溢出时发出
            completionStore[storeKey] = [completion]
            cacheOrTriggerRequest(sourceText: sourceText, attributes: attributes, request: request)
        }
    }

    /// 替换sourceText中链接为inline，优先使用内存数据，内存缓存命中，则不再触发SDK拉取
    ///
    /// - Parameters:
    ///     - completion: 主线程回调。回调一次或两次
    public func replaceWithInlineTryMemory(sourceID: String,
                                           sourceText: String,
                                           type: Url_V1_UrlPreviewSourceType,
                                           strategy: Basic_V1_SyncDataStrategy,
                                           attributes: [NSAttributedString.Key: Any],
                                           completion: @escaping Completion) {
        guard containValidURL(text: sourceText) else {
            let result = self.replaceWithInline(text: sourceText,
                                                inline: .init(sourceID: sourceID,
                                                              sourceType: type,
                                                              textMD5: sourceText,
                                                              entries: []),
                                                attributes: attributes)
            mainOrAsync { completion(result, sourceID, sourceText, .memory) }
            return
        }
        let sourceTextMd5 = sourceText.md5()
        var request = Url_V1_GetUrlPreviewRequest()
        request.sourceID = sourceID
        request.sourceTextMd5 = sourceTextMd5
        request.sourceType = type

        if let inline = inlineService.getInlineInMemory(request: request) {
            let result = self.replaceWithInline(text: sourceText, inline: inline, attributes: attributes)
            mainOrAsync { completion(result, sourceID, sourceText, .memory) }
            return
        }

        // 触发一次回调
        let attr = NSMutableAttributedString(string: sourceText, attributes: attributes)
        let result = ParseTextLinkResult(attriubuteText: attr, urlRangeMap: [:], textUrlRangeMap: [:])
        mainOrAsync { completion(result, sourceID, sourceText, .memory) }

        Self.logger.info("[URLPreview] replaceWithInlineTryMemory -> \(sourceID) -> \(sourceTextMd5) -> \(sourceText.count)")
        inlineService.getInlinesForceSDK(requests: [request], strategy: strategy) { [weak self] inlines, netCost, _ in
            guard let self = self else { return }
            if let inline = inlines.first(where: { $0.sourceID == sourceID && $0.textMD5 == sourceTextMd5 && $0.sourceType == type }) {
                let result = self.replaceWithInline(text: sourceText, inline: inline, attributes: attributes)
                mainOrAsync { completion(result, sourceID, sourceText, netCost > 0 ? .server : .sdk) }
            }
        }
    }

    public func replaceWithInlineEntity(text: String, inline: InlinePreviewEntries, attributes: [NSAttributedString.Key: Any]) -> ParseDescriptionLinkResult {
        guard !inline.entries.isEmpty else {
            return ParseDescriptionLinkResult(attriubuteText: NSMutableAttributedString(string: text, attributes: attributes),
                                       urlRangeMap: [:],
                                       textUrlRangeMap: [:])
        }
        let inlineVM = MessageInlineViewModel()
        let attr = NSMutableAttributedString()
        var urlRangeMap: [NSRange: (URL, InlinePreviewEntity)] = [:]
        var textUrlRangeMap: [NSRange: String] = [:]
        var inline = inline
        inline.entries.sort(by: { $0.offset < $1.offset })
        var sourceText = text
        var removedLength = 0
        for entry in inline.entries {
            // prefix部分
            if entry.offset > removedLength {
                let prefixLength = entry.offset - removedLength
                if let subStr = sourceText.removeUTF8(from: 0, length: prefixLength) {
                    attr.append(NSAttributedString(string: subStr, attributes: attributes))
                    removedLength = entry.offset
                } else {
                    Self.logger.error("[URLPreview] index not match",
                                      additionalData: ["indexs": "\(inline.entries.map({ $0.offset })) -> \(inline.entries.map({ $0.length }))"])
                    // index不匹配，兜底不替换预览
                    return ParseDescriptionLinkResult(attriubuteText: NSMutableAttributedString(string: text, attributes: attributes),
                                               urlRangeMap: [:],
                                               textUrlRangeMap: [:])
                }
            }
            if let subStr = sourceText.removeUTF8(from: 0, length: entry.length),
               let replaceAttr = inlineVM.getSummerizeAttr(entity: entry.inlineEntity,
                                                           customAttributes: attributes) {
                let href = (entry.inlineEntity.url?.tcURL ?? subStr).trimmingCharacters(in: .whitespacesAndNewlines)
                do {
                    let url = try URL.forceCreateURL(string: href)
                    urlRangeMap[NSRange(location: attr.length, length: replaceAttr.length)] = (url, entry.inlineEntity)
                } catch {
                    textUrlRangeMap[NSRange(location: attr.length, length: replaceAttr.length)] = href
                }
                attr.append(replaceAttr)
                removedLength += entry.length
            } else {
                Self.logger.error("[URLPreview] index not match",
                                  additionalData: ["indexs": "\(inline.entries.map({ $0.offset })) -> \(inline.entries.map({ $0.length }))"])
                // index不匹配，兜底不替换预览
                return ParseDescriptionLinkResult(attriubuteText: NSMutableAttributedString(string: text, attributes: attributes),
                                           urlRangeMap: [:],
                                           textUrlRangeMap: [:])
            }
        }
        // 最后剩下的text
        if !sourceText.isEmpty {
            attr.append(NSAttributedString(string: sourceText, attributes: attributes))
        }
        let result = ParseDescriptionLinkResult(attriubuteText: attr, urlRangeMap: urlRangeMap, textUrlRangeMap: textUrlRangeMap)
        return result
    }

    public func replaceWithInline(text: String, inline: InlinePreviewEntries, attributes: [NSAttributedString.Key: Any]) -> ParseTextLinkResult {
        guard !inline.entries.isEmpty else {
            return ParseTextLinkResult(attriubuteText: NSMutableAttributedString(string: text, attributes: attributes),
                                       urlRangeMap: [:],
                                       textUrlRangeMap: [:])
        }
        let inlineVM = MessageInlineViewModel()
        let attr = NSMutableAttributedString()
        var urlRangeMap: [NSRange: URL] = [:]
        var textUrlRangeMap: [NSRange: String] = [:]
        var inline = inline
        inline.entries.sort(by: { $0.offset < $1.offset })
        var sourceText = text
        var removedLength = 0
        for entry in inline.entries {
            // prefix部分
            if entry.offset > removedLength {
                let prefixLength = entry.offset - removedLength
                if let subStr = sourceText.removeUTF8(from: 0, length: prefixLength) {
                    attr.append(NSAttributedString(string: subStr, attributes: attributes))
                    removedLength = entry.offset
                } else {
                    Self.logger.error("[URLPreview] index not match",
                                      additionalData: ["indexs": "\(inline.entries.map({ $0.offset })) -> \(inline.entries.map({ $0.length }))"])
                    // index不匹配，兜底不替换预览
                    return ParseTextLinkResult(attriubuteText: NSMutableAttributedString(string: text, attributes: attributes),
                                               urlRangeMap: [:],
                                               textUrlRangeMap: [:])
                }
            }
            if let subStr = sourceText.removeUTF8(from: 0, length: entry.length),
               let replaceAttr = inlineVM.getSummerizeAttr(entity: entry.inlineEntity,
                                                           customAttributes: attributes) {
                let href = (entry.inlineEntity.url?.tcURL ?? subStr).trimmingCharacters(in: .whitespacesAndNewlines)
                do {
                    let url = try URL.forceCreateURL(string: href)
                    urlRangeMap[NSRange(location: attr.length, length: replaceAttr.length)] = url
                } catch {
                    textUrlRangeMap[NSRange(location: attr.length, length: replaceAttr.length)] = href
                }
                attr.append(replaceAttr)
                removedLength += entry.length
            } else {
                Self.logger.error("[URLPreview] index not match",
                                  additionalData: ["indexs": "\(inline.entries.map({ $0.offset })) -> \(inline.entries.map({ $0.length }))"])
                // index不匹配，兜底不替换预览
                return ParseTextLinkResult(attriubuteText: NSMutableAttributedString(string: text, attributes: attributes),
                                           urlRangeMap: [:],
                                           textUrlRangeMap: [:])
            }
        }
        // 最后剩下的text
        if !sourceText.isEmpty {
            attr.append(NSAttributedString(string: sourceText, attributes: attributes))
        }
        return ParseTextLinkResult(attriubuteText: attr, urlRangeMap: urlRangeMap, textUrlRangeMap: textUrlRangeMap)
    }

    private func cacheOrTriggerRequest(sourceText: String, attributes: [NSAttributedString.Key: Any], request: Url_V1_GetUrlPreviewRequest) {
        assert(Thread.isMainThread, "cache request must on Main Thread to avoid lock")

        let storeKey = Self.storeKey(request.sourceID, request.sourceTextMd5)
        requestBuffer[storeKey] = (sourceText, attributes, request)
        if requestBuffer.count == 1 { // 第一次缓存，100ms之后触发拉取
            perform(#selector(fetchInlines), with: nil, afterDelay: Self.expireTime)
        } else if requestBuffer.count > Self.maxRequest { // buffer溢出，立即拉取
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchInlines), object: nil)
            fetchInlines()
        }
    }

    @objc
    private func fetchInlines() {
        assert(Thread.isMainThread, "fetchInlines must on Main Thread to avoid lock")

        var buffer = requestBuffer
        requestBuffer.removeAll()
        let values = buffer.values
        let requests = values.map({ $0.request })
        Self.logger.info("[URLPreview] fetchInlines -> \(requests.map({ $0.sourceID })) -> \(requests.map({ $0.sourceTextMd5 })) -> \(values.map({ $0.sourceText.count }))")
        inlineService.getInlinesForceSDK(requests: requests, strategy: .tryLocal) { [weak self] inlines, netCost, _ in
            guard let self = self else { return }
            inlines.forEach { entry in
                let storeKey = Self.storeKey(entry.sourceID, entry.textMD5)
                if let req = buffer.removeValue(forKey: storeKey) {
                    let result = self.replaceWithInline(text: req.sourceText, inline: entry, attributes: req.attributes)
                    mainOrAsync {
                        if let completions = self.completionStore.removeValue(forKey: storeKey) {
                            completions.forEach({ $0(result, req.request.sourceID, req.sourceText, netCost > 0 ? .server : .sdk) })
                        }
                    }
                }
            }
            // 当没有inline时，也需要移除completion
            if !buffer.isEmpty {
                mainOrAsync { buffer.forEach({ self.completionStore.removeValue(forKey: $0.key) }) }
            }
        }
    }

    // 对齐PC，为减少请求，只有text中包含http时才触发请求
    // 目前URL中台只支持待协议头的URL
    private func containValidURL(text: String) -> Bool {
        return text.contains("http")
    }

    private static func storeKey(_ sourceID: String, _ sourceTextMd5: String) -> String {
        return sourceID + "_" + sourceTextMd5
    }
}

extension MessageTextToInlineService: TextToInlineService {
    public func replaceWithInlineTrySDK(sourceID: String,
                                        sourceText: String,
                                        type: Url_V1_UrlPreviewSourceType,
                                        strategy: Basic_V1_SyncDataStrategy,
                                        textColor: UIColor,
                                        linkColor: UIColor,
                                        font: UIFont,
                                        completion: @escaping TextToInlineService.Completion) {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: font,
            MessageInlineViewModel.iconColorKey: linkColor,
            MessageInlineViewModel.tagTypeKey: TagType.link
        ]
        guard containValidURL(text: sourceText) else {
            let result = self.replaceWithInline(text: sourceText,
                                                inline: .init(sourceID: sourceID,
                                                              sourceType: type,
                                                              textMD5: sourceText,
                                                              entries: []),
                                                attributes: attributes)
            completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap, .memory)
            return
        }
        let sourceTextMd5 = sourceText.md5()
        var request = Url_V1_GetUrlPreviewRequest()
        request.sourceID = sourceID
        request.sourceTextMd5 = sourceTextMd5
        request.sourceType = type

        let result: ParseTextLinkResult
        if let inline = inlineService.getInlineInMemory(request: request) {
            result = self.replaceWithInline(text: sourceText, inline: inline, attributes: attributes)
        } else {
            let attr = NSMutableAttributedString(string: sourceText, attributes: attributes)
            result = ParseTextLinkResult(attriubuteText: attr, urlRangeMap: [:], textUrlRangeMap: [:])
        }
        completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap, .memory)

        Self.logger.info("[URLPreview] replaceWithInlineTrySDK -> \(sourceID) -> \(sourceTextMd5) -> \(sourceText.count)")
        inlineService.getInlinesForceSDK(requests: [request], strategy: strategy) { [weak self] inlines, netCost, _ in
            guard let self = self else { return }
            if let inline = inlines.first(where: { $0.sourceID == sourceID && $0.textMD5 == sourceTextMd5 && $0.sourceType == type }) {
                let result = self.replaceWithInline(text: sourceText, inline: inline, attributes: attributes)
                completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap, netCost > 0 ? .server : .sdk)
            }
        }
    }

    public func replaceWithInlineEntityTrySDK(sourceID: String,
                                        sourceText: String,
                                        type: Url_V1_UrlPreviewSourceType,
                                        strategy: Basic_V1_SyncDataStrategy,
                                        textColor: UIColor,
                                        linkColor: UIColor,
                                        font: UIFont,
                                        completion: @escaping TextToInlineService.CompleteHandler) {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: font,
            MessageInlineViewModel.iconColorKey: linkColor,
            MessageInlineViewModel.tagTypeKey: TagType.link
        ]
        guard containValidURL(text: sourceText) else {
            let result = self.replaceWithInlineEntity(text: sourceText,
                                                inline: .init(sourceID: sourceID,
                                                              sourceType: type,
                                                              textMD5: sourceText,
                                                              entries: []),
                                                attributes: attributes)
            mainOrAsync { completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap, .memory) }
            return
        }
        let sourceTextMd5 = sourceText.md5()
        var request = Url_V1_GetUrlPreviewRequest()
        request.sourceID = sourceID
        request.sourceTextMd5 = sourceTextMd5
        request.sourceType = type

        let result: ParseDescriptionLinkResult
        if let inline = inlineService.getInlineInMemory(request: request) {
            result = self.replaceWithInlineEntity(text: sourceText, inline: inline, attributes: attributes)
        } else {
            let attr = NSMutableAttributedString(string: sourceText, attributes: attributes)
            result = ParseDescriptionLinkResult(attriubuteText: attr, urlRangeMap: [:], textUrlRangeMap: [:])
        }
        mainOrAsync { completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap, .memory) }

        Self.logger.info("[URLPreview] replaceWithInlineTrySDK -> \(sourceID) -> \(sourceTextMd5) -> \(sourceText.count)")
        inlineService.getInlinesForceSDK(requests: [request], strategy: strategy) { [weak self] inlines, netCost, _ in
            guard let self = self else { return }
            if let inline = inlines.first(where: { $0.sourceID == sourceID && $0.textMD5 == sourceTextMd5 && $0.sourceType == type }) {
                let result = self.replaceWithInlineEntity(text: sourceText, inline: inline, attributes: attributes)
                mainOrAsync { completion(result.attriubuteText, result.urlRangeMap, result.textUrlRangeMap, netCost > 0 ? .server : .sdk) }
            }
        }
    }

    public func subscribePush(sourceIDHandler: @escaping ([String]) -> Void) {
        subscribePush(handler: { (push: [String: InlinePreviewEntries]) in
            guard !push.isEmpty else { return }
            sourceIDHandler(Array(push.keys))
        })
    }

    public func trackURLParseClick(sourceID: String,
                                   sourceText: String,
                                   type: Url_V1_UrlPreviewSourceType,
                                   originURL: String,
                                   scene: String) {
        let sourceTextMd5 = sourceText.md5()
        var request = Url_V1_GetUrlPreviewRequest()
        request.sourceID = sourceID
        request.sourceTextMd5 = sourceTextMd5
        request.sourceType = type

        var params: [AnyHashable: Any] = ["occasion": scene,
                                          "click": "open_url",
                                          "target": "none"]
        if let inline = inlineService.getInlineInMemory(request: request),
           let entity = inline.entries.first(where: { sourceText.substringOfUTF8(from: $0.offset, length: $0.length) == originURL || $0.inlineEntity.url?.tcURL == originURL }) {
            params["is_succeed_parse"] = "true"
            params["url_id"] = entity.previewID
        } else {
            params["is_succeed_parse"] = "none"
            params["url_id"] = "none"
        }
        var domainPath = originURL
        if let url = URL(string: originURL), let host = url.host {
            domainPath = host.appending(url.path)
        }
        params["url_domain_path"] = domainPath
        Tracker.post(TeaEvent(Homeric.IM_URL_PARSE_CLICK, params: params))
    }

    @discardableResult
    public func trackURLInlineRender(sourceID: String,
                                     sourceText: String,
                                     type: Url_V1_UrlPreviewSourceType,
                                     sourceType: InlineSourceType,
                                     scene: String,
                                     startTime: CFTimeInterval,
                                     endTime: CFTimeInterval,
                                     isFromPush: Bool) -> Bool {
        // 为避免加锁，需要在主线程访问
        assert(Thread.isMainThread, "trackURLInlineRender must on Main Thread to avoid lock")

        // 从内存缓存获取的数据不上报埋点，因为内存缓存耗时很少，而且较频繁，上报意义不大
        guard (isFromPush || sourceType != .memory) && startTime > 0 else { return false }
        let sourceTextMd5 = sourceText.md5()
        let trackKey = "\(sourceID)_\(sourceTextMd5)_\(type.rawValue)"
        guard !trackedKeys.contains(trackKey) else { return true }

        var request = Url_V1_GetUrlPreviewRequest()
        request.sourceID = sourceID
        request.sourceTextMd5 = sourceTextMd5
        request.sourceType = type
        // 此处无法区分是签名未生成，有Inline但未返回的情况，还是签名里无URL，无Inline的情况
        guard let inline = inlineService.getInlineInMemory(request: request), !inline.entries.isEmpty else { return false }
        // 此处才开始上报
        trackedKeys.insert(trackKey)

        let isInBackground = AppReciableSDK.shared.isInBackground(start: startTime, end: endTime)
        let netStatus = AppReciableSDK.shared.getActualNetStatus(start: startTime, end: endTime)
        let cost = Int((endTime - startTime) * 1000)
        inline.entries.forEach { entry in
            if let originURL = sourceText.substringOfUTF8(from: entry.offset, length: entry.length) {
                var domainPath = originURL
                if let url = URL(string: originURL), let host = url.host {
                    domainPath = host.appending(url.path)
                }
                Tracker.post(TeaEvent("url_preview_sign_inline_render_dev", params: [
                    "net_status": netStatus,
                    "app_status": TCPreviewTrackAppStatus(isInBackground: isInBackground).rawValue,
                    "scene": scene,
                    "preview_id": entry.previewID,
                    "url_domain_path": domainPath,
                    "data_source": isFromPush ? InlineSourceType.sdkPush.rawValue : sourceType.rawValue,
                    "inline_render_cost": "\(cost)"
                ]))
            }
        }
        return true
    }
}

private func mainOrAsync(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async { task() }
    }
}

// 应用状态
public enum TCPreviewTrackAppStatus: Int {
    case foreground = 0
    case background = 1

    public init(isInBackground: Bool) {
        self = isInBackground ? .background : .foreground
    }
}
