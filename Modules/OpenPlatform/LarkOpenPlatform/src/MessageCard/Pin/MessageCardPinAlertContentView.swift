//
//  MessageCardPinAlertViewModel.swift
//  LarkOpenPlatform
//
//  Created by MJXin on 2022/6/14.
//

import Foundation
import UIKit
import AsyncComponent
import LarkModel
import LarkMessageCore
import LarkChat
import LKCommonsLogging
import NewLarkDynamic
import EEFlexiable
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignDialog
import LarkMessageCard
import LarkOPInterface
import UniversalCard
import LarkContainer
import UniversalCardInterface

// 设计图提供的最大宽高
private let MaxContentHeight: CGFloat = 240
private let CornerRadius: CGFloat = 5
private let BorderWidth: CGFloat = 1
private let GradientHeight: CGFloat = 30

final class MessageCardPinAlertContentView: UIView {
    static let logger = Logger.log(MessageCardPinAlertContentView.self, category: "MessageCardPrewController")
    private var previewComponent: MessageCardPinComponent<MessageCardPreviewContext>?
    private var cardContent: CardContent?
    private var cardContentView: UIView?
    private let cardContainer: UIView = {
        return UIView()
    }()
    private let gradient: MessageCardPinClipView = {
        return MessageCardPinClipView(frame: CGRect.zero)
    }()
    public var renderer: ASComponentRenderer?
    private var msgCardContainer: MessageCardContainer?
    private var cardLifeCyle :CardPreviewRenderLifeCycle?
    private let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        addSubview(cardContainer)
        cardContainer.addSubview(gradient)
        setupContainer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.layoutContainer()
        super.layoutSubviews()
    }
    
    private func setupContainer() {
        cardContainer.layer.masksToBounds = true
        cardContainer.layer.cornerRadius = CornerRadius
        cardContainer.layer.borderWidth = BorderWidth
        cardContainer.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        cardContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.lessThanOrEqualTo(MaxContentHeight)
        }
        gradient.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(GradientHeight)
        }
    }
    
    private func layoutContainer() {
        self.cardContentView?.removeFromSuperview()
        guard let cardContent = cardContent else {
            Self.logger.error("CardContent is nil")
            return
        }
        let (cardContentView, size) = createPinContentView(cardContent: cardContent)
        cardContainer.addSubview(cardContentView)
        cardContainer.bringSubviewToFront(gradient)
        cardContentView.snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
            make.edges.equalToSuperview()
        }
        self.cardContentView = cardContentView
    }
    
    private func createPinContentView(cardContent: CardContent) -> (UIView, CGSize) {
        if MessageCardRenderControl.lynxCardRenderEnable(content: cardContent) {
            var lynxView = UIView()
            cardLifeCyle = CardPreviewRenderLifeCycle(cardContent: cardContent,
                                                      cardScene: .sendMessageCardPreview,
                                                      renderBusinessType: .message)
            if MessageCardMigrateControl.useUniversalCard, let content = UniversalCardContent.transform(content: cardContent)  {
                let data = UniversalCardData(
                    cardID: "",
                    version: "",
                    bizID: "-1",
                    bizType: -1,
                    cardContent: content,
                    translateContent: nil,
                    actionStatus: UniversalCardData.ActionStatus(),
                    localExtra: [:],
                    appInfo: cardContent.appInfo
                )
                let source = (
                    data: data,
                    context: UniversalCardContext(
                        key: UUID().uuidString,
                        trace: OPTraceService.default().generateTrace(),
                        sourceData: data,
                        sourceVC: nil,
                        dependency: nil,
                        renderBizType: RenderBusinessType.message.rawValue,
                        bizContext: nil
                    ),
                    config: UniversalCardConfig(
                        width: bounds.width,
                        actionEnable: true,
                        actionDisableMessage: BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast
                    )
                )
                let card = UniversalCard.create(resolver: userResolver)
                cardLifeCyle?.didFinishSetup()
                card.render(
                    layout: UniversalCardLayoutConfig(preferWidth: bounds.width, maxHeight: nil),
                    source: source,
                    lifeCycle: cardLifeCyle
                )
                lynxView = card.getView()
            } else {
                let content: MessageCardContainer.CardContent = (origin: cardContent, translate: nil)
                let context = MessageCardContainer.Context(
                    trace: OPTraceService.default().generateTrace(),
                    dependency: nil,
                    bizContext: ["pinPreviewContent": cardContent]
                )
                let config = MessageCardContainer.Config(
                    perferWidth: bounds.width,
                    isWideMode: false,
                    actionEnable: true,
                    isForward: false,
                    i18nText: I18nText()
                )
                let localeLanguage = BundleI18n.currentLanguage.rawValue.getLocaleLanguageForMsgCard()
                let translateInfo = TranslateInfo(localeLanguage: localeLanguage,
                                                  translateLanguage: "",
                                                  renderType: RenderType.renderOriginal)
                msgCardContainer = MessageCardContainer.create(
                    cardID: "preview" + UUID().uuidString,
                    version: "",
                    content: content,
                    localStatus: "",
                    config: config,
                    context: context,
                    lifeCycleClient: cardLifeCyle,
                    translateInfo: translateInfo
                )
                cardLifeCyle?.didFinishSetup()
                msgCardContainer?.render()
                lynxView = msgCardContainer?.view ?? UIView()
            }
            lynxView.isUserInteractionEnabled = false
            return (lynxView, lynxView.bounds.size)
        } else {
            let dynamicStyle = ASComponentStyle()
            dynamicStyle.flexShrink = 0
            dynamicStyle.overflow = .scroll
            dynamicStyle.width = CSSValue(cgfloat: bounds.width)
            let previewComponent = MessageCardPinComponent<MessageCardPreviewContext>(
                props: MessageCardPinComponent.Props(card: cardContent),
                style: dynamicStyle,
                context: MessageCardPreviewContext(cardContent: cardContent)
            )

            let renderer = ASComponentRenderer(previewComponent)
            let cardContentView = previewComponent.create(bounds)
            cardContentView.isUserInteractionEnabled = false
            renderer.bind(to: cardContentView)
            renderer.render(cardContentView)
            return (cardContentView, renderer.size())
        }

    }
}

extension MessageCardPinAlertContentView: MessageCardPinAlertContentViewProtocol {
    public func setPinContent(content: CardContent) {
        self.cardContent = content
    }
}
