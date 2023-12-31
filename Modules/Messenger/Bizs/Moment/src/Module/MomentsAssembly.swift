//
//  MomentsAssembly.swift
//  Moment
//
//  Created by zhuheng on 2020/12/30.
//

import UIKit
import Foundation
import Swinject
import LarkTab
import LarkUIKit
import EENavigator
import LarkNavigation
import LarkRustClient
import LarkSDKInterface
import LarkAttachmentUploader
import LarkAppLinkSDK
import LarkContainer
import RxSwift
import RxCocoa
import LarkFeatureGating
import UniverseDesignToast
import LarkProfile
import LarkMessengerInterface
import LarkAssembler
import LarkAccountInterface
import LarkSetting
import LKCommonsLogging

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
public enum Moment {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") //Global
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class MomentsAssembly: LarkAssemblyInterface {
    private let logger = Logger.log(MomentsAssembly.self, category: "Moments")

    public init() {}

    public func registRouter(container: Container) {

        Navigator.shared.registerRoute.plain(Tab.moment.urlString).priority(.high).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, _, res) in
            let vc = MomentsFeedContainerViewController(userResolver: r, userPushCenter: try r.userPushCenter)
            if Display.pad {
                let navVC = LkNavigationController(rootViewController: vc)
                res.end(resource: navVC)
            } else {
                res.end(resource: vc)
            }
        }

        // register profile
        Navigator.shared.registerRoute.type(MomentUserProfileByIdBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let fgService = try r.resolve(assert: FeatureGatingService.self)
            let fgValue = fgService.staticFeatureGatingValue(with: "moments.profile.new")
            let tabId = !fgValue ? ProfilePostListViewController.tabId : MomentsPolybasicProfileViewController.tabId
            let body = PersonCardBody(chatterId: body.userId,
                                      source: .community,
                                      extraParams: ["tab": tabId])
            res.redirect(body: body)
        }

        Navigator.shared.registerRoute.type(MomentsUserNicknameProfileByIdBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let fgService = try r.resolve(assert: FeatureGatingService.self)
            let fgValue = fgService.staticFeatureGatingValue(with: "moments.profile.new")
            if fgValue {
                let vm = MomentsNickNameProfileContainerViewModel(userResolver: r,
                                                                  userId: body.userId,
                                                                  userInfo: body.userInfo,
                                                                  selectPostTab: body.selectPostTab,
                                                                  userPushCenter: try r.userPushCenter)
                let vc = MomentsNickNameProfileContainerVC(userResolver: r, viewModel: vm, isPresented: false)
                res.end(resource: vc)
            } else {
                res.end(error: nil)
            }
        }

        // register detail
        Navigator.shared.registerRoute.type(MomentPostDetailByIdBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let postContext = BaseMomentContext()
            let commentContext = BaseMomentContext()
            let attachmentUploader = try r.resolve(assert: AttachmentUploader.self, argument: MomentsKeyboardViewModel.momentskeyboardDraftKey())
            let vc = DetailViewController(userResolver: r,
                                          inputs: .postID(body.postId),
                                          scrollState: .toCommentId(body.toCommentId),
                                          postContext: postContext,
                                          commentContext: commentContext,
                                          userPushCenter: try r.userPushCenter,
                                          showKeyboard: body.autoShowKeyboard,
                                          canRouteToFeed: body.canRouteToFeed,
                                          source: body.source) { (delegate) -> MomentsKeyboard in

                let vm = MomentsKeyboardViewModel(userResolver: r, postEntity: nil, delegate: delegate, attachmentUploader: attachmentUploader)
                return MomentsKeyboard(userResolver: r, viewModel: vm, delegate: delegate, keyboardNewStyleEnable: false)
            }
            postContext.pageAPI = vc
            commentContext.pageAPI = vc
            res.end(resource: vc)
        }

        Navigator.shared.registerRoute.type(MomentPostDetailByPostBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let postContext = BaseMomentContext()
            let commentContext = BaseMomentContext()
            let attachmentUploader = try r.resolve(assert: AttachmentUploader.self, argument: MomentsKeyboardViewModel.momentskeyboardDraftKey())
            let vc = DetailViewController(userResolver: r,
                                          inputs: .entity(body.post.copy()),
                                          scrollState: body.scrollState,
                                          postContext: postContext,
                                          commentContext: commentContext,
                                          userPushCenter: try r.userPushCenter,
                                          showKeyboard: body.autoShowKeyboard,
                                          canRouteToFeed: body.canRouteToFeed,
                                          source: body.source) { (delegate) -> MomentsKeyboard in
                let vm = MomentsKeyboardViewModel(userResolver: r, postEntity: body.post, delegate: delegate, attachmentUploader: attachmentUploader)
                return MomentsKeyboard(userResolver: r, viewModel: vm, delegate: delegate, keyboardNewStyleEnable: false)
            }
            postContext.pageAPI = vc
            commentContext.pageAPI = vc
            res.end(resource: vc)
        }

        // register send post
        Navigator.shared.registerRoute.type(MomentsSendPostBody.self).factory(MomentsSendPostHandler.init)

        /// 板块详情页CategoryBody
        Navigator.shared.registerRoute.type(MomentsPostCategoryDetialByCategoryBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let vm = PostCategoryDetailContainerViewModel(userResolver: r, categoryInputs: .categoryEntity(body.category), userPushCenter: try r.userPushCenter)
            let vc = PostCategoryDetailContainerViewController(userResolver: r, viewModel: vm, isPresented: body.isPresented)
            res.end(resource: vc)
        }

        /// 板块详情页ID Body
        Navigator.shared.registerRoute.type(MomentsPostCategoryDetialByIDBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let vm = PostCategoryDetailContainerViewModel(userResolver: r, categoryInputs: .categoryID(body.categoryID), userPushCenter: try r.userPushCenter)
            let vc = PostCategoryDetailContainerViewController(userResolver: r, viewModel: vm, isPresented: body.isPresented)
            res.end(resource: vc)
        }

        /// 板块编辑页面
        Navigator.shared.registerRoute.type(MomentsCategoryEditBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let vm = CategoryEditViewModel(userResolver: r,
                                           selectedTab: body.selectedTab,
                                           usedTabs: body.usedTabs,
                                           selectBlock: body.selectBlock,
                                           finishBlock: body.finishBlock)
            let vc = CategoryEditViewController(viewModel: vm)
            res.end(resource: vc)
        }

        // 花名编辑页面
        Navigator.shared.registerRoute.type(MomentsUserNickNameSelectBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let vc = UserNickNameSelectViewController(userResolver: r,
                                                      circleId: body.circleId,
                                                      completeBlock: body.completeBlock,
                                                      nickNameSettingStyle: body.nickNameSettingStyle)
            res.end(resource: vc)
        }

        // 公司圈设置页面
        Navigator.shared.registerRoute.type(MomentsSettingBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, _, _, res) in
            let vc = MomentSettingViewController(userResolver: r)
            res.end(resource: vc)
        }

        // hashTag 详情页 点击post上的hashtag可以进入
        Navigator.shared.registerRoute.type(MomentsHashTagDetialByIDBody.self).handle(compatibleMode: { Moment.userScopeCompatibleMode }) { (r, body, _, res) in
            let vm = HashTagDetailContainerViewModel(userResolver: r,
                                                     hashTagId: body.hashTagID,
                                                     content: body.content,
                                                     userPushCenter: try r.userPushCenter)
            let vc = HashTagDetailContainerViewController(userResolver: r, viewModel: vm, isPresented: body.isPresented)
            res.end(resource: vc)
        }

        //图片查看器页面
        Navigator.shared.registerRoute.type(MomentsPreviewImagesBody.self).factory(cache: true, MomentsPreviewImagesHandler.init)
    }

    public func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/moments/home") { [weak self] (applink: AppLink) in
            let userResolver = Container.shared.getCurrentUserResolver()
            guard let from = applink.context?.from() else { return }
            let switchTabEnable = (try? userResolver.resolve(type: NavigationService.self))?.checkSwitchTabEnable(for: Tab.moment)
            self?.logger.info("perform applink /client/moments/home, tabEnable: \(String(describing: switchTabEnable))")
            if applink.url.queryParameters["action"] == "refresh" {
                if let vc = Navigator.shared.tabProvider?().tabbarController?.viewControllers?.first(where: { vc in
                    return vc.tabRootViewController is MomentsFeedContainerViewController
                }) {
                    (vc.tabRootViewController as? MomentsFeedContainerViewController)?.toRecommendTabAndRefresh()
                }
            }
            userResolver.navigator.switchTab(Tab.moment.url, from: from, animated: false) { success in
                if !success {
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FeatureDisabledContactAdministratorCustomized(MomentTab.tabTitle()), on: from.fromViewController?.view ?? UIView())
                }
            }
        }

        LarkAppLinkSDK.registerHandler(path: MomentPostDetailByIdBody.appLinkPattern, handler: { (applink: AppLink) in
            let userResolver = Container.shared.getCurrentUserResolver()
            guard let from = applink.context?.from(), let postId = applink.url.queryParameters["postId"] else { return }
            let commentId = applink.url.queryParameters["commentId"]
            let source = applink.url.queryParameters["source"]
            let body = MomentPostDetailByIdBody(postId: postId,
                                                toCommentId: commentId,
                                                source: Tracer.transformDetailSourceToPageSource(source),
                                                canRouteToFeed: true)
            if let pageAPI = from.fromViewController as? PageAPI,
               pageAPI.childVCMustBeModalView {
                userResolver.navigator.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: pageAPI) { vc in
                    vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
                }
            } else {
                userResolver.navigator.push(body: body, from: from)
            }
        })

        LarkAppLinkSDK.registerHandler(path: MomentUserProfileByIdBody.appLinkPattern, handler: { (applink: AppLink) in
            let userResolver = Container.shared.getCurrentUserResolver()
            guard let from = applink.context?.from(), let userId = applink.url.queryParameters["userId"] else { return }
            let body = MomentUserProfileByIdBody(userId: userId)
            userResolver.navigator.push(body: body, from: from)
            Tracer.trackCommunityProfileView(source: .profile)
        })

        LarkAppLinkSDK.registerHandler(path: MomentsHashTagDetialByIDBody.appLinkPatter) { (applink: AppLink) in
            let userResolver = Container.shared.getCurrentUserResolver()
            guard let from = applink.context?.from(),
                  let hashtagId = applink.url.queryParameters["hashtagId"] else { return }
            var body = MomentsHashTagDetialByIDBody(hashTagID: hashtagId, content: nil)
            if let pageAPI = from.fromViewController as? PageAPI,
               pageAPI.childVCMustBeModalView {
                body.isPresented = true
                userResolver.navigator.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: pageAPI) { vc in
                    vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
                }
            } else {
                userResolver.navigator.push(body: body, from: from)
            }
        }
        LarkAppLinkSDK.registerHandler(path: MomentsPostCategoryDetialByIDBody.appLinkPatter) { (applink: AppLink) in
            let userResolver = Container.shared.getCurrentUserResolver()
            guard let from = applink.context?.from(),
                  let categoryId = applink.url.queryParameters["categoryId"] else { return }
            var body = MomentsPostCategoryDetialByIDBody(categoryID: categoryId)
            if let pageAPI = from.fromViewController as? PageAPI,
               pageAPI.childVCMustBeModalView {
                body.isPresented = true
                userResolver.navigator.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: pageAPI) { vc in
                    vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
                }
            } else {
                userResolver.navigator.push(body: body, from: from)
            }
        }
        LarkProfileTabs.shared.registerTab(MomentsPolybasicProfileViewController.self)
        LarkProfileTabs.shared.registerTab(ProfilePostListViewController.self)
    }

    public func registTabRegistry(container: Container) {
        // register tab
        (Tab.moment, { (_: [URLQueryItem]?) -> TabRepresentable in
            MomentTab()
        })
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Moment.userScope)
        let userGraph = container.inObjectScope(Moment.userGraph)

        // Api
        user.register(RustApiService.self) { resolver -> RustApiService in
            return RustApiService(client: try resolver.resolve(assert: RustService.self), userPushCenter: try resolver.userPushCenter)
        }

        let apiImplGetter = { (resolver: UserResolver) throws -> RustApiService in
            try resolver.resolve(assert: RustApiService.self)
        }

        user.register(PostApiService.self, factory: apiImplGetter)
        user.register(DislikeApiService.self, factory: apiImplGetter)
        user.register(FeedApiService.self, factory: apiImplGetter)
        user.register(UserApiService.self, factory: apiImplGetter)
        user.register(DetailApiService.self, factory: apiImplGetter)
        user.register(AdminApiService.self, factory: apiImplGetter)
        user.register(NoticeApiService.self, factory: apiImplGetter)
        user.register(ProfileApiService.self, factory: apiImplGetter)
        user.register(UserDraftApiService.self, factory: apiImplGetter)
        user.register(UserTabApiService.self, factory: apiImplGetter)
        user.register(PostCategoriesApiService.self, factory: apiImplGetter)
        user.register(NickNameAndAnonymousService.self, factory: apiImplGetter)
        user.register(SettingApiService.self, factory: apiImplGetter)
        user.register(HashTagApiService.self, factory: apiImplGetter)
        user.register(MomentsTranslateAPI.self, factory: apiImplGetter)
        user.register(OfficialAccountAPI.self, factory: apiImplGetter)

        userGraph.register(EntityDeletedNotification.self) { resolver -> EntityDeletedNotification in
            return EntityDeletedPushHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(FollowingChangedNotification.self) { resolver -> FollowingChangedNotification in
            return FollowingChangedPushHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(PostStatusChangedNotification.self) { resolver -> PostStatusChangedNotification in
            return PostStatusChangedPushHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(CommentStatusChangedNotification.self) { resolver -> CommentStatusChangedNotification in
            return CommentStatusChangedPushHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(MomentUserNotification.self) { resolver -> MomentUserNotification in
            return MomentUserPushHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(ReactionSetNotification.self) { resolver -> ReactionSetNotification in
            return ReactionSetNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }
        userGraph.register(CommentSetNotification.self) { resolver -> CommentSetNotification in
            return CommentSetNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(PostShareCountNotification.self) { resolver -> PostShareCountNotification in
            return PostShareCountNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(PostDistributionNotification.self) { resolver -> PostDistributionNotification in
            return PostDistributionNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(MomentsUserGlobalConfigAndSettingNotification.self) { resolver -> MomentsUserGlobalConfigAndSettingNotification in
            return MomentsUserGlobalConfigAndSettingNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(MomentsBadgePushNotificationHandler.self) { resolver -> MomentsBadgePushNotificationHandler in
            return MomentsBadgePushNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        /// user 级别的 切换切换用户 重新拉取数据
        user.register(MomentBadgePushNotification.self) { r -> MomentBadgePushNotification in
            return MomentBadgePushNotificationManger(userResolver: r, userPushCenter: try r.userPushCenter)
        }

        userGraph.register(PostIsBoardcastNotification.self) { resolver -> PostIsBoardcastNotification in
            return PostIsBoardcastNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(PostUpdatedNotification.self) { resolver -> PostUpdatedNotification in
            return PostUpdatedNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }
        userGraph.register(CommentUpdatedNotification.self) { resolver -> CommentUpdatedNotification in
            return CommentUpdatedNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(MomentsTranslateNotification.self) { resolver -> MomentsTranslateNotification in
            return MomentsTranslateNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        userGraph.register(MomentsAccountNotification.self) { resolver -> MomentsAccountNotification in
            return MomentsAccountNotificationHandler(client: try resolver.resolve(assert: RustService.self))
        }

        user.register(MomentsDraftService.self) { r -> MomentsDraftService in
            let detailItem = DraftNameSpaceConfig(maxCount: 3, nameSpace: DetailViewModel.nameSpace, type: .draft)
            let postItem = DraftNameSpaceConfig(maxCount: 1, nameSpace: MomentSendPostViewModel.nameSpace, type: .draft)
            return MomentsDraftServiceImp(userResolver: r, nameSpaces: [detailItem, postItem])
        }

        user.register(MomentsKeyValueStorageService.self) { r -> MomentsKeyValueStorageService in
            return MomentsKeyValueStorageIMP(userResolver: r)
        }

        user.register(CreatePostApiService.self) { r -> CreatePostApiService in
            return CreatePostApiServiceImp(userResolver: r)
        }

        /// 维护UserCircleConfig 最新
        user.register(MomentsConfigAndSettingService.self) { r -> MomentsConfigAndSettingService in
            return MomentsConfigAndSettingServiceIMP(userResolver: r)
        }

        /// 匿名相关
        userGraph.register(UserAnonymousConfigService.self) { r -> UserAnonymousConfigService in
            return UserAnonymousConfigServiceIMP(userResolver: r)
        }
        user.register(UserCreateReactionService.self) { r -> UserCreateReactionService in
            return UserCreateReactionServiceIMP(userResolver: r)
        }
        user.register(RedDotNotifyService.self) { resolver -> RedDotNotifyService in
            return RedDotNotifyServiceImpl(userResolver: resolver,
                                           client: try resolver.resolve(assert: RustService.self),
                                           pushTabNotificationInfo: (try resolver.userPushCenter).observable(for: TabNotificationInfo.self))
        }

        user.register(MomentsSecurityAuditService.self) { r in
            return MomentsSecurityAuditServiceImp(currentUserID: r.userID)
        }

        user.register(MomentsTranslateService.self) { r in
            return MomentsTranslateServiceImp(userResolver: r)
        }

        user.register(MomentsAccountService.self) { r in
            return MomentsAccountServiceImp(userResolver: r)
        }
    }

    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerCommand.momentsPushTabNotification, PushTabNotificationHandler.init(resolver:))
    }
}
