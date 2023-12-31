//
//  BTFieldEditUtil.swift
//  SKBitable
//
//  Created by zoujie on 2022/5/27.
//  


import Foundation

final class BTFieldEditUtil {
    static func generateAutoNumberJSON(auotNumberRuleList: [BTAutoNumberRuleOption],
                                       commonData: BTCommonData) -> [[String: Any]] {
        var autoNumberJSON: [[String: Any]] = []

        auotNumberRuleList.forEach { model in
            var value = model.value

            if model.type == .createdTime,
               let ruleList = commonData.fieldConfigItem.commonAutoNumberRuleTypeList.first(where: { $0.isAdvancedRules })?.ruleFieldOptions,
               let dataModelList = ruleList.first(where: { $0.type == .createdTime })?.optionList {
                //转换日期格式 20220301 -> yyyymmdd
                value = dataModelList.first(where: { $0.text == value })?.format ?? ""
            }

            guard !value.isEmpty else { return }

            let autoNumber: [String: Any] = ["type": model.type.rawValue,
                                             "value": value]
            autoNumberJSON.append(autoNumber)
        }

        return autoNumberJSON
    }

    static func generateOptionJSON(options: [BTOptionModel]) -> [[String: Any]] {
        var optionsJSON: [[String: Any]] = []

        options.forEach { model in
            let option: [String: Any] = ["id": model.id,
                                         "name": model.name,
                                         "color": model.color]
            optionsJSON.append(option)
        }

        return optionsJSON
    }

    static func generateOptionIdsJSON(options: [BTOptionModel]) -> [String: Any] {
        var optionIds: [String] = []

        options.forEach { model in
            optionIds.append(model.id)
        }

        return ["optionIds": optionIds, "total": 1]
    }

    static func generateColorIdsJSON(options: [BTOptionModel]) -> [String: Any] {
        var colorIds: [Int] = []

        options.forEach { model in
            colorIds.append(model.color)
        }

        return ["colors": colorIds]
    }

    ///自动编号字段生成预览string
    static func generateAutoNumberPreString(auotNumberRuleList: [BTAutoNumberRuleOption]) -> String {
        var preViewText = ""
        for rule in auotNumberRuleList {
            let value = rule.value
            if rule.type == .systemNumber {
                let digit = Int(value) ?? 3
                let digitStr = String(repeating: "0", count: max(digit - 1, 0))
                preViewText += digitStr + "1"
            } else {
                preViewText += rule.value
            }
        }

        return preViewText
    }
}
