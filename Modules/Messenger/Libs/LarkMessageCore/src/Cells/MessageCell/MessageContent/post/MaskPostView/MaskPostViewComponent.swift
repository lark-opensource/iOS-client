//
//  MaskPostViewComponent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/19.
//

import UIKit
import Foundation
import AsyncComponent
import RichLabel
import EEFlexiable
import LKCommonsLogging
import LKRichView

private struct LabelLogger: LKLabelLogger {
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

/// 把maskView和postView包装一层
public final class MaskPostViewComponent<C: AsyncComponent.Context>: ASComponent<MaskPostViewComponent.Props, EmptyState, UIView, C> {
    /// 该Props包含了内部postView maskView的所有需要的上下文
    public final class Props: ASComponentProps {
        private var unfairLock = os_unfair_lock_s()
        /// postView props
        public var titleLines: Int = 0
        public var numberOfLines: Int = 0
        public var isShowTitle: Bool = false
        //是否是新的下线翻译的群公告
        public var isNewGroupAnnouncement: Bool = false
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
        public var textCheckingDetecotor: NSRegularExpression?
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
        /// maskView props
        private var _backgroundColors: [UIColor] = []
        public var backgroundColors: [UIColor] {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _backgroundColors
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _backgroundColors = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _showMoreHandler: (() -> Void)?
        public var showMoreHandler: (() -> Void)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _showMoreHandler
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _showMoreHandler = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        public var isShowMore: Bool = false
        /// 由于公告正文统一为白色，所以需要取消Margin，由post自己进行布局
        public var hasMargin: Bool = true
        /// 标题以及post正文背景色
        private var _titleBGColor: UIColor?
        public var titleBGColor: UIColor? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _titleBGColor
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _titleBGColor = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _postBGColor: UIColor?
        public var postBGColor: UIColor? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _postBGColor
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _postBGColor = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _splitLineColor: UIColor?
        public var splitLineColor: UIColor? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _splitLineColor
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _splitLineColor = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        /// 链接按压态样式
        private var _activeLinkAttributes: [NSAttributedString.Key: Any] = [:]
        public var activeLinkAttributes: [NSAttributedString.Key: Any] {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _activeLinkAttributes
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _activeLinkAttributes = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        /// link链接颜色
        private var _linkAttributesColor: UIColor?
        public var linkAttributesColor: UIColor? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _linkAttributesColor
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _linkAttributesColor = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        /// 用来控制title、content的左右边距
        public var marginToLeft: CGFloat = 12
        public var marginToRight: CGFloat = 12

        public weak var richDelegate: LKRichViewDelegate?
        private var _richElement: LKRichElement?
        public var richElement: LKRichElement? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _richElement
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _richElement = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _richStyleSheets: [CSSStyleSheet] = []
        public var richStyleSheets: [CSSStyleSheet] {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _richStyleSheets
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _richStyleSheets = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        public var propagationSelectors: [[CSSSelector]] = [] // 冒泡事件
        public var catchSelectors: [[CSSSelector]] = [] // 捕获事件
        public var configOptions: ConfigOptions?
        public var isNewRichComponent = false
        public var displayMode: DisplayMode = .auto
        /// 是否为译文，防止密聊出现翻译反馈button，默认设置为false
        public var isTranslate: Bool = false
    }

    /// post view style
    private lazy var postViewStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.position = .relative
        return style
    }()

    private lazy var postViewProps: PostViewComponent<C>.Props = {
        let options = PostViewComponent<C>.Props()
        options.contentOptions = [
            .cursorColor(UIColor.ud.colorfulBlue),
            .selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.16)),
            .cursorTouchHitTestInsets(UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25))
        ]
        #if DEBUG
        options.contentSelectionDebugOptions = LKSelectionLabelDebugOptions([.printTouchEvent])
        #endif
        options.contentDebugOptions = [.logger(LabelLogger())]
        return options
    }()

    ///  展开button，不带虚化效果
    private lazy var showMoreStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        /// 绝对布局，不撑开父视图
        style.position = .absolute
        style.left = 0
        style.right = 0
        style.bottom = -1 // TODO: qhy 疑似 yoga 问题
        style.height = CSSValue(cgfloat: ShowMoreButtonView.maskHeight)
        return style
    }()
    private let showMoreProps = ShowMoreMaskButtonComponent<C>.Props()
    private lazy var showMoreButton: ShowMoreMaskButtonComponent<C> = {
        return ShowMoreMaskButtonComponent<C>(props: showMoreProps, style: showMoreStyle)
    }()

    private lazy var postViewComponent: PostViewComponent<C> = {
        return PostViewComponent<C>(props: postViewProps, style: postViewStyle)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        /// get postView props
        setPostViewProps()
        /// set maskView style
        setMaskViewProps()
        showMoreStyle.display = props.isShowMore ? .flex : .none
        /// 是翻译内容且展示更多时上移展开button，上移的高度是翻译反馈button的高度，避免遮挡
        showMoreStyle.bottom = -1

        self.setPostViewMinWidth(props)

        setSubComponents([
            postViewComponent,
            showMoreButton
        ])
    }

    /// 此方法在该component的props属性被修改时调用，在这里我们可以根据最新的props
    /// 对界面进行调整
    public override func willReceiveProps(_ old: MaskPostViewComponent<C>.Props, _ new: MaskPostViewComponent<C>.Props) -> Bool {
        /// get postView props
        setPostViewProps()
        /// set maskView style
        setMaskViewProps()
        self.setPostViewMinWidth(props)
        // 这里如果群公告的翻译的话 -> 根据UI反馈不需要10的空白距离 挨着leftLineComponent
        if props.isNewGroupAnnouncement {
            postViewStyle.marginLeft = 0
            postViewStyle.flexGrow = 1
        } else {
            postViewStyle.flexGrow = 0
        }
        showMoreStyle.display = props.isShowMore ? .flex : .none
        // 如果是译文而且有展开按钮，需要将展开向上移动翻译反馈的高度
        if props.isShowMore {
            showMoreStyle.bottom = -1
        }
        showMoreButton.props = showMoreProps
        postViewProps.textCheckingDetecotor = new.textCheckingDetecotor
        postViewComponent.props = postViewProps
        return true
    }

    private func setPostViewMinWidth(_ props: MaskPostViewComponent<C>.Props) {
        let minWidth = props.isShowMore ? ShowMoreButton.caculatedSize.width : 0
        postViewStyle.minWidth = CSSValue(cgfloat: minWidth)
    }

    /// 获取post view显示需要的所有上下文
    private func setPostViewProps() {
        postViewProps.hasMargin = props.hasMargin
        postViewProps.titleBGColor = props.titleBGColor
        postViewProps.contentComponentTag = props.contentComponentTag
        postViewProps.titleLines = props.titleLines
        postViewProps.splitLineColor = props.splitLineColor
        postViewProps.contentMaxWidth = props.contentMaxWidth
        postViewProps.isShowTitle = props.isShowTitle
        postViewProps.titleAttributedText = props.titleAttributedText
        postViewProps.titleText = props.titleText
        postViewProps.titleComponentKey = props.titleComponentKey
        postViewProps.contentComponentKey = props.contentComponentKey
        postViewProps.rangeLinkMap = props.rangeLinkMap
        postViewProps.textLinkBlock = props.textLinkBlock
        postViewProps.tapableRangeList = props.tapableRangeList
        postViewProps.textLinkMap = props.textLinkMap
        postViewProps.contentAttributedText = props.contentAttributedText
        postViewProps.contentLineSpacing = props.contentLineSpacing
        postViewProps.numberOfLines = props.numberOfLines
        postViewProps.delegate = props.delegate
        postViewProps.tapHandler = props.tapHandler
        postViewProps.selectionDelegate = props.selectionDelegate
        postViewProps.textCheckingDetecotor = props.textCheckingDetecotor
        postViewProps.linkAttributesColor = props.linkAttributesColor
        postViewProps.activeLinkAttributes = props.activeLinkAttributes
        postViewProps.marginToLeft = props.marginToLeft
        postViewProps.marginToRight = props.marginToRight
        postViewProps.isNewGroupAnnouncement = props.isNewGroupAnnouncement

        postViewProps.richDelegate = props.richDelegate
        postViewProps.richElement = props.richElement
        postViewProps.richStyleSheets = props.richStyleSheets
        postViewProps.propagationSelectors = props.propagationSelectors
        postViewProps.catchSelectors = props.catchSelectors
        postViewProps.configOptions = props.configOptions
        postViewProps.isNewRichComponent = props.isNewRichComponent
        postViewProps.displayMode = props.displayMode
        postViewComponent.style.backgroundColor = props.postBGColor
    }
    /// 获取mask view显示需要的所有上下文
    private func setMaskViewProps() {
        showMoreProps.backgroundColors = props.backgroundColors
        showMoreProps.showMoreHandler = props.showMoreHandler
    }
}
