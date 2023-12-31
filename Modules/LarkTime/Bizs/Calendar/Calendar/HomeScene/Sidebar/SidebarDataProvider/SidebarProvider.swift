//
//  SidebarProvider.swift
//  Calendar
//
//  Created by huoyunjie on 2023/11/10.
//

import Foundation
import RxRelay

enum SidebarDataSource: Int {
    case calendar
    case timeContainer
    
    var description: String {
        switch self {
        case .calendar: return "calendar"
        case .timeContainer: return "timeContainer"
        default: return ""
        }
    }
}

protocol SidebarModelData: SidebarCellViewData {
    var id: String { get }
    var sectionType: CalendarListSection { get }// 所属 section, contents 为空
    var weight: Int32 { get }// 权重，排序用
    var colorIndex: ColorIndex { get }// 颜色下标
    var source: SidebarDataSource { get }
    var accountValid: Bool { get } // 账号是否有效
    var accountExpiring: Bool { get } // 账号是否过期
}

extension SidebarModelData {
    var uniqueId: String {
        "\(source.description)\(id)"
    }
    
    var color: UIColor {
        SkinColorHelper.pickerColor(of: self.colorIndex.rawValue)
    }
}

protocol SidebarDataProvider {
    var source: SidebarDataSource { get }// 数据源标识
    var modelData: [SidebarModelData] { get }
    var dataChanged: BehaviorRelay<Void> { get }
    func updateVisibility(with uniqueId: String, from: UIViewController) // 勾选可见性
    func clickTrailView(with uniqueId: String, from: UIViewController, _ popAnchor: UIView) // 点击 ...
    func clickFooterView(with uniqueId: String, from: UIViewController) // 点击 footerView
    func fetchData() // 刷新数据
}
