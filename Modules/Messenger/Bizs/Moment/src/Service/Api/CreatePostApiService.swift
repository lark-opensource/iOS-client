//
//  CreatePostApiService.swift
//  Moment
//
//  Created by liluobin on 2021/5/22.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer
import LKCommonsLogging

protocol CreatePostApiService: AnyObject {
    var createPostNot: PublishSubject<RawData.PostEntity> { get }
    /// 创建帖子 在finish 在主线程回到
    func createPostWith(categoryId: String?, isAnonymous: Bool, content: RawData.RichText?, imageMediaInfos: [PostImageMediaInfo]?, finish: ((Error?) -> Void)?)
}

final class CreatePostApiServiceImp: CreatePostApiService, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    static let logger = Logger.log(CreatePostApiService.self, category: "Module.Moments.CreatePostApiService")
    let tracker = MomentsCommonTracker()
    let createPostNot: PublishSubject<RawData.PostEntity> = .init()
    @ScopedInjectedLazy private var postApi: PostApiService?
    let disposeBag = DisposeBag()
    var postCreating = false

    func createPostWith(categoryId: String?, isAnonymous: Bool, content: RawData.RichText?, imageMediaInfos: [PostImageMediaInfo]?, finish: ((Error?) -> Void)?) {
        guard !postCreating else {
            Self.logger.warn("moment trace  postCreating")
            return
        }
        self.postCreating = true
        let item = MomentsSendPostItem(biz: .Moments, scene: .MoPost, event: .momentsSendPost, page: "publish")
        item.isAnonymous = isAnonymous
        self.tracker.startTrackWithItem(item)
        MomentsDataConverter.asyncTrans(imageMediaInfos: imageMediaInfos) { [weak self] (imageList, mediaInfo) in
                guard let self = self else { return }
                self.postApi?.createPost(byID: "", categoryId: categoryId, isAnonymous: isAnonymous, content: content, images: imageList, mediaInfo: mediaInfo)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (post) in
                        finish?(nil)
                        self?.createPostNot.onNext(post)
                        self?.postCreating = false
                        self?.endTrackItem(item, isAnonymous: isAnonymous)
                    }, onError: { [weak self] (error) in
                        finish?(error)
                        Self.logger.error("moment trace createPost fail \(error)")
                        self?.postCreating = false
                        MomentsErrorTacker.trackReciableEventError(error,
                                                                   sence: .MoPost,
                                                                   event: .momentsSendPost,
                                                                   page: "publish")
                    }).disposed(by: self.disposeBag)
        }
    }

    func endTrackItem(_ item: MomentsSendPostItem?, isAnonymous: Bool) {
        if !isAnonymous {
            self.tracker.endTrackWithItem(item)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + momentsAnonymousPostRefreshInterval) { [weak self] in
                self?.tracker.endTrackWithItem(item)
            }
        }
    }
}
