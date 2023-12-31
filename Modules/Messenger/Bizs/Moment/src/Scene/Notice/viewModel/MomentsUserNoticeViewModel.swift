//
//  MomentsUserNoticeViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting

final class MomentsUserNoticeViewModel: AsyncDataProcessViewModel<NoticeList.TableRefreshType, [MomentsNoticeBaseCellViewModel]>, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentsUserNoticeViewModel.self, category: "Module.Moments.MomentsUserNoticeViewModel")
    private var cellViewModels: [MomentsNoticeBaseCellViewModel] = []
    private let context: NoticeContext

    @ScopedInjectedLazy private var configService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy var noticeApi: NoticeApiService?
    @ScopedInjectedLazy private var translateNoti: MomentsTranslateNotification?
    private let disposeBag = DisposeBag()
    private var nextPageToken: String = ""
    let tracker: MomentsCommonTracker = MomentsCommonTracker()
    private var loadingMore: Bool = false
    private var refreshing: Bool = false
    /// 错误信号
    public let errorPub = PublishSubject<NoticeList.ErrorType>()
    public var errorDri: Driver<NoticeList.ErrorType> {
        return errorPub.asDriver(onErrorRecover: { _ in Driver<NoticeList.ErrorType>.empty() })
    }
    @ScopedInjectedLazy var badgeNoti: MomentBadgePushNotification?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?

    let sourceType: NoticeList.SourceType
    let circleId: String?
    var followable = true

    init(userResolver: UserResolver, type: NoticeList.SourceType, context: NoticeContext, circleId: String?) {
        self.userResolver = userResolver
        self.sourceType = type
        self.context = context
        self.circleId = circleId
        super.init(uiDataSource: [])
        let item = MomentsNotificationItem(biz: .Moments, scene: .MoNotification, event: .showNotification, page: "notification", type: type)
        self.tracker.startTrackWithItem(item)

        configTranslateNotification()
    }

    func configTranslateNotification() {
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
                        for cellVM in self.cellViewModels {
                            if cellVM.updateNoticeEntityIfNeed(targetCommentId: result.entityID) { comment in
                                var comment = comment
                                comment.translationInfo = translateNoti.transEntityTranslationResultToTranslationInfo(oldInfo: comment.translationInfo, result: result)
                                comment.contentLanguages = result.contentOriginalLanguages
                                return comment
                            } {
                                needUpdate = true
                            }
                        }
                    case .post:
                        for cellVM in self.cellViewModels {
                            if cellVM.updateNoticeEntityIfNeed(targetPostId: result.entityID) { entity in
                                entity.post.translationInfo = translateNoti.transEntityTranslationResultToTranslationInfo(oldInfo: entity.post.translationInfo, result: result)
                                entity.safeContentLanguages = result.contentOriginalLanguages
                                return entity
                            } {
                                needUpdate = true
                            }
                        }
                    @unknown default:
                        break
                    }
                }
                if needUpdate {
                    self.publish(.onlyRefresh)
                }
            }).disposed(by: disposeBag)

        translateNoti.rxTranslateUrlPreview
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                var needUpdate = false
                push.translationResults.forEach { result in
                    switch result.entityType {
                    case .comment:
                        for cellVM in self.cellViewModels {
                            if cellVM.updateNoticeEntityIfNeed(targetCommentId: result.entityID) { comment in
                                var comment = comment
                                comment.translationInfo.urlPreviewTranslation = result.urlPreviewTranslation
                                return comment
                            } {
                                needUpdate = true
                            }
                        }
                    case .post:
                        for cellVM in self.cellViewModels {
                            if cellVM.updateNoticeEntityIfNeed(targetPostId: result.entityID) { entity in
                                entity.post.translationInfo.urlPreviewTranslation = result.urlPreviewTranslation
                                return entity
                            } {
                                needUpdate = true
                            }
                        }
                    @unknown default:
                        break
                    }
                }
                if needUpdate {
                    self.publish(.onlyRefresh)
                }
            }).disposed(by: disposeBag)

        translateNoti.rxHideTranslation
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                var needUpdate = false
                switch result.entityType {
                case .comment:
                    for cellVM in self.cellViewModels {
                        if cellVM.updateNoticeEntityIfNeed(targetCommentId: result.entityID) { comment in
                            var comment = comment
                            comment.translationInfo.translateStatus = .hidden
                            return comment
                        } {
                            needUpdate = true
                        }
                    }
                case .post:
                    for cellVM in self.cellViewModels {
                        if cellVM.updateNoticeEntityIfNeed(targetPostId: result.entityID) { entity in
                            entity.post.translationInfo.translateStatus = .hidden
                            return entity
                        } {
                            needUpdate = true
                        }
                    }
                @unknown default:
                    break
                }
                if needUpdate {
                    self.publish(.onlyRefresh)
                }
            }).disposed(by: disposeBag)
    }

    func getCurrentCircle(_ finish: ((RawData.UserCircleConfig?) -> Void)?) {
        configService?.getUserCircleConfigWithFinsih({ config in
            finish?(config)
        }, onError: { error in
            finish?(nil)
            Self.logger.error("getUserConfigAndSettingsRequest \(error)")
        })
    }
    //获取推荐首屏数据
    func fetchFirstScreenData() {
        Self.logger.info("moment trace noticeList firstScreen start")
        let item = self.tracker.getItemWithEvent(.showNotification) as? MomentsNotificationItem
        fetchNotices()
            .subscribe(onNext: { [weak self] (nextPageToken: String, entitys: [RawData.NoticeEntity], trackerInfo: MomentsTrackerInfo) in
                guard let self = self else { return }
                item?.sdkCost = trackerInfo.timeCost
                item?.startRender()
                Self.logger.info("moment trace noticeList firstScreen remoteData success \(nextPageToken) \(entitys.count)")
                //转化为cellvm
                self.cellViewModels = entitys.map({ (data) -> MomentsNoticeBaseCellViewModel in
                    return self.cellVMWithNoticeEntity(data)
                })
                self.nextPageToken = nextPageToken
                /// 当前页已经加载完了，没有更多了
                self.publish(.remoteFirstScreenDataRefresh(hasFooter: !nextPageToken.isEmpty))
            }, onError: { [weak self] (error) in
                Self.logger.error("moment trace noticeList firstScreen remoteData fail ", error: error)
                self?.errorPub.onNext(.fetchFirstScreenDataFail(error))
                MomentsErrorTacker.trackReciableEventError(error, sence: .MoNotification, event: .showNotification, page: "notification")
            }).disposed(by: disposeBag)
    }

    //获取数据
    private func fetchNotices(pageToken: String = "", count: Int32 = NoticeList.pageCount) -> NoticeApi.RxGetNotice {
        return noticeApi?.getListNotificationsWithType(self.sourceType, pageToken: pageToken, count: count).observeOn(queueManager.dataScheduler) ?? .empty()
    }

    private func publish(_ type: NoticeList.TableRefreshType) {
        self.tableRefreshPublish.onNext((type, newDatas: self.cellViewModels, outOfQueue: false))
    }

    //获取更多
    func loadMoreNotices(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !loadingMore, !nextPageToken.isEmpty else { return finish(.noWork) }
        loadingMore = true
        Self.logger.info("moment trace feedList loadMorePosts start")
        fetchNotices(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, entitys: [RawData.NoticeEntity], _) in
                guard let self = self else {
                    return
                }
                Self.logger.info("moment trace feedList loadMorePosts finish \(nextPageToken) \(entitys.count)")
                //转化为cellvm
                let viewModels: [MomentsNoticeBaseCellViewModel] = entitys.map { (data) -> MomentsNoticeBaseCellViewModel in
                    return self.cellVMWithNoticeEntity(data)
                }
                self.cellViewModels.append(contentsOf: viewModels)
                self.nextPageToken = nextPageToken
                self.publish(.refreshTable(hasFooter: !nextPageToken.isEmpty))
                self.loadingMore = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.loadingMore = false
                self?.errorPub.onNext(.loadMoreFail(error))
                Self.logger.error("moment trace feedList loadMorePosts fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    //从头刷新
    func refreshNotices(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        guard !refreshing else { return finish(.noWork) }
        refreshing = true
        nextPageToken = ""
        Self.logger.info("moment trace noticeList refreshPosts start")
        fetchNotices(pageToken: nextPageToken)
            .subscribe(onNext: { [weak self] (nextPageToken: String, entitys: [RawData.NoticeEntity], _) in
                guard let self = self else { return }
                //转化为cellvm
                let viewModels: [MomentsNoticeBaseCellViewModel] = entitys.map { (data) -> MomentsNoticeBaseCellViewModel in
                    return self.cellVMWithNoticeEntity(data)
                }
                self.cellViewModels = viewModels
                self.nextPageToken = nextPageToken
                Self.logger.info("moment trace noticeList refreshPosts finish \(nextPageToken) \(entitys.count)")
                self.publish(.refreshTable(needResetHeader: true, hasFooter: !nextPageToken.isEmpty))
                self.refreshing = false
                finish(.success(valid: true))
            }, onError: { [weak self] (error) in
                self?.refreshing = false
                self?.errorPub.onNext(.refreshListFail(error))
                Self.logger.error("moment trace noticeList refreshPosts fail \(error)")
                finish(.error)
            }).disposed(by: disposeBag)
    }

    func cellVMWithNoticeEntity(_ noticeEntity: RawData.NoticeEntity) -> MomentsNoticeBaseCellViewModel {
        switch noticeEntity.noticeType {
        case .unknown:
            return MomentsNoticePostUnknownCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        case .follower:
            let vm = MomentsNoticefollowCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
            vm.followable = followable
            return vm
        case .postReaction:
            return MomentsNoticePostReactionCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        case .commentReaction:
            return MomentsNoticeCommentReactionCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        case .comment:
            return MomentsNoticeCommentCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        case .reply:
            return MomentsNoticeReplyCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        case .atInPost:
            return MomentsNoticeAtInPostCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        case .atInComment:
            return MomentsNoticeAtInCommentCellViewModel(userResolver: userResolver, noticeEntity: noticeEntity, context: self.context)
        }
    }

    /// 这里点击关注 需要刷新其他关注的状态 需要遍历其他的数据，有相关的user的关注状态需要改变
    func updateFollowDataForUserID(_ userID: String, hadFollow: Bool) {
        guard !userID.isEmpty else {
            return
        }
        /// 数据的修改需要在该串行队列执行
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            self.cellViewModels.forEach { (vm) in
                switch vm.noticeEntity.noticeType {
                case .follower(let followerEntity):
                    if userID == followerEntity.followerUser?.userID ?? "" {
                        followerEntity.hadFollow = hadFollow
                    }
                default:
                    break
                }
            }
            self.publish(.onlyRefresh)
        }
    }
    func endTrackShowNot() {
        if let item = self.tracker.getItemWithEvent(.showNotification) as? MomentsNotificationItem {
            item.endRender()
            self.tracker.endTrackWithItem(item)
        }
    }
}
extension MomentsUserNoticeViewModel: NoticeDataSourceAPI {
    func reloadDataForFollowStatusChange(userID: String, hadFollow: Bool) {
        updateFollowDataForUserID(userID, hadFollow: hadFollow)
    }
}
