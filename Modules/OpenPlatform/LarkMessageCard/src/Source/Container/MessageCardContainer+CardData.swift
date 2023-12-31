//
//  MessageCardContainer+CardData.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/11.
//

import Foundation
import RustPB
import LarkSetting
import LarkFeatureGating

extension MessageCardContainer {
    private static let cardFGKeys = [
       "messagecard.lynx.detailsummary.enable",
       "messagecard.input.enable",
       "messagecard.form.enable",
       "open_platform.message_card.local_cache",
       "lynxcard.udicon.enable",
       "open_platform.message_card.component_person_list",
       "messagecard.chart.enable",
       "lynxcard.businessmonitor.enable",
       "open_platform.message_card.component_text_tag",
       "universal.person.enable",
       "universalcard.interactive_container.enable",
       "universalcard.multi_select.enable",
       "universalcard.client_message.enable",
       "universalcard.table.enable",
       "universalcard.markdown_v1.enable",
       "universalcard.collapsible_panel.enable",
       "universalcard.select_img.enable",
       "openplatform.universalcard.table_date",
       "universalcard.checker.enable"
    ]
    
    static func cardContext(
        fromContext context: Context,
        config: Config
    ) -> CardData.CardContext {
        return CardData.CardContext(
            key: context.key,
            traceID: context.renderTrace.traceId,
            isWideMode: config.isWideMode,
            actionEnable: config.actionEnable,
            isForward: config.isForward,
            bizContext: context.bizContext,
            businessType: "message",
            actionContext: context.actionContext,
            host: context.host ?? "",
            deliveryType: context.deliveryType ?? ""
        )
    }
    
    static func cardConfig(
        fromConfig config: Config
    ) -> CardData.CardConfig {
        return CardData.CardConfig(
            showTranslateMargin: config.showTranslateMargin,
            showCardBGColor: config.showCardBGColor,
            showCardBorderRadius: config.showCardBorderRadius,
            preferWidth: config.perferWidth
        )
    }
    
    static func data(fromCardContent content: CardContent) -> (
        original: CardData.Data, translation: CardData.Data?
    )? {
        // 处理原始数据
        guard let originalJSON = content.origin.jsonBody,
              let originalAttachment = content.origin.jsonAttachment  else {
            assertionFailure("MessageCardContainer setup with wrong data, jsonBody or jsonAttachment is nil")
            return nil
        }
        let originalActions = content.origin.actions
        let originalData = CardData.Data(
            card: originalJSON,
            attachment: parseAttachment(attachment: originalAttachment),
            actionValues:  parseActionSelectValue(
                actions: originalActions,
                attachment: originalAttachment)
        )
        
        // 处理翻译数据
        var translationData: CardData.Data? = nil
        if let translationJSON = content.translate?.jsonBody,
           let translationAttachment = content.translate?.jsonAttachment,
           let translationActions = content.translate?.actions {
            translationData = CardData.Data(
                card: translationJSON,
                attachment: parseAttachment(attachment: translationAttachment),
                actionValues: parseActionSelectValue(actions: translationActions, attachment: translationAttachment)
            )
        }
        return (
            original: originalData,
            translation: translationData
        )
    }
    
    
    static func getSettings(translateInfo: TranslateInfo) -> [String: Any] {
        let fallbackStyleConfig = getFallbackStyleConfig()
        let timeFormatSetting = getTimeFormatSetting(translateInfo: translateInfo)
        let settings = fallbackStyleConfig.merging(timeFormatSetting) { (first, _) -> Any in return first }
        return settings
    }
    
    static func getFeatureGatings() -> [String: Bool] {
        var fgs: [String: Bool] = [:]
        for key in cardFGKeys {
            fgs[key] =  FeatureGatingManager.shared.featureGatingValue(
                with: FeatureGatingManager.Key(stringLiteral: key)
            )
        }
        return fgs
    }

    private static func parseActionSelectValue(
        actions: [String: RustPB.Basic_V1_CardAction],
        attachment: Basic_V1_CardContent.JsonAttachment
    ) -> CardData.Data.ActionValues {
        guard !actions.isEmpty else {
            return [:]
        }
        var result: [String: String] = [:]
        for action in actions {
            let initOption = action.value.parameters.parameters["initial_option"]
            let initialValue = action.value.parameters.parameters["initial_value"]
            let selectedValues = action.value.parameters.parameters["selected_values"]
            if let initOption = initOption {
                result[action.key] = initOption
            } else if let initialValue = initialValue {
                result[action.key] = initialValue
            } else if let selectedValues = selectedValues {
                result[action.key] = selectedValues
            }
        }
        return result
    }
    
    private static func parseAttachment(
        attachment:Basic_V1_CardContent.JsonAttachment
    ) -> CardData.Data.Attachment {
        let imageDict = attachment.images.mapValues{ image in
            return CardData.Data.ImageProperty(
                originWidth: image.originWidth, originHeight: image.originHeight
            )
        }
        let atDict = attachment.atUsers.mapValues { at in
            return CardData.Data.AtProperty(
                userID: at.userID,
                content: at.content,
                isOuter: at.isOuter,
                isAnonymous: at.isAnonymous
            )
        }
        let optionUsers = attachment.optionUsers.mapValues { optionUser in
            return CardData.Data.OptionUser(
                userID: optionUser.userID,
                avatarKey: optionUser.avatarKey,
                content: optionUser.content
            )
        }
        let persons = attachment.persons.mapValues { person in
            return CardData.Data.Person(
                personID: person.personID,
                content: person.content,
                avatarKey: person.avatarKey,
                type: person.type.rawValue
            )
        }
        return CardData.Data.Attachment(
            images: imageDict,
            atUsers: atDict,
            optionUsers: optionUsers,
            componentStatusByName: attachment.componentStatusByName,
            persons: persons
        )
    }
    
    static private func getTimeFormatSetting(translateInfo: TranslateInfo) -> [String: Any] {
        @Setting(key: UserSettingKey.make(userKeyLiteral: "messagecard_time_format_i18n_config"))
        var timeSettings: MessagecardTimeFormatI18nConfig?
        var localeLanguageFormat = timeSettings?.localeLanguageFormatPc[translateInfo.localeLanguage] ?? [:]
        var translateFormat = timeSettings?.translateFormatPc[translateInfo.translateLanguage] ?? [:]
        return ["timeFormatSetting":["localeLanguageFormat": localeLanguageFormat, "translateLanguageFormat": translateFormat]]
    }
    
    static private func getFallbackStyleConfig() -> [String: Any] {
        @RawSetting(key: UserSettingKey.make(userKeyLiteral: "open_card_fallback_style_config_mobile"))
        var fallbackStyleConfig: [String: Any]?
        return ["fallbackStyleConfig" : fallbackStyleConfig]
    }
    
    struct MessagecardTimeFormatI18nConfig: Codable {
        var localeLanguageFormatPc: [String:[String:String]]
        var localeLanguageFormatMobile: [String:[String:String]]
        var translateFormatPc: [String:[String:String]]
        var translateFormatMobile: [String:[String:String]]
    }
}
