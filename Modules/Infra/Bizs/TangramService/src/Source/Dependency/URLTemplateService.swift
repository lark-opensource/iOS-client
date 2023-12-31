//
//  URLTemplateService.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/8/9.
//

import Foundation
import RustPB
import RxSwift
import LarkModel
import LarkContainer
import LKCommonsLogging
import ThreadSafeDataStructure

/// Template 缓存逻辑
/// 兼容 message、widget 场景
public class URLTemplateService {
    static let logger = Logger.log(URLTemplateService.self, category: "URLTemplateService")

    private var templates = [String: Basic_V1_URLPreviewTemplate]() + .readWriteLock
    private var urlAPI: URLPreviewAPI?
    private let disposeBag: DisposeBag = DisposeBag()
    private let pushCenter: PushNotificationCenter
    private let sourceType: URLPreviewTemplatePushSourceType
    private let updateHandler: (([String], [String]) -> Void)?

    public init(pushCenter: PushNotificationCenter, updateHandler: (([String], [String]) -> Void)? = nil, sourceType: URLPreviewTemplatePushSourceType, urlAPI: URLPreviewAPI?) {
        self.pushCenter = pushCenter
        self.updateHandler = updateHandler
        self.sourceType = sourceType
        self.urlAPI = urlAPI
    }

    public func observe() {
        let sourceType = self.sourceType
        pushCenter.observable(for: URLPreviewTemplatePush.self)
            .filter { sourceType == $0.sourceType }
            .subscribe(onNext: { [weak self] push in
                self?.handle(push: push)
            }).disposed(by: disposeBag)
    }

    private func handle(push: URLPreviewTemplatePush) {
        // 更新template缓存
        self.update(templates: push.templates)
        self.fetchTemplates(missingIDs: push.missingTemplateIDs)
    }

    /// missingIDs: sourceID -> templateIDs
    private func fetchTemplates(missingIDs: [String: Set<String>]) {
        var missingIDs: [String: Set<String>] = missingIDs.compactMapValues { templateIDs in
            let templateIDs = templateIDs.filter({ !URLPreviewAdaptor.isLocalTemplate(templateID: $0) })
            return templateIDs.isEmpty ? nil : templateIDs
        }
        guard !missingIDs.isEmpty else { return }
        let cache = self.templates.getImmutableCopy()
        // 当templateID都有时，不需要再刷新sourceID
        missingIDs = missingIDs.compactMapValues { templateIDs in
            let ids = templateIDs.filter { cache[$0] == nil }
            return ids.isEmpty ? nil : ids
        }

        let missingTemplateIDs = missingIDs.values.flatMap({ Array($0) })
        Self.logger.info("[URLPreview] sourceType: \(self.sourceType) fetchTemplates: \(missingIDs)")
        guard !missingTemplateIDs.isEmpty else { return }
        _ = urlAPI?.getUrlPreviewTemplates(templatedIDs: Array(Set(missingTemplateIDs)))
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.update(templates: response.templates)
                self.updateHandler?(Array(missingIDs.keys), Array(Set(missingTemplateIDs)))
            }, onError: { error in
                Self.logger.error("[URLPreview] sourceType: \(self.sourceType) fetchTemplates error: \(missingIDs)", error: error)
            })
    }

    public func update(templates: [String: Basic_V1_URLPreviewTemplate]) {
        guard !templates.isEmpty else { return }
        self.templates.safeWrite { dict in
            dict += templates
        }
    }

    public func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate? {
        return templates[id]
    }
}

private func += (left: inout [String: Basic_V1_URLPreviewTemplate], right: [String: Basic_V1_URLPreviewTemplate]) {
    left.merge(right, uniquingKeysWith: { _, last in last })
}
