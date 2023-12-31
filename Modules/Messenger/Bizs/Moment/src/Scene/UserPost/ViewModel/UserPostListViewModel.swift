//
//  UserPostListViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/14.
//
import UIKit
import Foundation
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkMessageCore

class UserPostListViewModel: PostListBaseViewModel<UserPostList.TableRefreshType, UserPostList.ErrorType> {

    @ScopedInjectedLazy private var profileApi: ProfileApiService?
    @ScopedInjectedLazy var configService: MomentsConfigAndSettingService?
    let userId: String
    ///TODO: 李洛斌 后续优化 postCellVM感觉应该由外界传入样式 直接传入manageMode不太好
    /// 旧的profile页不需要展示新的样式 都展示老的样式
    private let manageMode: RawData.ManageMode = .basic
    let context: BaseMomentContext
    let tracker: MomentsCommonTracker = MomentsCommonTracker()
    var circleId: String?
    init(userResolver: UserResolver, userId: String, context: BaseMomentContext, userPushCenter: PushNotificationCenter) {
        self.userId = userId
        self.context = context
        let item = MomentsProfileItem(biz: .Moments, scene: .MoProfile, event: .momentsShowProfile, page: "profile")
        self.tracker.startTrackWithItem(item)
        super.init(userResolver: userResolver, userPushCenter: userPushCenter)
        getCurrentCircle()
    }
    func getCurrentCircle() {
        configService?.getUserCircleConfigWithFinsih({ [weak self] (config) in
            self?.circleId = config.circleID
        }, onError: nil)
    }

    //获取推荐首屏数据
    func fetchFirstScreenPosts() {
        Self.logger.info("moment trace profile firstScreen start")
        let item = self.tracker.getItemWithEvent(.momentsShowProfile) as? MomentsProfileItem
        fetchPosts()
            .subscribe(onNext: { [weak self] (nextPageToken: String, posts: [RawData.PostEntity], trackerInfo: MomentsTrackerInfo) in
                guard let self = self else { return }
                item?.startRemoteProfileListRender = CACurrentMediaTime()
                item?.sdkProfileListCost = trackerInfo.timeCost
                Self.logger.info("moment trace profile firstScreen remoteData success \(nextPageToken) \(posts.count)")
                //转化为cellvm
                self.cellViewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver,
                                                                          postEntity: $0, context: self.context, manageMode: self.manageMode)
                }
                self.nextPageToken = nextPageToken
                self.publish(.remoteFirstScreenDataRefresh(hasFooter: !nextPageToken.isEmpty))
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace profile firstScreen remoteData fail: \(error)")
                self?.errorPub.onNext(.fetchFirstScreenPostsFail(error, localDataSuccess: false))
                MomentsErrorTacker.trackReciableEventError(error, sence: .MoFeed, event: .momentsShowProfile, page: "profile")
            }).disposed(by: disposeBag)
    }

    //获取数据
    private func fetchPosts(pageToken: String = "", count: Int32 = UserPostList.pageCount) -> ProfileApi.RxGetPost {
        return self.profileApi?.getUserPost(byCount: count,
                                           pageToken: pageToken,
                                            userId: self.userId).observeOn(queueManager.dataScheduler) ?? .empty()
    }

    //获取更多
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore, !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace profile loadMorePosts start")
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, posts: [RawData.PostEntity], _) in
                guard let self = self else {
                    return
                }
                Self.logger.info("moment trace profile loadMorePosts finish \(nextPageToken) \(posts.count)")
                //转化为cellvm
                let viewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver,
                                                                     postEntity: $0, context: self.context, manageMode: self.manageMode)
                }
                self.cellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = nextPageToken
                self.publish(.refreshTable(hasFooter: !nextPageToken.isEmpty))
                self.loadingMore = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.loadingMore = false
                self?.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace profile loadMorePosts fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    //从头刷新
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !refreshing else { return finish(.noWork) }
        refreshing = true
        nextPageToken = ""
        Self.logger.info("moment trace profile refreshPosts start")
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, posts: [RawData.PostEntity], _) in
                guard let self = self else { return }
                //转化为cellvm
                let viewModels = posts.map { MomentPostCellViewModel(userResolver: self.userResolver,
                                                                     postEntity: $0, context: self.context, manageMode: self.manageMode)
                }
                self.cellViewModels = viewModels
                self.nextPageToken = nextPageToken
                Self.logger.info("moment trace profile refreshPosts finish \(nextPageToken) \(posts.count)")
                self.publish(.refreshTable(needResetHeader: true, hasFooter: !nextPageToken.isEmpty))
                self.refreshing = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.refreshing = false
                self?.errorPub.onNext(.refreshListFail(error))
                Self.logger.error("moment trace profile refreshPosts fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    func endTrackForShowProfile() {
        let item = self.tracker.getItemWithEvent(.momentsShowProfile) as? MomentsProfileItem
        item?.endRemoteProfileListRenderCost()
        self.tracker.endTrackWithItem(item)
    }

    override func businessType() -> String {
        return "profile"
    }
    override func refreshData() {
        self.publish(.refresh)
    }
    override func refreshCellsWith(indexPaths: [IndexPath], animation: UITableView.RowAnimation) {
        self.publish(.refreshCell(indexs: indexPaths, animation: animation))
    }

    override func deletePostWith(id: String) {
        super.deletePostWith(id: id)
        self.publish(.delePost)
    }

    override func needHandlePushForType(_ type: PostPushType) -> Bool {
        if type == .status {
            return false
        }
        return true
    }
    override func showPostFromCategory() -> Bool {
        return true
    }
}
