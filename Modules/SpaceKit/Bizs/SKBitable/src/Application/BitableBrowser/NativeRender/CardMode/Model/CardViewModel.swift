//
//  CardViewModel.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/31.
//

import SKFoundation
import SKInfra
import RxDataSources

struct CardPageModel: SKFastDecodable, NativeRenderBaseModel, Equatable {
    var viewId: String = ""
    var setting: CardSettingModel?
    var empty: EmptyModel?
    var renderForest: RenderForest?
    var groupDataMap: [String: GroupModel] = [:]
    var recordDataMap: [String: CardRecordModel] = [:]
    var footer: SimpleItem?
    var updateStrategy: CardPageUpdateStrategyModel?
    var callback: String = ""
    
    static func == (lhs: CardPageModel, rhs: CardPageModel) -> Bool {
        lhs.viewId == rhs.viewId &&
        lhs.setting == rhs.setting &&
        lhs.empty == rhs.empty &&
        lhs.renderForest == rhs.renderForest &&
        lhs.groupDataMap == rhs.groupDataMap &&
        lhs.recordDataMap == rhs.recordDataMap &&
        lhs.footer == rhs.footer &&
        lhs.updateStrategy == rhs.updateStrategy
    }
    
    static func deserialized(with dictionary: [String : Any]) -> CardPageModel {
        var model = CardPageModel()
        model.viewId <~ (dictionary, "viewId")
        model.empty <~ (dictionary, "empty")
        model.setting <~ (dictionary, "setting")
        model.callback <~ (dictionary, "callback")
        model.renderForest <~ (dictionary, "renderForest")
        model.groupDataMap <~ (dictionary, "groupDataMap")
        model.recordDataMap <~ (dictionary, "recordDataMap")
        model.footer <~ (dictionary, "footer")
        model.updateStrategy <~ (dictionary, "updateStrategy")
        return model
    }
}

enum CardPageUpdateStrategy: String, SKFastDecodableEnum {
    case rebuild // 数据发生变化，需要全量刷新
    case pull // native 主动拉取的数据
    case push // 前端推送的数据
    case scroll // 滚动到指定位置
}

struct CardPageUpdateStrategyModel: SKFastDecodable, Equatable {
    var strategy: CardPageUpdateStrategy = .rebuild
    var scrollToId: String?
    var pageSize: Int = 100
    var preIndex: Int = 20
    var bridgeStart: CGFloat = 0
    var processDuration: CGFloat = 0
    var switchView: Bool = false
    
    static func deserialized(with dictionary: [String : Any]) -> CardPageUpdateStrategyModel {
        var model = CardPageUpdateStrategyModel()
        model.strategy <~ (dictionary, "strategy")
        model.scrollToId <~ (dictionary, "scrollToId")
        model.pageSize <~ (dictionary, "pageSize")
        model.preIndex <~ (dictionary, "preIndex")
        model.bridgeStart <~ (dictionary, "bridgeStart")
        model.processDuration <~ (dictionary, "processDuration")
        model.switchView <~ (dictionary, "switchView")
        return model
    }
}
struct RenderItem: SKFastDecodable, Hashable, Encodable, Equatable {
    var type: RenderItemType = .record
    var id: String = ""
    
    static func deserialized(with dictionary: [String : Any]) -> RenderItem {
        var model = RenderItem()
        model.type <~ (dictionary, "type")
        model.id <~ (dictionary, "id")
        return model
    }
}

extension RenderItem: IdentifiableType {
    typealias Identity = String
    var identity: String { id }
}

struct RenderItemContainer: AnimatableSectionModelType {
    typealias Item = RenderItem
    var identity: String { identifier }

    let identifier: String
    private(set) var items: [Item]

    init(identifier: String,
         items: [RenderItem]) {
        self.identifier = identifier
        self.items = items
    }

    init(original: RenderItemContainer,
         items: [RenderItem]) {
        self = original
        self.items = items
    }
}

enum RenderItemType: String, SKFastDecodableEnum, Encodable, Equatable {
    case groupHeader
    case record
    
    var reuseIdentifier: String {
        switch self {
        case .groupHeader:
            return BTCardGroupHeaderCell.reuseIdentifier
        case .record:
            return BTCardViewCell.reuseIdentifier
        }
    }
}

// 分组的场景，1个大分组对应1颗IRenderTree
// 不份组场景，只有1颗IRenderTree
struct RenderForest: SKFastDecodable, Equatable {
    var renderTrees: [RenderTree] = []
    
    static func deserialized(with dictionary: [String : Any]) -> RenderForest {
        var model = RenderForest()
        model.renderTrees <~ (dictionary, "renderTrees")
        return model
    }
}

// groupTree中current是1个分组RenderItem，recordLeafs是1组记录RenderItem
struct RenderTree: SKFastDecodable, Equatable {
    var type: RenderTreeType = .recordLeafs
    var current: [RenderItem] = []
    var children: [RenderTree] = []
    
    static func deserialized(with dictionary: [String : Any]) -> RenderTree {
        var model = RenderTree()
        model.type <~ (dictionary, "type")
        model.current <~ (dictionary, "current")
        model.children <~ (dictionary, "children")
        return model
    }
}

enum RenderTreeType: String, SKFastDecodableEnum, Equatable {
    case groupTree
    case recordLeafs
}

struct CardSettingModel: SKFastDecodable, Equatable {
    var columnCount: Int = 0
    var fieldCount: Int = 0
    var showCover: Bool = false
    var showSubTitle: Bool = false
    
    static func deserialized(with dictionary: [String : Any]) -> CardSettingModel {
        var model = CardSettingModel()
        model.columnCount <~ (dictionary, "columnCount")
        model.fieldCount <~ (dictionary, "fieldCount")
        model.showCover <~ (dictionary, "showCover")
        model.showSubTitle <~ (dictionary, "showSubTitle")
        return model
    }
}

struct GroupModel: SKFastDecodable, Equatable {
    var id: String = ""
    var name: String = ""
    var color: String = ""
    var level: Int = 1
    var children: [String] = []
    var lastLevelGroup: Bool = false
    var isCollapsed: Bool = false // 是否折叠
    
    static func deserialized(with dictionary: [String : Any]) -> GroupModel {
        var model = GroupModel()
        model.id <~ (dictionary, "id")
        model.name <~ (dictionary, "name")
        model.color <~ (dictionary, "color")
        model.level <~ (dictionary, "level")
        model.children <~ (dictionary, "children")
        model.lastLevelGroup <~ (dictionary, "lastLevelGroup")
        return model
    }
}

struct CardRecordCoverModel: SKFastDecodable, Equatable {
    var index: Int?  // 占位图颜色标记
    var cover: BTAttachmentModel?
    var clickAction: Any?
    
    static func == (lhs: CardRecordCoverModel, rhs: CardRecordCoverModel) -> Bool {
        lhs.index == rhs.index &&
        lhs.cover == rhs.cover
    }
    
    static func deserialized(with dictionary: [String : Any]) -> CardRecordCoverModel {
        var model = CardRecordCoverModel()
        model.index <~ (dictionary, "index")
        model.cover <~ (dictionary, "cover")
        model.clickAction <~ (dictionary, "clickAction")
        return model
    }
}

struct CardRecordModel: SKFastDecodable, Equatable {
    var cardCover: CardRecordCoverModel?
    var clickAction: Any?
    var comment: SimpleItem?
    var highlightColor: String?
    var longPressMenu: [SimpleItem] = [] // 长按按钮，native调起
    var title: BTCardFieldCellModel?
    var subTitle: BTCardFieldCellModel?
    var cardRecordCells: [BTCardFieldCellModel] = []
    
    static func == (lhs: CardRecordModel, rhs: CardRecordModel) -> Bool {
        lhs.cardCover == rhs.cardCover &&
        lhs.comment == rhs.comment &&
        lhs.highlightColor == rhs.highlightColor &&
        lhs.longPressMenu == rhs.longPressMenu &&
        lhs.title == rhs.title &&
        lhs.subTitle == rhs.subTitle &&
        lhs.cardRecordCells == rhs.cardRecordCells
    }
    
    static func deserialized(with dictionary: [String : Any]) -> CardRecordModel {
        var model = CardRecordModel()
        model.cardCover <~ (dictionary, "cardCover")
        model.clickAction <~ (dictionary, "clickAction")
        model.comment <~ (dictionary, "comment")
        model.highlightColor <~ (dictionary, "highlightColor")
        model.longPressMenu <~ (dictionary, "longPressMenu")
        model.title <~ (dictionary, "title")
        model.subTitle <~ (dictionary, "subTitle")
        model.cardRecordCells <~ (dictionary, "cardRecordCells")
        return model
    }
}
