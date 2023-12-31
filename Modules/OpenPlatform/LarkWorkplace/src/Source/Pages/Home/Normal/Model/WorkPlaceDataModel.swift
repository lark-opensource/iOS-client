//
//  WorkPlaceDataModel.swift
//  LarkWorkplace
//  数据模型,参考文档：https://bytedance.feishu.cn/docs/doccn7ZRtxEHoUFUdY1sztL7SFf#
//  Created by 李论 on 2020/5/12.
//

import SwiftyJSON
import LKCommonsLogging
import LarkWorkplaceModel

extension WPAppItem.OpenURL {
    func isAllURLEmpty() -> Bool {
        return (mobileWebURL?.isEmpty ?? true) && (mobileMiniAppURL?.isEmpty ?? true) &&
               (mobileCardWidgetURL?.isEmpty ?? true) && (mobileAppLink?.isEmpty ?? true) &&
               (pcWebURL?.isEmpty ?? true) && (pcMiniAppURL?.isEmpty ?? true) &&
               (pcCardWidgetURL?.isEmpty ?? true) && (pcAppLink?.isEmpty ?? true)
    }

    func canOpenOnPC() -> Bool {
        return !(pcWebURL?.isEmpty ?? true) || !(pcMiniAppURL?.isEmpty ?? true) || !(pcAppLink?.isEmpty ?? true)
    }

    func canOpenInH5() -> Bool {
        if offlineWeb == true { return true }
        if let str = mobileWebURL, !str.isEmpty { return true }
        return false
    }
}

extension WPAppItem {
    func isNativeActionItem() -> Bool {
        if let nativeAppKey = nativeAppKey, !nativeAppKey.isEmpty { return true }
        return false
    }
    /// To Badge Ability
    func badgeAbility() -> WPBadge.AppType? {
        guard let defaultAbility = mobileDefaultAbility else { return nil }
        switch defaultAbility {
        case .miniApp:
            return .miniApp
        case .web:
            return .web
        case .unknown:
            if let mobileMpURL = url?.mobileMiniAppURL {
                return .miniApp
            }
            if let mobileH5URL = url?.mobileWebURL {
                return .web
            }
        default:
            break
        }
        return nil
    }

    /// scene id
    var sceneId: String {
        let ability = badgeAbility()
        return ability == .web ? (url?.mobileWebURL ?? "") : "\(mobileDefaultAbility ?? .unknown)"
    }

    func badgeKey() -> WorkPlaceBadge.BadgeSingleKey? {
        guard let ability = badgeAbility(), let appID = appId else { return nil }
        return WorkPlaceBadge.BadgeSingleKey(appId: appID, ability: ability)
    }
}

extension WPTemplateModule.ComponentDetail.Favorite.AppSubType {
    func getBlockScene(isFromTemplate: Bool) -> BlockScene? {
        /// block组件不走这里的逻辑，外部就能知道block组件的scene是templateComponent
        switch self {
        case .platformBlock, .platformWidget:
            return isFromTemplate ? .templatePlatform : .normalPlatfrom
        case .common:
            return isFromTemplate ? .templateCommon : .normalCommon
        case .recommend:
            return isFromTemplate ? .templateRecommend : .normalRecommend
        case .deletableRecommend:
            return isFromTemplate ? .templateDeletableRecommend : .normalDeletableRecommend
        default:
            return nil
        }
    }

    // 上报转化成 Int
    var trackIntVal: Int {
        switch self {
        case .recommend:
            return 1
        case .deletableRecommend:
            return 2
        case .common:
            return 3
        default:
            return -1
        }
    }
}

/// 由一个或者多个Item组成的单元
struct TagChildren: Codable {
    /// item 子类型，icon中存在normal和system_add
    var subType: WPTemplateModule.ComponentDetail.Favorite.AppSubType
    /// 主类型
    var type: WPTemplateModule.ComponentDetail.Favorite.AppType
    /// item ID
    var itemId: String
    /// application display size (only blocks have this field)
    let size: FavoriteAppDisplaySize?
}

/// 子tag
struct SubTag: Codable {
    /// 主类型
    var tagName: String
    /// item ID
    var tagId: Int
}

/// 后台返回的分组
struct Tag: Codable {
    /// 分组ID
    var id: String
    /// 主类型
    var showTagHeader: Bool
    /// 包含的元素
    var children: [TagChildren]?
    /// 分组名字
    var name: String
    /// showWidget, 是否展示widget
    var showWidget: Bool? = false
    /// 是否是我的常用组件
    var isMainTag: Bool? = false
    /// 是否有更多
    var hasMore: Bool? = false
    /// sub tags
    var subTags: [SubTag]?
    func canDisplayWidget() -> Bool {
        #if DEBUG
        return showWidget ?? true
        #endif
        return showWidget ?? false
    }
}

/// 服务端返回的数据
struct WorkPlaceRespDataModel: Codable {
    /// 所有item信息
    var allItemInfos: [String: WPAppItem]
    /// 所有分组信息
    var tagList: [Tag]
    /// 时间戳
    var ts: Int
}

/// 服务端返回的数据
struct WorkPlaceRespModel: Codable {
    /// msg信息
    var msg: String
    /// data
    var data: WorkPlaceRespDataModel
    /// code
    var code: Int
}

/// 对应到item分组信息
struct ItemCategory: Codable {
    /// 分组ID
    let categoryId: String
    /// 分组名
    let categoryName: String
    /// app数组
    var showTagHeader: Bool
    /// subTags, 分组子tag
    var subTags: [SubTag]?
    /// origin Tag
    var tag: Tag
}
/// subTag item列表信息
struct SubTagItemInfo: Codable {
    /// 包含的元素
    var children: [TagChildren]?
    /// 所有items
    var allItemInfos: [String: WPAppItem]?
    /// 是否还有更多
    var hasMore: Bool? = false
}

/// 由一个或者多个Item组成的单元
struct ItemUnit: Codable {
    /// item 类型，widget或者icon
    var type: WPTemplateModule.ComponentDetail.Favorite.AppType
    /// item 子类型，icon中存在normal和system_add
    var subType: WPTemplateModule.ComponentDetail.Favorite.AppSubType?
    /// item ID
    var itemID: String
    /// 如果是Widget类型，那么数组只有一个；如果是icon类型，那么可能存在多个
    var item: WPAppItem
    /// 应用大小（目前只有我的常用内的非标小组件有这个字段）
    var size: FavoriteAppDisplaySize?
}

/// 分组
struct GroupUnit: Codable {
    /// category 信息
    var category: ItemCategory
    /// children 信息
    var itemUnits: [ItemUnit]
    /// 是否应该展示红点信息
    func shouldDisplayBadge() -> Bool {
        return (category.tag.subTags == nil)
    }
}

/// 这个是转换之后的数据
final class WorkPlaceDataModel: Codable {
    static let logger = Logger.log(WorkPlaceDataModel.self)
    /// 返回的分组信息
    var rspModel: WorkPlaceRespModel?
    /// 处理之后的分组信息
    var groups: [GroupUnit] = []
    /// 处理之后的 item map
    var allItemInfos: [String: WPAppItem] = [:]
    /// server timestamp（单位：s）
    var timestamp: Int = 0

    // 因为有 Codable 协议，dependency 只能传递，不能持有
    init(json: JSON, dependency: WPDependency? = nil) {
        do {
            rspModel = try JSONDecoder().decode(WorkPlaceRespModel.self, from: json.rawData())
        } catch {
            WorkPlaceDataModel.logger.error("WorkPlaceDataModel parse fail \(error.localizedDescription)")
        }

        if let model = rspModel {
            WorkPlaceDataModel.logger.info("WorkPlaceDataModel parse \(model.code) \(model.msg)")
            parseModel(rspModel: model, dependency: dependency)
            /// 过滤掉其中为空的group，因为某些一方应用不合法可能被过滤掉
            groups = groups.filter { (group) -> Bool in
                !group.itemUnits.isEmpty
            }
        }
    }
    /// 将dataModel转化为按section分组的ViewModel
    /// - Parameter rspModel: dataModel
    private func parseModel(rspModel: WorkPlaceRespModel, dependency: WPDependency?) {
        /// 所有item信息的map，解析到对应的字典中
        allItemInfos = rspModel.data.allItemInfos
        /// 时间戳
        timestamp = rspModel.data.ts
        /// 解析分组信息，保存到groups中
        for sourceGroup in rspModel.data.tagList {
            groupSplit(group: sourceGroup, dependency: dependency)
        }
    }
    /// 将原始分组数据拆分成不同分组单元，并放到self的groups数组中
    /// - Parameter sourceGroup: 要拆分的分组数据
    /// - Note: 拆分规则-按照tag分组信息分割，每个tag一组
    private func groupSplit(group sourceGroup: Tag, dependency: WPDependency?) {
        /// 创建分组信息
        let category = ItemCategory(
            categoryId: sourceGroup.id,
            categoryName: sourceGroup.name,
            showTagHeader: sourceGroup.showTagHeader,
            tag: sourceGroup
        )
        /// 新建一个分组单元
        var groupUnit = GroupUnit(category: category, itemUnits: [])
        /// 开始解析分组内部的内容
        var tempUnits: [ItemUnit] = []
        for item in sourceGroup.children ?? [] {
            /// 生成item
            let type = item.type
            let itemid = item.itemId
            let subtype = item.subType

            /// 如果 item.type == .unknown 或者 item.subType == .unknown 的时候直接丢弃过滤掉
            guard let itemInfo = getItemInfo(itemId: item.itemId, subType: item.subType, dependency: dependency) else {
                WorkPlaceDataModel.logger.info("item \(itemid) subtype \(subtype) type \(type) not found")
                continue
            }
            /// 记录当前unit
            let unit = ItemUnit(
                type: type,
                subType: subtype,
                itemID: itemid,
                item: itemInfo,
                size: item.size
            )
            tempUnits.append(unit)
        }
        if !tempUnits.isEmpty {
            /// 最后之前的数据作为一个单位，添加到分组中
            groupUnit.itemUnits.append(contentsOf: tempUnits)
        }
        /// 分组信息构造完毕，添加分组到数据结构中
        groups.append(groupUnit)
    }

    /// 获取ItemIfno（对于system_add，手动构造「添加应用」icon应用，其他直接判断数据集中的itemInfo是否可用）
    /// - Parameters:
    ///   - itemId: 从@allItemInfos 中查询Item的key
    ///   - subType: Item的子类型（普通，添加应用），添加应用这个item在itemInfos没有实体，只能根据类型构造一个
    private func getItemInfo(itemId: String, subType: WPTemplateModule.ComponentDetail.Favorite.AppSubType, dependency: WPDependency?) -> WPAppItem? {
        if let item = allItemInfos[itemId] {
            /// 检查item是否合法，如果不合法的一方应用，直接过滤掉
            return WorkplaceTool.isItemValid(item: item, dependency: dependency) ? item : nil
        } else if subType == .systemAdd {
            return WPAppItem.buildAddItem()// 这种写法非常trick，后期使用时必须保证优先判断isAddAppItem
        } else {
            return nil
        }
    }
}

/// 工作台配置信息
struct WorkPlaceSetting: Codable {
    /// 应用目录移动端Url
    var appStoreMobileUrl: String = ""
    /// 是否展示应用目录入口
    var isShowAppStore: Bool = false

    init(json: JSON) {
        appStoreMobileUrl = json["data"]["workplaceSetting"]["appStoreMobileUrl"].stringValue
        isShowAppStore = json["data"]["workplaceSetting"]["isShowAppStore"].boolValue
    }
}
