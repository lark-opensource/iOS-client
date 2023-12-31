//
//  MessageCardMaskVIewComponent.swift
//  LarkOpenPlatform
//
//  Created by zhangjie.alonso on 2022/12/16.
//

import Foundation
import AsyncComponent
import LarkModel
import LarkMessageBase
//import struct LarkSDKInterface.PushCardMessageActionResult
import RustPB
import LKCommonsLogging
import LarkMessageCard
import LarkMessageCore
import EEFlexiable
import LarkMessengerInterface
import UniverseDesignIcon
import EEMicroAppSDK
import EENavigator
import LarkSetting

private struct Styles {
    static let PinContentMaxHeight: CGFloat = 240.0
    static let PinBottomGradientHeight: CGFloat = 30.0
    static let ContainerCornerRadius: CGFloat = 8.0
    static let ContainerMargin: CGFloat = 12.0
    static let HorizontalMargin: CGFloat = 12.0
    static let VerticalMargin: CGFloat = 8.0
    static let iconSize: CGSize =  CGSize(width: 10.auto(), height: 10.auto())
}

final class MessageCardMaskView: UIView {
    // MARK: 空实现，拦截掉didSelete事件，避免卡片多次点击闪烁问题
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}

final class MessageCardMaskViewComponent<C: MessageCardViewModelContext>: ASComponent<MessageCardMaskViewComponent.Props, EmptyState, MessageCardMaskView, C> {
    private let logger = Logger.log(MessageCardMaskViewComponent.self, category: "MessageCardMaskViewComponent")
    final class Props: ASComponentProps {
        var preferWidth: CGFloat
        var renderType: RenderType
        var message: Message 
        var chat: () -> Chat
        var trace: OPTrace? = nil
        public var maxHeight: CGFloat?
        public var showMoreBackgroundColors: [UIColor] = []
        public var hasCornerRadius: Bool = true
        public var isUserInteractionEnabled: Bool = true

        public init(preferWidth: CGFloat,
                    rendertype: RenderType,
                    message: Message,
                    isUserInteractionEnabled: Bool,
                    chat: @escaping () -> Chat
        ) {
            self.preferWidth = preferWidth
            self.renderType = rendertype
            self.message = message
            self.isUserInteractionEnabled = isUserInteractionEnabled
            self.chat = chat
            super.init()
        }
    }
    @FeatureGatingValue(key: "messagecard.support.translate.moreaction")
    var messageCardEnableTranslateMore: Bool

    @FeatureGatingValue(key: "messagecard.renderoptimization.enable")
    var enableRenderOptimization: Bool

    @FeatureGatingValue(key: "messagecard.lynxview_reuse_pool.enable")
    var enableLynxViewReusePool: Bool

    private var contentComponent: ComponentWithContext<C>?
    private var messageCardTranslateActionHandler: MessageCardTranslateActionHandler?
    
    #if BETA || ALPHA || DEBUG
    private lazy var debugButton: RightButtonComponent<C> = {
        return  self.GetDebugButton()
    }()
    fileprivate var messageCardDebugIsOn: Bool {
        return EMADebugUtil.sharedInstance()?.debugConfig(forID: kEMADebugConfigMessageCardDebugTool)?.boolValue ?? false
    }
    #endif
    
    //pin 蒙层
    private lazy var pinMaskComponent: MessageCardPinMaskComponent<C> = {
        let style = ASComponentStyle()
        style.display = .flex
        style.position = .absolute
        style.left = 0
        style.right = 0
        style.bottom = -1
        style.height = CSSValue(cgfloat: Styles.PinBottomGradientHeight)
        return MessageCardPinMaskComponent(
            props: MessageCardPinMaskComponent<C>.Props(),
            style: style,
            context: context
        )
    }()
    
    /// 翻译反馈style
    private lazy var translateRightButtonStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.marginBottom = CSSValue(cgfloat: Styles.VerticalMargin)
        style.marginLeft = CSSValue(cgfloat: Styles.ContainerMargin)
        style.backgroundColor = .clear
        style.alignContent = .flexStart
        style.alignSelf = .flexStart
        return style
    }()

    private lazy var translateFeedBackButton: RightButtonComponent<C> = {
        let props = RightButtonComponentProps()
        props.icon = UDIcon.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        props.iconSize = Styles.iconSize
        props.iconAndLabelSpacing = 2
        props.text = BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_TranslationFeedbackRateButton
        props.font = UIFont.ud.caption1
        props.textColor = UIColor.ud.textCaption
        props.onViewClicked = { [weak self] (_) in
            self?.translateFeedBackTapHandler()
        }
        return RightButtonComponent(props: props, style: translateRightButtonStyle)
    }()
    
    func translateFeedBackTapHandler() {
        if let translateFeedBackService = (self.context as? PageContext)?.resolver.resolve(TranslateFeedbackService.self),
           let targetVC = (self.context as? PageContext)?.pageAPI {
            translateFeedBackService.showTranslateFeedbackView(message: props.message, fromVC: targetVC)
            return
        }
    }
    
    /// 翻译 action props
    private lazy var translateActionProps: TranslateActionComponent<C>.Props = {
        let props = TranslateActionComponent<C>.Props()
        props.translateFeedBackTapHandler = { [weak self] in
            self?.messageCardTranslateActionHandler?.translateFeedBackTapHandler()
        }
        props.translateMoreActionTapHandler = { [weak self] view in
            self?.messageCardTranslateActionHandler?.translateMoreTapHandler(view)
        }
        return props
    }()
    /// 翻译 action style
    private lazy var translateActionStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.justifyContent = .spaceBetween
        style.marginBottom = CSSValue(cgfloat: Styles.VerticalMargin)
        style.marginLeft = CSSValue(cgfloat: Styles.ContainerMargin)
        style.marginRight = CSSValue(cgfloat: Styles.ContainerMargin)
        return style
    }()
    /// 翻译 action component
    private lazy var translateActionComponent: TranslateActionComponent<C> = {
        return TranslateActionComponent<C>(props: translateActionProps, style: translateActionStyle)
    }()
    
    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        if let context = context as? PageContext {
            messageCardTranslateActionHandler = MessageCardTranslateActionHandler(context: context, chat: props.chat, message: props.message)
        }
        super.init(props: props, style: style, context: context)
    }

    public func setContentComponent(_ component: ComponentWithContext<C>) {
        self.contentComponent = component
        setupComponents(self.props)
    }
    
    private func setupComponents(_ props: Props) {
        var subComponents:[ComponentWithContext<C>] = []
        if let contentComponent = self.contentComponent {
            subComponents.append(contentComponent)
        }
        if context?.scene == .pin {
            subComponents.append(pinMaskComponent)
            self.style.maxHeight = CSSValue(cgfloat: Styles.PinContentMaxHeight)
        }
        if props.renderType != .renderOriginal {
            if messageCardEnableTranslateMore {
                subComponents.append(translateActionComponent)
            } else {
                subComponents.append(translateFeedBackButton)
            }
        }
        #if BETA || ALPHA || DEBUG
        if messageCardDebugIsOn {
            subComponents.append(debugButton)
        }
        #endif
        setSubComponents(subComponents)
    }
    public override func create(_ rect: CGRect) -> MessageCardMaskView {
        let view = MessageCardMaskView()
        view.frame = rect
        view.isAccessibilityElement = true
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
        return view
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        setupComponents(new)
        // 消息更新了，message的displayrule会更新
        guard let messageCardTranslateActionHandler = messageCardTranslateActionHandler,
              let context = context as? PageContext else {
            logger.error("messageCardTranslateActionHandler update failed",additionalData: [
                "MessageID": new.message.id,
                "traceId": new.trace?.traceId ?? ""
            ])
            return true
        }
        messageCardTranslateActionHandler.update(context: context, chat: new.chat, message: new.message)
        return true
    }
    
    public override func update(view: MessageCardMaskView) {
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        super.update(view: view)
    }
    
}

#if BETA || ALPHA || DEBUG
extension MessageCardMaskViewComponent {

    fileprivate func debugHandler(newContent:CardContent) {
        if self.messageCardDebugIsOn ,
        let context = self.context as? PageContext {
            context.reloadRows(by: [props.message.id], doUpdate: { message -> Message? in
                message.content = newContent
                message.contentVersion += 1
                return message
            })
        }
    }

    fileprivate func GetDebugButton() ->RightButtonComponent<C> {
        let debugHandler = { [weak self] in
            guard let component = self else {
                return
            }
            if component.messageCardDebugIsOn {
                if let targetVC = component.context?.targetVC,
                   let content = component.props.message.content as? CardContent {
                    var vc = UINavigationController(rootViewController: MessageCardDebugEditController(content: content,
                                                                                                       handler: { [weak component] (newContent) in
                                                                                                                        component?.debugHandler(newContent:newContent)
                                                                                                                },
                                                                                                       message:  component.props.message,
                                                                                                       isNewCard: true))
                    Navigator.shared.present(vc, from: targetVC)
                } else {
                    component.logger.error("debugButton handle failed")
                }
            }
        }
        
        let debugButton: RightButtonComponent<C> = RightButtonFactory.create(name:"NEW—DEBUG",action: debugHandler, style: translateRightButtonStyle)
        return debugButton
    }
}
#endif
