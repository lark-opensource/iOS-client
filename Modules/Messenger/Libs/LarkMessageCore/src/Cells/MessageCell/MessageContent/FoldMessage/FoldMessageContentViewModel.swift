//
//  FoldMessageContentViewModel.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/9/16.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxRelay
import RichLabel
import LarkContainer
import AsyncComponent
import LarkMessageBase
import LarkModel
import LKRichView
import LarkCore
import RustPB
import LarkRichTextCore
import LarkActionSheet
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import TangramService
import LKCommonsLogging
import LarkSetting
import ThreadSafeDataStructure
import UniverseDesignActionPanel
import UniverseDesignToast
import LarkStorage

// VM 最小依赖
protocol FoldMessageContentViewModelContext: ViewModelContext, ColorConfigContext {
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getCurrentChatterId() -> String
    func getDisplayName(chatter: Chatter, chat: Chat) -> String
}

public enum FoldMessageStyle {
    case none
    case card
    case recallByAdmin(Chatter)
    case noMessages
}

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.FoldMessageContentViewModel")

struct FoldFollowDecisionInfo {
   let chatLastPostion: Int32
   let foldLastPostion: Int32?
   let isAllowPost: Bool
}

public final class FoldMessageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: MessageSubViewModel<M, D, C> {
    @PageContext.InjectedLazy var messageAPI: MessageAPI?
    @PageContext.InjectedLazy var enterpriseEntityWordService: EnterpriseEntityWordService?
    @PageContext.InjectedLazy var passportUserService: PassportUserService?

    let disposeBag = DisposeBag()

    private weak var targetElement: LKRichElement?

    public override var identifier: String {
        return "fold_message"
    }

    private let contentTextFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .medium)

    public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    var totalCount: Int32? {
        return self.message.foldDetailInfo?.totalCount
    }

    var userLength: Int32? {
        return self.message.foldDetailInfo?.userLen
    }

    var textLinks: [LKTextLink] = []
    var currentAbbreviationInfo: [String: AbbreviationInfoWrapper]?
    var style: FoldMessageStyle {
        guard let foldDetailInfo = self.message.foldDetailInfo else {
            return .card
        }
        switch foldDetailInfo.recallType {
        case .notRecall:
            return foldDetailInfo.userLen == 0 ? .noMessages : .card
        case .userRecall:
            assertionFailure("this type no use")
            return .noMessages
        case .groupOwnerRecall, .groupAdminRecall, .enterpriseAdminRecall:
            return .recallByAdmin(message.foldRecaller ?? Chatter.transform(pb: Chatter.PBModel()))
        @unknown default:
            assertionFailure("unknown case")
            return FoldMessageStyle.none
        }
    }

    var users: [FlodChatter] {
        if message.foldDetailInfo == nil {
            return []
        }
        return message.foldUsers.map { userInfo in
            return FlodChatter(userInfo.chatter.id,
                               avatarKey: userInfo.chatter.avatarKey,
                               name: context.getDisplayName(chatter: userInfo.chatter,
                                                            chat: metaModel.getChat()),
                               number: UInt(userInfo.count))
        }
    }

    public override var contentConfig: ContentConfig? {
        var isSystemStyle = true
        if case .card = style {
            isSystemStyle = false
        }
        var contentConfig = ContentConfig(
            hasMargin: false,
            backgroundStyle: .clear,
            maskToBounds: true,
            supportMutiSelect: false,
            hasBorder: isSystemStyle ? false : true
        )
        contentConfig.isCard = !isSystemStyle
        return contentConfig
    }

    var hasMore: Bool {
        if let foldDetail = message.foldDetailInfo {
            return foldDetail.userCounts.count < foldDetail.userLen
        }
        return false
    }

    var showFollowButton: Bool {
        get { _showFollowButton.value }
        set { _showFollowButton.value = newValue }
    }

    var _showFollowButton: SafeAtomic<Bool> = false + .semaphore

    /// 多线程访问
    var followDecisionInfo: FoldFollowDecisionInfo? {
        get { _followDecisionInfo.value }
        set { _followDecisionInfo.value = newValue }
    }
    private var _followDecisionInfo: SafeAtomic<FoldFollowDecisionInfo?> = nil + .semaphore
    private let lock = NSLock()
    public init(metaModel: M, metaModelDependency: D, context: C) {
        let chat = metaModel.getChat()
        /// 这里先初始化一个相对的值，减少后续updateShowMoreButton的刷新
        self._showFollowButton.value = !(chat.lastMessagePosition > metaModel.message.foldDetailInfo?.lastMessagePosition ?? Int32.min)
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: FoldMessageContentComponentBinder<M, D, C>(context: context)
        )
        self.followDecisionInfo = FoldFollowDecisionInfo(chatLastPostion: chat.lastMessagePosition,
                                           foldLastPostion: metaModel.message.foldDetailInfo?.lastMessagePosition,
                                           isAllowPost: chat.isAllowPost)
        self.updateShowMoreButton()
        self.logFoldDetail(isInit: true)
        /// 关于怎么排除不需要监听的Fold，目前只想到了该方法 暂时没有更好
        /// 如果消息卡片lastMessagePosition & chat.lastMessagePosition 相差较大 说明这条消息已经不再允许+1了 不需要再监听 max 暂定为 40
        logger.info("fold card init status lastMessagePostion: \(message.foldDetailInfo?.lastMessagePosition) chat.lastMessagePosition: \(chat.lastMessagePosition) foldId: \(message.foldId)")
        if let lastMessagePosition = message.foldDetailInfo?.lastMessagePosition, lastMessagePosition + 40 < chat.lastMessagePosition {
            return
        }
        logger.info("fold card observable push foldId\(message.foldId)")
        self.context.resolver.userPushCenter.observable(for: PushChat.self)
            .filter({ [weak self] (push) -> Bool in
                guard let `self` = self else { return false }
                return push.chat.id == chat.id
            }).delay(0.3, scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                /// 数据没有更新 直接返回
                if let oldValue = self.followDecisionInfo,
                   oldValue.isAllowPost == push.chat.isAllowPost,
                    oldValue.chatLastPostion == push.chat.lastMessagePosition {
                    return
                }
                let foldLastPostion = self.followDecisionInfo?.foldLastPostion
                self.followDecisionInfo = FoldFollowDecisionInfo(chatLastPostion: push.chat.lastMessagePosition,
                                                   foldLastPostion: foldLastPostion,
                                                   isAllowPost: push.chat.isAllowPost)
                self.updateShowMoreButton()
            }).disposed(by: disposeBag)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        self.logFoldDetail()
        let chatLastPostion = self.followDecisionInfo?.chatLastPostion
        let isAllowPost = self.followDecisionInfo?.isAllowPost
        self.followDecisionInfo = FoldFollowDecisionInfo(chatLastPostion: chatLastPostion ?? metaModel.getChat().lastMessagePosition,
                                           foldLastPostion: message.foldDetailInfo?.lastMessagePosition,
                                           isAllowPost: isAllowPost ?? metaModel.getChat().isAllowPost)
        updateShowMoreButton( )
    }

    private func logFoldDetail(isInit: Bool = false) {
        let detail = message.foldDetailInfo
        logger.info("metaModel isInit:\(isInit) foldId\(message.foldId) userLen \(detail?.userLen) userCounts: \(detail?.userCounts.count) -foldUsers count: \(message.foldUsers.count) \(detail?.recallType)")
    }

    /// 这里可能会有多线程的问题，如果需要添加代码或者变动 需要注意多线程问题
    /// 因为这里pushchat的现成不一致
    private func updateShowMoreButton() {
        lock.lock()
        let oldValue = self.showFollowButton
        defer {
            let needRefresh = oldValue != self.showFollowButton
            lock.unlock()
            if needRefresh {
                /// 这里主线程刷新可以解决异步线程刷新 但是UI刷新后高度不对的问题
                logger.info("updateShowMoreButton done needRefresh")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.binder.update(with: self)
                    self.update(component: self.binder.component)
                }
            }
        }
        guard let info = self.followDecisionInfo else {
            self.showFollowButton = false
            return
        }
        guard let foldLastPostion = info.foldLastPostion else {
            self.showFollowButton = false
            return
        }
        /// 当前用户
        if !info.isAllowPost {
            self.showFollowButton = false
            return
        }
        self.showFollowButton = !(info.chatLastPostion > foldLastPostion)
    }

    private func getAbbreviationInfo() -> [String: AbbreviationInfoWrapper]? {
        var abbreviationInfo = (message.content as? TextContent)?.abbreviation
        var typedElementRefs = (message.content as? TextContent)?.typedElementRefs
        if let postContent = message.content as? PostContent {
            abbreviationInfo = postContent.abbreviation
            typedElementRefs = postContent.typedElementRefs
        }
        let showAbbreviation = self.context.abbreviationEnable
        let userId = self.context.userID
        if let tenantId = self.passportUserService?.userTenant.tenantID {
            return AbbreviationV2Processor.filterAbbreviation(abbreviation: abbreviationInfo,
                                                                           typedElementRefs: typedElementRefs,
                                                                           tenantId: tenantId,
                                                                           userId: userId)
        }
        return nil
    }
    /// 这个地方虽然content不会变 但是因为支持了URL解析 所以标题会变化 所以不能缓存
    func getRichElement() -> LKRichElement {
        let foldContent = foldContent()
        let contents = PhoneNumberAndLinkParser.getNeedParserContent(richText: foldContent)
        // 密盾群需要本地识别 link
        let detector: PhoneNumberAndLinkParser.Detector = self.metaModel.getChat().isPrivateMode ? .phoneNumberAndLink : .onlyPhoneNumber
        let phoneNumberResult = PhoneNumberAndLinkParser.syncParser(contents: contents, detector: detector)
        let textDocsVMResult = TextDocsViewModel(
            userResolver: self.context.userResolver,
            richText: foldContent,
            docEntity: nil,
            hangPoint: message.urlPreviewHangPointMap
        )

        let richText = textDocsVMResult.richText
        var mediaAttachmentProvider: ((Basic_V1_RichTextElement.MediaProperty) -> LKRichAttachment)?
        self.currentAbbreviationInfo = getAbbreviationInfo()
        let result = RichViewAdaptor.parseRichTextToRichElement(
            richText: richText,
            isFromMe: false,
            isShowReadStatus: false,
            checkIsMe: isMe,
            botIDs: [],
            readAtUserIDs: [],
            defaultTextColor: UIColor.ud.textTitle,
            maxLines: 0,
            maxCharLine: 0,
            abbreviationInfo: currentAbbreviationInfo,
            mentions: [:],
            imageAttachmentProvider: nil,
            mediaAttachmentProvider: nil,
            urlPreviewProvider: { [weak self] elementID in
                guard let self = self else { return nil }
                let inlinePreviewVM = MessageInlineViewModel()
                return inlinePreviewVM.getNodeSummerizeAndURL(
                    elementID: elementID,
                    message: self.message,
                    font: self.contentTextFont,
                    textColor: UIColor.ud.textLinkNormal,
                    iconColor: UIColor.ud.textLinkNormal,
                    tagType: TagType.link
                )
            },
            phoneNumberAndLinkProvider: { elementID, _ in
                return phoneNumberResult[elementID] ?? []
            },
            edited: false
        )
        return result
    }

    /// 需要监听事件的Tag
    public let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.abbreviation)]
    ]

    public var styleSheets: [CSSStyleSheet] {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: self.contentTextFont,
                                                                                atColor: atColor))
    }

    private var atColor: AtColor {
        return AtColorConfig.getMessageAtColorWithContext(self.context, isFromMe: false)
    }
    // 处理匿名和普通场景的收敛判断方法
    private func isMe(_ id: String) -> Bool {
        return self.context.isMe(id, chat: self.metaModel.getChat())
    }

    var recallAtrr: NSAttributedString? {
        switch self.style {
        case .noMessages:
            let cardIsRecallText = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_StackMessageRecalled_Text
            let detailText = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_ViewDetails_Button
            let allText = cardIsRecallText + " " + detailText
            let range = (allText as NSString).range(of: detailText)
            var link = LKTextLink(range: range,
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                               .font: UIFont.ud.body2])
            link.linkTapBlock = { [weak self] (_, _)in
                self?.pushToFoldDetail()
            }
            textLinks = [link]
            let attr = NSMutableAttributedString(string: allText,
                                                 attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                              .font: UIFont.ud.body2])
            attr.addAttributes([.foregroundColor: UIColor.ud.textLinkNormal], range: range)
            return attr
        case .recallByAdmin(let chatter):
            /// 自己撤回的文案特化一下
            if chatter.id == self.context.userID {
                textLinks = []
                let text = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_YouRecalledAStackMessage_Text
                return NSAttributedString(string: text, attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                             .font: UIFont.ud.body2])
            }
            let name = context.getDisplayName(chatter: chatter,
                                              chat: metaModel.getChat())
            var text = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_GroupAdminOwnerRecalledAStackMessage_Text("##*##")
            var range = (text as NSString).range(of: "##*##")
            text = (text as NSString).replacingCharacters(in: range, with: name)
            range.length = name.utf16.count
            var link = LKTextLink(range: range,
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                               .font: UIFont.ud.body2])
            link.linkTapBlock = { [weak self] (_, _)in
                self?.pushToProfileVC(userId: chatter.id)
            }
            textLinks = [link]
            let attr = NSMutableAttributedString(string: text, attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                 .font: UIFont.ud.body2])
            attr.addAttributes([.foregroundColor: UIColor.ud.textLinkNormal], range: range)
            return attr
        case .card:
            textLinks = []
            return nil
        case .none:
            textLinks = []
            return NSAttributedString(string: "")
        }
    }

   public func showFoldMessageMenu(targetView: UIView) {
       /// 只有没有撤回消息才有长按的事件
       guard let targetVC = self.context.targetVC,
             let info = message.foldDetailInfo,
                info.recallType == .notRecall else {
            return
        }
       /// 群主 & 管理员
        let ownerId = metaModel.getChat().ownerId == context.getCurrentChatterId()
        let isAdmin = self.metaModel.getChat().isGroupAdmin || ownerId
        var title: String?
        let recallMyMessage = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_YouMayWantToRecall_OnlyMe_Option
        var recallAllCard = ""
        if isAdmin {
            recallAllCard = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_YouMayWantToRecall_TheEntireStack_Option
        }

       let canRecallMessages = message.foldUsers.contains { foldUser in
           return foldUser.chatter.id == self.pageContext.userID
       }
       if !canRecallMessages && !isAdmin {
           return
       }

       if canRecallMessages && isAdmin {
           title = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_YouMayWantToRecall_Title
       }
       /// 这里需要收起键盘
       self.context.targetVC?.view.endEditing(true)
       let arrowDirection = getPopoverArrowDirection(targetView: targetView)

       let popSource = UDActionSheetSource(sourceView: targetView,
                                           sourceRect: CGRect(
                                            x: targetView.frame.width / 2.0,
                                            y: arrowDirection == .up ? targetView.frame.height : 22,
                                            width: 0, height: 0),
                                            preferredContentWidth: 360,
                                            arrowDirection: arrowDirection)
       let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: title != nil,
                                                                     popSource: popSource))
       actionSheet.dismissWhenViewTransition(true)
       if let title = title {
           actionSheet.setTitle(title)
       }

       if canRecallMessages {
           actionSheet.addDefaultItem(text: recallMyMessage) { [weak self] in
               self?.recallFoldCard(recallByGroupAdmin: false)
           }
       }

       if isAdmin {
           actionSheet.addDefaultItem(text: recallAllCard) { [weak self, weak targetView] in
               self?.reconfirmRecallAction(targetView: targetView, recallByGroupAdmin: isAdmin)
           }
       }
       actionSheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
       self.context.navigator.present(actionSheet, from: targetVC)
    }

    private func reconfirmRecallAction(targetView: UIView?, recallByGroupAdmin: Bool) {
        guard let targetVC = self.context.targetVC,
        let targetView = targetView else {
            return
        }
        let arrowDirection = getPopoverArrowDirection(targetView: targetView)
        let title = BundleI18n.LarkMessageCore.Lark_IM_StackMessage_RecallEntireStack_TitlePlusDesc
        let popSource = UDActionSheetSource(sourceView: targetView,
                                            sourceRect: CGRect(
                                             x: targetView.frame.width / 2.0,
                                             y: arrowDirection == .up ? targetView.frame.height : 22,
                                             width: 0, height: 0),
                                             preferredContentWidth: 360,
                                             arrowDirection: arrowDirection)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true,
                                                                      popSource: popSource))
        actionSheet.dismissWhenViewTransition(true)
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkMessageCore.Lark_IM_StackMessage_RecallEntireStack_Recall_Button) { [weak self] in
            guard let self = self else { return }
            self.recallFoldCard(recallByGroupAdmin: recallByGroupAdmin)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
        self.context.navigator.present(actionSheet, from: targetVC)
    }

    func getPopoverArrowDirection(targetView: UIView) -> UIPopoverArrowDirection {
        var arrowDirection: UIPopoverArrowDirection = .up
        if Display.pad,
            let targetVC = self.context.targetVC,
           targetVC.view.frame.maxY - targetView.convert(targetView.bounds, to: targetVC.view).maxY < 200 {
            arrowDirection = .down
        }
        return arrowDirection
    }
    func recallFoldCard(recallByGroupAdmin: Bool) {
        let foldId = self.message.foldId
        logger.info("recallFoldCard recallByGroupAdmin\(recallByGroupAdmin), foldId: \(foldId)")
        self.messageAPI?.recallMessageFold(foldId: foldId,
                                          recallByGroupAdmin: recallByGroupAdmin)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            IMTracker.Msg.Menu.More.Click.RecallFoldCard(self.metaModel.getChat(),
                                                         self.message,
                                                         isReacllCard: recallByGroupAdmin,
                                                         self.context.trackParams[PageContext.TrackKey.sceneKey] as? String)
            logger.info("recallFoldCard recallByGroupAdmin foldId: \(foldId) success")
        }, onError: { [weak self] error in
            logger.error("recallMessageFold fail foldId: \(foldId) recallByGroupAdmin: \(recallByGroupAdmin)", error: error)
            if let view = self?.context.targetVC?.view {
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip, on: view, error: error)
            }
        }).disposed(by: self.disposeBag)
    }
    func pushToFoldDetail() {
        guard let from = self.context.targetVC,
              let richText = message.foldDetailInfo?.message.content.richText,
              message.foldDetailInfo?.recallType == .notRecall else {
            return
        }
        IMTracker.Chat.Main.Click.FoldCard(self.metaModel.getChat(),
                                           context.trackParams[PageContext.TrackKey.sceneKey] as? String,
                                           type: .repeat_card)
        let body = FoldMessageDetailBody(chat: self.metaModel.getChat(),
                                         message: self.message,
                                         richText: richText)
        self.context.navigator.push(body: body, from: from)
    }

    func pushToProfileVC(userId: String) {
        guard let from = self.context.targetVC else {
            return
        }
        let body = PersonCardBody(chatterId: userId,
                                  source: .chat)
        self.context.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }
}
extension FoldMessageContentViewModel {
    func foldContent() -> RustPB.Basic_V1_RichText {
        if let foldDetailInfo = message.foldDetailInfo {
            return foldDetailInfo.message.content.richText
        } else {
           return getCurrentMessageContent() ?? RustPB.Basic_V1_RichText()
        }
    }

    fileprivate func getCurrentMessageContent() -> RustPB.Basic_V1_RichText? {
        if message.isRecalled { return nil }
        if let textContent = message.content as? TextContent { return textContent.richText }
        if let postContent = message.content as? PostContent { return postContent.richText }
        return nil
    }
}

extension FoldMessageContentViewModel: FlodApproveViewDelegate,
                                       FlodChatterViewDelegate {
    public func animationFilePath() -> LarkStorage.IsoPath? {
        return try? context.resolver.resolve(assert: FoldApproveDataService.self).filePath
    }

    public func didStartApprove(_ flodApproveView: FlodApproveView) {
        /// 点击动画的时候 暂停队列 放置被打断
        context.dataSourceAPI?.pauseDataQueue(true)
    }
    public func didFinishApprove(_ flodApproveView: FlodApproveView, number: UInt) {
        /// 点击动画的时候 暂停队列 放置被打断
        context.dataSourceAPI?.pauseDataQueue(false)
        IMTracker.Chat.Main.Click.FoldCard(self.metaModel.getChat(),
                                           context.trackParams[PageContext.TrackKey.sceneKey] as? String,
                                           type: .repeat_plus_button(number))
        let foldId = message.foldId
        messageAPI?.putMessageFoldFollow(foldId: foldId, count: Int32(number))
        .subscribe(onError: { error in
            logger.error("putMessageFoldFollow foldId: \(foldId) - count:\(number)", error: error)
        }).disposed(by: self.disposeBag)
    }
    /// 点击了某个chatter的头像/名字/数量
    public func didTapChatter(_ flodChatterView: FlodChatterView, chatter: FlodChatter) {
        self.pushToProfileVC(userId: chatter.identifier)
    }

    /// 点击了flodChatterView除chatter外的其他区域
    public func didTapFlodChatterView(_ flodChatterView: FlodChatterView) {
        self.pushToFoldDetail()
    }
}

extension FoldMessageContentViewModel: LKRichViewDelegate {

    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
    }

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
    }

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        if targetElement !== event?.source { targetElement = nil }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }

        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID: needPropagation = handleTagAtEvent(element: element, event: event, view: view)
        case RichViewAdaptor.Tag.a.typeID: needPropagation = handleTagAEvent(element: element, event: event, view: view)
        default: needPropagation = handleClassNameEvent(isOrigin: true, view: view, element: element, event: event)
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    func handleClassNameEvent(isOrigin: Bool, view: LKRichView, element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        // 企业词典事件
        if element.classNames.contains(RichViewAdaptor.ClassName.abbreviation) {
            if context.abbreviationEnable,
               let abbreviationInfoWrapper = self.currentAbbreviationInfo?[element.id],
               let inlineBlockElement = element as? LKInlineBlockElement,
               let subElement = inlineBlockElement.subElements[0] as? LKTextElement {
                handleAbbreClick(abbres: abbreviationInfoWrapper, query: subElement.text)
            }
            return false
        }
        return true
    }
    /// Return - 事件是否需要继续冒泡
    private func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if anchor.classNames.contains(RichViewAdaptor.ClassName.phoneNumber) {
            handlePhoneNumberClick(phoneNumber: anchor.href ?? anchor.text, view: view)
            return false
        } else if let href = anchor.href, let url = URL(string: href) {
            handleURLClick(url: url, view: view)
            return false
        }
        return true
    }

    // MARK: - Event Handler
    /// Return - 事件是否需要继续冒泡
    func handleTagAtEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        let richText = message.foldDetailInfo?.message.content.richText ?? self.getCurrentMessageContent()
        guard let atElement = richText?.elements[element.id] else { return true }
        return handleAtClick(property: atElement.property.at, view: view)
    }

    private func handleAtClick(property: Basic_V1_RichTextElement.AtProperty, view: LKRichView) -> Bool {
        guard let window = view.window else {
            assertionFailure()
            return true
        }
        let body = PersonCardBody(chatterId: property.userID)
        if Display.phone {
            self.context.navigator.push(body: body, from: window)
        } else {
            self.context.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: window,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        return false
    }

    private func handleURLClick(url: URL, view: LKRichView) {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        if let httpUrl = url.lf.toHttpUrl() {
            self.context.navigator.push(httpUrl, context: [
                "from": "collector",
                "scene": "messenger",
                "location": "messenger_foldMessage"
            ], from: window)
        }
    }

    private func handleAbbreClick(abbres: AbbreviationInfoWrapper, query: String) {
        var id = AbbreviationV2Processor.getAbbrId(wrapper: abbres, query: query)
        var clientArgs: String?
        /// 聚合消息卡片的忽略/pin入口关闭
        var enableEdit: Bool = false
        let analysisParams: [String: Any] = [
            "card_source": "im_card",
            "message_id": message.id,
            "chat_id": message.chatID
        ]
        let extra: [String: Any] = [
            "spaceId": message.chatID,
            "spaceSubId": message.id,
            "space": SpaceType.IM.rawValue,
            "showPin": enableEdit
        ]
        let params: [String: Any] = [
            "page": LingoPageEnum.LingoCard.rawValue,
            "showIgnore": enableEdit,
            "analysisParams": analysisParams,
            "extra": extra
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: params) {
            clientArgs = String(data: jsonData, encoding: String.Encoding.utf8)
        }
        enterpriseEntityWordService?.showEnterpriseTopicForIM(
            abbrId: id ?? "",
            query: query,
            chatId: self.metaModel.getChat().id,
            msgId: self.metaModel.message.id,
            sense: .messenger,
            targetVC: context.targetVC,
            clientArgs: clientArgs,
            completion: nil,
            passThroughAction: nil
        )
    }

    private func handlePhoneNumberClick(phoneNumber: String, view: LKRichView) {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        self.context.navigator.open(body: OpenTelBody(number: phoneNumber), from: window)
    }
}
