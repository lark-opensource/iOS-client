//
//  MomentsProfileActivityCellViewModel.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import UIKit
import LarkMessageBase
import Foundation
import AsyncComponent
import RxSwift
import EEFlexiable
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkCore
import LarkMessageCore
import LarkMenuController
import LarkContainer
import LarkSDKInterface
import LarkSetting

final class MomentsProfileActivityCellViewModel: BaseMomentCellViewModel<BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver
    let content: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext>
    let activityEntry: RawData.ProfileActivityEntry
    var richTextParser: RichTextAbilityParser?

    @ScopedInjectedLazy var translateService: MomentsTranslateService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    var currentUser: MomentUser? {
        return self.activityEntry.currentUser
    }
    /// 生成菜单选项
    private lazy var menuItemGenerator: MenuItemGenerator = {
        let generator = MenuItemGenerator(userResolver: self.userResolver)
        generator.delegate = self
        return generator
    }()

    public override var identifier: String {
        return "unsupport_content"
    }

    //返回值：是否需要update
    func updateActivityEntryIfNeed(targetCommentId: String, doUpdate: (RawData.CommentEntity) -> RawData.CommentEntity?) -> Bool {
        var needToUpdateRichTextAbilityParser = false
        var needToUpdateContent = false
        switch activityEntry.type {
        case .unknown, .publishPost, .reactionToPost, .followUser:
            break
        case .commentToPost(let entity):
            if let comment = entity.comment,
                comment.id == targetCommentId {
                let newCommnet = doUpdate(comment)
                activityEntry.type = .commentToPost(.init(postEntity: entity.postEntity, comment: newCommnet))
                if let newComment = newCommnet {
                    content.update(entity: newComment)
                    needToUpdateContent = true
                }
            }
        case .replyToComment(let entity):
            if let comment = entity.comment,
                comment.id == targetCommentId {
                let newCommnet = doUpdate(comment)
                activityEntry.type = .replyToComment(.init(replyToComment: entity.replyToComment, comment: newCommnet))
                if let newComment = newCommnet {
                    content.update(entity: newComment)
                    needToUpdateContent = true
                }
            } else if let replyToComment = entity.replyToComment,
                      replyToComment.id == targetCommentId {
                activityEntry.type = .replyToComment(.init(replyToComment: doUpdate(replyToComment), comment: entity.comment))
                needToUpdateRichTextAbilityParser = true
            }
        case .reactionToCommment(let entity):
            if let comment = entity.comment,
                comment.id == targetCommentId {
                activityEntry.type = .reactionToCommment(.init(reactionType: entity.reactionType, comment: doUpdate(comment)))
                needToUpdateRichTextAbilityParser = true
            }
        }

        if needToUpdateRichTextAbilityParser {
            updateRichTextAbilityParser()
        } else if needToUpdateContent {
            super.calculateRenderer()
        }
        return needToUpdateContent || needToUpdateRichTextAbilityParser
    }

    //返回值：是否需要update
    func updateActivityEntryIfNeed(targetPostId: String, doUpdate: (RawData.PostEntity) -> RawData.PostEntity?) -> Bool {
        var needToUpdateRichTextAbilityParser = false
        switch activityEntry.type {
        case .unknown, .replyToComment, .reactionToCommment, .followUser:
            break
        case .publishPost(let entity):
            if let post = entity.postEntity,
               post.id == targetPostId {
                activityEntry.type = .publishPost(.init(postEntity: doUpdate(post)))
                needToUpdateRichTextAbilityParser = true
            }
        case .commentToPost(let entity):
            if let post = entity.postEntity,
               post.id == targetPostId {
                activityEntry.type = .commentToPost(.init(postEntity: doUpdate(post), comment: entity.comment))
                needToUpdateRichTextAbilityParser = true
            }
        case .reactionToPost(let entity):
            if let post = entity.postEntity,
               post.id == targetPostId {
                activityEntry.type = .reactionToPost(.init(reactionType: entity.reactionType, postEntity: doUpdate(post)))
                needToUpdateRichTextAbilityParser = true
            }
        }

        if needToUpdateRichTextAbilityParser {
            updateRichTextAbilityParser()
        }
        return needToUpdateRichTextAbilityParser
    }

    init(userResolver: UserResolver,
         activityEntry: RawData.ProfileActivityEntry,
         context: BaseMomentContext) {
        self.userResolver = userResolver
        self.activityEntry = activityEntry
        let content = MomentsProfileActivityCellViewModel.generateContent(userResolver: userResolver,
                                                                          activityEntry: activityEntry,
                                                                          context: context)
        let binder: ComponentBinder<BaseMomentContext> = MomentsProfileActivityCellViewModelBinder(context: context,
                                                                                                   contentComponent: content.component)
        self.content = content
        super.init(context: context,
                   binder: binder)

        if let userGeneralSettings, let fgService, let richText = self.activityEntry.type.translation(fgService: fgService, userGeneralSettings: userGeneralSettings)
            ?? self.activityEntry.type.richText() {
            var urlPreviewProvider: LarkCoreUtils.URLPreviewProvider?
            let useTranslation: Bool
            switch self.activityEntry.type.targetEntity() {
            case .empty:
                urlPreviewProvider = nil
                useTranslation = false
            case .comment(let comment):
                useTranslation = comment.comment.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
                urlPreviewProvider = { [weak self] elementID, customAttributes in
                   return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                               commentEntity: comment,
                                                                               useTranslation: useTranslation,
                                                                               customAttributes: customAttributes)
               }
            case .post(let post):
                useTranslation = post.post.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
                urlPreviewProvider = { [weak self] elementID, customAttributes in
                   return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                               postEntity: post,
                                                                               useTranslation: useTranslation,
                                                                               customAttributes: customAttributes)
               }
            }
            self.richTextParser = RichTextAbilityParser(userResolver: userResolver,
                                                        dependency: context,
                                                       richText: richText,
                                                       font: UIFont.systemFont(ofSize: 17),
                                                       showTranslatedTag: useTranslation,
                                                       textColor: UIColor.ud.textTitle,
                                                       iconColor: UIColor.ud.textTitle,
                                                       tagType: .normal,
                                                       numberOfLines: 0,
                                                       contentLineSpacing: 4,
                                                       needCheckFromMe: false,
                                                       urlPreviewProvider: urlPreviewProvider)
        }
        self.content.initRenderer(renderer)
        self.addChild(self.content)
        super.calculateRenderer()
    }

    func updateRichTextAbilityParser() {
        if let userGeneralSettings, let fgService, let richText = self.activityEntry.type.translation(fgService: fgService, userGeneralSettings: userGeneralSettings)
            ?? self.activityEntry.type.richText() {
            var urlPreviewProvider: LarkCoreUtils.URLPreviewProvider?
            var useTranslation: Bool
            switch self.activityEntry.type.targetEntity() {
            case .empty:
                urlPreviewProvider = nil
                useTranslation = false
            case .comment(let comment):
                useTranslation = comment.comment.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
                urlPreviewProvider = { [weak self] elementID, customAttributes in
                   return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                               commentEntity: comment,
                                                                               useTranslation: useTranslation,
                                                                               customAttributes: customAttributes)
               }
            case .post(let post):
                useTranslation = post.post.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
                urlPreviewProvider = { [weak self] elementID, customAttributes in
                   return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                               postEntity: post,
                                                                               useTranslation: useTranslation,
                                                                               customAttributes: customAttributes)
               }
            }
            self.richTextParser?.update(richText: richText,
                                       urlPreviewProvider: urlPreviewProvider,
                                       showTranslatedTag: useTranslation)
            super.calculateRenderer()
        }
    }

    private var displaying = false
    override func willDisplay() {
        super.willDisplay()
        guard !displaying else { return }
        displaying = true

        func autoTranslateIfNeed(post: RawData.PostEntity?) {
            guard let post = post, let translateService else { return }
            translateService.autoTranslateIfNeed(entity: .post(post))
        }

        func autoTranslateIfNeed(comment: RawData.CommentEntity?) {
            guard let comment = comment, let translateService else { return }
            translateService.autoTranslateIfNeed(entity: .comment(comment))
        }

        switch self.activityEntry.type {
        case .followUser:
            break
        case .commentToPost(let entity):
            autoTranslateIfNeed(post: entity.postEntity)
            autoTranslateIfNeed(comment: entity.comment)
        case .publishPost(let entity):
            autoTranslateIfNeed(post: entity.postEntity)
        case .reactionToCommment(let entity):
            autoTranslateIfNeed(comment: entity.comment)
        case .reactionToPost(let entity):
            autoTranslateIfNeed(post: entity.postEntity)
        case .replyToComment(let entity):
            autoTranslateIfNeed(comment: entity.comment)
            autoTranslateIfNeed(comment: entity.replyToComment)
        case .unknown:
            break
        }
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        displaying = false
    }

    lazy var titleAttributedText: NSAttributedString = {
        /// avatarTap 用户点击关注的人
        let attributedText = MomentsProfileActivityEntryParser.titleParseFor(self.activityEntry,
                                                                              user: self.currentUser,
                                                                              avatarTap: { [weak self] user in
            if let user = user, let pageAPI = self?.context.pageAPI, let self = self {
                MomentsNavigator.pushAvatarWith(userResolver: self.userResolver,
                                                user: user,
                                                from: pageAPI,
                                                source: .profile,
                                                trackInfo: nil)
            }
        })
        return attributedText
    }()

    var interactionAttributedText: NSAttributedString {
        guard let richTextParser = self.richTextParser else {
            return NSAttributedString()
        }
        let attr = NSMutableAttributedString()
        var isDeleComment = false
        var user: MomentUser?
        switch self.activityEntry.type.targetEntity() {
        case .empty:
            break
        case .post(let postEntity):
            attr.append(richTextParser.attributedString)
            if attr.string.isEmpty {
                let content = postEntity.post.postContent
                if !content.imageSetList.isEmpty {
                    attr.append(NSAttributedString(string: BundleI18n.Moment.Lark_Community_Image))
                } else if !content.media.driveURL.isEmpty || !content.media.localURL.isEmpty {
                    attr.append(NSAttributedString(string: BundleI18n.Moment.Lark_Community_Video))
                }
            }
            user = postEntity.user
        case .comment(let comment):
            /// 如果帖子被删除
            if comment.comment.isDeleted {
                attr.append(NSAttributedString(string: BundleI18n.Moment.Moments_CommentDeleted_Placeholder,
                                               attributes: [:]))
                isDeleComment = true
            } else {
                attr.append(richTextParser.attributedString)
                let imageSet = comment.comment.content.imageSet
                if attr.string.isEmpty {
                    if !imageSet.key.isEmpty ||
                        !imageSet.origin.key.isEmpty ||
                        !imageSet.thumbnail.key.isEmpty {
                        attr.append(NSAttributedString(string: BundleI18n.Moment.Lark_Community_Image))
                    }
                }
                user = comment.user
            }
        }
        let finalStr = NSMutableAttributedString()
        if let user = user {
            finalStr.append(NSAttributedString(string: "\(user.displayName): "))
        }
        finalStr.append(attr)
        return MomentsDataConverter.addAttributesForAttributeString(finalStr,
                                                                    font: UIFont.systemFont(ofSize: 17),
                                                                    textColor: isDeleComment ? UIColor.ud.textCaption : UIColor.ud.textTitle)
    }

    lazy var interactionUser: MomentUser? = {
        switch self.activityEntry.type.targetEntity() {
        case.post(let postEntity):
            return postEntity.user
        case.comment(let commentEntity):
            return commentEntity.user
        case.empty:
            return nil
        }
    }()

    lazy var formatTime: String = {
        let time = TimeInterval(self.activityEntry.activityEntry.timestampSec)
        let date = Date(timeIntervalSince1970: time)
        return MomentsTimeTool.displayTimeForDate(date)
    }()

    func tapAvatar(userId: String) {
        guard let targetVC = self.context.pageAPI,
                let user = self.currentUser else { return }
        MomentsNavigator.pushAvatarWith(userResolver: userResolver,
                                        user: user,
                                        from: targetVC,
                                        source: Tracer.LarkPrfileSource.profile,
                                        trackInfo: nil)
    }

    //true表示已被翻译，false表示还没有被翻译，nil表示无法翻译
    var isTranslated: Bool? {
        switch self.activityEntry.type {
        case .publishPost(let entity):
            return entity.postEntity?.post.isTranslated
        case .commentToPost(let entity):
            return entity.comment?.comment.isTranslated
        case .replyToComment(let entity):
            return entity.comment?.comment.isTranslated
        case .reactionToPost, .reactionToCommment, .followUser, .unknown:
            return nil
        }
    }

    var translateTargetEntity: RawData.TranslateTargetEntity? {
        switch self.activityEntry.type {
        case .publishPost(let entity):
            if let postEntity = entity.postEntity {
                return .post(postEntity)
            }
            return nil
        case .commentToPost(let entity):
            if let commentEntity = entity.comment {
                return .comment(commentEntity)
            }
            return nil
        case .replyToComment(let entity):
            if let commentEntity = entity.comment {
                return .comment(commentEntity)
            }
            return nil
        case .reactionToPost, .reactionToCommment, .followUser, .unknown:
            return nil
        }
    }

    private func menuTypes() -> [MenuItemGenerator.MenuType] {
        var menuTypes: [MenuItemGenerator.MenuType] = [.copy]
        //这里暂不提供手动翻译能力
        return menuTypes
    }

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
            menuViewModel.menuBar.reactionSupportSkinTones = false
            let menuVc = MomentsMenuViewController(
                viewModel: menuViewModel,
                layout: layout,
                trigerView: info.trigerView,
                trigerLocation: info.trigerLocation
            )
            menuVc.dismissBlock = info.dismissBlock
            menuVc.show(in: controller)
    }
    /// 点击交互区域
    func onInteractionAreaTap() {
        guard let targetVC = self.context.targetVC else {
            return
        }
        let data = self.activityEntry.type.getBinderData()
        switch self.activityEntry.type.targetEntity() {
        case .empty:
            break
        case .post(let postEntity):
            let body = MomentPostDetailByPostBody(post: postEntity,
                                                  source: MomentsDataConverter.transformSenceToPageSource(.profile))
            pushOrPresentToDetailPostBody(body)

        case .comment(let commentEntity):
            pushOrPresentToDetailIdBody(by: commentEntity)
        }
    }

    override func didSelect() {
        guard let targetVC = self.context.targetVC else {
            return
        }
        switch self.activityEntry.type {
        case .unknown, .followUser(_), .publishPost(_):
            return
        case .commentToPost(let commentToPostEntry):
            if let post = commentToPostEntry.postEntity {
                let body = MomentPostDetailByPostBody(post: post,
                                                      scrollState: .toCommentId(commentToPostEntry.comment?.id),
                                                      source: MomentsDataConverter.transformSenceToPageSource(.profile))
                pushOrPresentToDetailPostBody(body)
            }
        case .replyToComment(let replyToCommentEntry):
            if let comment = replyToCommentEntry.comment {
                pushOrPresentToDetailIdBody(by: comment)
            }
        case .reactionToPost(let reactionToPostEntry):
            if let post = reactionToPostEntry.postEntity {
                let body = MomentPostDetailByPostBody(post: post,
                                                      source: MomentsDataConverter.transformSenceToPageSource(.profile))
                pushOrPresentToDetailPostBody(body)
            }

        case .reactionToCommment(let reactionToCommmentEntry):
            if let comment = reactionToCommmentEntry.comment {
                pushOrPresentToDetailIdBody(by: comment)
            }
        }
    }

    func pushOrPresentToDetailIdBody(by comment: RawData.CommentEntity) {
        guard let pageAPI = context.pageAPI, !comment.comment.isDeleted else {
            return
        }
        let body = MomentPostDetailByIdBody(postId: comment.postId,
                                            toCommentId: comment.comment.isDeleted ? nil : comment.id,
                                            autoShowKeyboard: false,
                                            source: .profile)
        if pageAPI.childVCMustBeModalView {
            userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: pageAPI) { vc in
                vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
            }
        } else {
            userResolver.navigator.push(body: body, from: pageAPI)
        }
    }

    func pushOrPresentToDetailPostBody(_ body: MomentPostDetailByPostBody) {
        guard let pageAPI = context.pageAPI else {
            return
        }
        if pageAPI.childVCMustBeModalView {
            userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: pageAPI) { vc in
                vc.preferredContentSize = MomentsViewAdapterViewController.largeModalViewSize
            }
        } else {
            userResolver.navigator.push(body: body, from: pageAPI)
        }
    }
}

extension MomentsProfileActivityCellViewModel: MenuItemGeneratorDelegate {
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
        return content.richTextParser.richText
    }

    func didCopyContent() {
    }

    func doReaction(type: String) {
    }

    func thumbTapHandler() {
    }

    func translate() {
        guard let translateTargetEntity = self.translateTargetEntity, let translateService else { return }
        self.translateService?.translateByUser(entity: translateTargetEntity,
                                              manualTargetLanguage: nil,
                                              from: self.context.pageAPI)
    }

    func hideTranslation() {
        guard let translateTargetEntity = self.translateTargetEntity, let translateService else { return }
        translateService.hideTranslation(entity: translateTargetEntity)
    }

    func changeTranslationLanguage() {
        guard let translateTargetEntity = self.translateTargetEntity,
              let pageAPI = self.context.pageAPI,
              let translateService else { return }
        translateService.changeTranslationLanguage(entity: translateTargetEntity, from: pageAPI)
    }
}

extension MomentsProfileActivityCellViewModel: PolybasicCellViewModelProtocol {
    class func generateContent(userResolver: UserResolver,
                               activityEntry: RawData.ProfileActivityEntry,
                               context: BaseMomentContext) -> BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext> {
        let content: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext>
        switch activityEntry.type {
        case .unknown, .reactionToPost(_), .reactionToCommment(_), .followUser(_), .publishPost(_):
            let binder = MomentsEmptyContentCellViewModelBinder(context: context)
            content = MomentsEmptyContentCellViewModel(entity: RawData.CommentEntity.empty(),
                                                       context: context,
                                                       binder: binder)
        case .commentToPost(let commentToPostEntry):
            content = MomentsCommentCellViewModel.generateContent(userResolver: userResolver,
                                                                  commentEntity: commentToPostEntry.comment ?? RawData.CommentEntity.empty(),
                                                                  context: context)
        case .replyToComment(let replyToCommentEntry):
            content = MomentsCommentCellViewModel.generateContent(userResolver: userResolver,
                                                                  commentEntity: replyToCommentEntry.comment ?? RawData.CommentEntity.empty(),
                                                                  context: context)

        }
        return content
    }
    var entityId: String { self.activityEntry.id }
}

final class MomentsProfileActivityCellViewModelBinder: ComponentBinder<BaseMomentContext> {
    override public var component: ComponentWithContext<BaseMomentContext> {
        return _component
    }

    private let props: MomentsProfileActivityCellProps
    private var style = ASComponentStyle()
    private var _component: MomentsProfileActivityCellComponent

    init(key: String? = nil,
         context: BaseMomentContext? = nil,
         contentComponent: ComponentWithContext<BaseMomentContext>) {
        props = MomentsProfileActivityCellProps(contentComponent: contentComponent)
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        style.flexDirection = .column
        style.backgroundColor = UIColor.ud.bgBody
        _component = MomentsProfileActivityCellComponent(
            props: props,
            style: style,
            context: context
        )
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MomentsProfileActivityCellViewModel else {
            assertionFailure()
            return
        }
        props.avatarKey = vm.currentUser?.avatarKey ?? ""
        props.avatarId = vm.currentUser?.userID ?? ""
        props.userName = vm.currentUser?.displayName ?? ""
        props.interactionAvatarKey = vm.interactionUser?.avatarKey ?? ""
        props.interactionAvatarId = vm.interactionUser?.userID ?? ""
        props.interactionAvatarTapped = { [weak vm] in
            vm?.onInteractionAreaTap()
        }
        props.contentComponent = vm.content.component
        props.interactionAttributedText = vm.interactionAttributedText
        props.titleAttributedText = vm.titleAttributedText
        props.interactionAvatarId = vm.interactionUser?.userID ?? ""
        props.interactionAvatarKey = vm.interactionUser?.avatarKey ?? ""
        props.createTime = vm.formatTime
        props.interactionAreaTapped = { [weak vm] in
            vm?.onInteractionAreaTap()
        }
        _component.props = props
    }
}
