//
//  MentionTracker.swift
//  LarkMention
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation

// 埋点展示用
enum PickerMentionTraker {
    /// 面板展示时
    case show
    /// 面板关闭时
    case close
    /// 点击多选按钮切换模式
    case typeChange
    /// 滑动列表
    case listSlide
    /// 勾选框的点击（headerView）
    case checkboxClick
    /// 点击选中选项
    case itemClick
}

#if canImport(LKCommonsTracker)
import LKCommonsTracker
#endif

public final class MentionTraker {
    private var productLevel: String
    private var scene: String
    
    public init(productLevel: String, scene: String) {
        self.productLevel = productLevel
        self.scene = scene
    }
    
    func mentionTrakerPost(action: PickerMentionTraker, targer: String? = nil,
                                  hasCheckBox: Bool = false, isCheckSelected: Bool = false,
                                  listItemNumber: Int? = nil, item: PickerOptionType? = nil) {
        // 埋点上传参数
        var click: String?
        var status: String?
        var listItemType: String?
        var itemType: String?
        var checkboxStaus: String?
        
        var params: [AnyHashable : Any] = ["product_level": productLevel,
                                          "scene": scene]
        switch action {
        case .show: break
        case .close:
            click = "close"
        case .typeChange:
            click = "type_change"
            status = "to_multi"
        case .listSlide:
            click = "list_slide"
        case .checkboxClick:
            click = "checkbox_click"
            status = "to_unselected"
            if isCheckSelected {
                status = "to_selected"
            }
        case .itemClick:
            click = "item_click"
            guard let item = item else { return }
            switch item.type {
            case .chatter : listItemType = "user"
            case .chat : listItemType = "group"
            case .document : listItemType = "doc"
            case .wiki : listItemType = "doc"
            default : break
            }
            itemType = "single"
            if item.isEnableMultipleSelect {
                itemType = "multiple"
            }
            checkboxStaus = "none"
            if hasCheckBox {
                if isCheckSelected {
                    checkboxStaus = "selected"
                } else {
                    checkboxStaus = "unselected"
                }
            }
        }
        params["click"] = click
        params["target"] = targer
        params["status"] = status
        params["list_item_type"] = listItemType
        params["list_item_number"] = listItemNumber
        params["type"] = itemType
        params["checkbox_staus"] = checkboxStaus
        
#if canImport(LKCommonsTracker)
        if action == .show {
            Tracker.post(TeaEvent("public_mention_panel_view", params: params))
        } else {
            Tracker.post(TeaEvent("public_mention_panel_select_click", params: params))
        }
#else
        print("product_level : \(productLevel) ,scene: \(scene)")
#endif
    }
    
}
