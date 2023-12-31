//
//  PostViewComponent.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/15.
//

import UIKit
import Foundation
import RichLabel
import EEFlexiable
import AsyncComponent
import LKCommonsLogging
import UniverseDesignCardHeader
import UniverseDesignIcon
import LKRichView

struct LKLabelLoggerImpl: LKLabelLogger {
    let logger = Logger.log(LKLabel.self)

    func debug(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.debug(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }

    func info(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.info(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }

    func error(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.error(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }
}

// PostViewComponent<C: AsyncComponent.Context> 泛型中无法使用static，无法使用PostViewComponent的命名空间来调用。
// 所以创建一个命名上呈现命名空间特点的类来替代。
public struct PostViewComponentConstant {
    /// 原文key
    public static let titleKey = "PostViewComponentConstant_titleKey"
    public static let contentKey = "PostViewComponentConstant_contentKey"
    public static let imageKey = "ImageContent"
    public static let bubbleKey = "chat-cell-bubble"
    /// 译文key
    public static let translateTitleKey = "PostViewComponentConstant_translateTitleKey"
    public static let translateContentKey = "PostViewComponentConstant_translateContentKey"
}

/// showMore时，需要知道具体是哪个label来判断是原文还是译文需要显示"查看全文"，后期会用key代替
struct PostViewComponentTag {
    /// 原文 lklabel tag
    public static let contentTag: Int = 10_001
    /// 译文 lklabel tag
    public static let translateContentTag = PostViewComponentTag.contentTag + 1
}

public final class PostViewComponent<C: AsyncComponent.Context>: ASComponent<PostViewComponent.Props, EmptyState, PostViewCore, C> {
    public final class Props: ASComponentProps {
        private var unfairLock = os_unfair_lock_s()
        public var titleLines: Int = 2
        public var numberOfLines: Int = 0
        public var isShowTitle: Bool = false
        //是否是下线了翻译的群公告
        public var isNewGroupAnnouncement: Bool = false
        public var contentOptions: SelectionLKLabelOptions?
        public var textCheckingDetecotor: NSRegularExpression?
        public var contentSelectionDebugOptions: LKSelectionLabelDebugOptions?
        public var contentDebugOptions: [LKLabelDebugOptions]?
        public var titleText: String = ""
        public var titleComponentKey: String = ""
        public var titleAttributedText: NSAttributedString?
        public var contentComponentKey: String = ""
        public var contentComponentTag: Int = 0
        public var contentMaxWidth: CGFloat = 0
        public var contentAttributedText: NSAttributedString?
        public var contentLineSpacing: CGFloat = 2
        public var rangeLinkMap: [NSRange: URL] = [:]
        public var tapableRangeList: [NSRange] = []
        public var textLinkMap: [NSRange: String] = [:]
        public weak var delegate: LKLabelDelegate?
        public weak var selectionDelegate: LKSelectionLabelDelegate?
        private var _textLinkBlock: ((String) -> Void)?
        public var textLinkBlock: ((String) -> Void)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _textLinkBlock
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _textLinkBlock = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _tapHandler: (() -> Void)?
        public var tapHandler: (() -> Void)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _tapHandler
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _tapHandler = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        public var hasMargin: Bool = true
        public var titleBGColor: UIColor? = UIColor.clear
        public var splitLineColor: UIColor? = UIColor.ud.N400.withAlphaComponent(0.5)
        /// link链接颜色
        public var linkAttributesColor: UIColor? = UIColor.ud.textLinkNormal
        /// 链接按压态样式
        public var activeLinkAttributes: [NSAttributedString.Key: Any] = [:]
        /// 用来控制title、content的左右边距
        public var marginToLeft: CGFloat = 12
        public var marginToRight: CGFloat = 12

        public weak var richDelegate: LKRichViewDelegate?
        public var richElement: LKRichElement?
        public var richStyleSheets: [CSSStyleSheet] = []
        public var propagationSelectors: [[CSSSelector]] = [] // 冒泡事件
        public var catchSelectors: [[CSSSelector]] = [] // 捕获事件
        public var configOptions: ConfigOptions?
        public var isNewRichComponent = false
        public var displayMode: DisplayMode = .auto
    }

    lazy var titleComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.flexGrow = 0
        style.flexShrink = 1
        style.marginBottom = 1
        let props = UILabelComponentProps()
        props.font = UIFont.ud.title3
        props.textColor = UIColor.ud.N900
        props.textAlignment = .left
        props.numberOfLines = 2
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var titleWrapperComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.flexDirection = .column
        return UIViewComponent(props: .empty, style: style)
    }()

    private lazy var groupAnnouncementHeader: GroupAnnouncementCardHeaderComponent<C> = {
        let props = GroupAnnouncementCardHeaderComponent<C>.Props()
        let style = ASComponentStyle()
        style.width = 100%
        return GroupAnnouncementCardHeaderComponent<C>(props: props, style: style)
    }()

    private lazy var contentComponent: SelectionLabelComponent<C> = {
        return SelectionLabelComponent<C>(
            props: SelectionLabelComponent<C>.Props(),
            style: ASComponentStyle()
        )
    }()

    lazy var newContentComponent: RichViewComponent<C> = {
        return RichViewComponent<C>(
            props: RichViewComponentProps(),
            style: ASComponentStyle()
        )
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        titleWrapperComponent.setSubComponents([titleComponent])
        setSubComponents([titleWrapperComponent, contentComponent, newContentComponent])
        setUpProps()
        setUpStyle()
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        contentComponent.style.display = new.isNewRichComponent ? .none : .flex
        newContentComponent.style.display = new.isNewRichComponent ? .flex : .none

        if new.contentMaxWidth > 0 {
            style.maxWidth = CSSValue(cgfloat: new.contentMaxWidth)
        } else {
            style.maxWidth = CSSValueUndefined
        }
        self.setUpHeader(new)
        if !new.hasMargin {
            if new.isNewRichComponent {
                newContentComponent._style.marginTop = 8
                newContentComponent._style.marginLeft = CSSValue(cgfloat: props.marginToLeft.auto())
                newContentComponent._style.marginRight = CSSValue(cgfloat: props.marginToRight.auto())
            } else {
                contentComponent._style.marginTop = 8
                contentComponent._style.marginLeft = CSSValue(cgfloat: props.marginToLeft.auto())
                contentComponent._style.marginRight = CSSValue(cgfloat: props.marginToRight.auto())
            }
        } else {
            if new.isNewRichComponent {
                newContentComponent._style.marginTop = isShowTitle ? 4 : 0
            } else {
                contentComponent._style.marginTop = isShowTitle ? 4 : 0
            }
        }
        if new.isNewGroupAnnouncement {
            if new.isNewRichComponent {
                newContentComponent._style.marginTop = 0
            } else {
                contentComponent._style.marginTop = 0
            }
        }
        if new.isNewRichComponent {
            let props = RichViewComponentProps()
            props.delegate = new.richDelegate
            props.element = new.richElement
            props.styleSheets = new.richStyleSheets
            props.propagationSelectors = new.propagationSelectors
            props.catchSelectors = new.catchSelectors
            props.configOptions = new.configOptions
            props.key = new.isNewGroupAnnouncement ? "" : new.contentComponentKey
            props.tag = new.contentComponentTag
            props.displayMode = new.displayMode
            newContentComponent.props = props
        } else {
            contentComponent.props.options = new.contentOptions
            contentComponent.props.numberOfLines = new.numberOfLines
            // 因为post取消了margin，所以需要主动减少左右边距
            contentComponent.props.preferMaxLayoutWidth = new.hasMargin ? new.contentMaxWidth : (new.contentMaxWidth - 24.auto())
            /// contentComponent最终展示时的size是询问LKTextLayoutEngine经过layout得到的，
            /// preferMaxWidth做为LKTextLayoutEngine的入参进行layout后
            /// 可能会得到一个大于preferMaxWidth的width（这个后续会考虑优化）导致展示时超出父视图
            /// 所以我们需要从flex层再次约束maxWidth确保展示正常
            contentComponent._style.maxWidth = CSSValue(cgfloat: new.hasMargin ? new.contentMaxWidth : (new.contentMaxWidth - 24.auto()))
            contentComponent.props.delegate = new.delegate
            contentComponent.props.tapableRangeList = new.tapableRangeList
            contentComponent.props.rangeLinkMap = new.rangeLinkMap
            contentComponent.props.key = new.isNewGroupAnnouncement ? "" : new.contentComponentKey
            contentComponent.props.tag = new.contentComponentTag
            contentComponent.props.textCheckingDetecotor = props.textCheckingDetecotor
            contentComponent.props.selectionDelegate = props.selectionDelegate

            var textLinkList: [LKTextLink] = []
            new.textLinkMap.forEach { (range, url) in
                var textLink = LKTextLink(range: range, type: .link)
                textLink.linkTapBlock = { [weak self] (_, _) in
                    self?.props.textLinkBlock?(url)
                }
                textLinkList.append(textLink)
            }
            contentComponent.props.textLinkList = textLinkList
            contentComponent.props.attributedText = new.contentAttributedText
            contentComponent.props.activeLinkAttributes = new.activeLinkAttributes
        }
        return true
    }

    public override func update(view: PostViewCore) {
        super.update(view: view)
        view.tapHandler = props.tapHandler
    }

    public override func render() -> BaseVirtualNode {
        return super.render()
    }

    private func setUpHeader(_ props: Props) {
        if props.isNewGroupAnnouncement {
            groupAnnouncementHeader.style.paddingTop = 12
            groupAnnouncementHeader.style.paddingBottom = 8
            groupAnnouncementHeader.style.paddingLeft = CSSValue(cgfloat: props.marginToLeft)
            groupAnnouncementHeader.style.paddingRight = CSSValue(cgfloat: props.marginToRight)
            setSubComponents([groupAnnouncementHeader, contentComponent, newContentComponent])
            let announcementProps = groupAnnouncementHeader.props
            announcementProps.titleText = props.titleText
            announcementProps.titleAttributedText = props.titleAttributedText
            announcementProps.titleComponentKey = props.titleComponentKey
            groupAnnouncementHeader.props = announcementProps
            return
        }
        titleWrapperComponent.setSubComponents([titleComponent])
        setSubComponents([titleWrapperComponent, contentComponent, newContentComponent])
        titleComponent.style.display = isShowTitle ? .flex : .none
        titleWrapperComponent.style.display = isShowTitle ? .flex : .none
        if let titleAttributeText = props.titleAttributedText {
            titleComponent.props.attributedText = titleAttributeText
        } else {
            titleComponent.props.text = props.titleText
        }
        titleComponent.props.key = props.titleComponentKey
        titleWrapperComponent.style.backgroundColor = props.titleBGColor
        if !props.hasMargin {
            titleComponent._style.marginTop = 8
            titleComponent._style.marginBottom = 8
            titleComponent._style.marginLeft = CSSValue(cgfloat: props.marginToLeft)
            titleComponent._style.marginRight = CSSValue(cgfloat: props.marginToRight)
        }
    }
}

fileprivate extension PostViewComponent {
    var isShowTitle: Bool {
        return props.isShowTitle
    }

    func setUpStyle() {
        style.flexDirection = .column
        style.alignItems = .flexStart
        titleComponent.style.backgroundColor = .clear

        contentComponent.style.backgroundColor = UIColor.clear
        contentComponent.style.top = isShowTitle ? 4 : 0
    }

    func setUpProps() {
        contentComponent.props.lineSpacing = props.contentLineSpacing
        #if DEBUG
        contentComponent.props.seletionDebugOptions = LKSelectionLabelDebugOptions([.printTouchEvent])
        #endif
        contentComponent.props.options = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        contentComponent.props.debugOptions = [
            .logger(LKLabelLoggerImpl())
        ]

        contentComponent.props.textCheckingDetecotor = DataCheckDetector

        contentComponent.props.linkAttributes = [
            .foregroundColor: UIColor.ud.textLinkNormal
        ]
    }
}

// 群公告消息头部 UI 特化
final class GroupAnnouncementCardHeaderComponent<C: Context>: ASComponent<GroupAnnouncementCardHeaderComponent.Props, EmptyState, UDCardHeader, C> {
    final class Props: ASComponentProps {
        public var titleText: String = ""
        public var titleComponentKey: String = ""
        public var titleAttributedText: NSAttributedString?
    }

    private lazy var iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let iconSize: CGFloat = 16.auto()
        props.setImage = {
            $0.set(image: UDIcon.getIconByKey(.announceFilled,
                                              iconColor: UIColor.ud.O400,
                                              size: CGSize(width: iconSize, height: iconSize)))
        }
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: iconSize)
        style.height = CSSValue(cgfloat: iconSize)
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    private lazy var titleComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.backgroundColor = UIColor.clear
        let props = UILabelComponentProps()
        props.font = UIFont.ud.headline
        props.textColor = UIColor.ud.textTitle
        props.textAlignment = .left
        props.numberOfLines = 2
        return UILabelComponent<C>(props: props, style: style)
    }()

    override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([iconComponent, titleComponent])
        style.alignItems = .center
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        if let titleAttributeText = new.titleAttributedText {
            let titleMutableAttrStr = NSMutableAttributedString(attributedString: titleAttributeText)
            titleMutableAttrStr.addAttributes([.foregroundColor: UIColor.ud.textTitle,
                                               .font: UIFont.ud.headline],
                                              range: NSRange(location: 0, length: titleMutableAttrStr.length))
            titleComponent.props.attributedText = titleMutableAttrStr
        } else {
            titleComponent.props.text = new.titleText
        }
        titleComponent.props.key = new.titleComponentKey
        return true
    }

    override func create(_ rect: CGRect) -> UDCardHeader {
        return UDCardHeader(color: UIColor.ud.bgFloat, textColor: UIColor.ud.textTitle)
    }

    override func update(view: UDCardHeader) {
        super.update(view: view)
        view.layoutType = .normal
    }
}
