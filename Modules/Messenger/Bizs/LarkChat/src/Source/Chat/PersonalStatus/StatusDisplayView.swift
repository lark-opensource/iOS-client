//
//  StatusDisplayView.swift
//  LarkChat
//
//  Created by 郭怡然 on 2022/12/27.
//

import UIKit
import RxSwift
import RxCocoa
import Foundation
import EENavigator
import ByteWebImage
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignDialog
import LarkMessengerInterface
import LarkRichTextCore
import EditTextView
import RustPB
import LarkFocus
import LarkFocusInterface
import LKRichView
import LarkMessageCore
import LarkCore
import TangramService
import LarkModel
import LarkUIKit
import LarkContainer
import LarkAccountInterface
import LarkRustClient

public protocol StatusDisplayViewDelegate: AnyObject {
    func statusDisplayViewOnShowAndHide()
}

public struct StatusDesc {
    public var richText: Basic_V1_RichText
    public var urlHangPointMap: [String: Basic_V1_PreviewHangPoint] = [:]
    public var inlinePreviewEntities: [String: InlinePreviewEntity] = [:]

    public init(richText: Basic_V1_RichText = Basic_V1_RichText(),
                urlHangPointMap: [String: Basic_V1_PreviewHangPoint] = [:],
                inlinePreviewEntities: [String: InlinePreviewEntity] = [:]) {
        self.richText = richText
        self.urlHangPointMap = urlHangPointMap
        self.inlinePreviewEntities = inlinePreviewEntities
    }

    static func transform(pb: Basic_V1_StatusDesc) -> StatusDesc {
        let inlines = pb.urlPreviewEntityMap.mapValues({ InlinePreviewEntity.transform(from: $0) })
        return StatusDesc(richText: pb.richText,
                          urlHangPointMap: pb.urlHangPointMap,
                          inlinePreviewEntities: inlines)
    }
}

final class StatusDisplayView: UIView, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    private static let logger = Logger.log(StatusDisplayView.self, category: "StatusDisplayView")
    private var statusDescText: Basic_V1_RichText = Basic_V1_RichText()
    private var statusDesc: StatusDesc = StatusDesc()
    private var chat: BehaviorRelay<Chat>
    private var name: String?
    weak var targetVC: UIViewController?
    weak var delegate: StatusDisplayViewDelegate?
    private let chatNameObservable: Observable<String>
    private lazy var statusDescObservable = getStatusDescObservable(chat: self.chat.value)
    private let urlPushObservable: Observable<URLPreviewScenePush>
    private let chatStatusTipNotifyDriver: Driver<PushChatStatusTipNotify>
    private let disposeBag = DisposeBag()
    private var preferredMaxLayoutWidth: CGFloat = 30
    private var maxWidth: CGFloat = 30
    private weak var targetElement: LKRichElement?
    private var touchStartTime: TimeInterval?
    private var statusId: Int64?

    private lazy var core: LKRichViewCore = {
        let core = LKRichViewCore()
        core.load(styleSheets: StatusDisplayView.styleSheets)
        return core
    }()
    static let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: RichViewAdaptor.Tag.p)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)]
    ]
    private lazy var tipLabel: LKRichView = {
        let tipLabel = LKRichView(frame: .zero, options: ConfigOptions([.debug(false)]))
        tipLabel.delegate = self
        tipLabel.bindEvent(selectorLists: StatusDisplayView.propagationSelectors, isPropagation: true)
        // InlineBlockContainerRunBox.layout中最后一行展示不下也会参与布局计算，导致最终渲染出来，所以我们需要裁剪掉
        tipLabel.clipsToBounds = true
        return tipLabel
    }()
    private lazy var statusIconView: UIImageView = {
        let image = UDIcon.getIconByKey(.chatNewsOutlined, iconColor: .ud.iconN2)
        let statusIconView = UIImageView(image: image)
        return statusIconView
    }()

    var eventDriver: Driver<RichElementTouchedEvent?> { eventPublish.asDriver(onErrorJustReturn: (nil)) }
    private var eventPublish = PublishSubject<RichElementTouchedEvent?>()

    struct Config {
        static let labelLeftPadding: CGFloat = 36
        static let rightPadding: CGFloat = 10
        static let labelTopPadding: CGFloat = 2
        static let labelBottomPadding: CGFloat = 8
        static let iconTopPadding: CGFloat = 3
        static let iconLeftPadding: CGFloat = 10
        static let iconSize: CGFloat = 16
        static let arrowSize: CGFloat = 16
        static let viewMaxHeight: CGFloat = 35
        static let arrowTopPadding: CGFloat = 11
        static let insetTopPadding: CGFloat = 6
    }

    lazy private var arrow: StatusArrorView = {
        var imageView = StatusArrorView()
        imageView.isUserInteractionEnabled = true
        imageView.image = UDIcon.downRightOutlined.ud.withTintColor(UIColor.ud.iconN2)
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(arrowTapped)))
        imageView.isHidden = true
        return imageView
    }()

    static var styleSheets: [CSSStyleSheet] = {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: UIFont.ud.body1, atColor: AtColor()))
    }()

    private var richElement: LKRichElement?
    private func getRichElement() -> LKRichElement? {
        // xx的留言
        let nameElement = LKTextElement(classNames: [RichViewAdaptor.ClassName.text], text: BundleI18n.LarkChat.Lark_IM_StatusNoteAboveTextBox_Text(self.name ?? "") + " ")
        nameElement.style.font(UIFont.systemFont(ofSize: 14.0))
        // 个人状态内容
        let contentElement = RichViewAdaptor.parseRichTextToRichElement(richText: self.statusDescText,
                                                                        isFromMe: true,
                                                                        isShowReadStatus: false,
                                                                        checkIsMe: nil,
                                                                        botIDs: [],
                                                                        readAtUserIDs: [],
                                                                        abbreviationInfo: nil,
                                                                        mentions: nil,
                                                                        imageAttachmentProvider: nil,
                                                                        mediaAttachmentProvider: nil,
                                                                        urlPreviewProvider: { [weak self] anchorId in
            guard let self = self else { return nil }
            guard let hangPoint = self.statusDesc.urlHangPointMap[anchorId] else { return nil }
            let previewId = hangPoint.previewID
            guard let entity = self.statusDesc.inlinePreviewEntities[previewId] else { return nil }
            return StatusDisplayView.getNodeSummerizeAndURL(
                entity: entity,
                font: UIFont.ud.body1,
                textColor: UIColor.ud.textLinkNormal,
                iconColor: UIColor.ud.textLinkNormal,
                tagType: TagType.link
            )},
                                                                        hashTagProvider: nil,
                                                                        phoneNumberAndLinkProvider: nil)
        var children: [LKRichElement] = [nameElement]
        for subElement in contentElement.subElements {
            for element in subElement.subElements {
                guard let element = element as? LKRichElement else { continue }
                children.append(element)
            }
        }
        let document = LKBlockElement(tagName: RichViewAdaptor.Tag.p)
        document.children(children)
        // 不能设置textOverflow，会导致只展示一行内容，剩余部分展示"..."
        document.style.font(UIFont.ud.body1).color(UIColor.ud.textCaption)
        // 用lineCamp设置最多展示两行内容，超出展示省略号；设置为nil内部会替换为"..."
        document.style.lineCamp(LineCamp(maxLine: 2, blockTextOverflow: nil))
        return document
    }

    init(userResolver: UserResolver,
         chat: BehaviorRelay<Chat>,
         chatNameObservable: Observable<String>,
         urlPushObservable: Observable<URLPreviewScenePush>,
         chatStatusTipNotifyDriver: Driver<PushChatStatusTipNotify>) {
        self.userResolver = userResolver
        self.chatNameObservable = chatNameObservable
        self.urlPushObservable = urlPushObservable
        self.chatStatusTipNotifyDriver = chatStatusTipNotifyDriver
        self.chat = chat
        super.init(frame: .zero)
        self.isHidden = true
        initView()
        configEventHandler()
        observeData()
        observeURLPush()
    }

    private func initView() {
        self.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.addSubview(self.statusIconView)
        self.statusIconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(StatusDisplayView.Config.iconLeftPadding)
            make.top.equalToSuperview().offset(StatusDisplayView.Config.iconTopPadding + StatusDisplayView.Config.insetTopPadding)
            make.width.height.equalTo(StatusDisplayView.Config.iconSize)
        }
        self.addSubview(self.tipLabel)
        self.addSubview(self.arrow)
        self.arrow.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(StatusDisplayView.Config.arrowTopPadding)
            make.width.height.equalTo(StatusDisplayView.Config.arrowSize)
            make.right.equalTo(-StatusDisplayView.Config.rightPadding)
        }
    }

    func getStatusDescObservable(chat: Chat) -> Observable<RustPB.Contact_V1_PullChattersPartialInfoResponse> {
        guard let client: RustService = try? userResolver.resolve(assert: RustService.self) else { return .error(RCError.cancel) }
        var request = RustPB.Contact_V1_PullChattersPartialInfoRequest()
        request.userIds = [chat.chatterId]
        request.chatterFields = [.statusWithDesc]
        return client.sendAsyncRequest(request)
            .do(onNext: { (response) in
                StatusDisplayView.logger.info("chattersStatusWithDesc:\(response.chattersStatusWithDesc.count)")
            }, onError: { error in
                StatusDisplayView.logger.error("get chattersStatusWithDesc failed.", error: error)
            })
        }

    private func observeData() {
        self.chatNameObservable.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (name) in
                self?.name = name
            }).disposed(by: self.disposeBag)
        self.statusDescObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (descriptions) in
            guard let self = self else {return}
            guard let chatterCustomStatus = descriptions.chattersStatusWithDesc[self.chat.value.chatterId] else {return}
            self.updateWithChatterStatusDesc(chatterCustomStatus: chatterCustomStatus)
        }).disposed(by: self.disposeBag)
        self.chatStatusTipNotifyDriver
            .drive(onNext: { [weak self] (notify) in
                guard let self = self, self.chat.value.chatterId == notify.userID else { return }
                Self.logger.info("""
                    statusDisplayView chatStatusTipNotifyDriver
                """)
                self.updateWithChatterStatusDesc(chatterCustomStatus: notify.updateStatusWithDesc)
            }).disposed(by: disposeBag)
    }

    private func observeURLPush() {
        urlPushObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] push in
            guard let self = self else { return }
            let hangPointMap = self.statusDesc.urlHangPointMap
            let inlines = push.inlinePreviewEntities.filter({ (previewID, _) in
                return hangPointMap.values.contains(where: { $0.previewID == previewID })
            })
            if !inlines.isEmpty {
                self.statusDesc.inlinePreviewEntities += inlines
                self.updateTipContent()
            }
        }).disposed(by: self.disposeBag)
    }

    func replaceNilAtContentToUserName(_ from: FocusStatusDescRichText, completion: @escaping (FocusStatusDescRichText) -> Void) {

        guard !from.atIds.isEmpty else {
            completion(from)
            return
        }

        var toRichText = from
        var userIds: [String] = []
        var atId2UserIdMap: [String: String] = [:]
        var userId2ChatterMap: [String: Chatter] = [:]

        /// 通过 `atIds` 取得对应的 `userId`
        for atId in from.atIds {
            guard let element = from.elements[atId] as? Basic_V1_RichTextElement, element.tag == .at else {
                completion(from)
                return
            }
            let userId = element.property.at.userID
            atId2UserIdMap[atId] = userId
            userIds.append(userId)
        }

        /// 通过 `userId` 取得对应的 `chatter`，来获取备注名或其他名称
        self.chatterAPI?.getChatters(ids: userIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatterMap) in
                guard let self = self else { return }
                userId2ChatterMap = chatterMap
                var convertedElements = from.elements
                // 替换 elements 里的 content
                for atId in from.atIds {
                    guard var atElement = convertedElements[atId] as? Basic_V1_RichTextElement, atElement.tag == .at else { return }
                    guard let userId = atId2UserIdMap[atId] else { return }
                    guard let chatter = userId2ChatterMap[userId] else { return }
                    if chatter.alias.isEmpty {
                        atElement.property.at.content = chatter.nameWithAnotherName
                    } else {
                        atElement.property.at.content = chatter.alias
                    }
                    convertedElements[atId] = atElement
                }
                toRichText.elements = convertedElements
                Self.logger.info("[\(#function)]: handle urlPreview success, atId-Count: \(toRichText.atIds.count)")
            }, onError: { (error) in
                Self.logger.error("[\(#function)]: handle urlPreview error", error: error)
            }, onCompleted: {
                completion(toRichText)
            })
            .disposed(by: self.disposeBag)
    }

    func updateWithChatterStatusDesc(chatterCustomStatus: Contact_V1_ChatterCustomStatusWithStatusDesc) {
        guard !chatterCustomStatus.customStatuses.isEmpty else { return }
        guard let status = chatterCustomStatus.customStatuses.first,
              status.isActive else { return }
        if self.statusId != nil {
            guard status.statusID == self.statusId else { return }
        } else {
            self.statusId = status.statusID
        }
        guard var PbStatusDesc = chatterCustomStatus.statusDesc[status.statusID] else { return }
        self.statusDesc = StatusDesc.transform(pb: PbStatusDesc)
        self.updateTipContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var bounds: CGRect {
        didSet {
            let newMaxWidth = bounds.width -
            StatusDisplayView.Config.labelLeftPadding -
            StatusDisplayView.Config.rightPadding -
            StatusDisplayView.Config.arrowSize
            guard self.maxWidth != newMaxWidth else {
                return
            }
            self.maxWidth = newMaxWidth
            guard !name.isEmpty, !self.statusDesc.richText.elements.isEmpty else {
                Self.logger.info("panic: name or statusDesc is empty")
                return
            }
            self.isHidden = false
            updateUI()
        }
    }

    override var isHidden: Bool {
        didSet {
            if oldValue != isHidden {
                self.delegate?.statusDisplayViewOnShowAndHide()
            }
        }
    }

    @objc
    private func arrowTapped() {
        let statusDetailVC = StatusDetailViewController(userResolver: userResolver, statusDescText: statusDescText, statusDesc: statusDesc)
        if let vc = targetVC {
            navigator.push(statusDetailVC, from: vc)
        }
    }

    func updateTipContent() {
        guard !name.isEmpty, !self.statusDesc.richText.elements.isEmpty else {
            Self.logger.info("panic: name or statusDesc is empty")
            self.isHidden = true
            return
        }
        // 替换姓名显示
        self.replaceNilAtContentToUserName(statusDesc.richText, completion: { [weak self] richText in
            guard let self = self else { return }
            self.statusDescText = richText
            self.statusDesc.richText = richText
            // 对richElement进行布局计算
            self.richElement = self.getRichElement()
            DispatchQueue.main.async {
                self.updateUI()
            }
        })
    }

    func updateUI() {
        guard let richElement = self.richElement else {
            self.isHidden = true
            return
        }
        self.core.load(renderer: self.core.createRenderer(richElement))
        guard let contentSize = self.core.layout(CGSize(width: self.maxWidth, height: StatusDisplayView.Config.viewMaxHeight)) else { return }
        // core需要先设置renderer再layout后才可以调用setRichViewCore
        self.tipLabel.setRichViewCore(self.core)
        // 保险起间，设置preferredMaxLayoutWidth，intrinsicContentSize时使用
        self.tipLabel.preferredMaxLayoutWidth = self.maxWidth
        self.tipLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(StatusDisplayView.Config.labelLeftPadding)
            make.right.equalToSuperview().inset(StatusDisplayView.Config.rightPadding + StatusDisplayView.Config.arrowSize)
            make.top.equalToSuperview().inset(StatusDisplayView.Config.labelTopPadding + StatusDisplayView.Config.insetTopPadding)
            make.bottom.equalToSuperview().inset(StatusDisplayView.Config.labelBottomPadding)
            make.height.equalTo(contentSize.height)
        }
        // 如果内容没展示完，则需要展示arrow，否则隐藏arrow
        self.arrow.isHidden = !self.core.isContentScroll
        self.isHidden = false
    }

    func configEventHandler() {
        self.eventDriver
            .drive(onNext: { [weak self] event in
                guard let `self` = self,
                      let event = event else { return }
                switch event {
                case .atClick(let userID):
                    self.handleAtClick(userID: userID)
                case .URLClick(url: let url):
                    self.handleURLClick(url)
                }
            }).disposed(by: disposeBag)
    }

    func handleAtClick(userID: String) {
        let body = PersonCardBody(chatterId: userID,
                                  source: .chat)
        guard let vc = self.targetVC else { return }
        navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: vc,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func handleURLClick(_ url: URL) {
        guard let vc = self.targetVC else { return }
        if let httpUrl = url.lf.toHttpUrl() {
            navigator.push(httpUrl, from: vc)
        }
    }

    /// 更新间距显示，如果当前已显示了时区，需要更新padding
    func updateUIPadding(_ isShowTimeZone: Bool) {
        Self.logger.info("updateUIPadding")
        let topTipLabelMargin = isShowTimeZone ? StatusDisplayView.Config.labelTopPadding : (StatusDisplayView.Config.labelTopPadding + StatusDisplayView.Config.insetTopPadding)
        let topIconLabelMargin = isShowTimeZone ? StatusDisplayView.Config.iconTopPadding : (StatusDisplayView.Config.iconTopPadding + StatusDisplayView.Config.insetTopPadding)
        guard let contentSize = self.core.layout(CGSize(width: self.maxWidth, height: StatusDisplayView.Config.viewMaxHeight)) else { return }
        self.tipLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(StatusDisplayView.Config.labelLeftPadding)
            make.right.equalToSuperview().inset(StatusDisplayView.Config.rightPadding + StatusDisplayView.Config.arrowSize)
            make.top.equalToSuperview().inset(topTipLabelMargin)
            make.bottom.equalToSuperview().inset(StatusDisplayView.Config.labelBottomPadding)
            make.height.equalTo(contentSize.height)
        }
        self.statusIconView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().inset(StatusDisplayView.Config.iconLeftPadding)
            make.top.equalToSuperview().offset(topIconLabelMargin)
            make.width.height.equalTo(StatusDisplayView.Config.iconSize)
        }
    }
}

extension StatusDisplayView: LKRichViewDelegate {
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {}

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? { return nil }

    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {}

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard let event = event else {
            targetElement = nil
            return
        }
        if targetElement !== event.source { targetElement = nil }
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }
        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID:
            needPropagation = handleTagAtEvent(element: element, event: event)
        case RichViewAdaptor.Tag.a.typeID:
            needPropagation = handleTagAEvent(element: element, event: event)
        default: break
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagAtEvent(element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        guard let atElement = statusDescText.elements[element.id] else { return true }
        handleAtClick(property: atElement.property.at)
        return false
    }
    func handleAtClick(property: Basic_V1_RichTextElement.AtProperty) {
        // 非匿名用户 & 非艾特全体才有点击事件和跳转
        guard !property.isAnonymous, property.userID != "all" else { return }
        self.eventPublish.onNext(.atClick(userID: property.userID))
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if let href = anchor.href {
            do {
                let url = try URL.forceCreateURL(string: href)
                handleURLClick(url: url)
            } catch {
                Self.logger.error(logId: "url_parse", "Error: \(error.localizedDescription), SpecURL: \(href)")
            }
            return false
        }
        return true
    }

    func handleURLClick(url: URL) {
        self.eventPublish.onNext(.URLClick(url: url))
    }
}

// MARK: - NewRichComponent
extension StatusDisplayView {
    // swiftlint:disable large_tuple
    public static func getNodeSummerizeAndURL(
        entity: InlinePreviewEntity,
        font: UIFont,
        textColor: UIColor,
        iconColor: UIColor?,
        tagType: TagType
    ) -> (imageNode: LKAttachmentElement?, titleNode: LKTextElement?, tagNode: LKAttachmentElement?, clickURL: String?)? {
        let vm = MessageInlineViewModel()
        let imageNode = vm.getImageNode(entity: entity, font: font, iconColor: iconColor)
        let titleNode = vm.getTitleNode(entity: entity, font: font, textColor: textColor)
        let tagNode = vm.getTagNode(entity: entity, font: font, tagType: tagType)
        if titleNode == nil { return nil }
        return (imageNode, titleNode, tagNode, entity.url?.tcURL)
    }
    // swiftlint:enable large_tuple
}

enum RichElementTouchedEvent {
    case atClick(userID: String)
    case URLClick(url: URL)
}

final class StatusArrorView: ByteImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden {
            return nil
        }
        // 四周热区扩大4
        let insets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        if bounds.inset(by: insets).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
