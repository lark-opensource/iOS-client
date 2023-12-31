//
//  StatusDetailViewController.swift
//  LarkChat
//
//  Created by 郭怡然 on 2022/12/29.
//

import Foundation
import UIKit
import LarkUIKit
import RichLabel
import LKRichView
import LarkMessageCore
import RustPB
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkFocus
import TangramService
import LarkModel
import UniverseDesignIcon
import UniverseDesignColor
import LarkMessengerInterface
import EENavigator
import LarkRichTextCore
import LarkContainer

class StatusDetailViewController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver

    private static let logger = Logger.log(StatusDetailViewController.self, category: "StatusDetailViewController")
    private var statusDescText: Basic_V1_RichText
    private weak var targetElement: LKRichElement?
    private var touchStartTime: TimeInterval?
    lazy var core = LKRichViewCore()
    private var eventPublish = PublishSubject<RichElementTouchedEvent?>()
    var eventDriver: Driver<RichElementTouchedEvent?> { eventPublish.asDriver(onErrorJustReturn: (nil)) }
    private var statusDesc: StatusDesc
    private let disposeBag = DisposeBag()
    private var preferredMaxLayoutWidth: CGFloat = 0
    private var contentMaxHeight: CGFloat = 0
    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    private let labelView = LKRichView(frame: .zero, options: ConfigOptions([.debug(false)]))
    private let scrollView = UIScrollView()
    struct Config {
        static let labelLeftPadding: CGFloat = 16
        static let labelTopPadding: CGFloat = 12
        static let labelBottomPadding: CGFloat = 12
        static let topPadding: CGFloat = 8
        static let leftPadding: CGFloat = 16
        static let rightPadding: CGFloat = 16
        static let naviBarHeight: CGFloat = 56
    }

    static var styleSheets: [CSSStyleSheet] = {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: UIFont.ud.headline, atColor: AtColor()))
    }()

    init(userResolver: UserResolver, statusDescText: Basic_V1_RichText, statusDesc: StatusDesc) {
        self.userResolver = userResolver
        self.statusDescText = statusDescText
        self.statusDesc = statusDesc
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var richElement: LKRichElement?
    private func getRichElement() -> LKRichElement {
        var contentElement = RichViewAdaptor.parseRichTextToRichElement(
            richText: self.statusDescText,
            isFromMe: true,
            isShowReadStatus: false,
            checkIsMe: nil,
            botIDs: [],
            readAtUserIDs: [],
            defaultTextColor: .ud.textCaption,
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
                )
            },
            hashTagProvider: nil,
            phoneNumberAndLinkProvider: nil)
        contentElement.style.font(UIFont.ud.headline).color(UIColor.ud.textCaption)
        return contentElement
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkChat.Lark_IM_StatusNote_Title
        self.view.backgroundColor = UIColor.ud.bgBase
        let contentView = UIView()
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(StatusDetailViewController.Config.topPadding)
            make.left.equalToSuperview().offset(StatusDetailViewController.Config.leftPadding)
            make.right.equalToSuperview().offset(-StatusDetailViewController.Config.rightPadding)
        }
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.layer.cornerRadius = 8
        contentView.addSubview(scrollView)
        self.labelView.delegate = self
        core.load(styleSheets: StatusDetailViewController.styleSheets)
        self.labelView.bindEvent(selectorLists: StatusDisplayView.propagationSelectors, isPropagation: true)
        scrollView.addSubview(labelView)
        scrollView.backgroundColor = .clear
        labelView.backgroundColor = .clear
        configEventHandler()
        // 这里是为了让view在iPad上取到正确的bounds
        DispatchQueue.main.async {
            self.richElement = self.getRichElement()
            guard let richElement = self.richElement else {
                return
            }
            self.core.load(renderer: self.core.createRenderer(richElement))
            guard let labelSize = self.core.layout(CGSize(width: self.view.bounds.width - StatusDetailViewController.Config.labelLeftPadding * 2
                                                          - StatusDetailViewController.Config.leftPadding * 2, height: CGFloat.greatestFiniteMagnitude)) else {
                return
            }
            self.contentMaxHeight = self.view.bounds.height - StatusDetailViewController.Config.naviBarHeight - StatusDetailViewController.Config.topPadding * 2
            self.scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(min(labelSize.height + StatusDetailViewController.Config.labelTopPadding + StatusDetailViewController.Config.labelBottomPadding, self.contentMaxHeight))
            }
            self.labelView.setRichViewCore(self.core)
            self.labelView.preferredMaxLayoutWidth = self.view.bounds.width - StatusDetailViewController.Config.labelLeftPadding * 2 - StatusDetailViewController.Config.leftPadding * 2
            self.labelView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(StatusDetailViewController.Config.labelLeftPadding)
                make.top.equalToSuperview().offset(StatusDetailViewController.Config.labelTopPadding)
                make.bottom.equalToSuperview().offset(-StatusDetailViewController.Config.labelBottomPadding)
                make.height.equalTo(labelSize.height)
            }
        }
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
        navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func handleURLClick(_ url: URL) {
        if let httpUrl = url.lf.toHttpUrl() {
            navigator.push(httpUrl, from: self)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.richElement = self.getRichElement()
        guard let richElement = self.richElement else { return }
        self.core.load(renderer: self.core.createRenderer(richElement))
        let labelWidth = size.width - StatusDetailViewController.Config.labelLeftPadding * 2 - StatusDetailViewController.Config.leftPadding * 2
        let labelHeight = CGFloat.greatestFiniteMagnitude
        guard let labelSize = self.core.layout(CGSize(width: labelWidth, height: labelHeight)) else { return }
        self.contentMaxHeight = size.height - StatusDetailViewController.Config.naviBarHeight - StatusDetailViewController.Config.topPadding * 2
        self.scrollView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(min(labelSize.height + StatusDetailViewController.Config.labelTopPadding + StatusDetailViewController.Config.labelBottomPadding, self.contentMaxHeight))
        }
        self.labelView.setRichViewCore(self.core)
        self.labelView.preferredMaxLayoutWidth = labelWidth
        self.labelView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().inset(StatusDetailViewController.Config.labelLeftPadding)
            make.right.lessThanOrEqualToSuperview().inset(StatusDetailViewController.Config.labelLeftPadding)
            make.top.equalToSuperview().offset(StatusDetailViewController.Config.labelTopPadding)
            make.bottom.equalToSuperview().offset(-StatusDetailViewController.Config.labelBottomPadding)
            make.size.equalTo(labelSize)
        }
    }
}

extension StatusDetailViewController: LKRichViewDelegate {
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {}

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

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
