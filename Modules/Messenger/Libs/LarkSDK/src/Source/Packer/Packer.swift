//
//  Packer.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkSDKInterface

import RxSwift

class Packer<Model, Key: Hashable> {
    var fetchers: [DataFetcher] = []
    var packItems: [Key: [PackItem<Model>]] = [:]

    private var packTypes: [Key] {
        return packItems.map { $0.key }
    }

    func asyncPack(_ models: [Model]) -> Observable<[Model]> {
        return self.asyncPack(models, with: packTypes)
    }

    func asyncPack(_ models: [Model], with types: [Key]) -> Observable<[Model]> {
        let initial = Observable<[Model]>.just(models)
        return self.doPack(with: types, initialResult: initial, doPack: { (observable, items) -> Observable<[Model]> in
            return observable.flatMap({ [weak self] (models) -> Observable<[Model]> in
                guard let `self` = self else {
                    return .just(models)
                }
                return self.asyncPack(models, with: items)
            })
        })
    }

    private func doPack<T>(
        with types: [Key],
        initialResult: T,
        doPack: (T, [PackItem<Model>]) -> T
    ) -> T {
        let packItems = self.packItems.filter {
            return types.contains($0.key)
        }

        var result = initialResult
        var idx = 0
        var items: [PackItem<Model>] = []
        repeat {
            items = packItems.compactMap { (_, items) -> PackItem<Model>? in
                return items.count > idx ? items[idx] : nil
            }
            idx += 1
            result = doPack(result, items)
        } while !items.isEmpty

        return result
    }

    private func asyncPack(_ models: [Model], with packItems: [PackItem<Model>]) -> Observable<[Model]> {
        let collectItem = self.getCollectItem(for: models, with: packItems)

        return self.fetchPackData(with: collectItem).map({ [weak self] (data) -> [Model] in
            guard let `self` = self else {
                return models
            }
            return self.doPack(models, with: packItems, and: data)
        })
    }

    private func getCollectItem(for models: [Model], with packItems: [PackItem<Model>]) -> CollectItem {
        let collectItems = models.flatMap { model in
            return packItems.map { item in
                return item.collect(model: model)
            }
        }
        return collectItems.reduce(CollectItem()) { (result, item) -> CollectItem in
            return result.merge(item)
        }.unique()
    }

    private func doPack(_ models: [Model], with packItems: [PackItem<Model>], and data: PackData) -> [Model] {
        return models.map { model in
            var model = model
            packItems.forEach { item in
                model = item.pack(model: model, data: data)
            }
            return model
        }
    }

    private func fetchPackData(with collectItem: CollectItem) -> Observable<PackData> {
        let observables = self.fetchers.map { (fetcher) -> Observable<PackData> in
            return fetcher.asyncFetch(with: collectItem)
        }

        return Observable<PackData>.combineLatest(observables) { (datas) -> PackData in
            return datas.reduce(.default) { (result, data) -> PackData in
                return result.merge(data)
            }
        }
    }
}
