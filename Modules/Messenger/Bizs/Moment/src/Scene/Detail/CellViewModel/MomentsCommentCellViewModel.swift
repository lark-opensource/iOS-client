//
//  MomentsCommentCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/7.
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
import LarkMessageCore
import LarkContainer
import LarkAlertController
import LarkCore
import LarkEmotion
import UniverseDesignToast
import RxSwift
import LKCommonsLogging
import LarkSetting

extension RawData.CommentEntity: ReactionListEntitiesProtocol {
    var id: String {
        return self.comment.id
    }
    var reactions: [RawData.ReactionList] {
        return self.comment.reactionSet.reactions
    }
    var originalReactionSet: RawData.ReactionSet {
        return self.comment.reactionSet
    }
    var type: RawData.EntityType {
        return .comment
    }
    var circleId: String {
        return self.comment.circleID
    }
    var postId: String {
        return self.comment.postID
    }
}

extension RawData.CommentEntity: MomentsUnsupportTip {
    var unsupportTip: String? {
        if self.comment.hasIncompatibleAction {
            return self.comment.incompatibleAction.hint
        }
        return nil
    }
}

final class MomentsCommentCellViewModel: BaseMomentsEntityCellViewModel<RawData.CommentEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver

    static let logger = Logger.log(MomentsCommentCellViewModel.self, category: "Module.Moments.MomentsCommentCellViewModel ")

    private lazy var _identifier: String = {
        return [content.identifier, "comment"].joined(separator: "-")
    }()

    override var identifier: String {
        return _identifier
    }

    var user: MomentUser? {
        return self.entity.user
    }

    /**
     publishTimeMsec 评论的实际发布时间
     createTimeMsec  评论的实际创建时间
     feed和详情页: post优先展示publish_time，如果publish_time为0或空，展示create_time
     */
    var formatTime: String {
        var time = TimeInterval(entity.comment.publishTimeMsec / 1000)
        if time == 0 {
            time = TimeInterval(entity.comment.createTimeMsec / 1000)
        }
        let date = Date(timeIntervalSince1970: time)
        return MomentsTimeTool.displayTimeForDate(date)
    }

    var userAlreadyThumbsUP: Bool {
        guard let thumbsupService else { return false }
        let thumbsup = thumbsupService.thumbsupKey
        let hadThumpsUP = self.entity.comment.reactionSet.reactions.contains { (info) -> Bool in
            return info.type == thumbsup && info.selfInvolved
        }
        return hadThumpsUP
    }

    func onAvatarTapped() {
        guard let targetVC = self.context.pageAPI, let user = self.user else { return }
        MomentsNavigator.pushAvatarWith(userResolver: userResolver,
                                        user: user,
                                        from: targetVC,
                                        source: .detail,
                                        trackInfo: nil)
    }

    private lazy var menuItemGenerator: MenuItemGenerator = {
        let generator = MenuItemGenerator(userResolver: self.userResolver)
        generator.delegate = self
        return generator
    }()

    var replayCommentMaxWith: CGFloat {
        return context.maxCellWidth - 48 - 16
    }
    /// 这里暂时不考虑评论删除的问题，刷新数据更新UI
    var replayCommentAttr: NSAttributedString? {
        guard let userGeneralSettings, let fgService else { return nil }
        return MomentsDataConverter.convertCommentToAttributedStringWith(userResolver: userResolver,
                                                                         comment: entity.replyCommentEntity,
                                                                         userGeneralSettings: userGeneralSettings,
                                                                         fgService: fgService,
                                                                         ignoreTranslation: true)
    }

    var reactionCount: Int32 {
        return self.entity.comment.reactionSet.totalCount
    }

    var canShowTranslation: Bool {
        guard let userGeneralSettings, let fgService else { return false }
        return self.entity.comment.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
    }

    var canBeTranslated: Bool {
        return self.entity.comment.canBeTranslated(fgService: self.fgService)
    }

    var canCurrentAccountComment: Bool {
        return self.entity.comment.canComment
    }

    var canCurrentAccountReaction: Bool {
        //官方号禁止给匿名贴下的评论点赞
        if self.momentsAccountService?.isDisableReactionDueToAccount(user: self.postEntity?.user) ?? false {
            return false
        }
        return self.entity.comment.canReaction
    }

    @ScopedInjectedLazy private var postAPI: PostApiService?
    @ScopedInjectedLazy private var createReactionService: UserCreateReactionService?
    @ScopedInjectedLazy private var securityAuditService: MomentsSecurityAuditService?
    @ScopedInjectedLazy private var thumbsupService: ThumbsupReactionService?
    @ScopedInjectedLazy private var translateService: MomentsTranslateService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?
    @ScopedInjectedLazy var fgService: FeatureGatingService?

    private var getPostEntityCallBack: () -> RawData.PostEntity?

    fileprivate var postEntity: RawData.PostEntity? {
        return getPostEntityCallBack()
    }

    init(userResolver: UserResolver,
         commentEntity: RawData.CommentEntity,
         context: BaseMomentContext,
         getPostEntityCallBack: @escaping () -> RawData.PostEntity?,
         isRecommend: Bool) {
        self.userResolver = userResolver
        self.getPostEntityCallBack = getPostEntityCallBack
        let content = MomentsCommentCellViewModel.generateContent(userResolver: userResolver,
                                                                  commentEntity: commentEntity,
                                                                  context: context)
        let subvms = MomentsCommentCellViewModel.generateSubViewModels(userResolver: userResolver,
                                                                       commentEntity: commentEntity,
                                                                       context: context,
                                                                       getPostEntityCallBack: getPostEntityCallBack)
        let post = getPostEntityCallBack()
        let momentsAccountService = try? userResolver.resolve(assert: MomentsAccountService.self)
        let isDisableReactionDueToAccount = momentsAccountService?.isDisableReactionDueToAccount(user: post?.user) ?? false
        super.init(entity: commentEntity,
                   content: content,
                   subvms: subvms,
                   context: context,
                   binder: MomentsCommentCellComponentBinder(userResolver: userResolver,
                                                             context: context,
                                                             contentComponent: content.component,
                                                             canReaction: commentEntity.comment.canReaction && !isDisableReactionDueToAccount,
                                                             canComment: commentEntity.comment.canComment,
                                                             isRecommend: isRecommend))
        self.content.initRenderer(renderer)
        self.addChild(self.content)
        super.calculateRenderer()
    }

    override func update(entity: RawData.CommentEntity) {
        super.update(entity: entity)
        self.content.update(entity: entity)
        super.calculateRenderer()
    }

    private var displaying = false
    override func willDisplay() {
        super.willDisplay()
        guard !displaying else { return }
        displaying = true
        translateService?.autoTranslateIfNeed(entity: .comment(self.entity))
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        displaying = false
    }

    class func generateContent(userResolver: UserResolver,
                               commentEntity: RawData.CommentEntity,
                               context: BaseMomentContext) -> BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext> {
        //todo: 要区分内容类型、处理未识别的消息内容
        let binder = CommentTextAndMediaContentComponentBinder(key: nil, context: context)
        let content = CommentTextAndMediaContentCellViewModel(userResolver: userResolver,
                                                              entity: commentEntity,
                                                              context: context,
                                                              binder: binder)
        return content
    }

    private class func generateSubViewModels(userResolver: UserResolver,
                                             commentEntity: RawData.CommentEntity,
                                             context: BaseMomentContext,
                                             getPostEntityCallBack: @escaping () -> RawData.PostEntity?) ->
    [MomentsEntitySubType: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext>] {
        var subvms: [MomentsEntitySubType: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext>] = [:]

        let commentStatusBinder = CommentStatusCellViewModelBinder(key: nil, context: context)
        let commentStatusVM = CommentStatusCellViewModel(userResolver: userResolver, entity: commentEntity, context: context, binder: commentStatusBinder)
        subvms[.commentStatus] = commentStatusVM

        let binder = MomentsReactionCellViewModelBinder<RawData.CommentEntity, BaseMomentContext>(key: nil, context: context)
        let commentReactionVM = CommentReactionCellViewModel(userResolver: userResolver, entity: commentEntity, getPostEntityCallBack: getPostEntityCallBack, context: context, binder: binder)
        subvms[.reaction] = commentReactionVM
        /// 有IncompatibleAction且为hint， 展示不兼容文案
        let comment = commentEntity.comment
        if comment.hasIncompatibleAction,
           comment.incompatibleAction.type == .hint {
            let binder = MomentsUnsupportContentViewModelBinder<RawData.CommentEntity, BaseMomentContext>(key: nil, context: context)
            let unsupportVM = MomentsUnsupportContentViewModel<RawData.CommentEntity>(entity: commentEntity,
                                                                                   context: context,
                                                                                   binder: binder)
            subvms[.partUnsupport] = unsupportVM
        }
        return subvms
    }

    func showMenu(
        _ sender: UIView,
        location: CGPoint,
        triggerGesture: UIGestureRecognizer?) {
        self.menuTypes { [weak self] menuTypes in
            guard let menuItemInfo = self?.menuItemGenerator.generate(menuTypes: menuTypes), !menuItemInfo.isEmpty,
                  let controller = self?.context.pageAPI?.reactionMenuBarFromVC else {
                return
            }
            let info = MessageMenuInfo(trigerView: sender, trigerLocation: location)
            let layout: MenuBarLayout
            if let insets = self?.context.pageAPI?.reactionMenuBarInset {
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
        }
        self.trackDetailPageClick(.comment_press)
        self.trackMenuView()
    }

    private func menuTypes(callback: @escaping ([MenuItemGenerator.MenuType]) -> Void) {
        var menuTypes: [MenuItemGenerator.MenuType] = []
        menuTypes.append(.copy)
        if self.canCurrentAccountReaction {
            menuTypes.append(.reaction)
        }

        if self.canCurrentAccountComment {
            menuTypes.append(.reply(enable: true))
        }

        if self.entity.comment.canDelete {
            menuTypes.append(.delete)
        }
        // 自己不能举报
        if self.entity.comment.canReport {
            menuTypes.append(.report)
        }
        if self.canBeTranslated {
            if self.canShowTranslation {
                menuTypes.append(.changeTranslationLanguage)
                if let userGeneralSettings = userGeneralSettings {
                    switch self.entity.comment.getDisplayRule(userGeneralSettings: userGeneralSettings) {
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
        callback(menuTypes)
    }

    func reactionActionForType(_ type: String, reactionFrom: Tracer.ReactionSource) {
        let action: Bool
        if self.entity.comment.reactionSet.reactions.contains(where: { (reactionInfo) -> Bool in
            return reactionInfo.type == type && reactionInfo.selfInvolved
        }) {
            self.postAPI?.deleteReaction(byID: self.entity.id,
                                        entityType: self.entity.type,
                                        reactionType: type,
                                        originalReactionSet: self.entity.originalReactionSet,
                                        categoryIds: [],
                                        isAnonymous: self.reactionForAnonymous())
            .subscribe(onError: { [weak self] error in
                self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self?.context.pageAPI)
            }).disposed(by: self.disposeBag)
            action = false
        } else {
            self.createReactionService?.createReaction(byID: self.entity.id,
                                                      entityType: self.entity.type,
                                                      reactionType: type,
                                                      originalReactionSet: self.entity.originalReactionSet,
                                                      categoryIds: [],
                                                      isAnonymous: self.reactionForAnonymous(),
                                                      fromVC: self.context.pageAPI)
            action = true
        }
        Tracer.trackCommunityTabReaction(reaction: reactionFrom,
                                         contentType: .comment,
                                         source: .postDetail,
                                         postID: nil,
                                         commentID: self.entity.id, action: action)
    }

    private func reactionForAnonymous() -> Bool {
        return self.postEntity?.post.isAnonymous ?? false || self.entity.comment.isAnonymous
    }
}

extension MomentsCommentCellViewModel: MenuItemGeneratorDelegate {
    func richTextForCopy() -> RawData.RichText? {
        guard let content = self.content as? CommentTextAndMediaContentCellViewModel else { return nil }
        if content.richTextParser.attributedString.string.isEmpty {
            return nil
        }
        if content.displayRule == .onlyTranslation,
           content.needToShowTranslate,
           !content.translationRichTextParser.attributedString.string.isEmpty {
            return content.translationRichTextParser.richText
        }
        return self.entity.comment.content.content
    }

    func didCopyContent() {
        securityAuditService?.auditEvent(.momentsCopyComment(commentId: self.entity.id, postId: self.entity.postId), status: .success)
    }

    func doReply() {
        self.replyWithFromMenu(true)
    }

    func didSelectCell() {
        self.trackDetailPageClick(.reply_comment)
        self.replyWithFromMenu(false)
    }

    func replyWithFromMenu(_ fromMenu: Bool) {
        self.context.pageAPI?.reply(by: self.entity, fromMenu: fromMenu)
    }

    func delete() {
        guard let pageVC = self.context.pageAPI, let postEntity = self.postEntity else {
            return
        }
        let alertController = LarkAlertController()
        let title: String
        if self.entity.comment.isSelfOwner {
            title = BundleI18n.Moment.Lark_Community_AreYouSureYouWantToDeleteThisComment
        } else {
            title = BundleI18n.Moment.Lark_Community_AreYouSureDeleteComment(self.entity.userDisplayName)
        }
        alertController.setTitle(text: title)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_DeleteConfirm, dismissCompletion: {
            DelayLoadingObservableWraper
                .wraper(observable: self.postAPI?.deleteComment(byID: self.entity.id,
                                                               postId: postEntity.id,
                                                               postOriginCommentSet: postEntity.post.commentSet,
                                                                categoryIds: postEntity.post.categoryIds) ?? .empty(),
                        showLoadingIn: pageVC.view)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                }, onError: { [weak self] error in
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self?.context.pageAPI) == true {
                        return
                    }
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_DeleteFailed, on: pageVC.view)
                }).disposed(by: self.context.disposeBag)
        })
        userResolver.navigator.present(alertController, from: pageVC)
    }

    func doReaction(type: String) {
        reactionActionForType(type, reactionFrom: .long)
    }

    func thumbsupTapped() {
        guard let type = self.thumbsupService?.thumbsupKey else { return }
        reactionActionForType(type, reactionFrom: .btn)
    }

    func report() {
        guard let pageVC = self.context.pageAPI else {
            return
        }
        let report = ReportViewController(userResolver: self.userResolver, type: .comment(self.entity.id))
        userResolver.navigator.presentOrPush(report,
                                       wrap: LkNavigationController.self,
                                       from: pageVC,
                                       prepareForPresent: { vc in
            vc.modalPresentationStyle = .formSheet
        })
    }

    func translate() {
        self.trackMenuClick(type: .translateButton(.translate))
        self.translateService?.translateByUser(entity: .comment(self.entity),
                                              manualTargetLanguage: nil,
                                              from: self.context.pageAPI)
        self.entity.comment.translationInfo.translateStatus = .manual
        self.update(entity: self.entity)
    }

    func hideTranslation() {
        self.trackMenuClick(type: .translateButton(.show_original_text))
        self.translateService?.hideTranslation(entity: .comment(self.entity))
    }

    func changeTranslationLanguage() {
        self.trackMenuClick(type: .translateButton(.switch_languages))
        if let pageAPI = self.context.pageAPI {
            self.translateService?.changeTranslationLanguage(entity: .comment(self.entity), from: pageAPI)
        }
    }
}

//打点
extension MomentsCommentCellViewModel {
    func trackDetailPageClick(_ clickType: MomentsTracer.DetailPageClickType) {
        MomentsTracer.trackDetailPageClick(clickType,
                                           circleId: self.postEntity?.circleId,
                                           postId: self.postEntity?.postId,
                                           pageIdInfo: context.dataSourceAPI?.getTrackValueForKey(.pageIdInfo) as? MomentsTracer.PageIdInfo)
    }

    func trackMenuView() {
        MomentsTracer.detailPageMenuView(circleId: self.postEntity?.circleId,
                                         postId: self.postEntity?.postId,
                                         pageIdInfo: .pageId(self.postEntity?.category?.category.categoryID),
                                         pageType: .detailComment)
    }

    func trackMenuClick(type: MomentsTracer.PostMoreClickType) {
        MomentsTracer.detailPageMenuClick(clickType: type,
                                          circleId: self.postEntity?.circleId,
                                          postId: self.postEntity?.postId,
                                          pageIdInfo: .pageId(self.postEntity?.category?.category.categoryID),
                                          pageType: .detailComment)
    }
}

final class MomentsCommentCellComponentBinder: ComponentBinder<BaseMomentContext> {
    override public var component: ComponentWithContext<BaseMomentContext> {
        return _component
    }
    private var _component: MomentsCommentCellComponent
    private var style = ASComponentStyle()
    private let props: CommentCellProps

    init(userResolver: UserResolver,
         key: String? = nil,
         context: BaseMomentContext? = nil,
         contentComponent: ComponentWithContext<BaseMomentContext>,
         canReaction: Bool,
         canComment: Bool,
         isRecommend: Bool) {
        props = CommentCellProps(
            contentComponent: contentComponent
        )
        props.canComment = canComment
        props.canReaction = canReaction
        props.isRecommend = isRecommend
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        style.flexDirection = .column
        style.backgroundColor = .ud.bgBody
        _component = MomentsCommentCellComponent(userResolver: userResolver,
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MomentsCommentCellViewModel else {
            assertionFailure()
            return
        }
        // 头像和名字
        props.avatarTapped = { [weak vm] in
            vm?.onAvatarTapped()
        }
        props.thumbsupTapped = { [weak vm] in
            vm?.thumbsupTapped()
        }
        props.contentComponent = vm.content.component
        props.createFormatTime = vm.formatTime
        props.userName = vm.entity.userDisplayName
        props.isOfficialUser = vm.entity.user?.momentUserType == .official
        props.extraFields = vm.entity.userExtraFields
        props.avatarKey = vm.user?.avatarKey ?? ""
        props.avatarId = vm.user?.userID ?? ""
        props.replyCommentMaxWidth = vm.replayCommentMaxWith
        props.replyCommentAttributedString = vm.replayCommentAttr
        props.subComponents = vm.subvms.mapValues { $0.component }
        props.reactionCount = vm.reactionCount
        props.thumbsUpUseAnimation = !vm.userAlreadyThumbsUP
        props.canComment = vm.canCurrentAccountComment
        props.canReaction = vm.canCurrentAccountReaction
        _component.props = props
    }
}
