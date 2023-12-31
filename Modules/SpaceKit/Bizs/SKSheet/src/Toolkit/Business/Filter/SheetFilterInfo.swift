//
//  SheetFilterInfo.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//

import Foundation
import SKBrowser

enum SheetFilterType {
    case byValue, byColor, byCondition, byDefault
    init(by btnIdentifier: String) {
        switch btnIdentifier {
        case BarButtonIdentifier.cellFilterByValue.rawValue:
            self = .byValue
        case BarButtonIdentifier.cellFilterByColor.rawValue:
            self = .byColor
        case BarButtonIdentifier.cellFilterByCondition.rawValue:
            self = .byCondition
        default:
            self = .byDefault
        }
    }
}

class SheetFilterInfo {

    struct JSIdentifier {
        static let range = "colRange"
        static let none = "none"
        static let noneCondition = "noCondition"
        static let noneColor = "noColor"
        static let noneIdentitiers: Set<String> = [JSIdentifier.none, JSIdentifier.noneColor, JSIdentifier.noneCondition]
    }

    struct FilterValueItem {
        var index: Int = 0
        var value = ""
        var count = 0
        var selected = false
    }

    struct NormalListItem {
        var identifier = ""
        var title: String?
        var select = false
        var type: String?
        var colorValue: String?
        var textValue: String?
        var conditionValue: [String]?
        var colors: [String]?
    }

    struct ValueFilter {
        var total = 0
        var current = 2
        var hasNext = false
        var selectAll = false
        var valueList: [FilterValueItem]?
    }

    struct ColorFilter {
        var colorLists: [NormalListItem]?
    }

    struct ConditionFilter {
        var conditionLists: [NormalListItem]?
    }

    var identifier = ""
    var navigatorTitle = ""
    var colTitle = ""
    var colTotal = 0 //筛选列的总行数
    var colIndex = 0 //当前筛选列
    var sheetId = ""
    var filterType: SheetFilterType = .byDefault
    var valueFilter: ValueFilter?
    var colorFilter: ColorFilter?
    var conditionFilter: ConditionFilter?
    
    var filterId: String {
        return "\(sheetId)_\(colIndex)_\(identifier)"
    }

    init() { }

    init(filterType: SheetFilterType) {
        self.filterType = filterType
    }

    init(valueInfo: [String: Any]) {
        filterType = .byValue
        identifier = extractString(valueInfo, key: "id")
        navigatorTitle = extractString(valueInfo, key: "title")
        var newInfo = ValueFilter()
        newInfo.total = extractInt(valueInfo, key: "total")
        newInfo.current = extractInt(valueInfo, key: "current")
        newInfo.hasNext = extractBool(valueInfo, key: "hasNext")
        newInfo.selectAll = extractBool(valueInfo, key: "selectAll")
        if let listInfo = valueInfo["list"] as? [[String: Any]] {
            var lists = [FilterValueItem]()
            for item in listInfo {
                var valueItem = FilterValueItem()
                valueItem.count = extractInt(item, key: "count")
                valueItem.value = extractString(item, key: "value")
                valueItem.selected = extractBool(item, key: "select")
                lists.append(valueItem)
            }
            newInfo.valueList = lists
        }
        valueFilter = newInfo
    }

    init(colorInfo: [String: Any]) {
        filterType = .byColor
        identifier = extractString(colorInfo, key: "id")
        navigatorTitle = extractString(colorInfo, key: "title")
        var newColorFilter = ColorFilter()
        if let listInfos = colorInfo["list"] as? [[String: Any]] {
           newColorFilter.colorLists = listInfos.map { return extractListItem($0) }
        }
        colorFilter = newColorFilter
    }

    init(contiditonInfo: [String: Any]) {
        filterType = .byCondition
        identifier = extractString(contiditonInfo, key: "id")
        navigatorTitle = extractString(contiditonInfo, key: "title")
        var newConditionFilter = ConditionFilter()
        if let listInfos = contiditonInfo["list"] as? [[String: Any]] {
            newConditionFilter.conditionLists = listInfos.map { return extractListItem($0) }
        }
        conditionFilter = newConditionFilter
    }

    @inline(__always)
    private func extractListItem(_ dic: [String: Any]) -> NormalListItem {
        var item = NormalListItem()
        item.identifier = extractString(dic, key: "id")
        item.title = extractString(dic, key: "title")
        item.select = extractBool(dic, key: "select")
        item.type = extractString(dic, key: "type")
        item.colorValue = extractString(dic, key: "colorValue")
        item.textValue = extractString(dic, key: "textValue")
        item.conditionValue = dic["conditionValue"] as? [String]
        item.colors = dic["colors"] as? [String]
        return item
    }

    @inline(__always)
    private func extractInt(_ dic: [String: Any], key: String) -> Int {
        return (dic[key] as? Int) ?? 0
    }

     @inline(__always)
    private func extractBool(_ dic: [String: Any], key: String) -> Bool {
        return (dic[key] as? Bool) ?? false
    }

     @inline(__always)
    private func extractString(_ dic: [String: Any], key: String) -> String {
        return (dic[key] as? String) ?? ""
    }

}
