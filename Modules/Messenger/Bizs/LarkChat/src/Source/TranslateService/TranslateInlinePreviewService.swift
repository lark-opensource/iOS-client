//
//  TranslateInlinePreviewService.swift
//  LarkChat
//
//  Created by 袁平 on 2022/3/9.
//

import Foundation
import RustPB
import RxSwift
import LarkModel
import TangramService
import LarkSDKInterface
import LKCommonsLogging
import LarkMessageCore
import LarkMessengerInterface
import ThreadSafeDataStructure

private typealias WaitInlineInfo = (key: String, translateLanguage: String, inline: InlinePreviewEntity)
private typealias OriginInlineInfo = (translateLanguage: String, inline: InlinePreviewEntity)

/// 负责合并Inline更新时的翻译请求
final class TranslateInlinePreviewService: NSObject {
    static let logger = Logger.log(TranslateInlinePreviewService.self, category: "TranslateInlinePreviewService")

    // 需要保证translatedInlines values操作的原子性，需要自己加锁
    private var rwLock = pthread_rwlock_t()
    // previewID + version + translateLanguage作为InlinePreviewEntity的Key
    // title/tag/translateLanguage变更时，缓存需要失效
    private var translatedInlines = [String: [String: InlinePreviewEntity]]()
    // key: previewID; value: (key, translateLanguage, InlinePreviewEntity)
    // 主线程操作，不用加锁
    private var waitInlines: [String: WaitInlineInfo] = [:]

    private let disposeBag = DisposeBag()
    private let dependency: TranslateServiceDependency

    init(dependency: TranslateServiceDependency) {
        self.dependency = dependency
        super.init()
        pthread_rwlock_init(&self.rwLock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwLock)
    }

    private func safeWrite(_ action: () -> Void) {
        pthread_rwlock_wrlock(&rwLock)
        defer { pthread_rwlock_unlock(&rwLock) }
        action()
    }

    private func safeRead<T>(_ action: () -> T) -> T {
        pthread_rwlock_rdlock(&rwLock)
        defer { pthread_rwlock_unlock(&rwLock) }
        return action()
    }

    func resetTranslatedInlines(key: String) {
        safeWrite {
            self.translatedInlines.removeValue(forKey: key)
        }
    }

    func getTranslatedInline(translateParam: MessageTranslateParameter) -> InlinePreviewEntityBody {
        let message = translateParam.message
        // 原文inlines
        let inlines = getLanguageAndInlines(message: message)
        guard !inlines.isEmpty else { return [:] }

        // key为该message+source所在界面的唯一标示，common为chat.id，mergeForward为source.sourceID
        let key = translateParam.source.sourceType == .commonMessage ? translateParam.chat.id : translateParam.source.sourceID
        let translateLanguage = message.translateLanguage
        return safeRead {
            if let cache = self.translatedInlines[key] {
                return inlines.compactMapValues({ cache[translatedKey($0.1, $0.0)] })
            }
            return [:]
        }
    }

    func translateURLInlines(translateParam: MessageTranslateParameter) {
        let message = translateParam.message
        let inlines = getLanguageAndInlines(message: message)
        guard !inlines.isEmpty else { return }
        // key为该message+source所在界面的唯一标示，common为chat.id，mergeForward为source.sourceID
        let key = translateParam.source.sourceType == .commonMessage ? translateParam.chat.id : translateParam.source.sourceID
        var cache = safeRead({ return translatedInlines[key] })
        if cache == nil {
            safeWrite {
                cache = translatedInlines[key] ?? [:]
                // 需要对translatedInlines初始化个[:]，因为会resetTranslatedInlines
                translatedInlines[key] = cache
            }
        }

        // 筛选出无翻译缓存且translateLanguage有值的inline
        let waitInlines = inlines.filter({ cache?[translatedKey($0.value.1, $0.value.0)] == nil && !$0.value.0.isEmpty })
            .mapValues({ (key, $0.0, $0.1) })
        guard !waitInlines.isEmpty else { return }
        mainOrAsync { [weak self] in
            guard let self = self else { return }
            self.waitInlines += waitInlines
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.translateWaitInlines), object: nil)
            self.perform(#selector(self.translateWaitInlines), with: nil, afterDelay: 0.5)
        }
    }

    // 获取翻译的语言和原始Inline
    private func getLanguageAndInlines(message: Message) -> [String: OriginInlineInfo] {
        guard message.displayRule == .onlyTranslation || message.displayRule == .withOriginal else { return [:] }
        var inlines = [String: OriginInlineInfo]()
        if message.type == .post, let content = message.content as? PostContent {
            inlines = content.inlinePreviewEntities.mapValues({ (message.translateLanguage, $0) })
        } else if message.type == .text, let content = message.content as? TextContent {
            inlines = content.inlinePreviewEntities.mapValues({ (message.translateLanguage, $0) })
        } else if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            // 合并转发需要看内层消息的displayRule和translateLanguage
            content.messages.forEach { subMessage in
                guard subMessage.displayRule == .onlyTranslation || subMessage.displayRule == .withOriginal else { return }
                if subMessage.type == .post, let subContent = subMessage.content as? PostContent {
                    inlines += subContent.inlinePreviewEntities.mapValues({ (subMessage.translateLanguage, $0) })
                } else if subMessage.type == .text, let subContent = subMessage.content as? TextContent {
                    inlines += subContent.inlinePreviewEntities.mapValues({ (subMessage.translateLanguage, $0) })
                }
            }
            // 合并转发时，外层消息的inline是从内层消息取的，需要同步修改下sourceID
            inlines = inlines.mapValues { translateLanguage, inline in
                var inline = inline
                inline.sourceID = message.id
                return (translateLanguage, inline)
            }
        }
        return inlines
    }

    @objc
    private func translateWaitInlines() {
        assert(Thread.isMainThread, "must be on main thread!")
        let tempInlines = waitInlines
        waitInlines = [:]
        translateURLInlines(inlines: tempInlines)
    }

    private func translateURLInlines(inlines: [String: WaitInlineInfo]) {
        let contexts = inlines.values.map { _, manualTargetLanguage, inline in
            URLInlineContext(previewID: inline.previewID,
                             title: inline.title,
                             tag: inline.tag,
                             isSDKPreview: inline.isSDKPreview,
                             manualTargetLanguage: manualTargetLanguage.isEmpty ? nil : manualTargetLanguage)
        }
        guard !contexts.isEmpty else { return }
        // 跟SDK和后端同学对齐，对于URL中台的Inline翻译来说，isAutoTranslate没有用到
        self.dependency.translateAPI.translateURLInlines(inlineContexts: contexts, isAutoTranslate: false)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                var cacheInlines = [String: [String: InlinePreviewEntity]]()
                response.translatedEntities.forEach { entity in
                    let previewID = entity.previewID
                    if let (key, translateLanguage, originEntity) = inlines[previewID] {
                        let translateEntity = InlinePreviewEntity(version: originEntity.version,
                                                                  sourceID: originEntity.sourceID,
                                                                  previewID: originEntity.previewID,
                                                                  title: entity.hasTitle ? entity.title : nil,
                                                                  udIcon: originEntity.udIcon,
                                                                  imageSetPassThrough: originEntity.imageSetPassThrough,
                                                                  iconKey: originEntity.iconKey,
                                                                  iconUrl: originEntity.iconUrl,
                                                                  iconImage: nil,
                                                                  tag: entity.hasTag ? entity.tag : nil,
                                                                  url: originEntity.url,
                                                                  isSDKPreview: originEntity.isSDKPreview,
                                                                  needReload: originEntity.needReload,
                                                                  useColorIcon: originEntity.useColorIcon,
                                                                  unifiedHeader: originEntity.unifiedHeader,
                                                                  extra: originEntity.extra)
                        var cache = cacheInlines[key] ?? [:]
                        cache += [self.translatedKey(translateEntity, translateLanguage): translateEntity]
                        cacheInlines[key] = cache
                    }
                }
                guard !cacheInlines.isEmpty else { return }
                // 更新缓存
                self.safeWrite {
                    cacheInlines.forEach { key, inlines in
                        // 只有translatedInlines中有的时候才更新缓存（否则可能被reset了）
                        if var cache = self.translatedInlines[key] {
                            cache += inlines
                            self.translatedInlines[key] = cache
                        }
                    }
                }
                let translateSourceIDs = Set(cacheInlines.values.flatMap({ Array($0.values) }).map({ $0.sourceID }))
                let translateInfo = PushTranslateInfo(translateInlineIDs: Array(translateSourceIDs))
                self.dependency.pushTranslateInfo(info: translateInfo)
                Self.logger.info("translateInlines: origin = { \(self.originInlineDesc(inlines: inlines)) }; response = { \(self.translateInlineDesc(inlines: response.translatedEntities)) }")
            }, onError: { error in
                Self.logger.error("translateInlines error: origin = { \(self.originInlineDesc(inlines: inlines)) }", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func translatedKey(_ inline: InlinePreviewEntity, _ translateLanguage: String) -> String {
        return "\(inline.previewID)_\(inline.version)_\(translateLanguage)"
    }
}

// MARK: Track
extension TranslateInlinePreviewService {
    private func originInlineDesc(inlines: [String: WaitInlineInfo]) -> String {
        return inlines.values
            .map({ "{ key = \($0.key); translateLanguage = \($0.translateLanguage); inline = \($0.inline.tcDescription) }" })
            .joined(separator: "; ")
    }

    private func translateInlineDesc(inlines: [Basic_V1_TranslatedUrlPreviewEntity]) -> String {
        return inlines.map({ $0.tcDescription }).joined(separator: "; ")
    }
}

private func mainOrAsync(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async { task() }
    }
}

private extension Basic_V1_TranslatedUrlPreviewEntity {
    var tcDescription: String {
        return "{ previewID = \(previewID); title = \(title.count); tag = \(tag.count); targetLanguage = \(targetLanguage)}"
    }
}

private func += (_ left: inout [String: WaitInlineInfo], _ right: [String: WaitInlineInfo]) {
    left.merge(right) { old, new in
        return new.inline.version >= old.inline.version ? new : old
    }
}

private func += (_ left: inout [String: OriginInlineInfo], _ right: [String: OriginInlineInfo]) {
    left.merge(right) { old, new in
        return new.inline.version >= old.inline.version ? new : old
    }
}
