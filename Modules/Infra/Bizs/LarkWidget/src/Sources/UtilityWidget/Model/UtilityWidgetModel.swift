//
//  UtilityWidgetModel.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/7.
//

import Foundation

public struct UtilityWidgetModel: Codable, Equatable {
    public var quickTools: [UtilityTool]
    public var navigationTools: [UtilityTool]
    public var workplaceTools: [UtilityTool]

    public init(quickTools: [UtilityTool],
                navigationTools: [UtilityTool],
                workplaceTools: [UtilityTool]) {
        self.quickTools = quickTools
        self.navigationTools = navigationTools
        self.workplaceTools = workplaceTools
    }

    public var isEmpty: Bool {
        return quickTools.isEmpty && navigationTools.isEmpty && workplaceTools.isEmpty
    }

    public var allAvailableTools: [UtilityTool] {
        return quickTools + navigationTools + workplaceTools
    }

    /// 方便通过 AppLink 查询 Tool（多语言变化后，configuration 中的 Tool 并不会变化，需要从这里查询最新的数据，展示到 Widget 上）
    public var toolDictionary: [String: UtilityTool] {
        return allAvailableTools.toDictionary(with: { $0.identifier })
    }

    /// 检查数据是否缺少埋点所需的 key
    public var lostTrackingKeys: Bool {
        guard quickTools.compactMap({ $0.key }).count == quickTools.count else { return false }
        guard navigationTools.compactMap({ $0.key }).count == quickTools.count else { return false }
        guard workplaceTools.compactMap({ $0.key }).count == quickTools.count else { return false }
        return true
    }
}

extension UtilityWidgetModel {

    public static var defaultData: UtilityWidgetModel {
        return UtilityWidgetModel(
            quickTools: [.search, .scan],
            navigationTools: [.workplace],
            workplaceTools: []
        )
    }
}

extension Array {

    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key: Element] {
        var dict = [Key: Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}
