//
//  UserFollowListViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/3/9.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkContainer
import LKCommonsLogging
import LarkMessageCore
import LarkAccountInterface

enum FollowListType: Int {
    /// 被关注
    case followers
    /// 关注
    case followings
}

final class UserFollowListContext {
    weak var pageVC: UIViewController?
    var circleId: String?
}
final class UserFollowListViewModel: AsyncDataProcessViewModel<UserFollowList.TableRefreshType, [FollowCellViewModel]>, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(UserFollowListViewModel.self, category: "Module.Moments.UserFollowListViewModel")
    private let disposeBag = DisposeBag()
    private var nextPageToken: String = ""
    private var cellViewModels: [FollowCellViewModel] = []
    private var loadingMore: Bool = false
    private var refreshing: Bool = false

    let type: FollowListType
    let userId: String
    let context: UserFollowListContext

    var title: String {
        switch type {
        case .followers:
            return BundleI18n.Moment.Lark_MomentFollowers_ListTitle
        case .followings:
            return BundleI18n.Moment.Lark_MomentFollowing_ListTitle
        }
    }

    @ScopedInjectedLazy private var profileApi: ProfileApiService?

    var isCurrentUser: Bool {
        return userResolver.userID == userId
    }
    /// 错误信号
    public let errorPub = PublishSubject<UserFollowList.ErrorType>()
    public var errorDri: Driver<UserFollowList.ErrorType> {
        return errorPub.asDriver(onErrorRecover: { _ in Driver<UserFollowList.ErrorType>.empty() })
    }

    init(userResolver: UserResolver, type: FollowListType, userID: String, context: UserFollowListContext) {
        self.userResolver = userResolver
        self.type = type
        self.userId = userID
        self.context = context
        super.init(uiDataSource: [])
    }

    //获取数据
    private func fetchUsers(pageToken: String = "", count: Int32 = UserFollowList.pageCount) -> ProfileApi.RxFollowResponse {
        guard let profileApi else { return .empty() }
        switch type {
        case .followers:
            return profileApi.getUserFollowersList(byCount: count, userId: self.userId, pageToken: pageToken).observeOn(queueManager.dataScheduler)
        case .followings:
            return profileApi.getUserFollowingsList(byCount: count, userId: self.userId, pageToken: pageToken).observeOn(queueManager.dataScheduler)
        }
    }

    func fetchFirstScreenData() {
        Self.logger.info("moment trace followList firstScreen start: is followers \(self.type == .followers)")
        fetchUsers()
            .subscribe(onNext: { [weak self] (nextPageToken: String, users: [MomentUser]) in
                guard let self = self else { return }
                Self.logger.info("moment trace followList firstScreen remoteData success \(nextPageToken) \(users.count) is followers \(self.type == .followers)")
                //转化为cellvm
                self.cellViewModels = users.map({ FollowCellViewModel(userResolver: self.userResolver, user: $0, context: self.context, followListType: self.type) })
                self.nextPageToken = nextPageToken
                self.publish(.remoteFirstScreenDataRefresh(hasFooter: !nextPageToken.isEmpty))
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("moment trace followList firstScreen remoteData fail: \(error) is followers \(self.type == .followers)")
                self.errorPub.onNext(.fetchFirstScreenDataFail(error))
            }).disposed(by: disposeBag)
    }

    private func publish(_ refreshType: UserFollowList.TableRefreshType) {
        self.tableRefreshPublish.onNext((refreshType, newDatas: self.cellViewModels, outOfQueue: false))
    }

    //获取更多
    func loadMoreData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore, !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace followList loadMore: is followers \(self.type == .followers)")
        fetchUsers(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, users: [MomentUser]) in
                guard let self = self else {
                    return
                }
                Self.logger.info("moment trace followList loadMore finish \(nextPageToken) \(users.count)")
                //转化为cellvm
                let viewModels = users.map({ FollowCellViewModel(userResolver: self.userResolver, user: $0, context: self.context, followListType: self.type) })
                self.cellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = nextPageToken
                self.publish(.refreshTable(hasFooter: !nextPageToken.isEmpty))
                self.loadingMore = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.loadingMore = false
                self?.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace followList loadMore fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    //从头刷新
    func refreshData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !refreshing else { return finish(.noWork) }
        refreshing = true
        nextPageToken = ""
        Self.logger.info("moment trace followList refresh start: is followers \(self.type == .followers)")
        fetchUsers(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, users: [MomentUser]) in
                guard let self = self else { return }
                //转化为cellvm
                let viewModels = users.map({ FollowCellViewModel(userResolver: self.userResolver, user: $0, context: self.context, followListType: self.type) })
                self.cellViewModels = viewModels
                self.nextPageToken = nextPageToken
                Self.logger.info("moment trace followList refresh finish \(nextPageToken) \(users.count)")
                self.publish(.refreshTable(needResetHeader: true, hasFooter: !nextPageToken.isEmpty))
                self.refreshing = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.refreshing = false
                self?.errorPub.onNext(.refreshListFail(error))
                Self.logger.error("moment trace followList refresh fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

}
