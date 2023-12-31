//
//  LabelMainListDataModule.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB

/** LabelMainListDataModule的设计：作为整个功能的数据提供方，管理协调fetcher、queue、store等角色
1. 使用fetcher调用api接口，并监听fetcherOB获取数据
2. 将数据处理放到queue里执行
3. 使用store提供的接口进行数据存储
*/

final class LabelMainListDataModule {

    let fetcher: LabelMainListFetcher
    let dataQueue = LabelMainListDataQueue()
    private var _store: DataStoreInterface // 只在queue里使用
    var store: DataStoreInterface {
        return dataRelay.value.store
    }
    private let dataRelay: BehaviorRelay<LabelMainListDataState.StoreInfo>
    var dataObservable: Observable<LabelMainListDataState.StoreInfo> {
        return dataRelay.asObservable()
    }
    private let disposeBag: DisposeBag

    init(fetcher: LabelMainListFetcher) {
        self.fetcher = fetcher
        self.disposeBag = DisposeBag()
        let store = LabelMainListDataStore()
        self._store = store
        let storeInfo = LabelMainListDataState.StoreInfo(store: store, extraInfo: LabelMainListDataState.ExtraInfo.default())
        self.dataRelay = BehaviorRelay<LabelMainListDataState.StoreInfo>(value: storeInfo)
        setup()
    }

    private func setup() {
        fetcher.dataObservable
            .subscribe(onNext: { [weak self] data in
            self?.updateData(data)
        }).disposed(by: disposeBag)
    }

    func updateData(_ data: LabelMainListDataState.DataInfo) {
        let task = { [weak self] in
            guard let self = self else { return }
            let canUpdate = self._handleData(data.data)
            guard canUpdate else { return }
            self.output(store: self._store, extraInfo: data.extraInfo)
        }
        self.dataQueue.addTask(task)
    }

    func trigger(info: LabelMainListDataState.ExtraInfo) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.output(store: self._store, extraInfo: info)
        }
        self.dataQueue.addTask(task)
    }

    func trigger() {
        let info = LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .none)
        trigger(info: info)
    }

    private func _handleData(_ datas: [LabelMainListDataState.UpdatedData]) -> Bool {
        // TODO: 避免无效数据更新，减少UI刷新次数，这个不应该在数据层上做，成本比较高，应该交给diff库来做
        let canUpdate = true
        datas.forEach({ data in
            switch data {
            case .reload:
                break
            case .updateLabelByGet(let response):
                self._store.update(labels: response.labels)
                self._store.updateLabelList(hasMore: response.hasMore, nextCursor: response.nextCursor)
            case .updateFeedByGet(let response):
                self._store.update(feedEntities: response.entitys.map({ $0.feedViewModel }))
                self._store.update(feedRelations: response.relations)
                self._store.updateFeedList(labelId: response.labelId, hasMore: response.hasMore, nextCursor: response.nextCursor)
            case .updateLabel(let labelViewModels):
                self._store.update(labels: labelViewModels)
            case .removeLabel(let labelIds):
                self._store.remove(labelIds: labelIds)
            case .updateFeedEntity(let feedEntities):
                self._store.update(feedEntities: feedEntities)
            case .updateFeedRelation(let feedItems):
                self._store.update(feedRelations: feedItems)
            case .removeFeed(let feedIds):
                self._store.remove(feeds: feedIds)
            }
        })
        return canUpdate
    }

    private func output(store: DataStoreInterface, extraInfo: LabelMainListDataState.ExtraInfo) {
        let info = LabelMainListDataState.StoreInfo(store: store, extraInfo: extraInfo)
//        let logInfo = "storeInfo: \(store.description), "
//        + "dataFrom: \(extraInfo.dataFrom), "
//        + "renderType: \(extraInfo.render)"
//        FeedContext.log.info("feedlog/label/output: \(logInfo)")
        self.dataRelay.accept(info)
    }
}
