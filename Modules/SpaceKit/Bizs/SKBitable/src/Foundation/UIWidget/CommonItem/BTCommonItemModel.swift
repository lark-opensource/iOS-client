//
//  BTCommonItemModel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/11.
//


import SKFoundation
import HandyJSON
import UniverseDesignColor
import RxDataSources
import SKInfra

struct BTCommonItem: HandyJSON, Equatable, GroupableItem, SKFastDecodable {
    var id: String = "createView"
    var groupId: String = ""
    var select: Bool = false // 展示右侧选中icon，新增
    var enable: Bool = true  // 设置按压态，点击事件回传，新增
    
    var leftText: String? // 左侧text，替代text
    var leftIcon: BTIcon? // 左侧icon，替代leftIconId
    var leftIconTag: BTIcon? // 左侧文本后的小icon
    var leftStyle: BTIconAndTextStyle = .normal // 左侧染色，新增
    var leftIconStyle: BTIconAndTextStyle?
    var tagText: String?

    var rightText: String? // 右侧text，替换description
    var rightIcon: BTIcon?   // 右侧icon，新增
    var rightStyle: BTIconAndTextStyle? // 右侧染色，新增

    var desc: String? // 第二行描述，新增
    var descMaxLine: Int? // 描述最大行，新增
    
    var editable: Bool?
    
    var checkbox: CheckboxStruct?
    
    var placeholder: String?
    
    var isSelected: Bool = false
    var clickAction: String?
    
    var rightIconImage: UIImage? {
        guard let rightIcon = rightIcon else { return nil }
        return BTUtil.getImage(icon: rightIcon, style: rightIcon.style ?? rightStyle)
    }

    var leftIconImage: UIImage? {
        guard let leftIcon = leftIcon else { return nil }
        return BTUtil.getImage(icon: leftIcon, style: (leftIcon.style ?? leftIconStyle) ?? leftStyle)
    }
    
    var leftIconTagImage: UIImage? {
        guard let leftIconTag = leftIconTag else { return nil }
        return BTUtil.getImage(icon: leftIconTag, style: (leftIconTag.style ?? leftIconStyle) ?? leftStyle)
    }
    
    var headerIconImage: UIImage? {
        guard let headerIcon = leftIcon else { return nil }
        return BTUtil.getImage(icon: headerIcon, style: nil)
    }
    
    var rightTextColor: UIColor? {
        return rightStyle?.getColor().textColor
    }
    
    var leftTextColor: UIColor {
        return leftStyle.getColor().textColor
    }
    
    static func deserialized(with dictionary: [String: Any]) -> BTCommonItem {
        var model = BTCommonItem()
        model.id <~ (dictionary, "id")
        model.groupId <~ (dictionary, "groupId")
        model.select <~ (dictionary, "select")
        model.enable <~ (dictionary, "enable")
        model.leftText <~ (dictionary, "leftText")
        model.leftIcon <~ (dictionary, "leftIcon")
        model.leftIconTag <~ (dictionary, "leftIconTag")
        model.leftStyle <~ (dictionary, "leftStyle")
        model.leftIconStyle <~ (dictionary, "leftIconStyle")
        model.tagText <~ (dictionary, "tagText")
        model.rightText <~ (dictionary, "rightText")
        model.rightIcon <~ (dictionary, "rightIcon")
        model.rightStyle <~ (dictionary, "rightStyle")
        model.desc <~ (dictionary, "desc")
        model.descMaxLine <~ (dictionary, "descMaxLine")
        model.editable <~ (dictionary, "editable")
        model.checkbox <~ (dictionary, "checkbox")
        model.placeholder <~ (dictionary, "placeholder")
        model.isSelected <~ (dictionary, "isSelected")
        model.clickAction <~ (dictionary, "clickAction")
        return model
    }
}

extension BTCommonItem: IdentifiableType {
    typealias Identity = String
    
    var identity: String { id }
}

struct BTCommonItemContainer: AnimatableSectionModelType {
    typealias Item = BTCommonItem
    var identity: String { identifier }

    let identifier: String
    private(set) public var items: [Item]

    init(identifier: String,
         items: [BTCommonItem]) {
        self.identifier = identifier
        self.items = items
    }

    init(original: BTCommonItemContainer,
         items: [BTCommonItem]) {
        self = original
        self.items = items
    }
}
