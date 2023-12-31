//
//  MentionType.swift
//  LarkMention
//
//  Created by Yuri on 2022/7/15.
//

import Foundation
import UIKit

public protocol MentionPanelDelegate: AnyObject{
    func panel(didDismissWithGlobalCheckBox selected: Bool)
    func panel(didFinishWith items: [PickerOptionType])
    func panel(didFilter items: [PickerOptionType]) -> [PickerOptionType]
    func panel(didMultiSelect item: PickerOptionType, at row: Int, isSelected: Bool)
}

public protocol MentionType {
    /// 穿透view，ipad下交互不会关闭mention
    var passthroughViews: [UIView]? { get set }
    /// 指定iPad下popover的标点view
    var sourceView: UIView?  { get set }
    /// mention的事件代理回调
    var delegate: MentionPanelDelegate?  { get set }
    /// 默认数据，输入源为空时展示
    var defaultItems: [PickerOptionType]?  { get set }
    /// 自定义数据加载器，默认是飞书大搜
    var provider: MentionDataProviderType?  { get set }
    /// 默认数据，设置后会替换骨架屏显示
    var recommendItems: [PickerOptionType]? { get set }
    /// UI 配置项
    var uiParameters: MentionUIParameters { get set }
    /// 搜索参数配置
    var searchParameters: MentionSearchParameters { get set }
    
    func search(text: String)
}
