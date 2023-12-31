//
//  MomentPostCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import Foundation
import UIKit
import AsyncComponent
import LarkMessageBase
import EEFlexiable
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkNavigator
import LarkModel
import LarkSDKInterface
import LarkMenuController
import LarkContainer
import LarkMessageCore
import RxSwift
import LarkEmotion
import LarkCore
import LarkAlertController
import UniverseDesignToast
import LarkAccountInterface
import LKCommonsLogging
import LarkEnv
import LarkAppLinkSDK
import EditTextView
import LarkFeatureGating
import LKCommonsTracker
import LarkSetting
import UniverseDesignPopover
import RustPB
import LarkEMM
import LarkSensitivityControl

extension RawData.PostEntity: ReactionListEntitiesProtocol {
    var id: String {
        return self.post.id
    }
    var reactions: [RawData.ReactionList] {
        return self.post.reactionSet.reactions
    }
    var originalReactionSet: RawData.ReactionSet {
        return self.post.reactionSet
    }
    var type: RawData.EntityType {
        return .post
    }
    var circleId: String {
        return self.post.circleID
    }
    var postId: String {
        return self.post.id
    }
}

extension RawData.PostEntity: MomentsUnsupportTip {
    var unsupportTip: String? {
        if self.post.hasIncompatibleAction, self.post.incompatibleAction.type == .hint {
            return self.post.incompatibleAction.hint
        }
        return nil
    }
}
final class MomentPostCellViewModel: BaseMomentsEntityCellViewModel<RawData.PostEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentPostCellViewModel.self, category: "Module.Moments.MomentPostCellViewModel ")
    private lazy var _identifier: String = {
        return [content.identifier, "post"].joined(separator: "-")
    }()

    override var identifier: String {
        return _identifier
    }

    var cellConfig: MomentPostCellConfig {
        return self.config
    }

    var config: MomentPostCellConfig

    var user: MomentUser? {
        return self.entity.user
    }

    /// 所有的评论数
    var commentCount: Int32 {
        return self.entity.post.commentSet.totalCount
    }

    var shareCount: Int32 {
        return self.entity.post.shareCount
    }

    var reactionCount: Int32 {
        return self.entity.post.reactionSet.totalCount
    }

    lazy var isFromMe: Bool = {
        return self.entity.post.isSelfOwner
    }()

    lazy var canShowFollow: Bool = {
        //不是自己的，且不是匿名
        return !isFromMe && !self.entity.post.isAnonymous
    }()

    var formatTime: String {
        var time = TimeInterval(entity.post.publishTimeMsec / 1000)
        if time == 0 {
            time = TimeInterval(entity.post.createTimeMsec / 1000)
        }
        let date = Date(timeIntervalSince1970: time)
        return MomentsTimeTool.displayTimeForDate(date)
    }

    private(set) lazy var scene: MomentContextScene = {
        return self.context.pageAPI?.scene ?? .unknown
    }()

    /// 生成菜单选项
    private lazy var menuItemGenerator: MenuItemGenerator = {
        let generator = MenuItemGenerator(userResolver: self.userResolver)
        generator.delegate = self
        return generator
    }()

    var canShowTranslation: Bool {
        guard let userGeneralSettings, let fgService else { return false }
        return self.entity.post.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
    }

    var canBeTranslated: Bool {
        return self.entity.post.canBeTranslated(fgService: self.fgService)
    }

    var shouldShowLastReadTop: Bool {
        return self.context.dataSourceAPI?.lastReadPostId() ?? "" == self.entityId
    }

    @ScopedInjectedLazy private var postAPI: PostApiService?
    @ScopedInjectedLazy private var userAPI: UserApiService?
    @ScopedInjectedLazy private var adminAPI: AdminApiService?
    @ScopedInjectedLazy private var feedAPI: FeedApiService?
    @ScopedInjectedLazy private var createReactionService: UserCreateReactionService?
    @ScopedInjectedLazy private var securityAuditService: MomentsSecurityAuditService?
    @ScopedInjectedLazy private var thumbsupService: ThumbsupReactionService?
    @ScopedInjectedLazy private var dislikeService: DislikeApiService?
    @ScopedInjectedLazy private var translateService: MomentsTranslateService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?
    @ScopedInjectedLazy private var configAndSettingService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    let manageMode: RustPB.Moments_V1_ManageMode
    private lazy var followFont = {
        return UIFont.systemFont(ofSize: 14)
    }()
    /// UserCircleConfig中字段，代表该租户是否开启点踩
    let isEnableTrample: Bool

    init(userResolver: UserResolver,
         postEntity: RawData.PostEntity,
         context: BaseMomentContext,
         manageMode: RawData.ManageMode,
         config: MomentPostCellConfig = MomentPostCellConfig.default,
         isEnableTrample: Bool = false) {
        self.userResolver = userResolver
        self.config = config
        self.manageMode = manageMode
        self.isEnableTrample = isEnableTrample
        self.isFollowed = postEntity.user?.isCurrentUserFollowing ?? false
        let scene = context.pageAPI?.scene ?? .unknown
        let content = MomentPostCellViewModel.generateContent(userResolver: userResolver, postEntity: postEntity, context: context, scene: scene)
        let subvms = MomentPostCellViewModel.generateSubViewModels(userResolver: userResolver, postEntity: postEntity, context: context, scene: scene, manageMode: self.manageMode)
        let binder: ComponentBinder<BaseMomentContext>
        let momentsAccountService = try? userResolver.resolve(assert: MomentsAccountService.self)
        if self.manageMode == .recommendV2Mode {
            binder = RecommendMomentPostCellComponentBinder(userResolver: userResolver,
                                                            context: context,
                                                            contentComponent: content.component,
                                                            canReaction: postEntity.canCurrentAccountReaction(momentsAccountService: momentsAccountService),
                                                            canComment: postEntity.canCurrentAccountComment,
                                                            categoryReadable: postEntity.category?.category.canRead ?? true)
        } else {
            binder = MomentPostCellComponentBinder(userResolver: userResolver,
                                                   context: context,
                                                   contentComponent: content.component,
                                                   canReaction: postEntity.canCurrentAccountReaction(momentsAccountService: momentsAccountService),
                                                   canComment: postEntity.canCurrentAccountComment,
                                                   categoryReadable: postEntity.category?.category.canRead ?? true)
        }
        super.init(entity: postEntity,
                       content: content,
                       subvms: subvms,
                       context: context,
                       binder: binder)
        self.trampleStatus = !self.entity.post.isSelfDisliked ? .normal : .dislike
        self.content.initRenderer(renderer)
        self.addChild(self.content)
        super.calculateRenderer()
    }

    override func update(entity: RawData.PostEntity) {
        super.update(entity: entity)
        self.isFollowed = entity.user?.isCurrentUserFollowing ?? false
        self.trampleStatus = !self.entity.post.isSelfDisliked ? .normal : .dislike
        self.content.update(entity: entity)
        super.calculateRenderer()
    }

    private var displaying = false

    private var needReportEvent = false {
        didSet {
            if needReportEvent != oldValue {
                self.securityAuditService?.auditEvent(.momentsShowPost(postId: self.entity.postId), status: nil)
            }
        }
    }

    override func willDisplay() {
        super.willDisplay()
        if self.entity.post.localStatus == .success, self.scene != .postDetail {
            needReportEvent = true
        }
        guard !displaying else { return }
        displaying = true
        translateService?.autoTranslateIfNeed(entity: .post(self.entity))
        for comment in self.entity.comments {
            translateService?.autoTranslateIfNeed(entity: .comment(comment))
        }
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        displaying = false
    }

    private var followRequesting: Bool = false

    private var isFollowed: Bool {
        didSet {
            guard isFollowed != oldValue else { return }
            self.followRequesting = false
        }
    }

    var topContainerBottom: CGFloat {
        var space: CGFloat = 0
        switch self.scene {
        case .feed, .profile, .categoryDetail, .hashTagDetail:
            space = 6
        case .postDetail:
            space = 8
        case .unknown:
            break
        }
        return space
    }

    /// 不支持的类型
    var unSupportStr: String {
        return self.entity.post.incompatibleAction.hint
    }

    /// 点赞是否需要动画
    var userAlreadyThumbsUP: Bool {
        guard let thumbsupService else { return false }
        let thumbsup = thumbsupService.thumbsupKey
        let hadThumpsUP = self.entity.post.reactionSet.reactions.contains { (info) -> Bool in
            return info.type == thumbsup && info.selfInvolved
        }
        return hadThumpsUP
    }

    func followButConfig() -> (CustomIconTextTapComponentProps, FolowButStyleInfo) {
        let followButProps = CustomIconTextTapComponentProps()
        let styleInfo: FolowButStyleInfo
        let fontColor: UIColor
        if self.isFollowed {
            if self.followRequesting {
                followButProps.iconBlock = { Resources.postFollowing }
                followButProps.iconNeedRotate = true
                fontColor = UIColor.ud.N500
            } else {
                fontColor = UIColor.ud.N900
            }
            followButProps.attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_Followed, attributes: [.foregroundColor: fontColor, .font: followFont])
            styleInfo = FolowButStyleInfo(border: Border(BorderEdge(width: 1, color: UIColor.ud.N400, style: .solid)),
                                          backGroundColor: UIColor.clear)
        } else {
            if self.followRequesting {
                followButProps.iconBlock = { Resources.postFollowing }
                followButProps.iconNeedRotate = true
                fontColor = UIColor.ud.B300
            } else {
                followButProps.iconBlock = { Resources.postFollow }
                fontColor = UIColor.ud.colorfulBlue
            }
            followButProps.attributedText = NSAttributedString(string: BundleI18n.Moment.Lark_Community_Attention, attributes: [.foregroundColor: fontColor, .font: followFont])
            styleInfo = FolowButStyleInfo(border: Border(BorderEdge(width: 1, color: UIColor.ud.colorfulBlue, style: .solid)),
                                          backGroundColor: UIColor.clear)
        }
        followButProps.onViewClicked = { [weak self] in
            self?.followButClick()
        }
        followButProps.contentPaddingLeft = 8
        followButProps.contentPaddingRight = 8
        return (followButProps, styleInfo)
    }

    func followButClick() {
        guard !self.followRequesting, let pageAPI = self.context.pageAPI, let userAPI else {
            return
        }
        if self.scene == .postDetail {
            Tracer.trackCommunityTabFollow(source: .detail, action: !self.isFollowed, followId: self.entity.post.userID)
            let userId = self.entity.post.userID
            let clickType: MomentsTracer.DetailPageClickType = self.isFollowed ? .follow_cancel(userId) : .follow(userId)
            self.trackDetailPageClick(clickType)
        }
        self.setFollow(requesting: true)
        if self.isFollowed {
            userAPI.unfollowUser(byId: self.entity.post.userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (_) in
                    self?.setFollow(requesting: false)
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToUnfollow, on: pageAPI.view)
                }).disposed(by: self.context.disposeBag)
        } else {
            userAPI.followUser(byId: self.entity.post.userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (_) in
                    self?.setFollow(requesting: false)
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FollowFailed, on: pageAPI.view)
                }).disposed(by: self.context.disposeBag)
        }
    }

    private func setFollow(requesting: Bool) {
        self.followRequesting = requesting
        super.calculateRenderer()
        self.context.dataSourceAPI?.reloadRow(by: self.entity.id, animation: .none)
    }

    func onCategoryTapped() {
        guard let pageAPI = self.context.pageAPI,
              let category = self.entity.category else {
            return
        }
        if !category.category.canRead {
            UDToast.showTips(with: BundleI18n.Moment.Moments_Category_MomentPushByAdminNoEditPermission, on: pageAPI.view)
            return
        }
        var body = MomentsPostCategoryDetialByCategoryBody(category: category)
        if pageAPI.childVCMustBeModalView {
            body.isPresented = true
            self.userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: pageAPI) { vc in
                vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
            }
        } else {
            self.userResolver.navigator.push(body: body, from: pageAPI)
        }
        self.trackDetailPageClick(.category)
        self.trackFeedPageViewClick(.from_category)
    }

    func onAvatarTapped() {
        guard let targetVC = self.context.pageAPI, let user = self.user else { return }
        let trackInfo = MomentsNavigator.TrackInfo(circleId: self.entity.post.circleID,
                                                   postId: self.entity.post.id,
                                                   categoryId: self.entity.category?.category.categoryID,
                                                   scene: self.scene,
                                                   pageIdInfo: self.context.dataSourceAPI?.getTrackValueForKey(.pageIdInfo) as? MomentsTracer.PageIdInfo)

        MomentsNavigator.pushAvatarWith(userResolver: userResolver,
                                        user: user,
                                        from: targetVC,
                                        source: Tracer.transformMomentSceneToPrfileSource(scene),
                                        trackInfo: trackInfo)
    }

    func onMenuTapped(pointView: UIView) {
        if self.entity.post.localStatus == .error ||
            self.entity.post.localStatus == .failed {
            onPostSendFailMenuTapped(pointView: pointView)
            return
        }
        guard let pageVC = self.context.pageAPI else {
            return
        }
        self.popOverMenuActionTypes { popoverMenuItemTypes in
            MomentsPopOverMenuManager.showMenuVCWith(presentVC: pageVC, pointView: pointView, itemTypes: popoverMenuItemTypes) { [weak self] (type) in
                guard let self = self else { return }
                switch type {
                case .delete:
                    let alertController = LarkAlertController()
                    let title: String
                    if self.entity.post.isSelfOwner {
                        title = BundleI18n.Moment.Lark_Community_AreYouSureYouWantToDeleteThisPost
                    } else {
                        title = BundleI18n.Moment.Lark_Community_AreYouSureDeleteMoment(self.entity.userDisplayName)
                    }
                    alertController.setTitle(text: title)
                    alertController.addCancelButton()
                    alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_DeleteConfirm, dismissCompletion: {
                        self.deletePost()
                    })
                    self.userResolver.navigator.present(alertController, from: pageVC)
                case .report:
                    let report = ReportViewController(userResolver: self.userResolver, type: .post(self.entity.id))
                    self.userResolver.navigator.presentOrPush(report,
                                                   wrap: LkNavigationController.self,
                                                   from: pageVC,
                                                   prepareForPresent: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
                case .setVisible(isRecommend: let isRecommend):
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: MomentsDynamicTextKeyManager.textForKeyType(.onlyAuthorCanView,
                                                                                               isRecommend: isRecommend))
                    alertController.setContent(text: MomentsDynamicTextKeyManager.textForKeyType(.onlyAuthorCanViewDesc, isRecommend: isRecommend))
                    alertController.addCancelButton()
                    alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_Confirm, dismissCompletion: { [weak self] in
                        self?.setPostDistribution(isRecommend)
                    })
                    self.userResolver.navigator.present(alertController, from: pageVC)
                case .boardcast(boardcasting: let boardcasting):
                    if boardcasting {
                        self.unsetBoardcast()
                    } else {
                        self.setOrEditBoardcast(forEdit: false)
                    }
                case .editBoardcast:
                    self.setOrEditBoardcast(forEdit: true)
                case .copyLink:
                    self.copyPostLink()
                case .translate:
                    self.trackPostMoreClick(clickType: .translateButton(.translate))
                    self.translate()
                case .hideTranslation, .showSourceText:
                    self.trackPostMoreClick(clickType: .translateButton(.show_original_text))
                    self.hideTranslation()
                case .changeTranslationLanguage:
                    self.trackPostMoreClick(clickType: .translateButton(.switch_languages))
                    self.changeTranslationLanguage()
                }
            }
        }
        self.trackFeedPageViewClick(.more)
        self.trackDetailPageClick(.more)
        self.trackPostMoreView()
    }

    func onPostSendFailMenuTapped(pointView: UIView) {
        guard let pageVC = self.context.pageAPI else {
            return
        }
        let popoverMenuItemTypes: [MomentsPopOverMenuActionType] = [.delete]
        MomentsPopOverMenuManager.showMenuVCWith(presentVC: pageVC, pointView: pointView, itemTypes: popoverMenuItemTypes) { [weak self] (type) in
            guard let self = self else { return }
            switch type {
            case .delete:
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.Moment.Lark_Community_AreYouSureYouWantToDeleteThisPost)
                alertController.addCancelButton()
                alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_DeleteConfirm, dismissCompletion: { [weak self] in
                    self?.deletePost()
                })
                self.userResolver.navigator.present(alertController, from: pageVC)
            default:
                break
            }
        }
    }

    private func popOverMenuActionTypes(callback: @escaping ([MomentsPopOverMenuActionType]) -> Void) {
        ///profile的scene下 mode是固定写死的，故需要重新配置一下
        if self.scene == .profile {
            self.configAndSettingService?.getUserCircleConfigWithFinsih { [weak self] config in
                guard let self = self else { return }
                callback(self.getPopoverMenuItemTypes(config.manageMode == .recommendV2Mode))
            } onError: { [weak self] error in
                Self.logger.error("popOverMenuActionTypes getUserCircleConfigWithFinsih error", error: error)
                guard let self = self else { return }
                /// 如果请求失败给个兜底的逻辑，保证其他功能正常
                callback(self.getPopoverMenuItemTypes(self.manageMode == .recommendV2Mode))
            }
        } else {
            callback(self.getPopoverMenuItemTypes(self.manageMode == .recommendV2Mode))
        }
    }

    private func getPopoverMenuItemTypes(_ isRecommend: Bool) -> [MomentsPopOverMenuActionType] {
        var popoverMenuItemTypes: [MomentsPopOverMenuActionType] = []
        if self.entity.post.canAdministrate {
            popoverMenuItemTypes.append(.boardcast(boardcasting: self.entity.post.isBroadcast))
            if self.entity.post.isBroadcast {
                popoverMenuItemTypes.append(.editBoardcast)
            }
            /// 和产品确认，管理员有权限操作所有的帖子，包括自己的帖子
            if self.entity.post.distributionType != .notDistribution {
                popoverMenuItemTypes.append(.setVisible(isRecommend: isRecommend))
            } else {
                Self.logger.error("仅作者可见帖子不应展示 \(self.entity.post.id)")
            }
        }

        if self.canBeTranslated {
            if self.canShowTranslation {
                popoverMenuItemTypes.append(.changeTranslationLanguage)
                if let userGeneralSettings {
                    switch self.entity.post.getDisplayRule(userGeneralSettings: userGeneralSettings) {
                    case .withOriginal:
                        popoverMenuItemTypes.append(.hideTranslation)
                    case .onlyTranslation:
                        popoverMenuItemTypes.append(.showSourceText)
                    @unknown default:
                        break
                    }
                }
            } else {
                popoverMenuItemTypes.append(.translate)
            }
        }

        popoverMenuItemTypes.append(.copyLink)
        if self.entity.post.canReport {
            popoverMenuItemTypes.append(.report)
        }
        if self.entity.post.canDelete {
            popoverMenuItemTypes.append(.delete)
        }
        return popoverMenuItemTypes
    }

    func onReplyTapped() {
        switch self.scene {
        case .feed, .profile, .categoryDetail, .hashTagDetail:
            pushToMomentDetailWithShowKeyboard(scrollState: .toFirstComent)
            self.trackFeedPageViewClick(.comment)
        case .postDetail:
            self.context.pageAPI?.reply(by: self.entity)
            self.trackDetailPageClick(.comment)
        case .unknown:
            break
        }
    }

    /// 点踩的icon状态
    public enum TrampleIconState: Int {
        case normal
        case loading
        case dislike
    }

    var trampleStatus: TrampleIconState = .normal {
        didSet {
            if oldValue.rawValue != trampleStatus.rawValue {
                if trampleStatus == .loading {
                    self.context.dataSourceAPI?.updatePostCellDislike(isSelfDislike: nil, postId: self.entityId)
                } else {
                    self.context.dataSourceAPI?.updatePostCellDislike(isSelfDislike: trampleStatus == .dislike, postId: self.entityId)
                }
            }
        }
    }

    func trample() {
        let postId = self.entity.post.id
        /// 是否点过踩
        if self.entity.post.isSelfDisliked == false {
            trampleStatus = .loading
            dislikeService?.listDislikeReasons(entityID: postId, entityType: .post)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] reasons in
                    guard let self = self else { return }
                    self.trampleStatus = .normal
                    if let targetVC = self.context.pageAPI {
                        self.createTrampleVC(targetVC: targetVC, postId: postId, reasons: reasons)
                    }
                }, onError: { [weak self] error in
                    Self.logger.error("getDisikeReasons error", error: error)
                    self?.trampleStatus = .normal
                }).disposed(by: self.disposeBag)
        } else {
            dislikeService?.deleteDislike(entityID: postId, entityType: .post)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.trampleStatus = .normal
                }, onError: { [weak self] error in
                    Self.logger.error("deleteDislike error", error: error)
                    self?.trampleStatus = .dislike
                }).disposed(by: self.disposeBag)
            self.trackDetailPageClick(.tumbsdown(false))
        }
    }

    func createTrampleVC(targetVC: PageAPI, postId: String, reasons: [RawData.DislikeReason]) {
        if !Display.pad {
            let momentTrampleVC = MomentTrampleViewController(userResolver: userResolver, entityID: postId, entityType: .post, dislikeReason: reasons)
            momentTrampleVC.modalPresentationStyle = .custom
            momentTrampleVC.finishCallBack = { [weak self, weak targetVC] in
                UDToast.showSuccess(with: BundleI18n.Moment.Moments_DislikeAPostWhy_ThanksForFeedback_Toast, on: targetVC?.view ?? UIView())
                self?.trampleStatus = .dislike
                self?.trackDetailPageClick(.tumbsdown(true))
            }
            targetVC.present(momentTrampleVC, animated: true)
        } else {
            if let trampleBtn = self.renderer.getView(by: MomentsActionBarComponentConstant.trampleDownKey.rawValue) as? ActionButton {
                let momentTrampleVC = MomentTrampleViewController(userResolver: userResolver, entityID: postId, entityType: .post, dislikeReason: reasons)
                momentTrampleVC.modalPresentationStyle = .popover
                momentTrampleVC.popoverPresentationController?.sourceView = trampleBtn
                momentTrampleVC.popoverPresentationController?.permittedArrowDirections = [.down, .up]
                momentTrampleVC.finishCallBack = {  [weak self, weak targetVC] in
                    UDToast.showSuccess(with: BundleI18n.Moment.Moments_DislikeAPostWhy_ThanksForFeedback_Toast, on: targetVC?.view ?? UIView())
                    self?.trampleStatus = .dislike
                    self?.trackDetailPageClick(.tumbsdown(true))
                }
                targetVC.present(momentTrampleVC, animated: true)
            }
        }
    }

    func share() {
        guard let postAPI, let securityAuditService else { return }
        let postId = self.entity.post.id
        let originShareCount = self.entity.post.shareCount
        let body = ShareMomentsPostBody(post: self.entity.post) { (chatIds, replyText) -> Observable<Void> in
            return postAPI.sharePost(to: chatIds, postId: postId, replyText: replyText, originShareCount: originShareCount, categoryIds: self.entity.post.categoryIds)
                .do { [weak self] (_) in
                    securityAuditService.auditEvent(.momentsForwardPost(postId: postId, forwardIds: chatIds), status: .success)
                    Tracer.trackCommunityTabShareSend(success: true, postID: postId)
                    DispatchQueue.main.async { [weak self] in
                        guard let view = self?.context.pageAPI?.view else { return }
                        UDToast.showSuccess(with: BundleI18n.Moment.Lark_Community_Shared,
                                              on: view)
                    }
                } onError: { _ in
                    securityAuditService.auditEvent(.momentsForwardPost(postId: postId, forwardIds: chatIds), status: .fail)
                }
        } cancel: {
            Tracer.trackCommunityTabShareSend(success: false, postID: postId)
        }
        if let targetVC = self.context.pageAPI {
            self.userResolver.navigator.present(
                body: body,
                from: targetVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
            Tracer.trackCommunityTabShare(source: self.scene, postID: postId)
        }
        self.trackFeedPageViewClick(.share)
        self.trackDetailPageClick(.share)
    }

    private func setOrEditBoardcast(forEdit: Bool) {
        guard let pageVC = self.context.pageAPI, let feedAPI else {
            return
        }
        let postId = self.entity.post.id
        func goToSetBoardcast(operationType: BoardcastOperationType) {
            let vc = BoardcastViewController(userResolver: self.userResolver, postId: postId, operationType: operationType)
            let nav = LkNavigationController(rootViewController: vc)
            self.userResolver.navigator.present(nav, from: pageVC, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
            )
        }
        DelayLoadingObservableWraper.wraper(observable: feedAPI.listBroadcasts(mock: false), showLoadingIn: pageVC.view)
            .observeOn(MainScheduler.instance)
            .subscribe { (boardcasts) in
                if forEdit {
                    guard let boardcast = boardcasts.first(where: { $0.postID == postId }) else {
                        return
                    }
                    goToSetBoardcast(operationType: .edit(boardcast))
                } else {
                    if boardcasts.count >= 3 {
                        let alertController = LarkAlertController()
                        alertController.setTitle(text: BundleI18n.Moment.Lark_Moments_ReplaceTrendingPost_PopupTitle)
                        let content: String = BundleI18n.Moment.Lark_Moments_ReplaceTrendingPost_PopupText
                        alertController.setContent(text: content)
                        alertController.addCancelButton()
                        alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_Replace, dismissCompletion: {
                            goToSetBoardcast(operationType: .create(boardcasts))
                        })
                        self.userResolver.navigator.present(alertController, from: pageVC)
                    } else {
                        goToSetBoardcast(operationType: .create(boardcasts))
                    }
                }
            } onError: { [weak self] (error) in
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_SetFailed, on: pageVC.view)
                Self.logger.error("fetch boardcasts for setBoardcast fail \(self?.entity.post.id ?? "")", error: error)
            }.disposed(by: self.context.disposeBag)
    }

    private func copyPostLink() {
        guard let domain = DomainSettingManager.shared.currentSetting["applink"]?.first else { return }
        let url = "https://\(domain)\(MomentPostDetailByIdBody.appLinkPattern)?postId=\(self.entity.post.id)&source=share"
        let config = PasteboardConfig(token: Token("LARK-PSDA-moment_post_share_link"))
        do {
            try SCPasteboard.generalUnsafe(config).string = url
            securityAuditService?.auditEvent(.momentsCopyLink(url: url, postId: self.entity.post.id), status: .success)
            if let pageVC = self.context.pageAPI {
                UDToast.showTips(with: BundleI18n.Moment.Lark_Community_LinkCopiedToast, on: pageVC.view, delay: 1.5)
            }
            Self.logger.info("copyPostLink succeeded: \(domain)")
        } catch {
            // 复制失败兜底逻辑
            securityAuditService?.auditEvent(.momentsCopyLink(url: url, postId: self.entity.post.id), status: .fail)
            if let pageVC = self.context.pageAPI {
                UDToast.showFailure(with: BundleI18n.Moment.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: pageVC.view)
            }
            Self.logger.error("copyPostLink failed: \(domain)")
        }
    }

    private func unsetBoardcast() {
        guard let pageVC = self.context.pageAPI, let postAPI else {
            return
        }
        let postID = self.entity.post.id
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Moment.Lark_Moments_RemoveFromTrending_PopupTitle)
        alertController.setContent(text: BundleI18n.Moment.Lark_Moments_RemoveFromTrending_PopupText)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Legacy_ConfirmTip, dismissCompletion: {
            DelayLoadingObservableWraper.wraper(observable: postAPI.unBoardcast(postId: postID),
                                                showLoadingIn: pageVC.view)
                    .observeOn(MainScheduler.instance)
                    .subscribe { (_) in
                        UDToast.showSuccess(with: BundleI18n.Moment.Lark_Moments_RemovedFromTrendingRefresh_Toast, on: pageVC.view)
                    } onError: { (error) in
                        UDToast.showSuccess(with: BundleI18n.Moment.Lark_Moments_RemoveFromTrendingFailedTryAgain_Toast, on: pageVC.view)
                        Self.logger.error("unset boardcast fail \(postID)", error: error)
                    }.disposed(by: self.disposeBag)
        })
        self.userResolver.navigator.present(alertController, from: pageVC)
    }

    private func deletePost() {
        guard let pageVC = self.context.pageAPI, let postAPI, let momentsAccountService else {
            return
        }
        DelayLoadingObservableWraper.wraper(observable: postAPI.deletePost(byID: self.entity.id, categoryIds: self.entity.post.categoryIds),
                                            showLoadingIn: pageVC.view)
                                            .observeOn(MainScheduler.instance)
                                            .subscribe(onNext: { (_) in
                                            }, onError: { (error) in
                                                if momentsAccountService.handleOfficialAccountErrorIfNeed(error: error, from: pageVC) == true {
                                                    return
                                                }
                                                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_DeleteFailed, on: pageVC.view)
                                            }).disposed(by: self.context.disposeBag)
    }

    private func setPostDistribution(_ isRecommend: Bool) {
        guard let pageVC = self.context.pageAPI, let adminAPI else {
            return
        }
        DelayLoadingObservableWraper
            .wraper(observable: adminAPI.setPost(id: self.entity.id,
                                                      distributionType: .notDistribution,
                                                      categoryIds: self.entity.post.categoryIds),
                    showLoadingIn: pageVC.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (_) in
                UDToast.showSuccess(with: MomentsDynamicTextKeyManager.textForKeyType(.removedFromHomepage,
                                                                                      isRecommend: isRecommend), on: pageVC.view)
            }, onError: { (_) in
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_SetFailed, on: pageVC.view)
        }).disposed(by: self.context.disposeBag)
    }

    private class func generateContent(userResolver: UserResolver,
                                       postEntity: RawData.PostEntity,
                                       context: BaseMomentContext,
                                       scene: MomentContextScene) -> BaseMomentSubCellViewModel<RawData.PostEntity, BaseMomentContext> {
        /// 是否是POST的类型
        if postEntity.post.type == .post {
            let binder = PostTextAndMediaContentComponentBinder(key: nil, context: context)
            return PostTextAndMediaContentCellViewModel(userResolver: userResolver,
                                                        entity: postEntity,
                                                        context: context,
                                                        binder: binder)
        } else {
            let binder = MomentsUnsupportContentViewModelBinder<RawData.PostEntity, BaseMomentContext>(key: nil, context: context)
            return MomentsUnsupportContentViewModel<RawData.PostEntity>(entity: postEntity,
                                                    context: context,
                                                    binder: binder)
        }

    }

    private class func generateSubViewModels(userResolver: UserResolver,
                                             postEntity: RawData.PostEntity,
                                             context: BaseMomentContext,
                                             scene: MomentContextScene,
                                             manageMode: RawData.ManageMode) -> [MomentsEntitySubType: BaseMomentSubCellViewModel<RawData.PostEntity, BaseMomentContext>] {
        var subvms: [MomentsEntitySubType: BaseMomentSubCellViewModel<RawData.PostEntity, BaseMomentContext>] = [:]
        let postCommentsBinder = NewPostCommentCellViewModelBinder(key: nil, context: context)
        let postCommentsVM = NewPostCommentCellViewModel(userResolver: userResolver, entity: postEntity, context: context, binder: postCommentsBinder)
        subvms[.postComments] = postCommentsVM

        let postStatusBinder = PostStatusCellViewModelBinder(key: nil, context: context)
        let postStatusVM = PostStatusCellViewModel(userResolver: userResolver, entity: postEntity, context: context, binder: postStatusBinder, manageMode: manageMode)
        subvms[.postStatus] = postStatusVM

        let binder = MomentsReactionCellViewModelBinder<RawData.PostEntity, BaseMomentContext>(key: nil, context: context)
        let postReactionVM = PostReactionCellViewModel(userResolver: userResolver, entity: postEntity, context: context, binder: binder)
        postReactionVM.canReaction = postEntity.canCurrentAccountReaction(momentsAccountService: try? userResolver.resolve(assert: MomentsAccountService.self))
        subvms[.reaction] = postReactionVM
        /// 有不支持的类型
        if postEntity.post.hasIncompatibleAction,
           postEntity.post.incompatibleAction.type == .hint {
            let binder = MomentsUnsupportContentViewModelBinder<RawData.PostEntity, BaseMomentContext>(key: nil, context: context)
            let unsupportVM = MomentsUnsupportContentViewModel<RawData.PostEntity>(entity: postEntity,
                                                                                   context: context,
                                                                                   binder: binder)
            subvms[.partUnsupport] = unsupportVM
        }
        return subvms
    }

    override func didSelect() {
        pushToMomentDetailWithShowKeyboard()
        self.trackFeedPageViewClick(.post)
    }

    private func pushToMomentDetailWithShowKeyboard(scrollState: PostDetailScrollState? = nil) {
        guard !self.entity.post.isUnderReview && self.entity.post.localStatus == .success,
              let pageAPI = self.context.pageAPI else {
            return
        }
        let body = MomentPostDetailByPostBody(post: self.entity,
                                              scrollState: scrollState,
                                              source: MomentsDataConverter.transformSenceToPageSource(self.scene))
        if pageAPI.childVCMustBeModalView {
            self.userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: pageAPI) { vc in
                vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
            }
        } else {
            self.userResolver.navigator.push(body: body, from: pageAPI)
        }
    }

    private func menuTypes() -> [MenuItemGenerator.MenuType] {
        var menuTypes: [MenuItemGenerator.MenuType] = []
        if self.entity.canCurrentAccountReaction(momentsAccountService: momentsAccountService) {
            menuTypes.append(.reaction)
        }
        menuTypes.append(.copy)
        if self.canBeTranslated {
            if self.canShowTranslation {
                if let userGeneralSettings {
                    menuTypes.append(.changeTranslationLanguage)
                    switch self.entity.post.getDisplayRule(userGeneralSettings: userGeneralSettings) {
                    case .withOriginal:
                        menuTypes.append(.hideTranslation)
                    case .onlyTranslation:
                        menuTypes.append(.showSourceText)
                    @unknown default:
                        break
                    }
                }
            } else {
                menuTypes.append(.translate)
            }
        }
        return menuTypes
    }

    func getCategoryName() -> String? {
        /// 板块详情页 不需要展示板块信息
        guard self.context.dataSourceAPI?.showPostFromCategory() ?? false else {
            return nil
        }
        /// 具体板块下 也不需要展示板块信息
        return self.entity.category?.category.name
    }

    func getCategoryIconKey() -> String? {
        /// 板块详情页 不需要展示板块信息
        guard self.context.dataSourceAPI?.showPostFromCategory() ?? false else {
            return nil
        }
        /// 具体板块下 也不需要展示板块信息
        return self.entity.category?.category.iconKey
    }

    func getCategoryID() -> String? {
        /// 板块详情页 不需要展示板块信息
        guard self.context.dataSourceAPI?.showPostFromCategory() ?? false else {
            return nil
        }
        /// 具体板块下 也不需要展示板块信息
        return self.entity.category?.category.categoryID
    }

    func reactionActionForType(_ type: String, reactionFrom: Tracer.ReactionSource) {
        let action: Bool
        if self.entity.post.reactionSet.reactions.contains(where: { (reactionInfo) -> Bool in
            return reactionInfo.type == type && reactionInfo.selfInvolved
        }) {
            self.postAPI?.deleteReaction(byID: self.entity.id,
                                        entityType: self.entity.type,
                                        reactionType: type,
                                        originalReactionSet: self.entity.originalReactionSet,
                                        categoryIds: self.entity.post.categoryIds,
                                        isAnonymous: self.entity.post.isAnonymous)
            .subscribe(onError: { [weak self] error in
                self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self?.context.pageAPI)
            }).disposed(by: self.disposeBag)
            action = false
        } else {
            self.createReactionService?.createReaction(byID: self.entity.id,
                                                      entityType: self.entity.type,
                                                      reactionType: type,
                                                      originalReactionSet: self.entity.originalReactionSet,
                                                      categoryIds: self.entity.post.categoryIds,
                                                      isAnonymous: self.entity.post.isAnonymous,
                                                      fromVC: self.context.pageAPI)
            action = true
        }
        Tracer.trackCommunityTabReaction(reaction: reactionFrom, contentType: .post, source: self.scene, postID: self.entity.id, commentID: nil, action: action)
    }

    func refreshTableView() {
        self.context.pageAPI?.refreshTableView()
    }
}

extension MomentPostCellViewModel: MenuItemGeneratorDelegate {
    func richTextForCopy() -> RawData.RichText? {
        guard let content = self.content as? PostTextAndMediaContentCellViewModel else { return nil }
        if content.richTextParser.attributedString.string.isEmpty {
            return nil
        }
        if content.displayRule == .onlyTranslation,
           content.needToShowTranslate,
           !content.translationRichTextParser.attributedString.string.isEmpty {
            return content.translationRichTextParser.richText
        }
        return self.entity.post.postContent.content
    }

    func didCopyContent() {
        securityAuditService?.auditEvent(.momentsCopyPost(postId: self.entity.postId), status: .success)
    }

    func doReaction(type: String) {
        reactionActionForType(type, reactionFrom: .long)
    }

    func thumbTapHandler() {
        guard let thumbsupService else { return }
        let thumbsup = thumbsupService.thumbsupKey
        reactionActionForType(thumbsup, reactionFrom: .btn)
        self.trackFeedPageViewClick(.reaction)
        self.trackDetailPageClick(.reaction)
    }

    func translate() {
        trackMenuClick(type: .translateButton(.translate))
        translateRequest()
    }

    func translateRequest() {
        self.translateService?.translateByUser(entity: .post(self.entity),
                                              manualTargetLanguage: nil,
                                              from: self.context.pageAPI)
        self.entity.post.translationInfo.translateStatus = .manual
        self.update(entity: self.entity)
    }

    func hideTranslation() {
        trackMenuClick(type: .translateButton(.show_original_text))
        hideTranslationRequest()
    }

    func hideTranslationRequest() {
        self.translateService?.hideTranslation(entity: .post(self.entity))
    }

    func changeTranslationLanguage() {
        trackMenuClick(type: .translateButton(.switch_languages))
        changeTranslationLanguageRequest()
    }

    func changeTranslationLanguageRequest() {
        if let pageAPI = self.context.pageAPI {
            self.translateService?.changeTranslationLanguage(entity: .post(self.entity), from: pageAPI)
        }
    }
}

extension MomentPostCellViewModel: PolybasicCellViewModelProtocol {
    var entityId: String { self.entity.id }

    func showMenu(
        _ sender: UIView,
        location: CGPoint,
        triggerGesture: UIGestureRecognizer?) {
        let menuItemInfo = self.menuItemGenerator.generate(menuTypes: self.menuTypes())
        guard !menuItemInfo.isEmpty,
              let controller = self.context.pageAPI?.reactionMenuBarFromVC else {
            return
        }
        let info = MessageMenuInfo(trigerView: sender, trigerLocation: location)
        let layout: MenuBarLayout
            if let insets = self.context.pageAPI?.reactionMenuBarInset {
            layout = MessageCommonMenuLayout(insets: insets)
        } else {
            layout = MessageCommonMenuLayout()
        }
        let menuViewModel = SimpleMenuViewModel(recentReactionMenuItems: menuItemInfo.recentReactionMenuItems,
                                                scene: .moments,
                                                allReactionMenuItems: menuItemInfo.allReactionMenuItems,
                                                allReactionGroups: menuItemInfo.allReactionGroups,
                                                actionItems: menuItemInfo.actionItems,
                                                triggerGesture: triggerGesture)
        menuViewModel.menuBar.reactionBarAtTop = false
        menuViewModel.menuBar.reactionSupportSkinTones = true
        let menuVc = MomentsMenuViewController(
            viewModel: menuViewModel,
            layout: layout,
            trigerView: info.trigerView,
            trigerLocation: info.trigerLocation
        )
        menuVc.dismissBlock = info.dismissBlock
        menuVc.show(in: controller)
        self.trackFeedPageViewClick(.post_press)
            self.trackMenuView()
    }

    var menuViewPageType: MomentsTracer.MenuViewPageType {
        switch scene {
        case .postDetail:
            return .detailPost
        case .profile:
            return .profile
        default:
            return .feed
        }
    }

    func trackMenuView() {
        guard let pageIdInfo = self.pageIdInfo() else { return }
        MomentsTracer.detailPageMenuView(circleId: self.entity.circleId,
                                         postId: self.entity.id,
                                         pageIdInfo: pageIdInfo,
                                         pageType: self.menuViewPageType)
    }

    func trackMenuClick(type: MomentsTracer.PostMoreClickType) {
        guard let pageIdInfo = self.pageIdInfo() else { return }
        MomentsTracer.detailPageMenuClick(clickType: type,
                                          circleId: self.entity.circleId,
                                          postId: self.entity.id,
                                          pageIdInfo: pageIdInfo,
                                          pageType: self.menuViewPageType)
    }
}

//打点
extension MomentPostCellViewModel {
    func trackFeedPageViewClick(_ clickType: MomentsTracer.FeedPageViewClickType) {
        if let scene = self.context.pageAPI?.scene {
            switch scene {
            case .feed(let postTab):
                MomentsTracer.trackFeedPageViewClick(clickType,
                                                     circleId: self.entity.post.circleID,
                                                     postId: self.entity.post.id,
                                                     type: .tabInfo(postTab),
                                                     detail: nil)
            case .hashTagDetail(let index, let id):
                MomentsTracer.trackFeedPageViewClick(clickType,
                                                     circleId: self.entity.post.circleID,
                                                     postId: self.entity.post.id,
                                                     type: .hashtag(id),
                                                     detail: index == 1 ? .hashtag_new : .hashtag_hot)
            case .categoryDetail(let index, let id):
                MomentsTracer.trackFeedPageViewClick(clickType,
                                                     circleId: self.entity.post.circleID,
                                                     postId: self.entity.post.id,
                                                     type: .category(id),
                                                     detail: index == 1 ? .category_post : .category_comment)
            case .profile:
                MomentsTracer.trackFeedPageViewClick(clickType,
                                                     circleId: self.entity.post.circleID,
                                                     postId: self.entity.post.id,
                                                     type: .moments_profile,
                                                     detail: nil,
                                                     profileInfo: MomentsTracer.ProfileInfo(profileUserId: context.dataSourceAPI?.getTrackValueForKey(.profileUserId) as? String ?? "",
                                                                                            isFollow: context.dataSourceAPI?.getTrackValueForKey(.isFollow) as? Bool ?? false,
                                                                                            isNickName: entity.post.isAnonymous,
                                                                                            isNickNameInfoTab: false))
            default:
                break
            }
        }
    }

    func trackDetailPageClick(_ clickType: MomentsTracer.DetailPageClickType) {
        if let scene = self.context.pageAPI?.scene {
            switch scene {
            case .postDetail:
                MomentsTracer.trackDetailPageClick(clickType,
                                                   circleId: self.entity.post.circleID,
                                                   postId: self.entity.post.id,
                                                   pageIdInfo: pageIdInfo())
            default:
                break
            }
        }
    }

    func pageIdInfo() -> MomentsTracer.PageIdInfo? {
        if let scene = self.context.pageAPI?.scene {
            switch scene {
            case .feed(let postTab):
                return .tabInfo(postTab)
            default:
                var pageId = entity.category?.category.categoryID
                if pageId == nil,
                   let content = content as? PostTextAndMediaContentCellViewModel {
                    let hashTagMap = content.richTextParser.attributeElement.hashTagMap
                    if hashTagMap.count == 1 {
                        pageId = hashTagMap.first?.value.item.id
                    }
                }
                return .pageId(pageId)
            }
        }
        return nil
    }

    func trackPostMoreView() {
        if let pageIdInfo = self.pageIdInfo() {
            MomentsTracer.trackPostMoreView(circleId: self.entity.post.circleID,
                                            postId: self.entity.post.id,
                                            pageIdInfo: pageIdInfo,
                                            pageType: self.menuViewPageType)
        }
    }

    func trackPostMoreClick(clickType: MomentsTracer.PostMoreClickType) {
        if let pageIdInfo = self.pageIdInfo() {
            MomentsTracer.trackPostMoreClick(clickType: clickType,
                                             circleId: self.entity.post.circleID,
                                             postId: self.entity.postId,
                                             pageIdInfo: pageIdInfo,
                                             pageType: self.menuViewPageType)
        }
    }
}

final class RecommendMomentPostCellComponentBinder: ComponentBinder<BaseMomentContext>, UserResolverWrapper {
    override public var component: ComponentWithContext<BaseMomentContext> {
        return _component
    }

    private let props: RecommendMomentPostCellProps
    private var style = ASComponentStyle()
    private var _component: RecommendMomentPostCellComponent
    let userResolver: UserResolver
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?

    init(userResolver: UserResolver, key: String? = nil, context: BaseMomentContext? = nil, contentComponent: ComponentWithContext<BaseMomentContext>,
         canReaction: Bool, canComment: Bool, categoryReadable: Bool) {
        self.userResolver = userResolver
        props = RecommendMomentPostCellProps(
            config: .default,
            contentComponent: contentComponent
        )
        props.canReaction = canReaction
        props.canComment = canComment
        props.categoryReadable = categoryReadable
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        style.flexDirection = .column
        style.backgroundColor = UIColor.ud.bgBody
        _component = RecommendMomentPostCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MomentPostCellViewModel else {
            assertionFailure()
            return
        }
        // 配置
        props.config = vm.config
        props.categoryName = vm.getCategoryName() ?? ""
        props.categoryIconKey = vm.getCategoryIconKey() ?? ""
        props.categoryId = vm.getCategoryID() ?? ""
        switch vm.scene {
        case .feed, .hashTagDetail, .categoryDetail, .unknown:
            props.userInfoScene = .feed
            props.arrangementMode = .spaceBetween
            props.actionBarArray = [MomentsActionBarComponentConstant.thumbsUpKey.rawValue,
                                    MomentsActionBarComponentConstant.replykey.rawValue,
                                    MomentsActionBarComponentConstant.forwardKey.rawValue,
                                    MomentsActionBarComponentConstant.moreKey.rawValue]
        case .postDetail:
            props.userInfoScene = .detail
            props.arrangementMode = .spaceBetween
            props.actionBarArray = (!vm.entity.post.isSelfOwner && vm.isEnableTrample) ?
                                    [MomentsActionBarComponentConstant.thumbsUpKey.rawValue,
                                    MomentsActionBarComponentConstant.trampleDownKey.rawValue,
                                    MomentsActionBarComponentConstant.replykey.rawValue,
                                     MomentsActionBarComponentConstant.forwardKey.rawValue] :
                                    [MomentsActionBarComponentConstant.thumbsUpKey.rawValue,
                                    MomentsActionBarComponentConstant.replykey.rawValue,
                                    MomentsActionBarComponentConstant.forwardKey.rawValue]
        case .profile:
            props.userInfoScene = .profile
            props.arrangementMode = .spaceBetween
            props.actionBarArray = [MomentsActionBarComponentConstant.thumbsUpKey.rawValue,
                                    MomentsActionBarComponentConstant.replykey.rawValue,
                                    MomentsActionBarComponentConstant.forwardKey.rawValue,
                                    MomentsActionBarComponentConstant.moreKey.rawValue]
        }
        // 头像和名字
        props.avatarTapped = { [weak vm] in
            vm?.onAvatarTapped()
        }
        // 点击评论
        props.replyTapHandler = { [weak vm] in
            vm?.onReplyTapped()
        }
        // 点击菜单
        props.menuTapHandler = { [weak vm] (view) in
            vm?.onMenuTapped(pointView: view)
        }
        props.thumbTapHandler = { [weak vm] in
            vm?.thumbTapHandler()
        }
        /// 点踩
        props.trampleTapHandler = { [weak vm] in
            vm?.trample()
        }
        props.forwardTapHandler = { [weak vm] in
            vm?.share()
        }
        props.categoryTapHandler = { [weak vm] in
            vm?.onCategoryTapped()
        }
        props.shouldShowLastReadTip = vm.shouldShowLastReadTop
        props.lastReadTipTap = { [weak vm] in
            vm?.refreshTableView()
        }
        props.config = vm.cellConfig
        props.commentCount = vm.commentCount
        props.contentComponent = vm.content.component
        props.createFormatTime = vm.formatTime
        props.userName = vm.entity.userDisplayName
        props.isOfficialUser = vm.entity.user?.momentUserType == .official
        /// recommend新增属性，部门，交互操作的icon和description
        props.userDepartment = vm.user?.department ?? ""
        props.interactiveIcon = vm.entity.post.interactiveInfo.iconKey
        props.interactiveDescription = vm.entity.post.interactiveInfo.description_p
        props.avatarKey = vm.user?.avatarKey ?? ""
        props.avatarId = vm.user?.userID ?? ""
        /// 当为profile页时，不允许点击头像
        props.avatarCanTap = vm.scene != .profile
        props.subComponents = vm.subvms.mapValues { $0.component }
        props.shareCount = vm.shareCount
        props.reactionCount = vm.reactionCount
        props.thumbsUpUseAnimation = !vm.userAlreadyThumbsUP
        props.canComment = vm.entity.canCurrentAccountComment
        props.canReaction = vm.entity.canCurrentAccountReaction(momentsAccountService: momentsAccountService)
        props.trampleState = vm.trampleStatus
        props.categoryReadable = vm.entity.category?.category.canRead ?? true
        props.canShowInteractive = vm.scene != .profile
        _component.props = props
    }
}

final class MomentPostCellComponentBinder: ComponentBinder<BaseMomentContext>, UserResolverWrapper {
    override public var component: ComponentWithContext<BaseMomentContext> {
        return _component
    }

    private let props: MomentPostCellProps
    private var style = ASComponentStyle()
    private var _component: MomentPostCellComponent
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?
    let userResolver: UserResolver
    init(userResolver: UserResolver, key: String? = nil, context: BaseMomentContext? = nil, contentComponent: ComponentWithContext<BaseMomentContext>,
         canReaction: Bool, canComment: Bool, categoryReadable: Bool) {
        self.userResolver = userResolver
        props = MomentPostCellProps(
            config: .default,
            contentComponent: contentComponent
        )
        props.canReaction = canReaction
        props.canComment = canComment
        props.categoryReadable = categoryReadable
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        style.flexDirection = .column
        style.backgroundColor = UIColor.ud.bgBody
        _component = MomentPostCellComponent(userResolver: userResolver,
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MomentPostCellViewModel else {
            assertionFailure()
            return
        }
        // 配置
        props.config = vm.config
        props.categoryName = vm.getCategoryName() ?? ""
        props.categoryIconKey = vm.getCategoryIconKey() ?? ""
        props.categoryId = vm.getCategoryID() ?? ""
        // 头像和名字
        props.avatarTapped = { [weak vm] in
            vm?.onAvatarTapped()
        }
        // 点击评论
        props.replyTapHandler = { [weak vm] in
            vm?.onReplyTapped()
        }
        // 点击菜单
        props.menuTapHandler = { [weak vm] (view) in
            vm?.onMenuTapped(pointView: view)
        }
        props.thumbTapHandler = { [weak vm] in
            vm?.thumbTapHandler()
        }
        props.forwardTapHandler = { [weak vm] in
            vm?.share()
        }
        props.categoryTapHandler = { [weak vm] in
            vm?.onCategoryTapped()
        }
        props.config = vm.cellConfig
        props.commentCount = vm.commentCount
        props.contentComponent = vm.content.component
        props.createFormatTime = vm.formatTime
        props.userName = vm.entity.userDisplayName
        props.isOfficialUser = vm.entity.user?.momentUserType == .official
        props.extraFields = vm.entity.userExtraFields
        props.avatarKey = vm.user?.avatarKey ?? ""
        props.avatarId = vm.user?.userID ?? ""
        /// 当为profile页时，不允许点击头像
        props.avatarCanTap = vm.scene != .profile
        props.subComponents = vm.subvms.mapValues { $0.component }
        props.shareCount = vm.shareCount
        props.reactionCount = vm.reactionCount
        props.thumbsUpUseAnimation = !vm.userAlreadyThumbsUP
        props.topContainerBottom = vm.topContainerBottom
        props.canComment = vm.entity.canCurrentAccountComment
        props.canReaction = vm.entity.canCurrentAccountReaction(momentsAccountService: momentsAccountService)
        props.categoryReadable = vm.entity.category?.category.canRead ?? true
        if props.config.needShowFollowBut, vm.canShowFollow {
            props.followButConfig = vm.followButConfig()
        } else {
            props.followButConfig = nil
        }
        _component.props = props
    }
}
