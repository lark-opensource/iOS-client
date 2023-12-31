//
//  LabelMainListFetcher.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxRelay
import RustPB
import LarkModel
import LarkRustClient
import SwiftProtobuf
import RunloopTools
import LarkOpenFeed
import LarkContainer

/** LabelMainListFetcher的设计：屏蔽api接口，组装各种发送请求到server中
1. 不保存任何状态
2. 数据暂时不作简单处理，直接返回response，后期看是否优化成updateDatas、removeDatas
3. 增加数据状态：可通过使用枚举的方式，比如 idle、 loading、load、error
*/

final class LabelMainListFetcher: UserResolverWrapper {

    private let dataSubject = PublishSubject<LabelMainListDataState.DataInfo>()
    var dataObservable: Observable<LabelMainListDataState.DataInfo> {
        return dataSubject.asObservable()
    }

    private let stateSubject = PublishSubject<LabelMainListDataState.DataState>()
    var stateObservable: Observable<LabelMainListDataState.DataState> {
        return stateSubject.asObservable().distinctUntilChanged()
    }

    let dependency: LabelDependency
    var userResolver: UserResolver {
        return dependency.userResolver
    }
    @ScopedInjectedLazy private var feedCardModuleManager: FeedCardModuleManager?

    private let disposeBag = DisposeBag()

    init(dependency: LabelDependency) {
        self.dependency = dependency
        setup()
    }

    func refresh() {
        getLabels(nextCursor: nil, isFirstFetch: true)
    }

    private func getLabels(nextCursor: IndexCursor?, isFirstFetch: Bool) {
        var times = 0
        if isFirstFetch {
            stateSubject.onNext(.loading)
        }
        _getLabel(nextCursor: nextCursor).subscribe(onNext: { [weak self] (nextCursor: IndexCursor?) in
            if isFirstFetch {
                self?.stateSubject.onNext(.loaded)
            }
            times += 1
            guard let nextCursor = nextCursor, times < LabelConfig.loadMoreLabelMaxTimes else { return }
            self?.getLabels(nextCursor: nextCursor, isFirstFetch: false)
        }, onError: { [weak self] _ in
            if isFirstFetch {
                self?.stateSubject.onNext(.error)
            }
        }).disposed(by: disposeBag)
    }

    private func _getLabel(nextCursor: IndexCursor?) -> Observable<IndexCursor?> {
        dependency.getLabels(nextPosition: nextCursor?.position, count: LabelConfig.loadMoreLabelCount)
            .map({ [weak self] (response: GetLabelsResponse) -> IndexCursor? in
                guard let self = self else { return nil }
                var labels: [LabelViewModel] = []
                labels = response.groupInfos.map({
                    let id = Int($0.feedGroup.id)
                    let item = EntityItem(id: id,
                                          parentId: 0,
                                          position: $0.feedGroup.position,
                                          updateTime: $0.feedGroup.updateTime)
                    return LabelViewModel(item: item, meta: $0)
                })
                let nextCursor = IndexCursor(position: response.nextPosition)
                let response = LabelMainListDataState.GetLabelsResult(
                    labels: labels,
                    hasMore: response.hasMore_p,
                    nextCursor: nextCursor)
                let extraInfo = LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .none)
                let info = LabelMainListDataState.DataInfo(
                    data: [.updateLabelByGet(response)],
                    extraInfo: extraInfo)
                self.dataSubject.onNext(info)
                if response.hasMore {
                    return nextCursor
                } else {
                    return nil
                }
            })
    }

    // TODO: 需要优化下，一次拉完
    func loadMoreFeed(labelId: Int, nextCursor: IndexCursor?, orderBy: Feed_V1_FeedGroupItemOrderRule) -> Observable<Bool> {
        var cursor: Feed_V1_GroupCursor?
        if let nextCursor = nextCursor {
            var groupCursor = Feed_V1_GroupCursor()
            groupCursor.itemID = nextCursor.itemId
            groupCursor.position = nextCursor.position
            cursor = groupCursor
        }
        return dependency.getLabelFeeds(labelId: labelId,
                                        nextCursor: cursor,
                                        count: LabelConfig.loadMoreFeedCount,
                                        orderBy: orderBy)
        .map({ [weak self] (response: GetLabelFeedsResponse) -> Bool in
            guard let self = self else { return false }
            let entitys = response.feeds.compactMap({ self.transform(feedWrapper: $0) })
            var relations: [EntityItem] = []
            response.feeds.forEach { feedWrapper in
                let feedRelations = self.transformToRelation(feedWrapper: feedWrapper)
                relations += feedRelations
            }
            let nextCursor = IndexCursor(position: response.nextCursor.position, itemId: response.nextCursor.itemID)
            let result = LabelMainListDataState.GetLabelFeedsResult(labelId: labelId,
                                                                    entitys: entitys,
                                                                    relations: relations,
                                                                    hasMore: response.hasMore,
                                                                    nextCursor: nextCursor)
            let extraInfo = LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .loadMoreFeed(labelId))
            let info = LabelMainListDataState.DataInfo(
                data: [.updateFeedByGet(result)],
                extraInfo: extraInfo)
            self.dataSubject.onNext(info)
            return response.hasMore
        })
    }

    func setup() {
        dependency.pushLabels.subscribe(onNext: { [weak self] (pushLabel) in
            guard let self = self else { return }
            var datas: [LabelMainListDataState.UpdatedData] = []
            if !pushLabel.updateLabels.isEmpty {
                datas.append(.updateLabel(pushLabel.updateLabels.map({ self.transform(label: $0) })))
            }
            if !pushLabel.removeLabels.isEmpty {
                datas.append(.removeLabel(pushLabel.removeLabels.map({ Int($0.id) })))
            }
            if !pushLabel.updatedFeedEntitys.isEmpty {
                datas.append(.updateFeedEntity(pushLabel.updatedFeedEntitys.compactMap({ self.transform(feedEntity: $0) })))
            }
            if !pushLabel.updatedFeedRelations.isEmpty {
                datas.append(.updateFeedRelation(pushLabel.updatedFeedRelations))
            }
            if !pushLabel.removedFeeds.isEmpty {
                datas.append(.removeFeed(pushLabel.removedFeeds.map({ self.transform(feedRelation: $0) })))
            }
            guard !datas.isEmpty else { return }
            let extraInfo = LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .none)
            let info = LabelMainListDataState.DataInfo(
                data: datas,
                extraInfo: extraInfo)
            self.dataSubject.onNext(info)
        }).disposed(by: disposeBag)

        dependency.pushFeedPreview.subscribe(onNext: { [weak self] (feeds) in
            guard let self = self else { return }
            var updateFeeds = [FeedCardViewModelInterface]()
            feeds.updateFeeds.compactMap { (_: String, feedInfo: PushFeedInfo) in
                let feed = feedInfo.feedPreview
                if feedInfo.types.contains(.label), let feedVM = self.transform(feedEntity: feed) {
                    updateFeeds.append(feedVM)
                }
            }
            guard !updateFeeds.isEmpty else { return }
            let extraInfo = LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .none)
            let info = LabelMainListDataState.DataInfo(
                data: [.updateFeedEntity(updateFeeds)],
                extraInfo: extraInfo)
            self.dataSubject.onNext(info)
        }).disposed(by: disposeBag)

        dependency.badgeStyleObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.handleBadgeStyle()
            }).disposed(by: disposeBag)
    }

    func handleBadgeStyle() {
        let extraInfo = LabelMainListDataState.ExtraInfo(render: .fullReload, dataFrom: .none)
        let info = LabelMainListDataState.DataInfo(
            data: [.reload],
            extraInfo: extraInfo)
        self.dataSubject.onNext(info)
    }
}

extension LabelMainListFetcher {
    func transform(label: Feed_V1_FeedGroupPreview) -> LabelViewModel {
        let id = Int(label.feedGroup.id)
        let item = EntityItem(id: id,
                              parentId: 0,
                              position: label.feedGroup.position,
                              updateTime: label.feedGroup.updateTime)
        return LabelViewModel(item: item, meta: label)
    }

    func transform(feedRelation: Feed_V1_FeedGroupItem) -> IndexDataInterface {
        return EntityItem(id: Int(feedRelation.feedCardID),
                          parentId: Int(feedRelation.groupID),
                          position: 0,
                          updateTime: feedRelation.updateTime)
    }

    func transform(feedWrapper: LabelFeedWrapperModel) -> LabelFeedViewModel? {
        let feedEntity = feedWrapper.feedEntity
        guard let vm = transform(feedEntity: feedEntity) else {
            return nil
        }
        return LabelFeedViewModel(feedViewModel: vm)
    }

    func transformToRelation(feedWrapper: LabelFeedWrapperModel) -> [EntityItem] {
        let feedRelations = feedWrapper.feedRelations
        var items: [EntityItem] = []
        feedRelations.forEach { feedRelation in
            let item = EntityItem(id: Int(feedRelation.feedCardID),
                                  parentId: Int(feedRelation.groupID),
                                  position: feedRelation.position,
                                  updateTime: feedRelation.updateTime)
            items.append(item)
        }
        return items
    }

    func transform(feedEntity: FeedPreview) -> FeedCardViewModelInterface? {
        guard let feedCardModuleManager = feedCardModuleManager else { return nil }
        return FeedCardContext.cellViewModelBuilder?(feedEntity, dependency.userResolver, feedCardModuleManager, .label, .tag, [:])
    }
}
