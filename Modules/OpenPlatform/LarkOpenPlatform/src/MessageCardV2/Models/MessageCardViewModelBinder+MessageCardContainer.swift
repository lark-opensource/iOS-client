//
//  MessageCardViewModelBinder+MessageCardContainer.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/12.
//

import Foundation
import LarkModel
import EENavigator
import EEFlexiable
import LarkSetting
import AsyncComponent
import LarkMessageBase
import LarkMessageCard
import RustPB
import LarkFeatureGating
import UniversalCardInterface

//该context用于传递给外部业务方的交互上下文
public struct CardActionContext: Encodable, CardActionContextProtocol {
    let messageID: String?
    let chatID: String?

    public init(messageID: String?, chatID: String?) {
        self.messageID = messageID
        self.chatID = chatID
    }

    public func toDict() -> [String: Any] {
        var dict: [String : Any] = [:]
        if let messageID = messageID {
            dict["message_id"] = messageID
        }
        if let chatID = chatID {
            dict["chat_id"] = chatID
        }
        return dict
    }

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case chatID = "chat_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageID, forKey: .messageID)
        try container.encode(chatID, forKey: .chatID)
    }
}


extension MessageCardCommonViewModelBinder {
    
    static func cardContainer(fromVM vm: MessageCardViewModel<M, D, C>, config: MessageCardConfig) -> MessageCardContainer? {
        guard let content = Self.cardContent(from: vm),
              let context = Self.cardContext(fromVM: vm) else {
            assertionFailure("create cardContainer fail with wrong vm")
            return nil
        }
        let translateInfo = getTranslateInfo(vm.message, scene: vm.context.scene)
        let localStorageKey = Int32(Basic_V1_MessageLocalDataInfo.BusinessKey.openPlatformMessageCard.rawValue)
        let localStatus =  vm.message.localData?.data[localStorageKey]?.jsonDataString ?? ""
        return MessageCardContainer.create(
            cardID: vm.message.id,
            version: String(vm.message.contentVersion),
            content: content,
            localStatus: localStatus,
            config: Self.cardConfig(fromVM: vm, config: config),
            context: context,
            lifeCycleClient: vm,
            translateInfo: translateInfo
        )
    }
    
    static func cardContext(fromVM vm: MessageCardViewModel<M, D, C>) -> MessageCardContainer.Context? {
        guard let dependency = Self.cardDependency(from: vm) else {
            assertionFailure("create cardContext fail with wrong vm")
            return nil
        }
        return MessageCardContainer.Context(
            trace: vm.trace,
            dependency: dependency,
            bizContext: ["messageID": vm.message.id, "message": vm.message, "chat": vm.getChat()],
            actionContext: CardActionContext(messageID: vm.message.id, chatID: vm.getChat().id),
            host: UniversalCardHostType.imMessage.rawValue,
            deliveryType: UniversalCardDeliveryType.messageCard.rawValue
        )
    }

    //通过vm创建container.context所有数据
    static func cardContextData(fromVM vm: MessageCardViewModel<M, D, C>) -> MessageCardContainer.ContextData? {
        guard let dependency = Self.cardDependency(from: vm) else {
            assertionFailure("create cardContextData fail with wrong vm")
            return nil
        }
        let translateInfo = Self.getTranslateInfo(vm.message, scene: vm.context.scene)
        return MessageCardContainer.ContextData(
            trace: vm.trace,
            bizContext: ["messageID": vm.message.id, "message": vm.message, "chat": vm.getChat(), "translateInfo": translateInfo, "content": vm.content as Any, "translateContent": vm.translateContent as Any],
            dependency: dependency,
            actionContext: CardActionContext(messageID: vm.message.id, chatID: vm.getChat().id),
            host: UniversalCardHostType.imMessage.rawValue,
            deliveryType: UniversalCardDeliveryType.messageCard.rawValue
        )
    }

    //通过vm创建container所有数据
    static func cardContainerData(fromVM vm: MessageCardViewModel<M, D, C>, config: MessageCardConfig) -> MessageCardContainer.ContainerData? {
        guard let content = Self.cardContent(from: vm),
              let contextData = Self.cardContextData(fromVM: vm) else {
            assertionFailure("create cardContainerData fail with wrong vm")
            return nil
        }
        let config = Self.cardConfig(fromVM: vm, config: config)
        let translateInfo = Self.getTranslateInfo(vm.message, scene: vm.context.scene)
        let localStorageKey = Int32(Basic_V1_MessageLocalDataInfo.BusinessKey.openPlatformMessageCard.rawValue)
        let localStatus =  vm.message.localData?.data[localStorageKey]?.jsonDataString ?? ""
        return MessageCardContainer.ContainerData(
            cardID: vm.message.id,
            version: String(vm.message.contentVersion),
            content: content,
            localStatus: localStatus,
            contextData: contextData,
            config: config,
            translateInfo: translateInfo
        )
    }
    
    static func cardConfig(fromVM vm: MessageCardViewModel<M, D, C>, config: MessageCardConfig) -> MessageCardContainer.Config {
        let perferWidth = Self.getPreferWidth(
            message: vm.message,
            context: vm.context,
            metaModelDependency: vm.metaModelDependency,
            config: config
        )
        let isWideMode = shouldDisplayWideCard(
            vm.message,
            cellMaxWidth: vm.context.getCellMaxWidth(),
            contentPreferWidth: vm.metaModelDependency.getContentPreferMaxWidth(vm.message)
        )
        let isForward = vm.content?.jsonAttachment?.isForward ?? false
        let actionEnable = vm.context.scene != .mergeForwardDetail
        
        // 话题回复场景下不需要展示内边距,因为他自己加了
        var showTranslateMargin = true
        // 话题回复场景需要自己实现边框, 因为卡片在翻译和非翻译状态下边框逻辑不一致
        var showCardBorderRadius = false
        if vm.context.scene == .newChat || vm.context.scene == .mergeForwardDetail,
           vm.message.showInThreadModeStyle && !vm.message.displayInThreadMode {
            // 话题回复场景下不需要展示内边距,因为他自己加了
            showTranslateMargin = false
            // 话题回复场景需要自己实现边框, 因为卡片在翻译和非翻译状态下边框逻辑不一致
            showCardBorderRadius = true
        } else if vm.context.scene == .replyInThread
               || vm.context.scene == .threadDetail
               || vm.context.scene == .threadChat
               || vm.context.scene == .messageDetail
               || vm.context.scene == .replyInThread
               || vm.context.scene == .threadPostForwardDetail
               || vm.context.scene == .pin {
            // 这些场景不需要边距, 因为这些都不是气泡
            showTranslateMargin = false
            // 需要自己实现边框,这些场景边框存在翻译和非翻译态差异
            showCardBorderRadius = true
        }
        
        return MessageCardContainer.Config(
            perferWidth: perferWidth ?? .zero,
            maxHeight: vm.preferMaxHeight,
            isWideMode: isWideMode,
            actionEnable: actionEnable,
            showCardBGColor: true,
            showCardBorderRadius: showCardBorderRadius,
            showTranslateMargin: showTranslateMargin,
            isForward: isForward,
            i18nText: I18nText(
                translationText: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_Translation,
                imageTagText: "[" + BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_Image + "]",
                cancelText: BundleI18n.LarkOpenPlatform.Lark_Legacy_Cancel,
                textLengthError: BundleI18n.LarkOpenPlatform.__OpenPlatform_MessageCard_TextLengthErr,
                inputPlaceholder: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_PlsEnterPlaceholder,
                requiredErrorText: BundleI18n.LarkOpenPlatform.OpenPlatform_MessageCard_RequiredItemLeftEmptyErr,
                chartLoadError: BundleI18n.LarkOpenPlatform.Lark_InteractiveChart_ChartLoadingErr,
                chartTagText: BundleI18n.LarkOpenPlatform.OpenPlatform_InteractiveChart_ChartComptLabel,
                tableTagText: BundleI18n.LarkOpenPlatform.OpenPlatform_TableComponentInCard_TableInSummary,
                tableEmptyText: BundleI18n.LarkOpenPlatform.Lark_TableComponentInCard_NoData,
                cardFallbackText: BundleI18n.LarkOpenPlatform.OpenPlatform_CardFallback_PlaceholderText()
            )
        )
    }
    
    static func cardContent(from vm: MessageCardViewModel<M, D, C>) -> MessageCardContainer.CardContent? {
        guard let content = vm.content else {
            assertionFailure("Create Card Content with wrong Content: \(vm.content)")
            return nil
        }
        return (origin: content, translate: vm.translateContent)
    }
    
    static func cardDependency(from vm: MessageCardViewModel<M, D, C>) -> MessageCardContainerDependency? {
        guard let context = vm.context as? PageContext else {
            assertionFailure("Create Card Dependency with wrong context: \(vm.context.self)")
            return nil
        }
        return MessageCardContaienrDependencyImpl(
            message: vm.metaModel.message,
            trace: vm.trace,
            pageContext: context,
            chat: vm.metaModel.getChat,
            actionEventHandler: vm
        )
    }
    
    public static func getTranslateInfo(_ message: Message, scene: ContextScene) -> LarkMessageCard.TranslateInfo {
        let localeLanguage = BundleI18n.currentLanguage.rawValue.getLocaleLanguageForMsgCard()
        return TranslateInfo(localeLanguage: localeLanguage,
                             translateLanguage: message.translateLanguage,
                             renderType: getRenderType(message,scene: scene))
    }
}

func getRenderType(_ message: Message, scene: ContextScene?) -> LarkMessageCard.RenderType {
   guard let scene = scene, scene != .pin, let translateContent = message.translateContent else {
       return .renderOriginal
   }

   switch message.displayRule {
   case .onlyTranslation:
       return .renderTranslation
   case .withOriginal:
       return .renderOriginalWithTranslation
   @unknown default:
       return .renderOriginal
   }
}

