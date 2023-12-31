//
//  PostListBaseViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/3/14.
//

import UIKit
import RxSwift
import RxCocoa
import LarkContainer
import LKCommonsLogging
import LarkMessageCore
import LarkMenuController
import TangramService
import Foundation
import LarkFeatureGating
import LarkSetting
import ThreadSafeDataStructure

enum PostPushType {
    case delete
    case followingChange
    case user
    case status
    case reaction
    case comment
    case share
    case distribution
    case post
    case inlinePreview
}
final class PostListLogger {
    static let logger = Logger.log(PostListLogger.self, category: "Module.Moments.PostListLogger")
}

class PostListBaseObservePushViewModel<RefreshType: OuputTaskTypeInfo, T: Any>: AsyncDataProcessViewModel<RefreshType, [T]>, UserResolverWrapper {

    let userResolver: UserResolver
    let disposeBag = DisposeBag()
    /// 通知
    @ScopedInjectedLazy private var entityDeletedNoti: EntityDeletedNotification?
    @ScopedInjectedLazy private var followingChangedNoti: FollowingChangedNotification?
    @ScopedInjectedLazy private var momentsUserNoti: MomentUserNotification?
    @ScopedInjectedLazy private var postStatusNoti: PostStatusChangedNotification?
    @ScopedInjectedLazy private var reactionSetNoti: ReactionSetNotification?
    @ScopedInjectedLazy private var commentSetNoti: CommentSetNotification?
    @ScopedInjectedLazy private var shareCountNoti: PostShareCountNotification?
    @ScopedInjectedLazy private var postDistributionNoti: PostDistributionNotification?
    @ScopedInjectedLazy private var postUpdatedNoti: PostUpdatedNotification?
    @ScopedInjectedLazy private var translateNoti: MomentsTranslateNotification?
    lazy var inlinePreviewVM: MomentInlineViewModel = MomentInlineViewModel()
    let userPushCenter: PushNotificationCenter

    init(userResolver: UserResolver, userPushCenter: PushNotificationCenter) {
        self.userResolver = userResolver
        self.userPushCenter = userPushCenter
        super.init(uiDataSource: [])
        observerNotification()
    }

    /// 监听通知的逻辑 category
    func observerNotification() {
        if needHandlePushForType(.delete) {
            entityDeletedNoti?.rxDeleteInfo
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (deleteInfo) in
                    self?.onDeleInfoUpdate(deleteInfo: deleteInfo)
                }).disposed(by: disposeBag)
        }

        /// 用户关注状态改变
        if needHandlePushForType(.followingChange) {
            followingChangedNoti?.rxFollowingInfo
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (followingInfo) in
                    self?.onFollowingStatusUpdate(followingInfo: followingInfo)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.user) {
            /// 接口不保证User都有，后续会异步拉取，推送给端上
            momentsUserNoti?.rxUserInfo
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (userInfo) in
                    self?.onMomentUserUpdate(userInfo: userInfo)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.status) {
            /// 帖子状态的ID
            postStatusNoti?.rxPostStatus
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (postStatus) in
                    guard let self = self,
                          self.needHanderDataForCategoryIds([]) else { return }
                    self.onPostStatusUpdate(postStatus: postStatus)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.reaction) {
            reactionSetNoti?.rxReactionSet
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (reactionInfo) in
                    guard let self = self, self.needHanderDataForCategoryIds(reactionInfo.categoryIds) else { return }
                    self.onReactionSetUpdate(reactionInfo: reactionInfo)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.comment) {
            /// 发布评论 commontSetInfo
            commentSetNoti?.rxCommentSet
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (commontSetInfo) in
                    guard let self = self, self.needHanderDataForCategoryIds(commontSetInfo.categoryIds) else { return }
                    self.onCommentSetUpdate(commontSetInfo: commontSetInfo)
                }).disposed(by: disposeBag)
        }

        /// 分享数量的变化
        if needHandlePushForType(.share) {
            shareCountNoti?.rxShareCount
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (shareCountInfo) in
                    guard let self = self, self.needHanderDataForCategoryIds(shareCountInfo.categoryIds) else { return }
                    self.onShareCountUpdate(shareCountInfo: shareCountInfo)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.distribution) {
            /// 是否首页可见 visibilityInfo.categoryIDs
            postDistributionNoti?.rxPostDistribution
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (distributionInfo) in
                    self?.onPostDistributionUpdate(distributionInfo: distributionInfo)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.post) {
            let postUpdateHandler: (RawData.PostEntity) -> Void = { [weak self] entity in
                self?.onPostUpdate(entity: entity)
            }
            /// 本地推送
            userPushCenter.observable(for: PushMomentPostByCommentList.self)
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { (push) in
                    postUpdateHandler(push.post)
                }).disposed(by: disposeBag)

            /// 远端推送
            postUpdatedNoti?.rxPostUpdated
                .observeOn(queueManager.dataScheduler)
                .subscribe(onNext: { postEntity in
                    postUpdateHandler(postEntity)
                }).disposed(by: disposeBag)
        }

        if needHandlePushForType(.inlinePreview) {
            self.inlinePreviewVM.subscribePush { [weak self] push in
                self?.queueManager.addDataProcess { [weak self] in
                    self?.onInlinePreviewVMPush(push)
                }
            }
        }

        observerTranslateNotification()
    }

    private func observerTranslateNotification() {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.client.translation") ?? false
        guard fgValue, let translateNoti else { return }
        translateNoti.rxTranslateEntities
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                var needUpdate = false
                push.translationResults.forEach { result in
                    switch result.entityType {
                    case .comment:
                        if self.needHandlePushForType(.comment) {
                            var categoryID = result.entityPos.categoryID
                            var postID = result.entityPos.postID
                            self.update(targetCommentId: result.entityID,
                                        postID: postID.isEmpty ? nil : postID,
                                        categoryID: categoryID.isEmpty ? nil : categoryID) { entity in
                                entity.comment.translationInfo = translateNoti.transEntityTranslationResultToTranslationInfo(oldInfo: entity.comment.translationInfo, result: result)
                                entity.comment.contentLanguages = result.contentOriginalLanguages
                                return entity
                            }
                        }
                    case .post:
                        if self.needHandlePushForType(.post) {
                            var categoryID = result.entityPos.categoryID
                            self.update(targetPostId: result.entityID,
                                        categoryID: categoryID.isEmpty ? nil : categoryID) { entity in
                                entity.post.translationInfo = translateNoti.transEntityTranslationResultToTranslationInfo(oldInfo: entity.post.translationInfo, result: result)
                                entity.safeContentLanguages = result.contentOriginalLanguages
                                return entity
                            }
                        }
                    @unknown default:
                        break
                    }
                }
            }).disposed(by: disposeBag)

        translateNoti.rxTranslateUrlPreview
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                push.translationResults.forEach { result in
                    switch result.entityType {
                    case .comment:
                        if self.needHandlePushForType(.comment) {
                            var categoryID = result.entityPos.categoryID
                            var postID = result.entityPos.postID
                            self.update(targetCommentId: result.entityID,
                                        postID: postID.isEmpty ? nil : postID,
                                        categoryID: categoryID.isEmpty ? nil : categoryID) { entity in
                                entity.comment.translationInfo.urlPreviewTranslation = result.urlPreviewTranslation
                                return entity
                            }
                        }
                    case .post:
                        if self.needHandlePushForType(.post) {
                            var categoryID = result.entityPos.categoryID
                            self.update(targetPostId: result.entityID,
                                        categoryID: categoryID.isEmpty ? nil : categoryID) { entity in
                                entity.post.translationInfo.urlPreviewTranslation = result.urlPreviewTranslation
                                return entity
                            }
                        }
                    @unknown default:
                        break
                    }
                }
            }).disposed(by: disposeBag)

        translateNoti.rxHideTranslation
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                switch push.entityType {
                case .comment:
                    if self.needHandlePushForType(.comment) {
                        var categoryID = push.entityPos.categoryID
                        var postID = push.entityPos.postID
                        self.update(targetCommentId: push.entityID,
                                    postID: postID.isEmpty ? nil : postID,
                                    categoryID: categoryID.isEmpty ? nil : categoryID) { entity in
                            entity.comment.translationInfo.translateStatus = .hidden
                            return entity
                        }
                    }
                case .post:
                    if self.needHandlePushForType(.post) {
                        var categoryID = push.entityPos.categoryID
                        self.update(targetPostId: push.entityID,
                                    categoryID: categoryID.isEmpty ? nil : categoryID) { entity in
                            entity.post.translationInfo.translateStatus = .hidden
                            return entity
                        }
                    }
                @unknown default:
                    break
                }
            }).disposed(by: disposeBag)
    }

    func update(targetPostId: String, categoryID: String? = nil, doUpdate: (RawData.PostEntity) -> RawData.PostEntity?) {
    }

    func update(targetCommentId: String, postID: String? = nil, categoryID: String? = nil, doUpdate: (RawData.CommentEntity) -> RawData.CommentEntity?) {
    }

    func onDeleInfoUpdate(deleteInfo: RawData.DeletedInfoNof) {
    }

    func onFollowingStatusUpdate(followingInfo: RawData.FollowingInfoNof) {
    }

    func onMomentUserUpdate(userInfo: RawData.PushMomentsUserInfoNof) {
    }

    func onPostStatusUpdate(postStatus: PostStatusInfo) {
    }

    func onReactionSetUpdate(reactionInfo: RawData.ReactionSetNofEntity) {
    }

    func onCommentSetUpdate(commontSetInfo: RawData.CommentSetNof) {
    }

    func onShareCountUpdate(shareCountInfo: RawData.ShareCountNof) {
    }

    func onPostDistributionUpdate(distributionInfo: RawData.PostDistributionNof) {
    }

    func onPostUpdate(entity: RawData.PostEntity) {
    }

    func onInlinePreviewVMPush(_ push: URLPreviewPush) {
    }

    func needHandlePushForType(_ type: PostPushType) -> Bool {
        return true
    }

    func needHanderDataForCategoryIds(_ categoryIds: [String]) -> Bool {
        return true
    }
}

class PostListBaseViewModel<RefreshType: OuputTaskTypeInfo, ErrorType: Any>: PostListBaseObservePushViewModel<RefreshType, MomentPostCellViewModel> {
    static var logger: Log {
        return PostListLogger.logger
    }

    var cellViewModels: [MomentPostCellViewModel] = []
    var nextPageToken: String = ""
    var loadingMore: Bool = false
    var refreshing: Bool = false

    private var lastNewRecommendPostID: String? {
        get { _lastNewRecommendPostID.value }
        set { _lastNewRecommendPostID.value = newValue }
    }

    private var _lastNewRecommendPostID: SafeAtomic<String?> = nil + .semaphore

    @ScopedInjectedLazy var keyValueService: MomentsKeyValueStorageService?

    /// 错误信号
    public let errorPub = PublishSubject<ErrorType>()
    public var errorDri: Driver<ErrorType> {
        return errorPub.asDriver(onErrorRecover: { _ in Driver<ErrorType>.empty() })
    }

    func publish(_ type: RefreshType) {
        self.tableRefreshPublish.onNext((type, newDatas: self.cellViewModels, outOfQueue: false))
    }

    override func update(targetPostId: String, categoryID: String? = nil, doUpdate: (RawData.PostEntity) -> RawData.PostEntity?) {
        //如果传入了categoryID，则需要先判断categoryID
        if let categoryID = categoryID,
           !self.needHanderDataForCategoryIds([categoryID]) {
            return
        }

        for cellVM in self.cellViewModels {
            let entity = cellVM.entity
            if entity.id == targetPostId {
                if let newEntity = doUpdate(entity) {
                    cellVM.update(entity: newEntity)
                    self.refreshData()
                }
                break
            }
        }
    }

    override func update(targetCommentId: String, postID: String? = nil, categoryID: String? = nil, doUpdate: (RawData.CommentEntity) -> RawData.CommentEntity?) {
        //如果传入了categoryID，则需要先判断categoryID
        if let categoryID = categoryID,
           !self.needHanderDataForCategoryIds([categoryID]) {
            return
        }

        for cellVM in self.cellViewModels {
            let entity = cellVM.entity
            if postID == nil || entity.id == postID {
                for (i, comment) in entity.comments.enumerated() where comment.id == targetCommentId {
                    if let newComment = doUpdate(comment) {
                        entity.comments[i] = newComment
                        cellVM.update(entity: entity)
                        self.reloadData()
                    }
                    return
                }
            }
        }
    }

    func deletePostWith(id: String) {
        Self.logger.info("moment trace \(self.businessType()) nof handle delete post \(id)")
        self.cellViewModels = self.cellViewModels.filter { (cellModel) -> Bool in
            return cellModel.entity.post.id != id
        }
        self.refreshData()
    }

    override func onDeleInfoUpdate(deleteInfo: RawData.DeletedInfoNof) {
        switch deleteInfo.entityType {
        case .post:
            self.deletePostWith(id: deleteInfo.entityID)
        case .comment:
            var needUpdate = false
            for cellVM in self.cellViewModels {
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
            Self.logger.info("moment trace \(self.businessType()) nof handle delete comment \(deleteInfo.entityID)")
            if needUpdate {
                Self.logger.info("moment trace \(self.businessType()) nof handle delete comment refresh")
                self.refreshData()
            }
        case .unknown:
            return
        @unknown default:
            return
        }
    }

    override func onFollowingStatusUpdate(followingInfo: RawData.FollowingInfoNof) {
        var needPublish = false
        self.cellViewModels.forEach { (cellVM) in
            let entity = cellVM.entity
            if entity.user?.userID == followingInfo.targetUserID {
                entity.user?.isCurrentUserFollowing = followingInfo.isCurrentUserFollowing
                cellVM.update(entity: entity)
                needPublish = true
            }
        }
        Self.logger.info("moment trace \(self.businessType()) nof handle follow \(followingInfo.targetUserID) \(followingInfo.isCurrentUserFollowing)")
        if needPublish {
            Self.logger.info("moment trace \(self.businessType()) nof handle follow refresh")
            self.refreshData()
        }
    }

    override func onMomentUserUpdate(userInfo: RawData.PushMomentsUserInfoNof) {
        self.cellViewModels.forEach { (cellVM) in
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
            Self.logger.info("moment trace \(self.businessType()) nof handle userInfo")
            if needUpdate {
                Self.logger.info("moment trace \(self.businessType()) nof handle userInfo refresh")
                cellVM.update(entity: entity)
            }
        }
        self.refreshData()
    }

    override func onPostStatusUpdate(postStatus: PostStatusInfo) {
        Self.logger.info("moment trace \(self.businessType()) nof handle postStatus \(postStatus.localPostID) \(postStatus.createStatus.rawValue) \(postStatus.successPost.id)")
        self.update(targetPostId: postStatus.localPostID) { (entity) -> RawData.PostEntity? in
            Self.logger.info("moment trace \(self.businessType()) nof handle postStatus refresh")
            entity.error = postStatus.error
            if postStatus.createStatus != .success {
                entity.post.localStatus = postStatus.createStatus
                return entity
            } else {
                return postStatus.successPost
            }
        }
    }

    override func onReactionSetUpdate(reactionInfo: RawData.ReactionSetNofEntity) {
        Self.logger.info("moment trace \(self.businessType()) nof handle reactionSet \(reactionInfo.id)")
        self.update(targetPostId: reactionInfo.id) { (entity) -> RawData.PostEntity? in
            entity.reactionListEntities = reactionInfo.reactionEntities
            entity.post.reactionSet = reactionInfo.reactionSet
            Self.logger.info("moment trace \(self.businessType()) nof handle reactionSet refresh")
            return entity
        }
    }

    override func onCommentSetUpdate(commontSetInfo: RawData.CommentSetNof) {
        Self.logger.info("moment trace \(self.businessType()) nof handle commentSet \(commontSetInfo.entityID) \(commontSetInfo.commentSet.totalCount)")
        self.update(targetPostId: commontSetInfo.entityID) { (entity) -> RawData.PostEntity? in
            entity.post.commentSet = commontSetInfo.commentSet
            Self.logger.info("moment trace \(self.businessType()) nof handle commentSet refresh")
            return entity
        }
    }

    override func onShareCountUpdate(shareCountInfo: RawData.ShareCountNof) {
        Self.logger.info("moment trace \(self.businessType()) nof handle shareCount \(shareCountInfo.postID)")
        self.update(targetPostId: shareCountInfo.postID) { (entity) -> RawData.PostEntity? in
            entity.post.shareCount = shareCountInfo.shareCount
            Self.logger.info("moment trace \(self.businessType()) nof handle shareCount refresh")
            return entity
        }
    }

    override func onPostDistributionUpdate(distributionInfo: RawData.PostDistributionNof) {
        Self.logger.info("moment trace \(String(describing: self.businessType())) nof handle distribution \(distributionInfo.postID) \(distributionInfo.distributionType)")
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
        Self.logger.info("moment trace \(self.businessType()) nof handle pushMomentPostByCommentList \(entity.id)")
        self.update(targetPostId: entity.id) { (oldEntity) -> RawData.PostEntity? in
            Self.logger.info("moment trace \(self.businessType()) nof handle pushMomentPostByCommentList refresh")
            entity.post.translationInfo.contentTranslation = oldEntity.post.translationInfo.contentTranslation
            entity.post.translationInfo.urlPreviewTranslation = oldEntity.post.translationInfo.urlPreviewTranslation
            return entity
        }
    }

    override func onInlinePreviewVMPush(_ push: URLPreviewPush) {
        let pair = push.inlinePreviewEntityPair
        guard !pair.inlinePreviewEntities.isEmpty else { return }
        var needUpdate = false
        self.cellViewModels.forEach { cellVM in
            let entity = cellVM.entity
            if let newEntity = self.inlinePreviewVM.update(postEntity: entity, pair: pair) {
                Self.logger.info("moment trace \(self.businessType()) nof handle inlinePreview refresh",
                                 additionalData: ["sourceID": "\(newEntity.post.id)",
                                                  "previewIDs": "\(newEntity.inlinePreviewEntities.keys)"])
                cellVM.update(entity: newEntity)
                needUpdate = true
            }
        }
        if needUpdate {
            self.refreshData()
        }
    }

    func refreshData() {
        assertionFailure("子类需要重写")
    }

    func refreshCellsWith(indexPaths: [IndexPath], animation: UITableView.RowAnimation) {
        assertionFailure("子类需要重写")
    }

    func businessType() -> String {
        assertionFailure("子类需要重写")
        return ""
    }

    override func needHandlePushForType(_ type: PostPushType) -> Bool {
        return true
    }

    override func needHanderDataForCategoryIds(_ categoryIds: [String]) -> Bool {
        return true
    }

    func showPostFromCategory() -> Bool {
        return false
    }

    func getTrackValueForKey(_ key: MomentsTrackParamKey) -> Any? {
        return nil
    }

    /// 存储数据
    func saveUserStoreWith(key: String, value: String) {
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh") else { return }
        self.keyValueService?.userStore.set(value, forKey: key)
    }

    /// 获取结果
    func getUserStoreValueForKey(_ key: String) -> String? {
        return self.keyValueService?.userStore.string(forKey: key)
    }

    func updateLastNewRecommendPostID(_ postId: String?) {
        /// 如果FG为false 不存储结果
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh") else { return }
        self.lastNewRecommendPostID = postId
    }

    /// 上次阅读位置
    func lastReadPostId() -> String? {
        return self.lastNewRecommendPostID
    }
}

extension PostListBaseViewModel: DataSourceAPI {

    func updatePostCellDislike(isSelfDislike: Bool?, postId: String) {}

    func reloadRow(by indentifyId: String, animation: UITableView.RowAnimation) {
        self.queueManager.addDataProcess { [weak self] in
            if let index = self?.cellViewModels.firstIndex(where: { (cellVM) -> Bool in
                return cellVM.entity.id == indentifyId
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
