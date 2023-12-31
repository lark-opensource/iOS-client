//
//  MsgCardLynxTextView.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/11/17.
//

import Foundation
import Lynx
import LKCommonsLogging
import LKRichView
import LarkContainer
import LarkSetting
import LarkAccountInterface
import RustPB
import LarkModel
import LarkOPInterface
import LarkMessengerInterface
import LarkUIKit
import LarkCore
import EENavigator

fileprivate typealias TextViewInteractionData = (
    atClickable: Bool,
    linkClickable: Bool,
    codeBlockData: [String : Basic_V1_RichTextElement.CodeBlockV2Property]?,
    listImgData: [String : ListItemImageProps]?,
    images: [String : Basic_V1_RichTextElement.ImageProperty]?
)

fileprivate typealias TextViewData = (
    tag: String?,
    id: String?,
    core: LKRichViewCore,
    interaction: TextViewInteractionData
)

fileprivate let InvalidTextViewSize: CGFloat = 10000
public final class MsgCardLynxTextViewShadowNode: LynxShadowNode, LynxCustomMeasureDelegate {
    public static let name: String = "msg-card-text"
    private static let logger = Logger.oplog(MsgCardLynxTextViewShadowNode.self, category: "MsgCardLynxTextViewShadowNode")
    @InjectedLazy private var cardContextManager: MessageCardContextManagerProtocol
    @InjectedOptional private var openPlatformService: OpenPlatformService?
    private let core = LKRichViewCore()
    private var textViewProps: TextViewProps?
    private var atUsers: [String: MsgCardLynxAtUser]?
    private var cardContext: MessageCardContainer.Context?
    private var images: [String : Basic_V1_RichTextElement.ImageProperty]?
    private var codeBlockData: [String: Basic_V1_RichTextElement.CodeBlockV2Property]?
    
    private var element: LKRichElement?
    // 重载构造函数
    override init(sign: Int, tagName: String) {
        super.init(sign: sign, tagName: tagName)
        customMeasureDelegate = self
    }
    
    @objc public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
            ["context", NSStringFromSelector(#selector(setContext))],
        ]
    }
    
    public func measure(with param: MeasureParam, measureContext context: MeasureContext?) -> MeasureResult {
        let (width, widthMode, height, heightMode ) = (param.width, param.widthMode, param.height, param.heightMode)
        let originSize: CGSize = CGSize(width: width, height: height)
        // 在宽或高为未定义的情况下,给与最大值, 由 richcore 计算宽高
        // 潜在前提, 前端必须至少提供宽或高其中一个值, 否者无法正常进行计算 (可以通过 originSize 进行调试)

        var measureSize = CGSize(
            width: (widthMode == .indefinite || width > InvalidTextViewSize) ? CGFloat.greatestFiniteMagnitude : width,
            // core.layout 提供高度时有 bug, 某些场景下会算出比实际高度更高的值, 然后因为这个 height 的限制,导致 RichView 被强行裁剪,
            // 因为目前卡片不存在宽自适应, 高度固定的情况
            height: CGFloat.greatestFiniteMagnitude
        )
        if (widthMode == .indefinite || width > InvalidTextViewSize)  && (heightMode == .indefinite || height > InvalidTextViewSize) {
            return MeasureResult(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), baseline: 0)
        }

        //先 setuprichcore 后 layout
        setupRichElement(limitWidth: measureSize.width)
        setupRichCore(elementWidth: measureSize.width, isdefinite: widthMode == .definite )
        let textSize = core.layout(measureSize)
        return MeasureResult(size: textSize ?? originSize, baseline: 0)
    }
    
    public func align(with param: AlignParam, alignContext context: AlignContext) {

    }

    // 实现属性响应，响应的属性为 content，方法名称为 setContent，通过 setNeedsLayout() 触发排版。
    @objc private func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [String: Any] else {
            assertionFailure("MsgCardLynxTextViewShadowNode receive wrong props type: \(String(describing: props.self))")
            Self.logger.error("MsgCardLynxTextViewShadowNode receive wrong props type: \(String(describing: props.self))")
            return
        }
        do {
            var textViewProps = try TextViewProps.from(dict: props)
            @Setting(key: UserSettingKey.make(userKeyLiteral: "msg_card_max_content_limit"))
            var maxConfig: [String: Int]?
            if let maxLength = maxConfig?["text_max_length"] {
                let contentProps = textViewProps.contentProps?.map({ props in
                    guard let plainProps = props.plainTextProps, var content = plainProps.content else { return props }
                    var element = props
                    let lastLength = content.count
                    content = String(content.prefix(maxLength))
                    if lastLength > maxLength { content += "..." }
                    element.plainTextProps?.content = content
                    return element
                })
                textViewProps.contentProps = contentProps
            }
            self.textViewProps = textViewProps

        } catch let error {
            Self.logger.error("MsgCardLynxTextViewShadowNode props serilize fail: \(error.localizedDescription)")
        }
        setNeedsLayout()
    }
    
    @objc private func setContext(context: Any?, requestReset _: Bool) {
        guard let context = context as? [String: Any],
              let attachment = context["attachment"] as? [String: Any], attachment.count > 0,
              let atUsersDict = attachment["atUsers"] as? [String: [String: Any]],
              let key = context["key"] as? String,
              let cardContext = cardContextManager.getContext(key: key) else {
            assertionFailure("MsgCardLynxTextViewShadowNode receive wrong context type: \(String(describing: context.self))")
            Self.logger.error("MsgCardLynxTextViewShadowNode receive wrong context type: \(String(describing: context.self))")
            return
        }
        self.atUsers = [:]
        atUsersDict.forEach { [weak self ](key: String, value: [String: Any]) in
            do {
                self?.atUsers?[key] = try MsgCardLynxAtUser.from(dict: value)
            } catch let error {
                Self.logger.error("MsgCardLynxTextViewShadowNode atUsers serilize fail: \(error.localizedDescription)")
            }
        }
        
        self.cardContext = cardContext
        
        setNeedsLayout()
    }
    
    private func setupRichElement(limitWidth: CGFloat) {
        guard let textViewProps = textViewProps, let atUsers = atUsers, let cardContext = cardContext else {
            // 数据未准备好
            return
        }
        images = MsgCardImageUtils.getAttachmentImages(cardContext: cardContext, openPlatformService: openPlatformService, isTranslateElement: textViewProps.isTranslateElement ?? false)
        element = LKRichElement.richElement(fromTextViewProps: textViewProps, atUsers: atUsers, images: images, limitWidth: limitWidth, isME: { userid in
            return AccountServiceAdapter.shared.currentChatterId == userid
        })
    }
    
    private func setupRichCore(elementWidth: CGFloat, isdefinite: Bool) {
        guard let element = element else { return }
        if (isdefinite) { element.style.minWidth(.point(elementWidth)) }
        core.load(styleSheets: createStyleSheets())
        let renderer = core.createRenderer(element)
        core.load(renderer: renderer)

    }
    
    public override func getExtraBundle() -> Any {
        let interaction = getInteractionData()
        let data: TextViewData = (
            tag: textViewProps?.tag,
            id: textViewProps?.id,
            core: core,
            interaction: interaction
        )
        return data
    }
    
    private func getInteractionData() -> TextViewInteractionData {
        guard let textViewProps = textViewProps else {
            return (
                atClickable: true,
                linkClickable: true,
                codeBlockData: nil,
                listImgData: nil,
                images: nil
            )
        }
        
        var codeBlockData: [String : Basic_V1_RichTextElement.CodeBlockV2Property] = [:]
        var listImgData: [String : ListItemImageProps] = [:]
        textViewProps.contentProps?.forEach({ contentProp in
            if let codeBlockProps = contentProp.codeBlockProps,
               let codeProperty = try? Basic_V1_RichTextElement.CodeBlockV2Property(jsonString: codeBlockProps),
               let codeBlockID = contentProp.id {
                codeBlockData[codeBlockID] = codeProperty
            } else if let listProps = contentProp.listProps {
                listProps.forEach { itemProps in
                    itemProps.items?.forEach({ itemContent in
                        if let imageProps = itemContent.imageProps,
                           let imageID = itemContent.id {
                            listImgData[imageID] = imageProps
                        }
                    })
                }
            }
        })
        return (
            atClickable: true,
            linkClickable: true,
            codeBlockData: codeBlockData as [String : Basic_V1_RichTextElement.CodeBlockV2Property]?,
            listImgData: listImgData as [String : ListItemImageProps]?,
            images: images as [String : Basic_V1_RichTextElement.ImageProperty]?
        )
    }
}

public final class MsgCardLynxTextView: LynxUIView {
    public static let name: String = "msg-card-text"
    private static let logger = Logger.oplog(MsgCardLynxTextView.self, category: "MsgCardLynxTextView")
    
    @InjectedLazy private var cardContextManager: MessageCardContextManagerProtocol
    private static let msgCardCopyableBaseKey = "msgCardCopyableBaseKey"

    private var cardContext: MessageCardContainer.Context?
    
    private weak var targetElement: LKRichElement?
    
    private var tag: String?
    private var id: String?
    private var interactionData: TextViewInteractionData = (
        atClickable: true,
        linkClickable: true,
        codeBlockData: nil,
        listImgData: nil,
        images: nil
    )
    
    public override func ignoreFocus() -> Bool {
        return true
    }
    
    // fix 复制选中态，点击大头针时点到父组件上,  因此扩大组件的点击范围
    public override func contains(_ point: CGPoint, inHitTestFrame:CGRect) -> Bool {
        let frame = inHitTestFrame.inset(by: UIEdgeInsets(edges: CursorSize ))
        return super.contains(point, inHitTestFrame: frame)
    }
    
    private let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: ElementTag.container)],
        [CSSSelector(value: ElementTag.link)],
        [CSSSelector(value: ElementTag.at)],
        [CSSSelector(value: ElementTag.codeBlock)],
        [CSSSelector(value: ElementTag.listItemImg)]
    ]
    
    private lazy var richContainerView: LKRichContainerView = {
        let richContainerView = LKRichContainerView(options: MsgCardRichViewConfig)
        richContainerView.richView.displayMode = .sync
        richContainerView.richView.delegate = self
        richContainerView.richView.bindEvent(selectorLists: propagationSelectors, isPropagation: true)
        return richContainerView
    }()
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
            ["context", NSStringFromSelector(#selector(setContext))],
        ]
    }
    
    @objc public override func createView() -> LKRichContainerView? {
        return richContainerView
    }
    
    public override func onReceiveOperation(_ value: Any?) {
        guard let data = value as? TextViewData else {
            Self.logger.info("MsgCardLynxTextView Receive Wrong type: \(value.self ?? "")")
            return
        }
        tag = data.tag
        id = data.id
        interactionData = data.interaction
        self.richContainerView.richView.setNeedsDisplay()
        DispatchQueue.main.async {
            self.richContainerView.richView.setRichViewCore(data.core)
        }
    }
    
    @objc func setProps(props: Any?, requestReset _: Bool) {
        // 空实现, 绑定 lynx 前端组件属性. ShadowNode 的 props 与此值一致
        // 为避免对富文本重复计算, ShadowNode -layoutDidUpdate 会将 core 传过来, 在 ReceiveOperation 中处理
    }
    
    @objc func setContext(context: Any?, requestReset _: Bool) {
        // 空实现, 绑定 lynx 前端组件属性. ShadowNode 的 context 与此值一致
        // 为避免对富文本重复计算, ShadowNode -layoutDidUpdate 会将 core 传过来, 在 ReceiveOperation 中处理
        guard let context = context as? [AnyHashable: Any],
              let key = context["key"] as? String,
              let cardContext = cardContextManager.getContext(key: key) else {
            assertionFailure("MsgCardLynxTextView get wrong context: \(context)")
            return
        }
        richContainerView.componentKey = cardContext.getCopyableComponentKey()
        self.cardContext = cardContext
    }
}

extension MsgCardLynxTextView: LKRichViewDelegate {
    
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
        // 只响应源和目标相同的点击事件,忽略滑动等
        guard targetElement === event?.source else { return }
        switch element.tagName.typeID {
        case ElementTag.link.rawValue where interactionData.linkClickable:
            handleTagLinkEvent(element, event: event)
        case ElementTag.at.rawValue where interactionData.atClickable:
            handleTagAtEvent(element, event: event)
        case ElementTag.codeBlock.rawValue:
            handleCodeBlockEvent(element, event: event)
        case ElementTag.listItemImg.rawValue:
            handleListItemImageEvent(element, event: event)
        default:
            return
        }
    }
    
    func handleListItemImageEvent(_ element: LKRichElement, event: LKRichTouchEvent?) {
        guard let property = interactionData.listImgData?[element.id],
              let images = interactionData.images,
              let imageID = property.image_id,
              images[imageID]?.imgCanPreview ?? false else { return }
        MsgCardImageUtils.showPreviewImage(cardContext: cardContext, images: images, imageKey: images[imageID]?.originKey, previewImages: property.previewImages)
    }
    
    func handleCodeBlockEvent(_ element: LKRichElement, event: LKRichTouchEvent?) {
        guard let property = interactionData.codeBlockData?[element.id],
              let actionService = cardContext?.dependency?.actionService else { return }
        let actionContext = MessageCardActionContext(
            elementTag: tag,
            elementID: id,
            bizContext: cardContext,
            actionFrom: .innerLink()
        )
        actionService.openCodeBlockDetail(context: actionContext, property: property)
    }
    
    func handleTagLinkEvent(_ element: LKRichElement, event: LKRichTouchEvent?) {
        guard let href = (element as? LKAnchorElement)?.href,
              let actionService = cardContext?.dependency?.actionService else { return }
        let actionContext = MessageCardActionContext(
            elementTag: tag,
            elementID: id,
            bizContext: cardContext,
            actionFrom: .innerLink()
        )
        actionService.openUrl(context: actionContext, urlStr: href)
    }

    func handleTagAtEvent(_ element: LKRichElement, event: LKRichTouchEvent?) {
        guard let href = (element as? LKAnchorElement)?.href,
              let actionService = cardContext?.dependency?.actionService else { return }
        let actionContext = MessageCardActionContext(
            elementTag: tag,
            elementID: id,
            bizContext: cardContext,
            actionFrom: .innerLink()
        )
        actionService.openProfile(context: actionContext, chatterID: href)
    }

    func checkCanHandleTap(_ point: CGPoint) -> Bool {
        if let element = self.richContainerView.richView.getElementByPoint(point) {
            switch element.tagName.typeID {
            case ElementTag.link.rawValue where interactionData.linkClickable:
                guard interactionData.linkClickable else { return false }
                return true
            case ElementTag.at.rawValue where interactionData.atClickable:
                guard interactionData.atClickable else { return false }
                return true
            case ElementTag.codeBlock.rawValue, ElementTag.listItemImg.rawValue:
                return true
            default:
                return false
            }
        }
        return false
    }

    public override func dispatchEvent(_ event: LynxEventDetail) -> Bool {
        if(event.eventName == "tap") {
            return checkCanHandleTap(event.targetPoint)
        }
        return false
    }
}

