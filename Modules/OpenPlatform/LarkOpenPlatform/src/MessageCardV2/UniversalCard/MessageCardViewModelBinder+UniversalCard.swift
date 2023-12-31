//
//  MessageCardViewModelBinder+UniversalCard.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/10/24.
//

import Foundation
import RustPB
import ECOProbe
import LarkModel
import LarkContainer
import LarkMessageBase
import UniversalCardInterface
import LKCommonsLogging
import LarkLocalizations

fileprivate let ConvertLogger = Logger.log(UniversalCardData.self, category: "UniversalCardData")
extension MessageCardCommonViewModelBinder {

    static func universalCardData(
        fromVM vm: MessageCardViewModel<M, D, C>, config: MessageCardConfig, userResolver: UserResolver?
    ) -> (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)? {
        guard let data = UniversalCardData.transform(message: vm.message) else {
            ConvertLogger.error("UniversalCardData cover fail",additionalData: ["id": vm.message.id, "traceID": vm.trace.traceId])
            return nil
        }
        guard let preferWidth = Self.getPreferWidth(
            message: vm.message,
            context: vm.context,
            metaModelDependency: vm.metaModelDependency,
            config: config
        ) else {
            ConvertLogger.error("UniversalCardData get preferWidth fail",additionalData: ["id": vm.message.id, "traceID": vm.trace.traceId])
            return nil
        }

        guard let displayConfig = Self.displayConfig(fromVM: vm, config: config) else {
            ConvertLogger.error("UniversalCardData get displayConfig fail",additionalData: ["id": vm.message.id, "traceID": vm.trace.traceId])
            return nil
        }

        return (
            data: data,
            context: UniversalCardContext(
                key: vm.trace.traceId,
                trace: vm.trace,
                sourceData: data,
                sourceVC: vm.targetVC,
                dependency: MessageUniversalCardDependencyImpl(userResolver: userResolver, actionDependency: vm),
                renderBizType: RenderBusinessType.message.rawValue,
                bizContext: nil,
                actionContext: CardActionContext(messageID: vm.message.id, chatID: vm.getChat().id),
                host: UniversalCardHostType.imMessage.rawValue,
                deliveryType: UniversalCardDeliveryType.messageCard.rawValue
            ),
            config: UniversalCardConfig(
                width: preferWidth,
                displayConfig: displayConfig,
                translateConfig: Self.translateInfo(fromVM: vm),
                actionEnable: Self.actionEnable(from: vm),
                actionDisableMessage: BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast
            )
        )
    }

    private static func actionEnable(from vm: MessageCardViewModel<M, D, C>) -> Bool {
        let isForward = vm.content?.jsonAttachment?.isForward ?? false
        let actionEnable = vm.context.scene != .mergeForwardDetail
        return !isForward && actionEnable
    }

    private static func translateInfo(fromVM vm: MessageCardViewModel<M, D, C>) -> UniversalCardConfig.TranslateConfig {
        return UniversalCardConfig.TranslateConfig(
            renderType: Self.renderType(vm.message, scene: vm.context.scene),
            translateLanguage: vm.message.translateLanguage
        )
    }

    private static func renderType(_ message: Message, scene: ContextScene?) -> UniversalCardConfig.TranslateConfig.RenderType {
        guard let scene = scene, scene != .pin, message.translateContent != nil else {
           return .renderOriginal
       }
       switch message.displayRule {
       case .onlyTranslation:
           return .renderTranslation
       case .withOriginal:
           return .renderOriginalWithTranslation
       case .unknownRule, .noTranslation:
           return .renderOriginal
       @unknown default:
           return .renderOriginal
       }
    }

    private static func displayConfig(fromVM vm: MessageCardViewModel<M, D, C>, config: MessageCardConfig) -> UniversalCardConfig.DisplayConfig? {
        guard let preferWidth = Self.getPreferWidth(
            message: vm.message,
            context: vm.context,
            metaModelDependency: vm.metaModelDependency,
            config: config
        ) else {
            ConvertLogger.error("UniversalCardData displayConfig get preferWidth fail", additionalData: ["id": vm.message.id, "traceID": vm.trace.traceId])
            return nil
        }
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

        return UniversalCardConfig.DisplayConfig(
            preferWidth: preferWidth,
            isWideMode: shouldDisplayWideCard(
                vm.message,
                cellMaxWidth: vm.context.getCellMaxWidth(),
                contentPreferWidth: vm.metaModelDependency.getContentPreferMaxWidth(vm.message)
            ),
            showCardBGColor: true,
            showTranslateMargin: showTranslateMargin,
            showCardBorderRadius: showCardBorderRadius,
            inCardDetailPage: false
        )
    }

}

extension UniversalCardContent {
    static func transform(content: CardContent) -> UniversalCardContent? {
        guard let json = content.jsonBody, let attachment = content.jsonAttachment else {
            ConvertLogger.error("UniversalCardData transform content fail: json or attachmen is nil")
            return nil
        }
        return UniversalCardContent(
            card: json,
            attachment: Self.attachment(pb: attachment)
        )
    }

    static func attachment(pb: Basic_V1_CardContent.JsonAttachment) -> UniversalCardContent.Attachment {
        var characters: [String: Basic_V1_UniversalCardEntity.Character] = [:]
        pb.optionUsers.forEach { (key: String, value: Basic_V1_CardContent.JsonAttachment.OptionUser) in
            var character = Basic_V1_UniversalCardEntity.Character()
            character.id = value.userID
            character.avatarKey = value.avatarKey
            character.content = value.content
            character.type = .user
            characters[key] = character
        }
        pb.persons.forEach { (key: String, value: Basic_V1_CardContent.JsonAttachment.PersonInfo) in
            var character = Basic_V1_UniversalCardEntity.Character()
            character.id = value.personID
            character.avatarKey = value.avatarKey
            character.content = value.content
            character.type = value.type == .user ? .user : .chat
            characters[key] = character
        }
        return UniversalCardContent.Attachment(
            images: pb.images,
            atUsers: pb.atUsers,
            characters: characters,
            ignoreAtRemind: pb.isForward,
            previewImageKeyList: pb.images.keys.map({ $0 })
        )
    }
}

extension UniversalCardData {
    static func transform(message: Message) -> UniversalCardData? {
        guard let content = message.content as? CardContent, let attachment = content.jsonAttachment else {
            ConvertLogger.error("UniversalCardData transform content fail: content or attachment is nil", additionalData: ["id": message.id])
            return nil
        }

        guard let originContent = UniversalCardContent.transform(content: content) else {
            ConvertLogger.error("UniversalCardData transform content fail", additionalData: ["id": message.id])
            return nil
        }

        var translateContent: UniversalCardContent?
        if let content = message.translateContent as? CardContent{
            translateContent = UniversalCardContent.transform(content: content)
        }

        var actionStatus = ActionStatus()
        actionStatus.componentStatusByName = attachment.componentStatusByName
        var componentStatusByActionID: [String: String] = [:]
        content.actions.forEach { (key: String, action: CardContent.CardAction) in
            let tag = action.parameters.parameters["initial_type"] ?? ""
            let initOption = action.parameters.parameters["initial_option"]
            let initialValue = action.parameters.parameters["initial_value"]
            let selectedValues = action.parameters.parameters["selected_values"]
            var status: [String: String] = [:]
            if let initOption = initOption {
                status = ["tag": tag, "value": initOption]
            } else if let initialValue = initialValue {
                status = ["tag": tag, "value": initialValue]
            } else if let selectedValues = selectedValues {
                status = ["tag": tag, "value": selectedValues]
            }
            if let jsonData = try? JSONEncoder().encode(status),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                componentStatusByActionID[key] = jsonString
            }
        }
        actionStatus.componentStatusByActionID = componentStatusByActionID
        var localExtra: [Int32: String] = [:]
        message.localData?.data.forEach({ (key: Int32, value: Basic_V1_MessageLocalData) in
            localExtra[key] = value.jsonDataString
        })
        return UniversalCardData(
            cardID: message.id,
            version: String(message.contentVersion),
            bizID: message.id,
            bizType: -1,
            cardContent: originContent,
            translateContent: translateContent,
            actionStatus: actionStatus,
            localExtra: localExtra,
            appInfo: content.appInfo
        )
    }
}

public enum UniversalCardDeliveryType: String {
    case urlPreview = "url_preview"
    //消息卡片使用空串表示
    case messageCard = ""

    case unknown = "unknown"
}

//宿主场景：消息场景/工作台
public enum UniversalCardHostType: String {
    case imMessage = "im_message"
}
