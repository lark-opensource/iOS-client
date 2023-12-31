//
//  BlockCatalogueModel.swift
//  SKBitable
//
//  Created by zoujie on 2023/9/6.
//  

import Foundation
import HandyJSON
import SKInfra

enum BlockCatalogAction: String {
    case DocCreate
    case TableCreate
}

struct BlockTreeItem {
    let icon: UIImage
    let title: String
    let selected: Bool
    let showMore: Bool
}

struct ActionContainerModel {
    let title: String
    let items: [ActionButtonModel]
}

struct ActionButtonModel {
    let icon: UIImage
    let title: String
    let disable: Bool
    let clickCallback: (() -> Void)?
}

struct BlockCatalogueModel: HandyJSON, SKFastDecodable, Equatable {
    var searchBar: SearchBarModel?
    var items: [BTCommonItem] = []
    var canSort: Bool = false
    var empty: EmptyModel?
    var bottomText: String?
    var bottomMenu: [SimpleItem]?
    var closePanel: Bool = false
    var callback: String?
    var sortAction: String? // 排序
    var searchAction: String? // 搜索
    var getDataAction: String? // 主动获取数据
    
    static func deserialized(with dictionary: [String : Any]) -> BlockCatalogueModel {
        var model = BlockCatalogueModel()
        model.searchBar <~ (dictionary, "searchBar")
        model.items <~ (dictionary, "items")
        model.canSort <~ (dictionary, "canSort")
        model.empty <~ (dictionary, "empty")
        model.bottomText <~ (dictionary, "bottomText")
        model.bottomMenu <~ (dictionary, "bottomMenu")
        model.closePanel <~ (dictionary, "closePanel")
        model.sortAction <~ (dictionary, "sortAction")
        model.searchAction <~ (dictionary, "searchAction")
        model.callback <~ (dictionary, "callback")
        model.getDataAction <~ (dictionary, "getDataAction")
        return model
    }
}

extension BlockCatalogueModel {
    func hasValidData() -> Bool {
        return items.count > 0
    }
}
