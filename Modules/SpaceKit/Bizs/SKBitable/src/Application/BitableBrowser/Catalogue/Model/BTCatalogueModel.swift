//
//  BTCatalogueModel.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/22.
//  


import HandyJSON
import SKResource
import UniverseDesignTheme
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit
import UIKit
import SKFoundation
import SKBrowser

// bitable管理面板数据模型

enum CatalogueOprationId: String, HandyJSONEnum {
    case addTable = "add_table"
    case addView = "add_view"
    case more = "more"
    case exit = "exit"
    case `switch` = "switch"
    case unfoldTable = "unfold_table"
    case foldTable = "fold_table"
    case addLinkedDoc = "add_linked_doc"
}

final class BTCatalogueModel: HandyJSON {
    
    final class CatalogueDataModel: HandyJSON {
        
//        enum GroupType: String, HandyJSONEnum {
//            /// 普通bitable，有二级目录
//            case table = "BITABLE_TABLE"
//            /// 无二级目录的一种类型
//            case dashboard = "DASHBOARD"
//        }
        
        required init() {}
        
        var text: String = ""
        /// 就是tableId
        var id: String = ""
        
        var type: String? = "BITABLE_TABLE"
        
        var icon: String?
       
        /// 侧滑菜单，空表示无权限
        var actions: [BTCatalogueContextualAction.ActionType] = []
        
        /// 是否为同步表, 需要展示闪电标识
        var isSync: Bool = false
        /// 是否展示 warning icon
        var shouldShowWarningIcon: Bool = false
        
        var active: Bool = false
        var views: [CatalogueDataViewModel] = []
        
        // ====== 自定义字段 =========
        
        /// 记录当前分组是否展开
        var isExpand: Bool = false
        
        /// 是否可以展开
        var canExpand: Bool {
            return !views.isEmpty
        }
        
        /// 折叠状态Image
        lazy var foldImage: UIImage = {
            return UDIcon.globalTrianglesmallOutlined
        }()
        /// 展开状态Image
        lazy var expandImage: UIImage = {
            return UDIcon.globalTrianglesmallOutlined.sk.rotate(radians: Float.pi / 2)
                ?? UDIcon.expandDownFilled
        }()
        
        var iconImage: UIImage {
            var image: UIImage?
            if let udIconKey = bitableRealUDKey(icon), let key = UDIcon.getIconTypeByName(udIconKey) {
                image = UDIcon.getIconByKey(key)
            } else {
                if self.type == "BITABLE_TABLE" {
                    image = UDIcon.sheetBitableOutlined
                } else if self.type == "DASHBOARD" {
                    image = UDIcon.burnlifeNotimeOutlined
                }
            }
            guard let img = image else {
                return UIImage()
            }
            return img.ud.withTintColor(UDColor.iconN1)
        }
        
        func didFinishMapping() {
            isExpand = active
            if active {
                DocsLogger.btInfo("BTCatalogue: \(id) is expend")
            }
        }
    }
    
    final class CatalogueDataViewModel: HandyJSON {
        
        required init() {}
        var text: String = ""
        var type: String = "grid"
        // 灰度阶段为optional，且只有任务视图使用，灰度完成改为require
        var icon: String?
        // 插件视图 自定义url
        var iconUrl: String?
        /// 就是viewId
        var id: String = ""
        /// 当前是否是高亮状态
        var active: Bool = false
        
        /// 侧滑菜单，空表示无权限
        var actions: [BTCatalogueContextualAction.ActionType] = []
        
        // ====== 自定义字段 =========
        /// 记录上一级的id
        var tableId = ""
        
        var iconImage: UIImage {
            var image: UIImage? = BTUtil.getImage(icon: BTIcon(udKey: icon), style: nil)
            guard let img = image else {
                return UIImage()
            }
            return img.ud.withTintColor(UDColor.iconN1)
        }
        
        func didFinishMapping() {
            if active {
                DocsLogger.btInfo("BTCatalogue: \(id) is active")
            }
        }
    }
    
    enum BottomFixedStyle: String, HandyJSONEnum {
        case normal = "normal"
        case disable = "disable"
    }
    
    final class BottomFixedData: HandyJSON {
        
        required init() {}
        var text: String = ""
        var id: CatalogueOprationId?
        var style: BottomFixedStyle = .normal
        var showBadge: Bool = false
    }
    
    /// data为空时关闭面板
    var data: [CatalogueDataModel] = []
    
    var title: String = ""
    
    /// 底部新增功能，无权限时返回为nil
    var bottomFixedData: BottomFixedData?
    var bottomFixedDatas: [BottomFixedData]?
    
    /// 点击面板后给H5那边的回调
    /// 参数：
    ///  { tableId: string
    ///   viewId: string;
    ///   id: CatalogueOprationId;
    ///  }
    var callback: String = ""
    
    required init() {}
    
    func didFinishMapping() {
        for head in data {
            head.views.forEach {
                $0.tableId = head.id
            }
        }
    }

}

// MARK: - UI extension

extension BTCatalogueModel.CatalogueDataModel: BitableCatalogueData {
    var showLighting: Bool {
        isSync
    }
    
    var showWarning: Bool {
        shouldShowWarningIcon
    }
    
    var editable: Bool {
        let isPhoneLandscape = SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape
        return !actions.isEmpty && !isPhoneLandscape
    }
    
    var arrowIcon: UIImage? {
        if canExpand {
            return isExpand ? expandImage : foldImage
        } else {
            return nil
        }
    }
    
    var iconImgUrl: String? {
        return nil
    }
    
    var iconImg: UIImage {
        return iconImage
    }
    
    var title: String? {
        return text
    }
    
    var isSelected: Bool {
        // 未展开的表也可以成为选中状态
        return active
    }
    
    var catalogueType: BTCatalogueCellType {
        return .head
    }
    
    var slideActions: [BTCatalogueContextualAction.ActionType] {
        return actions.reversed()
    }

    var canAddView: Bool {
        return editable && slideActions.contains { $0 == .add }
    }
    
    var canHighlighted: Bool {
        return true
    }
    
    var canBackgroundHighlighted: Bool {
        return canHighlighted && views.isEmpty
    }
}

extension BTCatalogueModel.CatalogueDataViewModel: BitableCatalogueData {
    var showLighting: Bool {
        false
    }
    
    var showWarning: Bool {
        false
    }
    
    
    var editable: Bool {
        let isPhoneLandscape = SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape
        return !actions.isEmpty && !isPhoneLandscape
    }
    
    var arrowIcon: UIImage? {
       return nil
    }
    
    var iconImgUrl: String? {
        return iconUrl
    }
    
    var iconImg: UIImage {
        return iconImage
    }
    
    var title: String? {
        return text
    }
    
    var isSelected: Bool {
        return active
    }
    
    var catalogueType: BTCatalogueCellType {
        return .node
    }
    
    var slideActions: [BTCatalogueContextualAction.ActionType] {
        return actions.reversed()
    }

    var canAddView: Bool {
        return editable && slideActions.contains { $0 == .add }
    }
    
    var canHighlighted: Bool {
        return true
    }
    
    var canExpand: Bool { return false }
    
    var canBackgroundHighlighted: Bool {
        return canHighlighted
    }
}

extension BTCatalogueModel.BottomFixedData: CatalogueCreateViewData {
    
    var title: String {
        return text
    }
    
    var image: UIImage? {
        return  UDIcon.addOutlined.ud.withTintColor(UDColor.iconN1)
    }
}
