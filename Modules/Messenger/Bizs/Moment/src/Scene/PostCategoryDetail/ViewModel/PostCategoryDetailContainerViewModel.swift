//
//  PostCategoryDetailViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/4/27.
//

import Foundation
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkMessageCore

final class PostCategoryDetailContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let categoryInputs: CategoryDetailInputs
    let userPushCenter: PushNotificationCenter
    var postCreating: Bool = false
    var circleId: String? {
        return self.circleConfig?.circleID
    }
    /// 是否需要展示多tab
    var needShowFilterTab = true
    @ScopedInjectedLazy private var postApi: PostApiService?
    @ScopedInjectedLazy private var postStatusNoti: PostStatusChangedNotification?
    @ScopedInjectedLazy private var configService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy var createPostService: CreatePostApiService?
    @ScopedInjectedLazy var categoriesApi: PostCategoriesApiService?
    private (set) var circleConfig: RawData.UserCircleConfig?

    let disposeBag = DisposeBag()
    static let logger = Logger.log(PostCategoryDetailContainerViewModel.self, category: "Module.Moments.PostCategoryDetailContainerViewModel")

    init(userResolver: UserResolver, categoryInputs: CategoryDetailInputs, userPushCenter: PushNotificationCenter) {
        self.userResolver = userResolver
        self.categoryInputs = categoryInputs
        self.userPushCenter = userPushCenter
    }

    func initCurrentCircleConfig(_ finish: ((RawData.UserCircleConfig) -> Void)?) {
        configService?.getUserCircleConfigWithFinsih({[weak self] config in
            self?.circleConfig = config
            finish?(config)
            self?.trackCategoryFeedShowWithID(self?.categoryInputs.id ?? "",
                                              pageDetail: .category_comment)
        }, onError: nil)
    }

    func trackCategoryFeedShowWithID(_ id: String, pageDetail: MomentsTracer.PageDetail?) {
        //刚进入页面时默认按“最新评论”排序，所以埋点对应参数为.category_comment
        MomentsTracer.trackFeedPageView(circleId: self.circleId ?? "",
                                        type: .category(self.categoryInputs.id),
                                        detail: pageDetail)
    }

    func addObserverForPostStatus(_ complete: ((Bool, [String]?) -> Void)?) {
        /// 帖子状态的ID
        postStatusNoti?.rxPostStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (postStatus) in
                let status = postStatus.createStatus
                if status == .success {
                    complete?(true, postStatus.successPost.post.categoryIds)
                } else if status == .error || status == .failed {
                    complete?(false, nil)
                }
            }).disposed(by: disposeBag)
    }
    func getCategoryDetailWithRefreshBlock(_ refresh: ((RawData.CategoryInfoEntity?) -> Void)?) {
        self.categoriesApi?
            .getCategoryDetailRequestWidth(categoryID: self.categoryInputs.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (categoryInfoEntity) in
                refresh?(categoryInfoEntity)
            }, onError: { (error) in
                refresh?(nil)
                Self.logger.error("getCategoryDetailRequest fail --\(error)")
            }).disposed(by: disposeBag)
    }
}
