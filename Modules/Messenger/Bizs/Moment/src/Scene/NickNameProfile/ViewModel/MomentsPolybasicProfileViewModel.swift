//
//  MomentsPolybasicProfileViewModel.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import UIKit
import Foundation
import LarkMessageCore
import RxSwift
import RxRelay
import LarkContainer
import LarkMessengerInterface
import RxCocoa
import LarkAccountInterface
import LKCommonsLogging
import TangramService

protocol PolybasicCellViewModelProtocol: BaseMomentCellViewModel<BaseMomentContext> {
    var entityId: String { get }
    func showMenu(
        _ sender: UIView,
        location: CGPoint,
        triggerGesture: UIGestureRecognizer?)
}

final class MomentsPolybasicProfileViewModel: PostListBaseObservePushViewModel<UserPostList.TableRefreshType, PolybasicCellViewModelProtocol> {
    static let logger = Logger.log(MomentFeedListViewModel.self, category: "Module.Moments.MomentsPolybasicProfileViewModel")
    var cellViewModels: [PolybasicCellViewModelProtocol] = []
    /// 错误信号
    public let errorPub = PublishSubject<UserPostList.ErrorType>()
    public var errorDri: Driver<UserPostList.ErrorType> {
        return errorPub.asDriver(onErrorRecover: { _ in Driver<UserPostList.ErrorType>.empty() })
    }

    var isCurrentUser: Bool {
        guard self.userType == .user else {
            return false
        }
        return self.userId == self.userResolver.userID
    }

    /// 状态控制
    var nextPageToken: String = ""
    var loadingMore: Bool = false
    var refreshing: Bool = false
    let userId: String
    let userType: RawData.UserType
    let context: BaseMomentContext
    let showInNickNameContainer: Bool
    @ScopedInjectedLazy private var profileApi: ProfileApiService?

    init(userResolver: UserResolver,
         userId: String,
         userType: RawData.UserType,
         showInNickNameContainer: Bool,
         context: BaseMomentContext,
         userPushCenter: PushNotificationCenter) {
        self.userId = userId
        self.userType = userType
        self.context = context
        self.showInNickNameContainer = showInNickNameContainer
        super.init(userResolver: userResolver, userPushCenter: userPushCenter)
    }

    //获取推荐首屏数据
    func fetchFirstScreenPosts() {
        Self.logger.info("moment trace new profile firstScreen start")
        fetchPosts()
            .subscribe(onNext: { [weak self] (nextPageToken: String, activityEntrys: [RawData.ProfileActivityEntry]) in
                guard let self = self else { return }
                Self.logger.info("moment trace new profile firstScreen remoteData success \(nextPageToken) \(activityEntrys.count)")
                self.cellViewModels = activityEntrys.map { self.activityEntryToCellVM($0) }
                self.nextPageToken = nextPageToken
                self.publish(.remoteFirstScreenDataRefresh(hasFooter: !nextPageToken.isEmpty))
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace new profile firstScreen remoteData fail: \(error)")
                self?.errorPub.onNext(.fetchFirstScreenPostsFail(error, localDataSuccess: false))
                MomentsErrorTacker.trackReciableEventError(error, sence: .MoFeed, event: .momentsShowProfile, page: "profile")
            }).disposed(by: disposeBag)
    }

    //获取数据
    private func fetchPosts(pageToken: String = "", count: Int32 = 2 * UserPostList.pageCount) -> ProfileApi.RxGetActivityEntry {
        return self.profileApi?.getActivityEntry(byCount: count,
                                                pageToken: pageToken,
                                                userId: userId,
                                                 userType: userType) ?? .empty()
    }

    //获取更多
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore, !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace new profile loadMorePosts start")
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, activityEntrys: [RawData.ProfileActivityEntry]) in
                guard let self = self else {
                    return
                }
                Self.logger.info("moment trace new profile loadMorePosts finish \(nextPageToken) \(activityEntrys.count)")
                //转化为cellvm
                let viewModels = activityEntrys.map { self.activityEntryToCellVM($0) }
                self.cellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = nextPageToken
                self.publish(.refreshTable(hasFooter: !nextPageToken.isEmpty))
                self.loadingMore = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.loadingMore = false
                self?.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace new profile loadMorePosts fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    //从头刷新
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !refreshing else { return finish(.noWork) }
        refreshing = true
        nextPageToken = ""
        Self.logger.info("moment trace new profile refreshPosts start")
        fetchPosts(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, activityEntrys: [RawData.ProfileActivityEntry]) in
                guard let self = self else { return }
                //转化为cellvm
                let viewModels = activityEntrys.map { self.activityEntryToCellVM($0) }
                self.cellViewModels = viewModels
                self.nextPageToken = nextPageToken
                Self.logger.info("moment trace new profile refreshPosts finish \(nextPageToken) \(activityEntrys.count)")
                self.publish(.refreshTable(needResetHeader: true, hasFooter: !nextPageToken.isEmpty))
                self.refreshing = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.refreshing = false
                self?.errorPub.onNext(.refreshListFail(error))
                Self.logger.error("moment trace new profile refreshPosts fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    private func activityEntryToCellVM(_ activityEntry: RawData.ProfileActivityEntry) -> PolybasicCellViewModelProtocol {
        if let activityEntry = activityEntry.type.getBinderData() as? RawData.PublishPostEntry, let postEntity = activityEntry.postEntity {
            return MomentPostCellViewModel(userResolver: userResolver,
                                           postEntity: postEntity,
                                           context: self.context,
                                           manageMode: .recommendV2Mode)
        } else {
            return MomentsProfileActivityCellViewModel(userResolver: self.userResolver,
                                                       activityEntry: activityEntry,
                                                       context: self.context)
        }
    }

    func refreshData() {
        self.publish(.refresh)
    }

    func refreshCellsWith(indexPaths: [IndexPath], animation: UITableView.RowAnimation) {
        self.publish(.refreshCell(indexs: indexPaths, animation: animation))
    }

    func publish(_ type: UserPostList.TableRefreshType) {
        self.tableRefreshPublish.onNext((type, newDatas: self.cellViewModels, outOfQueue: false))
    }

    /// 监听各种样式的push
    override func needHandlePushForType(_ type: PostPushType) -> Bool {
        if type == .status {
            return false
        }
        return true
    }
    override func onDeleInfoUpdate(deleteInfo: RawData.DeletedInfoNof) {
        switch deleteInfo.entityType {
        case .post:
            self.deletePostWith(id: deleteInfo.entityID)
        case .comment:
            var needUpdate = false
            for cellVM in self.cellViewModels {
                if let cellVM = cellVM as? MomentPostCellViewModel {
                    let entity = cellVM.entity
                    entity.comments = entity.comments.filter { (comment) -> Bool in
                        if comment.id != deleteInfo.entityID {
                            if comment.replyCommentEntity?.id == deleteInfo.entityID {
                                comment.replyCommentEntity?.comment.isDeleted = true
                                needUpdate = true
                            }
                            return true
                        }
                        needUpdate = true
                        return false
                    }
                    if needUpdate {
                        cellVM.update(entity: entity)
                        break
                    }
                }
                Self.logger.info("moment trace new profile nof handle delete comment \(deleteInfo.entityID)")
                if needUpdate {
                    Self.logger.info("moment trace new profile nof handle delete comment refresh")
                    self.refreshData()
                }
            }
        case .unknown:
            return
        @unknown default:
            return
        }
    }

    private func deletePostWith(id: String) {
        self.cellViewModels = self.cellViewModels.filter { (cellModel) -> Bool in
            if let vm = cellModel as? MomentPostCellViewModel, vm.entity.post.id == id {
                return false
            }
            return true
        }
        self.refreshData()
    }

    override func onFollowingStatusUpdate(followingInfo: RawData.FollowingInfoNof) {
        var needPublish = false
        self.cellViewModels.forEach { (cellVM) in
            if let cellVM = cellVM as? MomentPostCellViewModel {
                let entity = cellVM.entity
                if entity.user?.userID == followingInfo.targetUserID {
                    entity.user?.isCurrentUserFollowing = followingInfo.isCurrentUserFollowing
                    cellVM.update(entity: entity)
                    needPublish = true
                }
            }
        }
        Self.logger.info("moment trace new profile nof handle follow \(followingInfo.targetUserID) \(followingInfo.isCurrentUserFollowing)")
        if needPublish {
            Self.logger.info("moment trace new profile nof handle follow refresh")
            self.refreshData()
        }
    }

    override func onMomentUserUpdate(userInfo: RawData.PushMomentsUserInfoNof) {
        self.cellViewModels.forEach { (cellVM) in
            if let cellVM = cellVM as? MomentPostCellViewModel {
                let entity = cellVM.entity
                var needUpdate: Bool = false
                if let newUser = userInfo.momentUsers[entity.user?.userID ?? ""] {
                    entity.user = newUser
                    needUpdate = true
                }
                for comment in entity.comments {
                    if let newUser = userInfo.momentUsers[comment.user?.userID ?? ""] {
                        comment.user = newUser
                        needUpdate = true
                    }
                }
                Self.logger.info("moment trace new profile nof handle userInfo")
                if needUpdate {
                    Self.logger.info("moment trace new profile nof handle userInfo refresh")
                    cellVM.update(entity: entity)
                }
            }
        }
        self.refreshData()
    }

    override func onPostStatusUpdate(postStatus: PostStatusInfo) {
        Self.logger.info("moment trace new profile nof handle postStatus \(postStatus.localPostID) \(postStatus.createStatus.rawValue) \(postStatus.successPost.id)")
        self.update(targetPostId: postStatus.localPostID) { (entity) -> RawData.PostEntity? in
            Self.logger.info("moment trace new profile nof handle postStatus refresh")
            entity.error = postStatus.error
            if postStatus.createStatus != .success {
                entity.post.localStatus = postStatus.createStatus
                return entity
            } else {
                return postStatus.successPost
            }
        }
    }

    override func update(targetPostId: String, categoryID: String? = nil, doUpdate: (RawData.PostEntity) -> RawData.PostEntity?) {
        //如果传入了categoryID，则需要先判断categoryID
        if let categoryID = categoryID,
           !self.needHanderDataForCategoryIds([categoryID]) {
            return
        }

        var needToUpdate = false
        for cellVM in self.cellViewModels {
            if let cellVM = cellVM as? MomentPostCellViewModel {
                let entity = cellVM.entity
                if entity.id == targetPostId {
                    if let newEntity = doUpdate(entity) {
                        cellVM.update(entity: newEntity)
                        needToUpdate = true
                    }
                }
            } else if let cellVM = cellVM as? MomentsProfileActivityCellViewModel {
                if cellVM.updateActivityEntryIfNeed(targetPostId: targetPostId, doUpdate: doUpdate) {
                    needToUpdate = true
                }
            }
        }
        if needToUpdate {
            self.refreshData()
        }
    }

    override func update(targetCommentId: String, postID: String? = nil, categoryID: String? = nil, doUpdate: (RawData.CommentEntity) -> RawData.CommentEntity?) {
        //如果传入了categoryID，则需要先判断categoryID
        if let categoryID = categoryID,
           !self.needHanderDataForCategoryIds([categoryID]) {
            return
        }

        var needToUpdate = false
        for cellVM in self.cellViewModels {
            if let cellVM = cellVM as? MomentsProfileActivityCellViewModel {
                if cellVM.updateActivityEntryIfNeed(targetCommentId: targetCommentId, doUpdate: doUpdate) {
                    needToUpdate = true
                }
            } else if let cellVM = cellVM as? MomentPostCellViewModel {
                if postID == nil || cellVM.entityId == postID {
                    for (i, comment) in cellVM.entity.comments.enumerated() {
                        if comment.id == targetCommentId,
                           let newComment = doUpdate(comment) {
                            var entity = cellVM.entity
                            entity.comments[i] = newComment
                            cellVM.update(entity: entity)
                            needToUpdate = true
                        }
                    }
                }
            }
        }
        if needToUpdate {
            self.refreshData()
        }
    }

    override func onReactionSetUpdate(reactionInfo: RawData.ReactionSetNofEntity) {
        Self.logger.info("moment trace new profile nof handle reactionSet \(reactionInfo.id)")
        self.update(targetPostId: reactionInfo.id) { (entity) -> RawData.PostEntity? in
            entity.reactionListEntities = reactionInfo.reactionEntities
            entity.post.reactionSet = reactionInfo.reactionSet
            Self.logger.info("moment trace new profile nof handle reactionSet refresh")
            return entity
        }
    }

    override func onCommentSetUpdate(commontSetInfo: RawData.CommentSetNof) {
        Self.logger.info("moment trace new profile nof handle commentSet \(commontSetInfo.entityID) \(commontSetInfo.commentSet.totalCount)")
        self.update(targetPostId: commontSetInfo.entityID) { (entity) -> RawData.PostEntity? in
            entity.post.commentSet = commontSetInfo.commentSet
            Self.logger.info("moment trace new profile nof handle commentSet refresh")
            return entity
        }
    }

    override func onShareCountUpdate(shareCountInfo: RawData.ShareCountNof) {
        Self.logger.info("moment trace new profile nof handle shareCount \(shareCountInfo.postID)")
        self.update(targetPostId: shareCountInfo.postID) { (entity) -> RawData.PostEntity? in
            entity.post.shareCount = shareCountInfo.shareCount
            Self.logger.info("moment trace new profile nof handle shareCount refresh")
            return entity
        }
    }

    override func onPostDistributionUpdate(distributionInfo: RawData.PostDistributionNof) {
        Self.logger.info("moment trace new profile nof handle distribution \(distributionInfo.postID) \(distributionInfo.distributionType)")
        guard distributionInfo.distributionType == .notDistribution,
              self.needHanderDataForCategoryIds(distributionInfo.categoryIds) else { return }
        /// 设置从首页移除后, 不需要对帖子进行移除。 只有管理员可以对帖子操作，如果移除了后续管理员无法进行其他操作
        self.update(targetPostId: distributionInfo.postID) { postEntity in
            postEntity.post.distributionType = distributionInfo.distributionType
            return postEntity
        }
    }

    override func onPostUpdate(entity: RawData.PostEntity) {
        guard self.needHanderDataForCategoryIds(entity.post.categoryIds) else { return }
        if entity.post.isDeleted {
            self.deletePostWith(id: entity.id)
            return
        }
        Self.logger.info("moment trace new profile nof handle pushMomentPostByCommentList \(entity.id)")
        self.update(targetPostId: entity.id) { (_) -> RawData.PostEntity? in
            Self.logger.info("moment trace new profile nof handle pushMomentPostByCommentList refresh")
            return entity
        }
    }

    override func onInlinePreviewVMPush(_ push: URLPreviewPush) {
        let pair = push.inlinePreviewEntityPair
        guard !pair.inlinePreviewEntities.isEmpty else { return }
        var needUpdate = false
        self.cellViewModels.forEach { cellVM in
            if let cellVM = cellVM as? MomentPostCellViewModel {
                let entity = cellVM.entity
                if let newEntity = self.inlinePreviewVM.update(postEntity: entity, pair: pair) {
                    Self.logger.info("moment trace new profile nof handle inlinePreview refresh",
                                     additionalData: ["sourceID": "\(newEntity.post.id)",
                                                      "previewIDs": "\(newEntity.inlinePreviewEntities.keys)"])
                    cellVM.update(entity: newEntity)
                    needUpdate = true
                }
            }
        }
        if needUpdate {
            self.refreshData()
        }
    }
}

extension MomentsPolybasicProfileViewModel: DataSourceAPI {
    func lastReadPostId() -> String? {
        nil
    }

    func updatePostCellDislike(isSelfDislike: Bool?, postId: String) { }

    func showPostFromCategory() -> Bool {
        return true
    }

    func getTrackValueForKey(_ key: MomentsTrackParamKey) -> Any? {
        return nil
    }

    func reloadRow(by indentifyId: String, animation: UITableView.RowAnimation) {
        self.queueManager.addDataProcess { [weak self] in
            if let index = self?.cellViewModels.firstIndex(where: { (cellVM) -> Bool in
                return cellVM.entityId == indentifyId
            }) {
                let indexPath = IndexPath(row: index, section: 0)
                self?.refreshCellsWith(indexPaths: [indexPath], animation: animation)
            }
        }
    }

    func pauseDataQueue(_ pause: Bool) {
        if pause {
            self.pauseQueue()
        } else {
            self.resumeQueue()
        }
    }

    func reloadData() {
        self.queueManager.addDataProcess { [weak self] in
            self?.refreshData()
        }
    }
}
