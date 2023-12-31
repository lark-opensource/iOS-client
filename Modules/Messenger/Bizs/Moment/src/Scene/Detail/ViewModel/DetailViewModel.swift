//
//  DetailViewModel.swift
//  Moment
//
//  Created by zhuheng on 2021/1/7.
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
import RustPB
import LarkFeatureGating
import LarkSetting

final class DetailViewModel: AsyncDataProcessViewModel<Detail.TableRefreshType, [[MomentsCommentCellViewModel]]>, UserResolverWrapper {
    let userResolver: UserResolver
    static let nameSpace = "detail_name_space"
    static let logger = Logger.log(MomentFeedListViewModel.self, category: "Module.Moments.DetailViewModel")
    @ScopedInjectedLazy var detailApi: DetailApiService?
    @ScopedInjectedLazy private var postApi: PostApiService?
    @ScopedInjectedLazy private var entityDeletedNoti: EntityDeletedNotification?
    @ScopedInjectedLazy private var followingChangedNoti: FollowingChangedNotification?
    @ScopedInjectedLazy private var momentsUserNoti: MomentUserNotification?
    @ScopedInjectedLazy private var reactionSetNoti: ReactionSetNotification?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy private var commentStatusNoti: CommentStatusChangedNotification?
    @ScopedInjectedLazy private var commentSetNoti: CommentSetNotification?
    @ScopedInjectedLazy private var shareCountNoti: PostShareCountNotification?
    @ScopedInjectedLazy private var postIsBoardcast: PostIsBoardcastNotification?
    @ScopedInjectedLazy private var commentUpdatedNoti: CommentUpdatedNotification?
    @ScopedInjectedLazy private var translateNoti: MomentsTranslateNotification?
    @ScopedInjectedLazy private var draftService: MomentsDraftService?
    @ScopedInjectedLazy var anonymousConfigService: UserAnonymousConfigService?
    @ScopedInjectedLazy private var configService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var thumbsupReactionService: ThumbsupReactionService?
    @ScopedInjectedLazy var securityAuditService: MomentsSecurityAuditService?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?

    private lazy var inlinePreviewVM: MomentInlineViewModel = MomentInlineViewModel()

    private let inputs: Detail.Inputs
    private let postContext: BaseMomentContext
    private let commentContext: BaseMomentContext
    private let disposeBag = DisposeBag()
    private(set) var postCellViewModel: MomentPostCellViewModel?
    private var loadingMore: Bool = false
    private var nextPageToken: String = ""
    private var prePageToken: String = ""
    private let userPushCenter: PushNotificationCenter
    var circleConfig: RawData.UserCircleConfig?

    var manageMode: RawData.ManageMode {
        return circleConfig?.manageMode ?? .basic
    }

    var postLoading: Bool = true
    var commentsLoading: Bool = true
    private let commentSkeletonCount = 10 //默认10个占位骨架图 超出一屏
    let tracker = MomentsCommonTracker()
    var replyCommentId: String?

    var followable = false

    private lazy var getPostEntityCallBack: () -> RawData.PostEntity? = { [weak self] in
        return self?.postCellViewModel?.entity
    }

    //发评论后，后面通过接口可能还会拉取到，需要端上去重处理
    private var sendSuccessCommentIds: [String] = []

    private var commentCellViewModels: [[MomentsCommentCellViewModel]] = [[], []]

    private var hotCommentsCellViewModels: [MomentsCommentCellViewModel] {
        get {
            commentCellViewModels[Detail.SubIndexInComments.hot.rawValue]
        }
        set {
            commentCellViewModels[Detail.SubIndexInComments.hot.rawValue] = newValue
        }
    }

    private var normalCommentsCellViewModels: [MomentsCommentCellViewModel] {
        get {
            commentCellViewModels[Detail.SubIndexInComments.normal.rawValue]
        }
        set {
            commentCellViewModels[Detail.SubIndexInComments.normal.rawValue] = newValue
        }
    }

    private var uiNormalCommentsCellViewModels: [MomentsCommentCellViewModel] {
        return uiDataSource[Detail.SubIndexInComments.normal.rawValue]
    }

    private var uiHotCommentsCellViewModels: [MomentsCommentCellViewModel] {
        return uiDataSource[Detail.SubIndexInComments.hot.rawValue]
    }

    private var isEnableTrample: Bool {
        guard let momentsAccountService = self.momentsAccountService, !(self.momentsAccountService?.getCurrentUserIsOfficialUser() ?? false) else {
            //官方号不允许给别人点踩
            return false
        }
        return self.circleConfig?.enableDislike ?? false
    }

    /// 错误信号
    public let errorPub = PublishSubject<Detail.ErrorType>()
    public var errorDri: Driver<Detail.ErrorType> {
        return errorPub.asDriver(onErrorRecover: { _ in Driver<Detail.ErrorType>.empty() })
    }

    lazy var postId: String = {
        switch inputs {
        case .entity(let entity):
            return entity.post.id
        case .postID(let postID):
            return postID
        }
    }()

    init(userResolver: UserResolver, inputs: Detail.Inputs, userPushCenter: PushNotificationCenter, postContext: BaseMomentContext, commentContext: BaseMomentContext) {
        self.userResolver = userResolver
        self.inputs = inputs
        self.userPushCenter = userPushCenter
        self.postContext = postContext
        self.commentContext = commentContext
        super.init(uiDataSource: [[], []])
        self.observePush()
        let item = MomentsDetialItem(biz: .Moments, scene: .MoPost, event: .showDetail, page: "detail")
        self.tracker.startTrackWithItem(item)
    }

    func initCurrentCircle(_ finish: ((RawData.UserCircleConfig?) -> Void)?) {
        configService?.getUserCircleConfigWithFinsih({ config in
            self.circleConfig = config
            finish?(config)
        }, onError: { error in
            finish?(nil)
            Self.logger.error("getUserConfigAndSettingsRequest \(error)")
        })
    }

    private var viewType: Detail.ViewType {
        let isCommentInMiddle = !prePageToken.isEmpty
        if postCellViewModel != nil && !uiNormalCommentsCellViewModels.isEmpty && !isCommentInMiddle {
            return .all
        } else if postCellViewModel == nil && uiDataSource.isEmpty {
            return .empty
        } else if !uiNormalCommentsCellViewModels.isEmpty && isCommentInMiddle {
            return .onlyComment
        } else if postCellViewModel != nil && uiNormalCommentsCellViewModels.isEmpty {
            return .postAndHotComment
        }
        return .empty
    }

    var numberOfSections: Int {
        return 3
    }

    func numberOfRows(in section: Int) -> Int {
        switch viewType {
        case .all:
            if section == Detail.Sections.post {
                return 1
            } else if section == Detail.Sections.hotComments {
                return uiHotCommentsCellViewModels.count
            } else if section == Detail.Sections.comments {
                return uiNormalCommentsCellViewModels.count
            }
        case .empty:
            if section == Detail.Sections.post {
                return 1
            } else if section == Detail.Sections.hotComments {
                return 0
            } else if section == Detail.Sections.comments {
                if commentsLoading {
                    return commentSkeletonCount
                }
            }
        case .onlyComment:
            if section == Detail.Sections.comments {
                return uiNormalCommentsCellViewModels.count
            }
        case .postAndHotComment:
            if section == Detail.Sections.post {
                return 1
            } else if section == Detail.Sections.hotComments {
                return uiHotCommentsCellViewModels.count
            } else if section == Detail.Sections.comments {
                if commentsLoading {
                    return commentSkeletonCount
                }
            }
        }
        return 0
    }

    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Detail.Sections.post {
            if postLoading {
                return 300
            } else if let postCellViewModel = self.postCellViewModel {
                return postCellViewModel.renderer.size().height
            }
        } else if indexPath.section == Detail.Sections.hotComments {
            return uiHotCommentsCellViewModels[indexPath.row].renderer.size().height
        } else if indexPath.section == Detail.Sections.comments {
            if commentsLoading {
                return 128
            }
            return uiNormalCommentsCellViewModels[indexPath.row].renderer.size().height
        }
        return 0
    }

    func commentCellViewModelInForUI(indexPath: IndexPath) -> MomentsCommentCellViewModel? {
        if indexPath.section == Detail.Sections.hotComments {
            return uiHotCommentsCellViewModels[indexPath.row]
        } else if indexPath.section == Detail.Sections.comments {
            if commentsLoading {
                return nil
            }
            return uiNormalCommentsCellViewModels[indexPath.row]
        }
        return nil
    }

    func postCellViewModel(indexPath: IndexPath) -> MomentPostCellViewModel? {
        return self.postCellViewModel
    }

    func cellForRow(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Detail.Sections.post {
            if postLoading {
                return tableView.dequeueReusableCell(withIdentifier: PostInDetailSkeletonlTableViewCell.identifier, for: indexPath)
            } else if let cellVM = postCellViewModel {
                let cellId = cellVM.entity.post.id
                return cellVM.dequeueReusableCell(tableView, cellId: cellId)
            }
        } else if indexPath.section == Detail.Sections.hotComments {
            let cellVM = uiHotCommentsCellViewModels[indexPath.row]
            let cellId = cellVM.entity.comment.id
            return cellVM.dequeueReusableCell(tableView, cellId: cellId)
        } else if indexPath.section == Detail.Sections.comments {
            if commentsLoading {
                return tableView.dequeueReusableCell(withIdentifier: CommentSkeletonlTableViewCell.identifier, for: indexPath)
            } else {
                let cellVM = uiNormalCommentsCellViewModels[indexPath.row]
                let cellId = cellVM.entity.comment.id
                return cellVM.dequeueReusableCell(tableView, cellId: cellId)
            }
        }
        return UITableViewCell()
    }

    func loadFirstScreenData(scrollState: PostDetailScrollState?) {
        Self.logger.info("moment trace detail firstScreen start")
        let item = self.tracker.getItemWithEvent(.showDetail) as? MomentsDetialItem
        rxPostAndCommentsEntity()
            .observeOn(self.queueManager.dataScheduler)
            .flatMap({ [weak self] (info) -> DetailApi.RxListComments in
                guard let self = self, let post = info.0, let detailApi = self.detailApi else { return .empty() }
                item?.sdkCost = info.1?.timeCost ?? 0
                // 获取到本地数据
                if info.1 == nil {
                    item?.startLocalRenderTime = CACurrentMediaTime()
                } else {
                    item?.startRemoteRenderTime = CACurrentMediaTime()
                }
                // 帖子被删除的展示优先级 高于不支持的类型，优先展示被删除
                if self.showDelePageIfNeedForPost(post) {
                    return .empty()
                }
                // 详情页不支持的类型 直接弹框
                if self.isUnsupportTypeForPostEntity(post) {
                    Self.logger.info("moment trace detail firstScreen get post unsupportType \(post.post.type)")
                    self.publish(.unsupportType)
                    return .empty()
                }

                Self.logger.info("moment trace detail firstScreen get post \(post.post.id) \(post.hotComments.count)")
                self.postCellViewModel = MomentPostCellViewModel(userResolver: self.userResolver,
                                                                 postEntity: post,
                                                                 context: self.postContext,
                                                                 manageMode: self.manageMode,
                                                                 config: MomentPostCellConfig(contentNeedAlignAvatar: true,
                                                                                              needShowFollowBut: self.followable,
                                                                                              categoryLabelColor: UIColor.ud.textLinkNormal, topLayoutStyle: .vertical),
                                                                 isEnableTrample: self.isEnableTrample)
                self.hotCommentsCellViewModels = post.hotComments.map { MomentsCommentCellViewModel(userResolver: self.userResolver,
                                                                                                    commentEntity: $0,
                                                                                                    context: self.commentContext,
                                                                                                    getPostEntityCallBack: self.getPostEntityCallBack,
                                                                                                    isRecommend: self.manageMode == .recommendV2Mode)
                }
                MomentsTracer.trackDetailPageView(entity: post)
                self.publish(.postInitRefresh)
                if let listComments = info.2 {
                    return .just((nextPageToken: listComments.nextPageToken, comments: listComments.comments, post: nil, trackerInfo: nil))
                } else {
                    //接口不支持拉取指定区间，默认取100条 1.尽量保证要跳转的消息能覆盖到 2.发消息时，尽量能保证消息是在最后的
                    return detailApi.listComments(byCount: 100,
                                                  postId: post.id,
                                                  pageToken: self.nextPageToken)
                }
            })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (nextPageToken: String, comments: [RawData.CommentEntity], post: RawData.PostEntity?, trackerInfo: MomentsTrackerInfo?) in
                guard let self = self else { return }
                item?.commentStartRender = CACurrentMediaTime()
                self.normalCommentsCellViewModels = comments.map { MomentsCommentCellViewModel(userResolver: self.userResolver,
                    commentEntity: $0,
                                                                                               context: self.commentContext,
                                                                                               getPostEntityCallBack: self.getPostEntityCallBack,
                                                                                               isRecommend: self.manageMode == .recommendV2Mode)
                }
                if let post = post {
                    if self.showDelePageIfNeedForPost(post) {
                        self.userPushCenter.post(PushMomentPostByCommentList(post: post))
                        return
                    }
                    // 详情页不支持的类型 直接弹框
                    if self.isUnsupportTypeForPostEntity(post) {
                        self.publish(.unsupportType)
                        return
                    }
                    if let contentTranslation = self.postCellViewModel?.entity.post.translationInfo.contentTranslation {
                        post.post.translationInfo.contentTranslation = contentTranslation
                    }
                    if let urlPreviewTranslation = self.postCellViewModel?.entity.post.translationInfo.urlPreviewTranslation {
                        post.post.translationInfo.urlPreviewTranslation = urlPreviewTranslation
                    }
                    //最新的post信息会随commentList接口返回
                    self.postCellViewModel?.update(entity: post)
                    self.hotCommentsCellViewModels = post.hotComments.map { MomentsCommentCellViewModel(userResolver: self.userResolver,
                                                                                                        commentEntity: $0,
                                                                                                        context: self.commentContext,
                                                                                                        getPostEntityCallBack: self.getPostEntityCallBack,
                                                                                                        isRecommend: self.manageMode == .recommendV2Mode)
                    }
                    self.userPushCenter.post(PushMomentPostByCommentList(post: post))
                }
                self.nextPageToken = nextPageToken
                var scrollInfo: Detail.ScrollInfo?
                switch scrollState {
                case .toCommentId(let commentId):
                    if let commentId = commentId {
                        let indexPath: IndexPath
                        if let hotIndex = self.commentIndex(commentId, hotComment: true) {
                            indexPath = IndexPath(row: hotIndex, section: Detail.Sections.hotComments.rawValue)
                            scrollInfo = Detail.ScrollInfo(indexPath: indexPath,
                                                           tableScrollPosition: .top,
                                                           highlightCommentId: commentId)
                        } else if let commentIndex = self.commentIndex(commentId, hotComment: false) {
                            indexPath = IndexPath(row: commentIndex, section: Detail.Sections.comments.rawValue)
                            scrollInfo = Detail.ScrollInfo(indexPath: indexPath,
                                                           tableScrollPosition: .top,
                                                           highlightCommentId: commentId)
                        }
                    }
                case .toFirstComent:
                    if !self.commentCellViewModels[Detail.SubIndexInComments.hot.rawValue].isEmpty {
                        let indexPath = IndexPath(row: 0, section: Detail.Sections.hotComments.rawValue)
                        scrollInfo = Detail.ScrollInfo(indexPath: indexPath,
                                                       tableScrollPosition: .top,
                                                       highlightCommentId: nil)
                    } else if !self.commentCellViewModels[Detail.SubIndexInComments.normal.rawValue].isEmpty {
                        let indexPath = IndexPath(row: 0, section: Detail.Sections.comments.rawValue)
                        scrollInfo = Detail.ScrollInfo(indexPath: indexPath,
                                                       tableScrollPosition: .top,
                                                       highlightCommentId: nil)
                    }
                default:
                    break
                }
                Self.logger.info("moment trace detail firstScreen get comments \(self.postId) \(comments.count) \(nextPageToken) \(scrollInfo == nil)")
                self.publish(.firstScreenCommentRefresh(hasHeader: false, hasFooter: !nextPageToken.isEmpty, scrollTo: scrollInfo, sdkCost: trackerInfo?.timeCost ?? 0))
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace detail firstScreen fail \(self?.postId ?? "")", error: error)
                self?.errorPub.onNext(.fetchPostFail(error))
                MomentsErrorTacker.trackReciableEventError(error, sence: .MoPost, event: .showDetail, page: "detail")
                self?.trackDetailPageViewWhenFail()
            }).disposed(by: disposeBag)
    }

    func trackDetailPageViewWhenFail() {
        MomentsTracer.trackDetailPageViewWhenFail(postId: postId, circleId: circleConfig?.circleID)
    }

    private func rxPostAndCommentsEntity() -> Observable<(RawData.PostEntity?, MomentsTrackerInfo?, DetailApi.ListComments?)> {
        switch inputs {
        case .entity(let entity):
            return .just((entity, nil, nil))
        case .postID(let postID):
            guard let detailApi else { return .empty() }
            return self.detailApi?.listComments(byCount: 100,
                                               postId: postID,
                                               pageToken: self.nextPageToken)
                .map { (info) -> (RawData.PostEntity?, MomentsTrackerInfo?, DetailApi.ListComments?) in
                    return (info.post, info.trackerInfo, info)
                } ?? .empty()
        }
    }

    private func publish(_ type: Detail.TableRefreshType) {
        self.tableRefreshPublish.onNext((type, newDatas: self.commentCellViewModels, outOfQueue: false))
    }

    func loadTopComments(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
    }

    func loadMoreCommens(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore,
              let postId = postCellViewModel?.entity.post.id,
              !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace detail loadMoreCommens start \(postId)")
        detailApi?.listComments(byCount: Detail.commentPageCount, postId: postId, pageToken: nextPageToken)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (nextPageToken: String, comments: [RawData.CommentEntity], _, _) in
                guard let self = self else {
                    return
                }
                //转化为cellvm
                let viewModels = comments.filter { !self.sendSuccessCommentIds.contains($0.id) }
                    .map { MomentsCommentCellViewModel(userResolver: self.userResolver,
                                                       commentEntity: $0, context: self.commentContext, getPostEntityCallBack: self.getPostEntityCallBack,
                                                       isRecommend: self.manageMode == .recommendV2Mode)
                    }
                self.normalCommentsCellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = nextPageToken
                self.publish(.refreshTable(hasHeader: false, hasFooter: !nextPageToken.isEmpty, scrollTo: nil))
                self.loadingMore = false
                Self.logger.info("moment trace detail loadMoreCommens finish \(nextPageToken) \(comments.count)")
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.loadingMore = false
                self?.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace detail loadMoreCommens fail \(self?.postId ?? "")", error: error)
                finish(.error)
            }).disposed(by: disposeBag)
    }

    func createCommentByContent(_ content: RawData.RichText?, imageInfo: RawData.ImageInfo?, replyComment: RawData.CommentEntity?, isAnonymous: Bool) {
        guard let postEntity = self.postCellViewModel?.entity else {
            return
        }
        self.postApi?.createComment(byID: self.postCellViewModel?.entity.id ?? "",
                                   replyComment: replyComment?.comment,
                                   isAnonymous: isAnonymous,
                                   content: content,
                                   image: imageInfo,
                                   postOriginCommentSet: postEntity.post.commentSet)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (comment) in
                guard let self = self else { return }
                let commentCellVM = MomentsCommentCellViewModel(userResolver: self.userResolver,
                                                                commentEntity: comment,
                                                                context: self.commentContext,
                                                                getPostEntityCallBack: self.getPostEntityCallBack,
                                                                isRecommend: self.manageMode == .recommendV2Mode)
                self.normalCommentsCellViewModels.append(commentCellVM)
                self.publish(.publishComment)
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace detail createComment fail \(self?.postId ?? "")", error: error)
                self?.errorPub.onNext(.sendCommentFail(error))
            }).disposed(by: disposeBag)
    }

    func uploadPostView() {
        self.postApi?.uploadPostView(postId: postId).subscribe().disposed(by: self.disposeBag)
    }

    private func observePush() {
        self.entityDeletedNoti?
            .rxDeleteInfo
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (deleteInfo) in
                guard let self = self else { return }
                switch deleteInfo.entityType {
                case .post:
                    Self.logger.info("moment trace detail nof handle delete post \(deleteInfo.entityID) \(self.postId)")
                    if deleteInfo.entityID == self.postCellViewModel?.entity.id {
                        self.publish(.postDeletedBySelf)
                    }
                case .comment:
                    self.hotCommentsCellViewModels = self.hotCommentsCellViewModels.filter { (hotCommentCellVM) -> Bool in
                        if hotCommentCellVM.entity.id != deleteInfo.entityID {
                            if hotCommentCellVM.entity.replyCommentEntity?.comment.id == deleteInfo.entityID {
                                hotCommentCellVM.entity.replyCommentEntity?.comment.isDeleted = true
                                hotCommentCellVM.update(entity: hotCommentCellVM.entity)
                            }
                            return true
                        }
                        return false
                    }
                    self.normalCommentsCellViewModels = self.normalCommentsCellViewModels.filter({ (normalCommentCellVM) -> Bool in
                        if normalCommentCellVM.entity.id != deleteInfo.entityID {
                            if normalCommentCellVM.entity.replyCommentEntity?.comment.id == deleteInfo.entityID {
                                normalCommentCellVM.entity.replyCommentEntity?.comment.isDeleted = true
                                normalCommentCellVM.update(entity: normalCommentCellVM.entity)
                            }
                            return true
                        }
                        return false
                    })
                    Self.logger.info("moment trace detail nof handle delete comment \(self.postId)")
                    self.publish(.refresh)
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }).disposed(by: self.disposeBag)

        self.followingChangedNoti?
            .rxFollowingInfo
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (followingInfo) in
                guard let self = self, let postCellViewModel = self.postCellViewModel else { return }
                Self.logger.info("moment trace detail nof handle followChange \(self.postId)")
                let entity = postCellViewModel.entity
                if entity.user?.userID == followingInfo.targetUserID {
                    entity.user?.isCurrentUserFollowing = followingInfo.isCurrentUserFollowing
                    postCellViewModel.update(entity: entity)
                    Self.logger.info("moment trace detail nof handle refresh \(self.postId) \(followingInfo.isCurrentUserFollowing)")
                    self.publish(.refresh)
                }
            }).disposed(by: self.disposeBag)

        momentsUserNoti?.rxUserInfo
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (userInfo) in
                guard let self = self else { return }
                var needUpdate: Bool = false
                if let postCellVM = self.postCellViewModel, let newUser = userInfo.momentUsers[postCellVM.entity.user?.userID ?? ""] {
                    postCellVM.entity.user = newUser
                    postCellVM.update(entity: postCellVM.entity)
                    needUpdate = true
                }
                self.commentCellViewModels.forEach { (subCommentCellVMs) in
                    subCommentCellVMs.forEach { (cellVM) in
                        let entity = cellVM.entity
                        if let newUser = userInfo.momentUsers[entity.user?.userID ?? ""] {
                            entity.user = newUser
                            cellVM.update(entity: entity)
                            needUpdate = true
                        }
                    }
                }
                Self.logger.info("moment trace detail nof handle userInfo \(self.postId)")
                if needUpdate {
                    Self.logger.info("moment trace detail nof handle userInfo refresh \(self.postId)")
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        reactionSetNoti?.rxReactionSet
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (reactionInfo) in
                guard let self = self else { return }
                Self.logger.info("moment trace detail nof handle reactionSet \(self.postId) \(reactionInfo.id)")
                if let postCellVM = self.postCellViewModel, postCellVM.entity.id == reactionInfo.id {
                    postCellVM.entity.reactionListEntities = reactionInfo.reactionEntities
                    postCellVM.entity.post.reactionSet = reactionInfo.reactionSet
                    postCellVM.update(entity: postCellVM.entity)
                    Self.logger.info("moment trace detail nof handle reactionSet fresh for post \(self.postId) \(reactionInfo.reactionSet.totalCount)")
                    self.publish(.refresh)
                    return
                }
                self.commentCellViewModels.forEach { (subCommentCellVMs) in
                    subCommentCellVMs.forEach { (cellVM) in
                        let entity = cellVM.entity
                        if entity.id == reactionInfo.id {
                            entity.reactionListEntities = reactionInfo.reactionEntities
                            entity.comment.reactionSet = reactionInfo.reactionSet
                            cellVM.update(entity: entity)
                            Self.logger.info("moment trace detail nof handle reactionSet fresh for comment \(self.postId) \(reactionInfo.id) \(reactionInfo.reactionSet.totalCount)")
                            self.publish(.refresh)
                            return
                        }
                    }
                }
            }).disposed(by: disposeBag)

        commentStatusNoti?.rxCommentStatus
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (commentStatus) in
                guard let self = self else { return }
                Self.logger.info("moment trace detail nof handle commentStatus \(self.postId) \(commentStatus.localCommentID) \(commentStatus.createStatus.rawValue) \(commentStatus.successComment.id)")
                self.normalCommentsCellViewModels.forEach { (commentCellVM) in
                    let entity = commentCellVM.entity
                    entity.error = commentStatus.error
                    if entity.id == commentStatus.localCommentID {
                        if commentStatus.createStatus != .success {
                            if commentStatus.createStatus == .failed ||
                                commentStatus.createStatus == .error {
                                self.auditEvent(succeed: false, commentStatus: commentStatus)
                            }
                            entity.comment.localStatus = commentStatus.createStatus
                            commentCellVM.update(entity: entity)
                        } else {
                            self.auditEvent(succeed: true, commentStatus: commentStatus)
                            commentCellVM.update(entity: commentStatus.successComment)
                            self.sendSuccessCommentIds.append(commentStatus.successComment.id)
                        }
                        Self.logger.info("moment trace detail nof handle commentStatus refresh \(self.postId)")
                        self.publish(.refresh)
                        return
                    }
                }
            }).disposed(by: disposeBag)

        commentSetNoti?.rxCommentSet
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (commontSetInfo) in
                guard let self = self else { return }
                Self.logger.info("moment trace detail nof handle commentSet \(self.postId) \(commontSetInfo.entityID) \(commontSetInfo.commentSet.totalCount)")
                if let entity = self.postCellViewModel?.entity, entity.id == commontSetInfo.entityID {
                    entity.post.commentSet = commontSetInfo.commentSet
                    self.postCellViewModel?.update(entity: entity)
                    Self.logger.info("moment trace detail nof handle commentSet refresh \(self.postId)")
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        shareCountNoti?.rxShareCount
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (shareCountInfo) in
                guard let self = self else { return }
                Self.logger.info("moment trace detail nof handle shareCount \(self.postId) \(shareCountInfo.postID) \(shareCountInfo.shareCount)")
                if let entity = self.postCellViewModel?.entity, entity.id == shareCountInfo.postID {
                    entity.post.shareCount = shareCountInfo.shareCount
                    self.postCellViewModel?.update(entity: entity)
                    Self.logger.info("moment trace detail nof handle shareCount refresh \(self.postId)")
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        postIsBoardcast?.rxPostIsBoardcast
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (postBoardcastInfo) in
                guard let self = self else { return }
                Self.logger.info("moment trace detail nof postIsBoardcast handle \(postBoardcastInfo.postID)")
                if let entity = self.postCellViewModel?.entity, entity.id == postBoardcastInfo.postID {
                    entity.post.isBroadcast = postBoardcastInfo.isBroadcast
                    self.postCellViewModel?.update(entity: entity)
                    Self.logger.info("moment trace detail nof handle postIsBoardcast refresh \(self.postId)")
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        commentUpdatedNoti?.rxCommentUpdated
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] entity in
                guard let self = self else { return }
                var needUpdate = false
                Self.logger.info("moment trace detail nof commentUpdated handle \(entity.postId) -> \(entity.comment.id)")
                self.commentCellViewModels.forEach { cellVMs in
                    cellVMs.forEach { cellVM in
                        if cellVM.entity.comment.id == entity.comment.id {
                            cellVM.update(entity: entity)
                            needUpdate = true
                        }
                    }
                }
                if needUpdate {
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        inlinePreviewVM.subscribePush { [weak self] push in
            self?.queueManager.addDataProcess {
                guard let self = self else { return }
                let pair = push.inlinePreviewEntityPair
                var needUpdate = false
                // 更新post
                if let postEntity = self.postCellViewModel?.entity,
                   let newEntity = self.inlinePreviewVM.update(postEntity: postEntity, pair: pair) {
                    needUpdate = true
                    self.postCellViewModel?.update(entity: newEntity)
                    Self.logger.info("moment trace detail nof handle post inlinePreview refresh",
                                     additionalData: ["sourceID": "\(newEntity.post.id)",
                                                      "previewIDs": "\(newEntity.inlinePreviewEntities.keys)"])
                }
                // 更新comment
                self.commentCellViewModels.forEach { cellVMs in
                    cellVMs.forEach { cellVM in
                        let entity = cellVM.entity
                        if let newEntity = self.inlinePreviewVM.update(commentEntity: entity, pair: pair) {
                            needUpdate = true
                            cellVM.update(entity: newEntity)
                            Self.logger.info("moment trace detail nof handle post inlinePreview refresh",
                                             additionalData: ["sourceID": "\(newEntity.comment.id)",
                                                              "previewIDs": "\(newEntity.inlinePreviewEntities.keys)"])
                        }
                    }
                }
                if needUpdate {
                    self.publish(.refresh)
                }
            }
        }

        self.thumbsupReactionService?.thumbsupUpdate
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.postCellViewModel?.calculateRenderer()
                self.commentCellViewModels.forEach { cellVMs in
                    cellVMs.forEach { cellVM in
                        cellVM.calculateRenderer()
                    }
                }
                self.publish(.refresh)
            }).disposed(by: disposeBag)

        observeTranslatePush()
    }

    private func auditEvent(succeed: Bool, commentStatus: CommentStatusInfo) {
        let imageKeys = [commentStatus.successComment.comment.content.imageSet.origin.key]
        let commentId = commentStatus.successComment.id
        self.securityAuditService?.auditEvent(.momentsCreateComment(commentId: commentId,
                                                                    postId: self.postId,
                                                                    imageKeys: imageKeys,
                                                                    officialUserId: self.momentsAccountService?.getCurrentOfficialUser()?.userID),
                                              status: succeed ? .success : .fail)
    }

    private func observeTranslatePush() {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.client.translation") ?? false
        guard fgValue else { return }
        translateNoti?.rxTranslateEntities
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self, let translateNoti = self.translateNoti else { return }
                var needUpdate = false
                push.translationResults.forEach { result in
                    switch result.entityType {
                    case .comment:
                        self.commentCellViewModels.forEach { cellVMs in
                            cellVMs.forEach { cellVM in
                                if cellVM.entity.comment.id == result.entityID {
                                    var newEntity = cellVM.entity
                                    newEntity.comment.translationInfo = translateNoti.transEntityTranslationResultToTranslationInfo(
                                        oldInfo: newEntity.comment.translationInfo, result: result)
                                    newEntity.comment.contentLanguages = result.contentOriginalLanguages
                                    cellVM.update(entity: newEntity)
                                    needUpdate = true
                                }
                            }
                        }
                    case .post:
                        if let postVM = self.postCellViewModel,
                           postVM.entityId == result.entityID {
                            var newEntity = postVM.entity
                            newEntity.post.translationInfo = translateNoti.transEntityTranslationResultToTranslationInfo(
                                oldInfo: newEntity.post.translationInfo, result: result)
                            newEntity.safeContentLanguages = result.contentOriginalLanguages
                            self.postCellViewModel?.update(entity: newEntity)
                            needUpdate = true
                        }
                    @unknown default:
                        break
                    }
                }
                if needUpdate {
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        translateNoti?.rxTranslateUrlPreview
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                var needUpdate = false
                push.translationResults.forEach { result in
                    switch result.entityType {
                    case .comment:
                        self.commentCellViewModels.forEach { cellVMs in
                            cellVMs.forEach { cellVM in
                                if cellVM.entity.comment.id == result.entityID {
                                    var newEntity = cellVM.entity
                                    newEntity.comment.translationInfo.urlPreviewTranslation = result.urlPreviewTranslation
                                    cellVM.update(entity: newEntity)
                                    needUpdate = true
                                }
                            }
                        }
                    case .post:
                        if let postVM = self.postCellViewModel,
                           postVM.entityId == result.entityID {
                            var newEntity = postVM.entity
                            newEntity.post.translationInfo.urlPreviewTranslation = result.urlPreviewTranslation
                            self.postCellViewModel?.update(entity: newEntity)
                            needUpdate = true
                        }
                    @unknown default:
                        break
                    }
                }
                if needUpdate {
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)

        translateNoti?.rxHideTranslation
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                var needUpdate = false
                switch result.entityType {
                case .comment:
                    self.commentCellViewModels.forEach { cellVMs in
                        cellVMs.forEach { cellVM in
                            if cellVM.entity.comment.id == result.entityID {
                                var newEntity = cellVM.entity
                                newEntity.comment.translationInfo.translateStatus = .hidden
                                cellVM.update(entity: newEntity)
                                needUpdate = true
                            }
                        }
                    }
                case .post:
                    if let postVM = self.postCellViewModel,
                       postVM.entityId == result.entityID {
                        var newEntity = postVM.entity
                        newEntity.post.translationInfo.translateStatus = .hidden
                        self.postCellViewModel?.update(entity: newEntity)
                        needUpdate = true
                    }
                @unknown default:
                    break
                }
                if needUpdate {
                    self.publish(.refresh)
                }
            }).disposed(by: disposeBag)
    }

    private func commentIndex(_ id: String, hotComment: Bool) -> Int? {
        let partIndex = hotComment ? Detail.SubIndexInComments.hot.rawValue : Detail.SubIndexInComments.normal.rawValue
        return self.commentCellViewModels[partIndex].firstIndex { (cellVM) -> Bool in
            return cellVM.entity.id == id
        }
    }

    private func showDelePageIfNeedForPost(_ post: RawData.PostEntity) -> Bool {
        if post.post.isDeleted {
            Self.logger.info("moment trace detail firstScreen get post delete \(post.post.isDeleted) \(post.post.distributionType.rawValue)")
            self.publish(.postDelete)
            return true
        }
        return false
    }

    // 不支持的类型 或者incompatibleAction type = hide
    func isUnsupportTypeForPostEntity(_ postEntity: RawData.PostEntity) -> Bool {
        return postEntity.post.type == .unknown || (postEntity.post.hasIncompatibleAction && postEntity.post.incompatibleAction.type == .hide)
    }

    func cellVMDisplayStatusForIndexPath(_ indexPath: IndexPath, display: Bool) {

        if !postLoading, indexPath.section == Detail.Sections.post {
            if display {
                self.postCellViewModel?.willDisplay()
            } else {
                self.postCellViewModel?.didEndDisplay()
            }
            return
        }
        var cellVM: MomentsCommentCellViewModel?
        if indexPath.section == Detail.Sections.hotComments,
           indexPath.row < self.hotCommentsCellViewModels.count {
            cellVM = self.hotCommentsCellViewModels[indexPath.row]
        } else if !commentsLoading,
                  indexPath.section == Detail.Sections.comments,
                  indexPath.row < self.normalCommentsCellViewModels.count {
            cellVM = self.normalCommentsCellViewModels[indexPath.row]
        }
        if display {
            cellVM?.willDisplay()
        } else {
            cellVM?.didEndDisplay()
        }
    }

    func saveDraftWith(anonymous: Bool, richText: RustPB.Basic_V1_RichText?) {
        let key = MomentsDraftItem.draftKeyWith(postID: self.postId, commentID: nil)
        guard let richText = richText else {
            self.draftService?.removeValueForKey(key, nameSpace: Self.nameSpace)
            return
        }
        let json = MomentsDraftItem(anonymous: anonymous, content: richText, images: [], videos: []).stringify()
        self.draftService?.setValue(json, forKey: key, nameSpace: Self.nameSpace)
    }

    func getDraftWith(complete: ((Bool, RustPB.Basic_V1_RichText?) -> Void)?) {
        let key = MomentsDraftItem.draftKeyWith(postID: self.postId, commentID: nil)
        self.draftService?.valueForKey(key, nameSpace: Self.nameSpace) { (success, content) in
            if success, !content.isEmpty {
                let item = MomentsDraftItem.parse(content)
                complete?(item.anonymous, item.content)
            } else {
                complete?(false, nil)
            }
        }
    }

    func endTrackForShowDetailWith(sdkCost: TimeInterval?) {
        guard let item = self.tracker.getItemWithEvent(.showDetail) as? MomentsDetialItem else {
            return
        }
        if let sdkCost = sdkCost {
            item.updateDataWith(sdkCost: sdkCost, remoteRenderCost: CACurrentMediaTime() - item.commentStartRender)
        } else {
            item.endRender()
        }
        self.tracker.endTrackWithItem(item)
    }
}
extension DetailViewModel: DataSourceAPI {
    func lastReadPostId() -> String? {
        nil
    }
    func reloadRow(by indentifyId: String, animation: UITableView.RowAnimation) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            if let postCellVM = self.postCellViewModel, postCellVM.entity.id == indentifyId {
                let indexPath = IndexPath(row: 0, section: Detail.Sections.post.rawValue)
                self.publish(.refreshCell(indexs: [indexPath], animation: animation))
            } else {
                var indexPaths: [IndexPath] = []
                if let hotCommentIndex = self.commentIndex(indentifyId, hotComment: true) {
                    indexPaths.append(IndexPath(row: hotCommentIndex, section: Detail.Sections.hotComments.rawValue))
                }
                if let commentIndex = self.commentIndex(indentifyId, hotComment: false) {
                    indexPaths.append(IndexPath(row: commentIndex, section: Detail.Sections.comments.rawValue))
                }
                if !indexPaths.isEmpty {
                    self.publish(.refreshCell(indexs: indexPaths, animation: animation))
                }
            }
        }
    }

    func reloadData() {
        self.queueManager.addDataProcess { [weak self] in
            self?.publish(.refresh)
        }
    }

    func updatePostCellDislike(isSelfDislike: Bool?, postId: String) {
        self.queueManager.addDataProcess { [weak self] in
            if let isSelfDislike = isSelfDislike {
                self?.postCellViewModel?.entity.post.isSelfDisliked = isSelfDislike
            }
            self?.postCellViewModel?.calculateRenderer()
        }
        self.reloadRow(by: postId, animation: .none)
    }

    func pauseDataQueue(_ pause: Bool) {
        if pause {
            self.pauseQueue()
        } else {
            self.resumeQueue()
        }
    }
    func showPostFromCategory() -> Bool {
        return true
    }
    func getTrackValueForKey(_ key: MomentsTrackParamKey) -> Any? {
        switch key {
        case .pageIdInfo:
            return pageIdInfo()
        default:
            return nil
        }
    }
}

extension DetailViewModel {
    func trackDetailPageClick(_ clickType: MomentsTracer.DetailPageClickType) {
        MomentsTracer.trackDetailPageClick(clickType,
                                           circleId: postCellViewModel?.entity.circleId,
                                           postId: postCellViewModel?.entity.postId,
                                           pageIdInfo: pageIdInfo())
    }
    func pageIdInfo() -> MomentsTracer.PageIdInfo? {
        return postCellViewModel?.pageIdInfo()
    }
}
