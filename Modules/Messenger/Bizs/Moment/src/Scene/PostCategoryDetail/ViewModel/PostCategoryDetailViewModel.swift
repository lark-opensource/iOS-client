//
//  PostCategoryDetailViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/4/27.
//

import UIKit
import Foundation
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkMessageCore

class PostListDetailViewModel: PostListBaseViewModel <PostList.TableRefreshType, PostList.ErrorType>, BasePostListViewModelProtocol {
    let manageMode: RawData.ManageMode
    private let context: BaseMomentContext
    let tracker: MomentsCommonTracker = MomentsCommonTracker()
    init(userResolver: UserResolver,
         context: BaseMomentContext,
         manageMode: RawData.ManageMode,
         userPushCenter: PushNotificationCenter) {
        self.context = context
        self.manageMode = manageMode
        super.init(userResolver: userResolver, userPushCenter: userPushCenter)
    }
    func fetchFirstScreenPosts() {
        Self.logger.info("moment trace \(businessType()) list firstScreen start")
        let item = MomentsPolymerizationItem(biz: .Moments, scene: .MoFeed, detail: self.getPageDetail())
        self.tracker.startTrackWithItem(item)
        fetchPosts()
            .subscribe(onNext: { [weak self] data in
                item.updateDataWithSDKCost(data.trackerInfo.timeCost, postCount: data.posts.count)
                item.startListRender()
                self?.updateLastNewRecommendPostID(data.lastNewRecommendPostID)
                self?.refreshRemoteFirstScreenDataWith(nextPageToken: data.nextPageToken,
                                                       posts: data.posts)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("moment trace \(self.businessType()) list firstScreen remoteData fail", error: error)
                self.errorPub.onNext(.fetchFirstScreenPostsFail(error, localDataSuccess: false))
                MomentsErrorTacker.trackFeedUpdateError(error, pageDetail: self.getPageDetail())
            }).disposed(by: disposeBag)
    }

    func willRefreshPostData(posts: [RawData.PostEntity], byUserAction: Bool) -> PostTipStyle? {
        return nil
    }

    //获取数据
    func fetchPosts(pageToken: String = "", count: Int32 = FeedList.pageCount) -> FeedApi.RxGetFeed {
        assertionFailure("子类需要重写")
        return FeedApi.RxGetFeed.empty()
    }

    private func refreshRemoteFirstScreenDataWith(nextPageToken: String,
                                                  posts: [RawData.PostEntity]) {
        Self.logger.info("moment trace \(self.businessType()) firstScreen remoteData success \(nextPageToken) \(posts.count)")
        let style = self.willRefreshPostData(posts: posts, byUserAction: false)
        //转化为cellvm
        self.cellViewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver, postEntity: $0, context: self.context, manageMode: self.manageMode) }
        self.nextPageToken = nextPageToken
        self.publish(.remoteFirstScreenDataRefresh(hasFooter: !nextPageToken.isEmpty, style: style))
    }

    //获取更多
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore, !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace \(self.businessType()) list loadMorePosts start")
        let item = self.getFeedUpdateItem(isRefresh: false)
        self.tracker.startTrackWithItem(item)
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else {
                    return
                }
                item.updateDataWithSDKCost(data.trackerInfo.timeCost, postCount: data.posts.count)
                item.startListRender()
                Self.logger.info("moment trace \(self.businessType()) list loadMorePosts finish \(data.nextPageToken) \(data.posts.count)")
                //转化为cellvm
                let viewModels = data.posts.map { MomentPostCellViewModel(userResolver: self.userResolver,
                                                                     postEntity: $0,
                                                                     context: self.context,
                                                                     manageMode: self.manageMode)
                }
                self.cellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = data.nextPageToken
                self.publish(.refreshTable(hasFooter: !data.nextPageToken.isEmpty, style: nil))
                self.loadingMore = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.loadingMore = false
                self.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace \(self.businessType()) list loadMorePosts fail \(error)")
                finish(.error)
                MomentsErrorTacker.trackFeedUpdateError(error, event: .loadMoreFeed, pageDetail: self.getPageDetail())
            }).disposed(by: disposeBag)
    }

    //从头刷新
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !refreshing else { return finish(.noWork) }
        refreshing = true
        nextPageToken = ""
        Self.logger.info("moment trace \(self.businessType()) list refreshPosts start")
        let item = self.getFeedUpdateItem(isRefresh: true)
        self.tracker.startTrackWithItem(item)
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                let nextPageToken = data.nextPageToken
                item.updateDataWithSDKCost(data.trackerInfo.timeCost, postCount: data.posts.count)
                item.startListRender()
                self.updateLastNewRecommendPostID(data.lastNewRecommendPostID)
                let style = self.willRefreshPostData(posts: data.posts, byUserAction: true)
                //转化为cellvm
                let viewModels = data.posts.map { MomentPostCellViewModel(userResolver: self.userResolver,
                                                                     postEntity: $0, context: self.context, manageMode: self.manageMode)
                }
                self.cellViewModels = viewModels
                self.nextPageToken = data.nextPageToken
                Self.logger.info("moment trace \(self.businessType()) list refreshPosts finish \(nextPageToken) \(data.posts.count)")
                self.publish(.refreshTable(needResetHeader: true, hasFooter: !nextPageToken.isEmpty, style: style))
                self.refreshing = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.refreshing = false
                self.errorPub.onNext(.refreshListFail(error))
                Self.logger.error("moment trace \(self.businessType()) list refreshPosts fail \(error)")
                finish(.error)
                MomentsErrorTacker.trackFeedUpdateError(error, event: .refreshFeed, pageDetail: self.getPageDetail())
            }).disposed(by: disposeBag)
    }

    override func refreshData() {
        self.publish(.refresh)
    }
    override func refreshCellsWith(indexPaths: [IndexPath], animation: UITableView.RowAnimation) {
        self.publish(.refreshCell(indexs: indexPaths, animation: animation))
    }

    override func deletePostWith(id: String) {
        super.deletePostWith(id: id)
    }

    override func needHandlePushForType(_ type: PostPushType) -> Bool {
        if type == .status {
            return false
        }
        return true
    }

    func getPageType() -> MomentsTracer.PageType {
        fatalError("Need To Be Override")
    }

    func getPageDetail() -> MomentsTracer.PageDetail? {
        fatalError("Need To Be Override")
    }

    func getFeedUpdateItem(isRefresh: Bool) -> MomentsFeedUpdateItem {
        fatalError("Need To Be Override")
    }

    func endTrackFeedItem() {
        self.tracker.endTrackFeedUpateItem()
    }

    /// 这里收一下
    func endTrackPolymerizationItem() {
        self.tracker.endTrackWithDetail(self.getPageDetail())
    }
}

final class PostCategoryDetailViewModel: PostListDetailViewModel {
    @ScopedInjectedLazy private var feedApi: FeedApiService?
    private let feedOrder: RawData.FeedOrder
    let tabID: String

    private var cacheCategoryID: String {
        return "category_" + self.tabID
    }

    init(userResolver: UserResolver,
         tabID: String,
         feedOrder: RawData.FeedOrder,
         manageMode: RawData.ManageMode,
         context: BaseMomentContext,
         userPushCenter: PushNotificationCenter) {
        self.tabID = tabID
        self.feedOrder = feedOrder
        super.init(userResolver: userResolver, context: context, manageMode: manageMode, userPushCenter: userPushCenter)
    }
    //获取数据
    override func fetchPosts(pageToken: String = "", count: Int32 = FeedList.pageCount) -> FeedApi.RxGetFeed {
        return feedApi?.getRecommendFeed(byCount: count,
                                        useLocal: false,
                                        pageToken: pageToken,
                                        tabID: tabID,
                                        feedOrder: feedOrder,
                                        manageMode: self.manageMode,
                                         isIOSMock: false).observeOn(queueManager.dataScheduler) ?? .empty()
    }
    override func businessType() -> String {
        return "category detail"
    }

    override func willRefreshPostData(posts: [RawData.PostEntity], byUserAction: Bool) -> PostTipStyle? {
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh") else { return nil }
        if posts.isEmpty {
            return byUserAction ? .empty : nil
        }
        /// 这里的key需要区分一下，方式跟feed的覆盖
        let postId = self.cellViewModels.first?.entityId ?? self.getUserStoreValueForKey(self.cacheCategoryID)
        Self.logger.info("willRefreshPostData -- old \(postId) - new \(posts.first?.id) -\(byUserAction)")
        self.saveUserStoreWith(key: self.cacheCategoryID, value: posts.first?.id ?? "")
        if let postId = postId {
            let res: PostTipStyle = (postId == posts.first?.id) ? .empty : .success
            if res == .empty, !byUserAction {
                return nil
            }
            return res
        }
        return .success
    }

    override func getPageType() -> MomentsTracer.PageType {
        return .category(tabID)
    }

    override func getPageDetail() -> MomentsTracer.PageDetail? {
        switch feedOrder {
        case .lastReplied:
            return .category_comment
        case .lastPublish:
            return .category_post
        case .recommend, .recommendV2:
            return .category_recommend
        case .unspecified:
            return nil
        @unknown default:
            return nil
        }
    }

    override func getFeedUpdateItem(isRefresh: Bool) -> MomentsFeedUpdateItem {

        let item = MomentsFeedUpdateItem(biz: .Moments,
                                         scene: .MoFeed,
                                         event: isRefresh ? .refreshFeed : .loadMoreFeed,
                                         page: "category")
        item.order = feedOrder.rawValue
        return item
    }
}
