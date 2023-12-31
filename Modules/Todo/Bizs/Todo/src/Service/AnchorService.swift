//
//  AnchorService.swift
//  Todo
//
//  Created by 张威 on 2021/6/29.
//

import RxSwift
import RichLabel

/// Anchor Service，用于管理 Todo 业务域的 Anchor Hang 资源
protocol AnchorService: AnyObject {
    typealias HangPoint = Rust.RichText.AnchorHangPoint
    typealias HangEntity = Rust.RichText.AnchorHangEntity

    // cache/get hangEntity for url
    func cacheHangEntity(_ hangEntity: HangEntity, forUrl urlStr: UrlStr)
    func getCachedHangEntity(forUrl urlStr: UrlStr) -> HangEntity?

    // cache hangEntity for point
    func cacheHangEntity(_ hangEntity: HangEntity, forPoint point: HangPoint)

    /// generate hangEntity for url
    func generateHangEntity(forUrl urlStr: UrlStr) -> Maybe<HangEntity>

    /// get entity
    func getHangEntities(forPoints points: [HangPoint], sourceId: String) -> Return<[HangEntity]>
}

extension AnchorService {

    func cacheHangEntities(in richContent: Rust.RichContent) {
        for (eleId, ele) in richContent.richText.elements {
            guard
                ele.tag == .a,
                let anchor = richContent.richText.elements[eleId]?.property.anchor,
                let point = richContent.urlPreviewHangPoints[eleId],
                let entity = richContent.urlPreviewEntities.previewEntity[point.previewID]
            else {
                continue
            }
            cacheHangEntity(entity, forPoint: point)
        }
    }

    func getHangEntity(forPoint point: HangPoint, sourceId: String? = nil) -> Return<HangEntity> {
        let fixedSourceId: String
        if let s = sourceId, !s.isEmpty {
            fixedSourceId = s
        } else {
            fixedSourceId = UUID().uuidString
        }
        let ret = getHangEntities(forPoints: [point], sourceId: fixedSourceId)
        switch ret {
        case .sync(let entities):
            if entities.count == 1, let entity = entities.first, entity.previewID == point.previewID {
                return .sync(value: entity)
            }
            let next = Return<HangEntity>.Completion()
            DispatchQueue.main.async { next.onCompleted?() }
            return .async(completion: next)
        case .async(let completion):
            let next = Return<HangEntity>.Completion()
            completion.onSuccess = { entities in
                if entities.count == 1, let entity = entities.first, entity.previewID == point.previewID {
                    next.onSuccess?(entity)
                } else {
                    next.onCompleted?()
                }
            }
            completion.onError = { next.onError?($0) }
            completion.onCompleted = { next.onCompleted?() }
            return .async(completion: next)
        }
    }

}
