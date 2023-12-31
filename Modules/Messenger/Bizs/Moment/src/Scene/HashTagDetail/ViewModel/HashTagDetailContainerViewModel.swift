//
//  HashTagDetailContainerViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/6/27.
//

import Foundation
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging
import LarkMessageCore

final class HashTagDetailContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let userPushCenter: PushNotificationCenter
    let hashTagId: String
    let content: String?

    var circleId: String? {
        return circleConfig?.circleID
    }
    var circleConfig: RawData.UserCircleConfig?

    var needShowFilterTab = false
    @ScopedInjectedLazy private var postStatusNoti: PostStatusChangedNotification?
    @ScopedInjectedLazy var createPostService: CreatePostApiService?
    @ScopedInjectedLazy private var configService: MomentsConfigAndSettingService?
    let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         hashTagId: String,
         content: String?,
         userPushCenter: PushNotificationCenter) {
        self.userResolver = userResolver
        self.hashTagId = hashTagId
        self.content = content
        self.userPushCenter = userPushCenter
    }

    func initCurrentCircle(_ finish: ((RawData.UserCircleConfig) -> Void)?) {
        configService?.getUserCircleConfigWithFinsih({[weak self] config in
            self?.circleConfig = config
            finish?(config)
        }, onError: nil)
    }

    func trackCategoryFeedShowWith(pageDetail: MomentsTracer.PageDetail?) {
        MomentsTracer.trackFeedPageView(circleId: circleId ?? "",
                                        type: .hashtag(self.hashTagId),
                                        detail: pageDetail)
    }
    func addObserverForPostStatus(_ complete: ((Bool) -> Void)?) {
        /// 帖子状态的ID
        postStatusNoti?.rxPostStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (postStatus) in
                let status = postStatus.createStatus
                if status == .success {
                    complete?(true)
                } else if status == .error || status == .failed {
                    complete?(false)
                }
            }).disposed(by: disposeBag)
    }

}
