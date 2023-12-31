//
//  MomentFeedListViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/5.
//

import UIKit
import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkAccountInterface
import AppReciableSDK

final class MomentFeedListViewModel: PostListBaseViewModel <FeedList.TableRefreshType, FeedList.ErrorType> {

    private let sourceType: FeedList.SourceType
    private let context: BaseMomentContext
    let tabInfo: RawData.PostTab
    @ScopedInjectedLazy private var feedApi: FeedApiService?
    @ScopedInjectedLazy private var postApi: PostApiService?
    @ScopedInjectedLazy private var thumbsupReactionService: ThumbsupReactionService?
    @ScopedInjectedLazy private var postIsBoardcast: PostIsBoardcastNotification?
    @ScopedInjectedLazy var createPostService: CreatePostApiService?
    @ScopedInjectedLazy var badgeNoti: MomentBadgePushNotification?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?

    let tracker: MomentsCommonTracker = MomentsCommonTracker()
    let manageMode: RawData.ManageMode

    init(userResolver: UserResolver,
         sourceType: FeedList.SourceType,
         manageMode: RawData.ManageMode,
         userPushCenter: PushNotificationCenter,
         context: BaseMomentContext,
         tabInfo: RawData.PostTab) {

        self.sourceType = sourceType
        self.manageMode = manageMode
        self.context = context
        self.tabInfo = tabInfo
        self.tracker.startTrackFeedItemWithIsRecommendTab(tabInfo.isRecommendTab)
        super.init(userResolver: userResolver, userPushCenter: userPushCenter)
    }

    override func observerNotification() {
        super.observerNotification()
        /// 这个每个都存在入口 都需要监听
        postIsBoardcast?.rxPostIsBoardcast
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (postBoardcastInfo) in
                guard let self = self else { return }
                Self.logger.info("moment trace feedList nof postIsBoardcast handle \(postBoardcastInfo.postID)")
                self.update(targetPostId: postBoardcastInfo.postID) { (entity) -> RawData.PostEntity? in
                    entity.post.isBroadcast = postBoardcastInfo.isBroadcast
                    Self.logger.info("moment trace feedList nof postIsBoardcast handle refresh")
                    return entity
                }
            }).disposed(by: disposeBag)
        // 如果是推荐页的情况下 监听通知
        if self.tabInfo.isRecommendTab {
            createPostService?.createPostNot
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (post) in
                    self?.insertPost(post, finish: nil)
                }).disposed(by: self.disposeBag)
        }

        thumbsupReactionService?.thumbsupUpdate
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (_) in
                self?.cellViewModels.forEach { $0.calculateRenderer() }
                self?.publish(.refresh)
            }).disposed(by: disposeBag)
    }

    func fetchFirstScreenPosts() {
        if self.tabInfo.isRecommendTab {
            self.fetchFirstScreenPostsFromLocalFirst()
        } else {
            self.fetchFirstScreenPostsOnlyFromRemote()
        }
    }
    //获取推荐首屏数据
    func fetchFirstScreenPostsFromLocalFirst() {
        //先取本地
        var fetchLocalDataSuccess = true
        let item = self.tracker.getMomentsFeedLoadItem(isRecommendTab: self.tabInfo.isRecommendTab)
        Self.logger.info("moment trace feedList firstScreen start local first \(self.tabInfo.id)")
        fetchPosts(byRemote: false)
            .catchError({ [weak self] (error) -> FeedApi.RxGetFeed in
                guard let self = self else {
                    return .just(FeedApiResponseData(nextPageToken: "",
                                                     posts: [],
                                                     trackerInfo: MomentsTrackerInfo(timeCost: 0)))
                }
                //失败了也会取远端数据
                fetchLocalDataSuccess = false
                Self.logger.error("moment trace feedList firstScreen localData fail", error: error)
                MomentsErrorTacker.trackFeedError(error, event: .momentsShowHomePage, failSence: .localListFeedFail)
                return self.fetchPosts(byRemote: true)
            })
            .flatMap({ [weak self] (data) -> FeedApi.RxGetFeed in
                let nextPageToken = data.nextPageToken
                let posts = data.posts
                let trackerInfo = data.trackerInfo
                guard let self = self, fetchLocalDataSuccess else {
                    //如果本地失败了，会兜底取远端，此处直接把远端数据传递即可
                    Self.logger.info("moment trace feedList firstScreen localData fail remoteData success \(data.nextPageToken) \(data.posts.count)")
                    return .just(data)
                }
                item?.sdkLocalCost(trackerInfo.timeCost)
                item?.startLocalDataRender()
                Self.logger.info("moment trace feedList firstScreen localData success \(nextPageToken) \(posts.count)")
                //转化为cellvm
                self.cellViewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver, postEntity: $0, context: self.context, manageMode: self.manageMode) }
                self.saveUserStoreWith(key: self.cellViewModels.first?.entityId ?? "", value: self.tabInfo.id)
                self.publish(.localFirstScreenDataRefresh)
                return self.fetchPosts(byRemote: true)
            })
            .subscribe(onNext: { [weak self] (data) in
                self?.updateLastNewRecommendPostID(data.lastNewRecommendPostID)
                self?.refreshRemoteFirstScreenDataWith(nextPageToken: data.nextPageToken,
                                                       posts: data.posts,
                                                       trackerInfo: data.trackerInfo,
                                                       trackerItem: item)
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace feedList firstScreen remoteData fail \(fetchLocalDataSuccess)", error: error)
                self?.errorPub.onNext(.fetchFirstScreenPostsFail(error, localDataSuccess: fetchLocalDataSuccess))
                MomentsErrorTacker.trackFeedError(error, event: .momentsShowHomePage, failSence: .remoteFeedFail)
            }).disposed(by: disposeBag)
    }

    //获取推荐首屏数据
    func fetchFirstScreenPostsOnlyFromRemote() {
        let item = self.tracker.getMomentsFeedLoadItem(isRecommendTab: self.tabInfo.isRecommendTab)
        Self.logger.info("moment trace feedList firstScreen start only from remote \(self.tabInfo.id)")
        fetchPosts(byRemote: true)
            .subscribe(onNext: { [weak self] data in
                self?.updateLastNewRecommendPostID(data.lastNewRecommendPostID)
                self?.refreshRemoteFirstScreenDataWith(nextPageToken: data.nextPageToken,
                                                       posts: data.posts,
                                                       trackerInfo: data.trackerInfo,
                                                       trackerItem: item)
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace feedList firstScreen remoteData fail", error: error)
                self?.errorPub.onNext(.fetchFirstScreenPostsFail(error, localDataSuccess: false))
                MomentsErrorTacker.trackReciableEventError(error, sence: .MoFeed, event: .momentsShowCategoryPage, page: "home")
            }).disposed(by: disposeBag)
    }

    private func refreshRemoteFirstScreenDataWith(nextPageToken: String,
                                                  posts: [RawData.PostEntity],
                                                  trackerInfo: MomentsTrackerInfo,
                                                  trackerItem: MomentsFeedLoadItem?) {
        Self.logger.info("moment trace feedList firstScreen remoteData success \(nextPageToken) \(posts.count)")
        trackerItem?.sdkRemotelCost(trackerInfo.timeCost, postCount: posts.count)
        trackerItem?.startRemoteDataRender()
        let style = self.willRefreshPostData(posts, byUserAction: false)
        //转化为cellvm
        self.cellViewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver, postEntity: $0, context: self.context, manageMode: self.manageMode) }
        self.nextPageToken = nextPageToken
        self.publish(.remoteFirstScreenDataRefresh(hasFooter: !nextPageToken.isEmpty, style: style))
    }

    /// 这里的返回提示逻辑
    func willRefreshPostData(_ data: [RawData.PostEntity], byUserAction: Bool) -> PostTipStyle? {
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh") else { return nil }
        guard !data.isEmpty else {
            return byUserAction ? .empty : nil
        }
        /// 如果内存中有数据，优先用内存中的数据比对
        let postID = self.cellViewModels.first?.entityId ?? self.getUserStoreValueForKey(self.tabInfo.id)
        self.saveUserStoreWith(key: self.tabInfo.id, value: data.first?.postId ?? "")
        Self.logger.info("willRefreshPostData ---old \(postID) new \(data.first?.postId) -\(byUserAction)")
        if let postID = postID, postID == data.first?.postId {
            return byUserAction ? .empty : nil
        }
        return .success
    }

    //获取数据
    private func fetchPosts(pageToken: String = "", count: Int32 = FeedList.pageCount, byRemote: Bool = true) -> FeedApi.RxGetFeed {
        guard let feedApi else { return .empty() }
        switch sourceType {
        case .follow:
            return feedApi.getFollowingFeed(byCount: count, pageToken: pageToken).observeOn(queueManager.dataScheduler)
        case .recommand:
            var feedOrder: RawData.FeedOrder?
            switch self.manageMode {
            case .recommendV2Mode:
                feedOrder = .recommendV2
            case .strongIntervention:
                feedOrder = .recommend
            @unknown default:
                feedOrder = nil
            }
            return feedApi.getRecommendFeed(byCount: count,
                                            useLocal: !byRemote,
                                            pageToken: pageToken,
                                            tabID: self.tabInfo.id,
                                            feedOrder: feedOrder,
                                            manageMode: self.manageMode,
                                            isIOSMock: false).observeOn(queueManager.dataScheduler)
        }
    }

    //获取更多
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore, !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace feedList loadMorePosts start")
        let item = MomentsFeedUpdateItem(biz: .Moments, scene: .MoFeed, event: .loadMoreFeed, page: "home")
        item.order = self.tabInfo.isRecommendTab ? RawData.FeedOrder.recommend.rawValue : RawData.FeedOrder.unspecified.rawValue
        self.tracker.startTrackWithItem(item)
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else {
                    return
                }
                item.updateDataWithSDKCost(data.trackerInfo.timeCost, postCount: data.posts.count)
                item.startListRender()
                Self.logger.info("moment trace feedList loadMorePosts finish \(data.nextPageToken) \(data.posts.count)")
                //转化为cellvm
                let viewModels = data.posts.map { MomentPostCellViewModel(userResolver: self.userResolver, postEntity: $0, context: self.context, manageMode: self.manageMode) }
                self.cellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = data.nextPageToken
                self.publish(.refreshTable(hasFooter: !data.nextPageToken.isEmpty,
                                           style: nil,
                                           trackSence: .loadMore))
                self.loadingMore = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.loadingMore = false
                self?.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace feedList loadMorePosts fail \(error)")
                finish(.error)
                MomentsErrorTacker.trackFeedError(error, event: .loadMoreFeed)
            }).disposed(by: disposeBag)
    }

    //从头刷新
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !refreshing else { return finish(.noWork) }
        refreshing = true
        nextPageToken = ""
        Self.logger.info("moment trace feedList refreshPosts start")
        let item = MomentsFeedUpdateItem(biz: .Moments, scene: .MoFeed, event: .refreshFeed, page: "home")
        item.order = self.manageMode.rawValue
        self.tracker.startTrackWithItem(item)
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                let nextPageToken = data.nextPageToken
                let posts = data.posts
                let trackerInfo = data.trackerInfo
                self.updateLastNewRecommendPostID(data.lastNewRecommendPostID)
                let style = self.willRefreshPostData(posts, byUserAction: true)
                item.updateDataWithSDKCost(trackerInfo.timeCost, postCount: posts.count)
                item.startListRender()
                //转化为cellvm
                let viewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver, postEntity: $0, context: self.context, manageMode: self.manageMode) }
                self.cellViewModels = viewModels
                self.nextPageToken = nextPageToken
                Self.logger.info("moment trace feedList refreshPosts finish \(nextPageToken) \(posts.count)")
                self.publish(.refreshTable(needResetHeader: true,
                                           hasFooter: !nextPageToken.isEmpty,
                                           style: style,
                                           trackSence: .refresh))
                self.refreshing = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.refreshing = false
                self?.errorPub.onNext(.refreshListFail(error))
                Self.logger.error("moment trace feedList refreshPosts fail \(error)")
                MomentsErrorTacker.trackFeedError(error, event: .refreshFeed)
                finish(.error)
            }).disposed(by: disposeBag)
    }

    private func insertPost(_ post: RawData.PostEntity, finish: (() -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            let cellViewModel = MomentPostCellViewModel(userResolver: self.userResolver, postEntity: post, context: self.context, manageMode: self.manageMode)
            self.cellViewModels.insert(cellViewModel, at: 0)
            self.publish(.publishPost)
            finish?()
        }
    }

    func fetchBoardcastPosts() {
        /// 不是推荐页不展示置顶
        if !self.tabInfo.isRecommendTab {
            return
        }
        self.feedApi?.listBroadcasts(mock: false).subscribe { [weak self] (boardcasts) in
            self?.publish(.refreshBoardcast(boardcasts))
            Self.logger.error("moment trace fetchBoardcastPosts count \(boardcasts.count)")
        } onError: { (error) in
            Self.logger.error("moment trace fetchBoardcastPosts fail \(error)")
        }.disposed(by: self.disposeBag)
    }

    private func hasNewPost(posts: [RawData.PostEntity]) -> Bool {
        let oldPostIds = self.cellViewModels.map { (cellVM) -> String in
            return cellVM.entity.id
        }
        let newPostIds = posts.map { (post) -> String in
            return post.id
        }
        for newPostId in newPostIds where !oldPostIds.contains(newPostId) {
            return true
        }
        return false
    }

    func endTrackForFirstScreen() {
        let item = self.tracker.getMomentsFeedLoadItem(isRecommendTab: self.tabInfo.isRecommendTab)
        item?.endRemoteDataRender()
        self.tracker.endTrackWithItem(item)
    }

    func endTrackForSence(_ sence: FeedTrackSence) {
        let event = MomentsFeedUpdateItem.convertFeedTraceSenceToEvent(sence)
        let item: MomentsBusinessTrackerItem? = self.tracker.getItemWithEvent(event)
        if let feedItem = item as? MomentsFeedUpdateItem {
            feedItem.endListRender()
            self.tracker.endTrackWithItem(feedItem)
        }
    }

    override func businessType() -> String {
        return "feedList"
    }

    override func refreshData() {
        self.publish(.refresh)
    }

    override func refreshCellsWith(indexPaths: [IndexPath], animation: UITableView.RowAnimation) {
        self.publish(.refreshCell(indexs: indexPaths, animation: animation))
    }

    override func needHandlePushForType(_ type: PostPushType) -> Bool {
        /// 除了关注页之外 其他页面不需要关注
        if type == .status, !tabInfo.isRecommendTab {
            return false
        }
        return true
    }

    override func showPostFromCategory() -> Bool {
        return tabInfo.isRecommendTab || tabInfo.isFollowTab
    }

    override func needHanderDataForCategoryIds(_ categoryIds: [String]) -> Bool {
        /// 推荐页|| 关注页需要更新
        if tabInfo.isRecommendTab || tabInfo.isFollowTab {
            return true
        }
        if categoryIds.contains(tabInfo.id) {
            return true
        }
        return false
    }
}
