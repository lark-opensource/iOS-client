//
//  ContainerSceneModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/9.
//

import Foundation
import SKInfra
import HandyJSON
import SKFoundation

enum ViewType: Int, SKFastDecodableEnum, HandyJSONEnum {
    case grid = 1
    case kanban = 2
    case form = 3
    case gallery = 4
    case gantt = 5
    case hierarchy = 6
    case calendar = 7
    case widgetView = 100
    
    // 是否应当显示 ToolBar
    var shouldToolBar: Bool {
        let _shouldToolBar = (self == .kanban)
        || (self == .calendar)
        || (self == .gallery)
        || (self == .gantt)

        if UserScopeNoChangeFG.LYL.disableAllViewAnimation {
            return _shouldToolBar
        }

        return _shouldToolBar
        || (self == .grid)
        || (self == .hierarchy)
    }
    
    // Toolbar 可以被显示的情况下，是否可以切换隐藏和显示
    var canSwitchToolBar: Bool {
        return shouldToolBar && self != .kanban
    }
}

extension ViewType: CustomStringConvertible {
    public var description: String {
        "ViewType(\(rawValue))"
    }
}

enum BlockType: String, SKFastDecodableEnum {
    case dashboard = "DASHBOARD"
    case table = "BITABLE_TABLE"
    case linkedDocx = "LINKED_DOCX"
}

extension BlockType: CustomStringConvertible {
    public var description: String {
        "BlockType(\(rawValue))"
    }
}

enum NativeViewType: String, SKFastDecodableEnum {
    case card
}

struct ContainerSceneModel: SKFastDecodable, Equatable {
    var blockType: BlockType?
    var viewType: ViewType?
    var nativeViewType: NativeViewType?
    var embeddedInSheet: Bool?
    var dashboardFullScreen: Bool?
    var showAiConfigForm: Bool?
    
    static func deserialized(with dictionary: [String : Any]) -> ContainerSceneModel {
        var model = ContainerSceneModel()
        model.blockType <~ (dictionary, "blockType")
        model.viewType <~ (dictionary, "viewType")
        model.nativeViewType <~ (dictionary, "nativeViewType")
        model.embeddedInSheet <~ (dictionary, "embeddedInSheet")
        model.dashboardFullScreen <~ (dictionary, "dashboardFullScreen")
        model.showAiConfigForm <~ (dictionary, "showAIConfigForm")
        return model
    }
}

extension ContainerSceneModel: CustomStringConvertible {
    public var description: String {
        "ContainerSceneModel:{blockType:\(blockType?.description ?? "nil"),viewType:\(viewType?.description ?? "nil"),embeddedInSheet:\(embeddedInSheet?.description ?? "nil"),dashboardFullScreen:\(dashboardFullScreen?.description ?? "nil")}"
    }
}
