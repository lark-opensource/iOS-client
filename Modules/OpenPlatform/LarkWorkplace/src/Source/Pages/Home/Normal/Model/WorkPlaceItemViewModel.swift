//
//  WorkPlaceItemModels.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/8/12.
//

import LarkUIKit
import SwiftyJSON
import LarkWorkplaceModel
import ByteWebImage
import LKCommonsLogging

/// WorkPlaceItem横向占位空间
let horizontalPlaceHolderWidth: CGFloat = 10.0
/// item 类型
enum ItemType: String {
    // widget类型
    case widget
    // block 类型
    case block
    // icon类型
    case icon
    // 无常用应用时显示的方形「添加应用」
    case addRect
    // 常用应用尾部的圆形「添加应用」
    case addIcon
    // 垂直间隔
    case verticalSpace
    // 填充item
    case fillItem
    // 状态Item
    case stateItem

    // 存储 Item 间接时用的存储 key
    var spaceKey: String {
        switch self {
        case .widget, .block:
            return "widget-block"
        default:
            return rawValue
        }
    }

    var isWidgetOrBlock: Bool {
        self == .widget || self == .block
    }
}
/// item 协议方法
protocol WorkPlaceItem {
    /// Item的类型
    var itemType: ItemType { get }
    /// 获取Item布局高度，用于CollectionView中计算item的高度
    func getItemLayoutSize(superViewWidth: CGFloat) -> CGSize
    /// 获取相应的AppInfo，适配icon应用的展示
    func getSingleAppInfo() -> SingleAppInfo?
    /// 获取相应的WidgetModl，适配widget的展示
    func getWidgetModel() -> WidgetModel?
    /// 获取相应的 blockModel
    func getBlockModel() -> BlockModel?
    /// 是否是常用应用
    func isCommon() -> Bool
    /// 获取itemId
    func getItemId() -> String?
    /// 获取additional info的block
    func additionalInfo() -> ItemModelAdditionInfo?
    /// 是否是本地添加的常用应用
    var isAddCommonLocal: Bool { get set }
    /// section can display widget
    var sectionCanDisplayWidget: Bool { get set }
    /// badge key
    func badgeKey() -> [WorkPlaceBadge.BadgeSingleKey]?
    /// section can display Badge
    var sectionCanDisplayBadge: Bool { get set }
}
/// item 实现默认协议方法
extension WorkPlaceItem {
    func getItemLayoutSize(superViewWidth: CGFloat) -> CGSize {
        let cellWidth = superViewWidth - ItemModel.horizontalCellMargin * 2 - horizontalPlaceHolderWidth
        let cellHeight: CGFloat = ItemModel.iconItemHeight
        return CGSize(width: cellWidth, height: cellHeight)
    }
    func getSingleAppInfo() -> SingleAppInfo? {
        return nil
    }
    func getWidgetModel() -> WidgetModel? {
        return nil
    }
    func getBlockModel() -> BlockModel? {
        return nil
    }
    func additionalInfo() -> ItemModelAdditionInfo? {
        return nil
    }
    func badgeKey() -> [WorkPlaceBadge.BadgeSingleKey]? {
        return nil
    }
}
/// 空白的横向间距
struct EmptySpaceItemModel: WorkPlaceItem {
    var sectionCanDisplayWidget: Bool = false
    var sectionCanDisplayBadge: Bool = false
    var isAddCommonLocal: Bool = false
    func getItemId() -> String? {
        return nil
    }

    var itemType: ItemType = .verticalSpace
    func getItemLayoutSize(superViewWidth: CGFloat) -> CGSize {
        let cellWidth = superViewWidth - ItemModel.horizontalCellMargin * 2 - horizontalPlaceHolderWidth
        return CGSize(width: cellWidth, height: height)
    }
    /// space height
    var height: CGFloat = 0
    init(height: CGFloat) {
        self.height = height
    }
    func isCommon() -> Bool {
        false
    }
}

/// 分类页面的状态 item
struct StateItemModel: WorkPlaceItem {
    var sectionCanDisplayWidget: Bool = false
    var sectionCanDisplayBadge: Bool = false
    var isAddCommonLocal: Bool = false
    func getItemId() -> String? {
        return nil
    }

    func isCommon() -> Bool {
        false
    }
    var itemType: ItemType
    var state: SubSectionState = .loading
    func getItemLayoutSize(superViewWidth: CGFloat) -> CGSize {
        if state == .loading {
            return ItemModel.iconItemSize
        } else {
            let cellWidth = superViewWidth - ItemModel.horizontalCellMargin * 2 - horizontalPlaceHolderWidth
            let cellHeight: CGFloat = 350
            return CGSize(width: cellWidth, height: cellHeight)
        }
    }
}
/// 假的icon空白cell，填充作用
struct EmptyFillSpaceItemModel: WorkPlaceItem {
    var sectionCanDisplayWidget: Bool = false
    var sectionCanDisplayBadge: Bool = false
    var isAddCommonLocal: Bool = false
    func getItemId() -> String? {
        return nil
    }

    var itemType: ItemType = .fillItem
    func getItemLayoutSize(superViewWidth: CGFloat) -> CGSize {
        return ItemModel.iconItemSize
    }
    func getSingleAppInfo() -> SingleAppInfo? {
        return nil
    }
    func getWidgetModel() -> WidgetModel? {
        return nil
    }
    func isCommon() -> Bool {
        false
    }
}
/// 真实的icon cell
struct ItemModel: WorkPlaceItem {
    static let logger = Logger.log(ItemModel.self)

    /// section 是否可以展示Badge
    var sectionCanDisplayBadge: Bool
    var sectionCanDisplayWidget: Bool = false
    /// 是否是本地添加的常用
    var isAddCommonLocal: Bool = false
    /// 原始dataModel
    var dataItem: ItemUnit
    /// item类型
    // swiftlint:disable identifier_name
    var _itemType: ItemType
    // swiftlint:enable identifier_name
    var itemType: ItemType {
        get {
            if (_itemType == .widget || _itemType == .block) && !sectionCanDisplayWidget {
                return .icon
            }
            return _itemType
        }
        set {
            _itemType = newValue
        }
    }
    /// 得到item信息的block
    private var queryAdditionInfo: (() -> ItemModelAdditionInfo?)?
    /// item的标示
    var itemID: String
    /// 真实的item
    var item: WPAppItem
    /// 水平方向相对于父布局的单边间距（设计稿间距值为16，竖屏宽度375）
    static let horizontalCellMargin: CGFloat = 16
    /// widgetItem的宽高比（设计稿宽值为150，343）
    static let widgetAspectRatio: CGFloat = 0.45
    /// iconItem的宽度（取自设计稿固定值）
    static let iconItemWidth: CGFloat = Display.pad ? 70 : 76
    /// iconItem的高度（取自设计稿固定值）
    static let iconItemHeight: CGFloat = 106
    /// 方形「添加应用」的宽高比（设计稿宽值为44，343）
    static let addRectAspectRatio: CGFloat = 0.13
    /// 运营位高度
    static let operationHeight: CGFloat = 44.0
    /// item之间行间距
    static let miniLineSpace: CGFloat = 8.0
    /// 默认容器宽度
    static let containerDefaultWidth: CGFloat = 375.0
    /// widget 默认宽度
    static let widgetDefaultWidth: CGFloat = 343.0
    /// widget 默认高度
    static let widgetDefaultHeight: CGFloat = 150.0
    /// widget navBar的高度
    static let widgetNavBarHeight: CGFloat = 44.0
    /// block 默认高度
    static let blockDefaultHeight: CGFloat = 150.0

    static var iconItemSize: CGSize {
        return CGSize(width: iconItemWidth, height: iconItemHeight)
    }

    /// 是否可删除
    var isDeletable: Bool {
        dataItem.subType == .common || dataItem.subType == .deletableRecommend
    }

    /// 是否可排序
    var isSortable: Bool {
        dataItem.subType == .common
    }

    var isEditable: Bool {
        isDeletable || isSortable
    }

    /// 是否为推荐应用（包含 A 类 不可删除应用、B 类可删除应用）
    var isRecommand: Bool {
        dataItem.subType == .recommend || dataItem.subType == .deletableRecommend
    }

    var canAddComon: Bool {
        dataItem.subType == .available
    }

    var appId: String? {
        return item.appId
    }

    init(
        dataItem: ItemUnit,
        isAddRect: Bool,
        sectionCanDisplayBadge: Bool = false,
        additionalInfoProxy: WorkPlaceQueryAdditionContext? = nil
    ) {
        self.sectionCanDisplayBadge = sectionCanDisplayBadge
        self.dataItem = dataItem
        self.itemID = dataItem.itemID
        self.item = dataItem.item

        if isAddRect {
            _itemType = .addRect
            return
        }

        /// 这里把 if 判断重构成 switch，便于之后扩充 type 时有编译提示
        /// 之前的逻辑就是对于 unknown 的 case，设置 _itemType=.widget
        /// 这里有点奇怪，重构暂时先不改逻辑，之后再看下
        switch dataItem.type {
        case .icon:
            _itemType = dataItem.subType == .systemAdd ? .addIcon : .icon
        case .block, .nonStandardBlock:
            _itemType = .block
        case .widget:
            _itemType = .widget
        @unknown default:
            assertionFailure("should not be here")
            _itemType = .widget
        }

        /// setup query context
        if _itemType == .widget {
            let itemId = self.itemID
            self.queryAdditionInfo = {[weak additionalInfoProxy] in
                return additionalInfoProxy?.queryAdditionItem(itemId: itemId)
            }
        }
    }

    /// widget cell size
    private func widgetItemSize(superViewWidth: CGFloat) -> CGSize {
        let widgetSize = ItemModel.getWidgetSize(superViewWidth: superViewWidth)
        if let additionInfo = queryAdditionInfo, let containerState = additionInfo()?.widgetContainerState {
            if containerState.isExpand {
                /// 展开模式，根据card的高度计算高度
                let widgetHeight = max(
                    widgetSize.widgetHeight,
                    containerState.expandSize.height + widgetSize.widgetNaviHeight
                )
                return CGSize(width: widgetSize.widgetWidth, height: widgetHeight)
            }
        }
        return CGSize(width: widgetSize.widgetWidth, height: widgetSize.widgetHeight)
    }
    /// block cell size
    private func blockItemSize(superViewWidth: CGFloat) -> CGSize {
        let margin = ItemModel.horizontalCellMargin * 2
        var height = ItemModel.blockDefaultHeight
        if let size = dataItem.size { height = CGFloat(WPUtils.getBlockHeight(size: size)) }
        return CGSize(width: superViewWidth - margin, height: height)
    }

    /// 获取widget容器的尺寸
    static func getWidgetSize(superViewWidth: CGFloat) -> WidgetSizeConfig {
        return WidgetSizeConfig(
            isRadioScale: false,
            widgetHeight: ItemModel.widgetDefaultHeight,
            widgetNaviHeight: ItemModel.widgetNavBarHeight,
            widgetWidth: superViewWidth - ItemModel.horizontalCellMargin * 2
        )
    }

    func getItemLayoutSize(superViewWidth: CGFloat) -> CGSize {
        switch itemType {
        case .widget:               // widget应用
            return widgetItemSize(superViewWidth: superViewWidth)
        case .block:
            return blockItemSize(superViewWidth: superViewWidth)
        case .icon, .addIcon, .fillItem:       // icon应用 / icon「添加应用」
            return CGSize(width: ItemModel.iconItemWidth, height: ItemModel.iconItemHeight)
        case .addRect:              // 方形「添加应用」
            let addRectItemWidth = superViewWidth - ItemModel.horizontalCellMargin * 2
            return CGSize(width: addRectItemWidth, height: addRectItemWidth * ItemModel.addRectAspectRatio)
        case .verticalSpace, .stateItem:
            return .zero
        }
    }

    /// 适配icon渲染模型
    func getSingleAppInfo() -> SingleAppInfo? {
        if itemType == .addIcon {
            // icon类型的「添加应用」
            return SingleAppInfo(item: item, isAddAppItem: true)
        } else if itemType == .icon || itemType == .widget || itemType == .block {
            // icon应用
            return SingleAppInfo(item: item, isAddAppItem: false)
        } else {
            return nil
        }
    }

    /// 适配widget渲染模型
    func getWidgetModel() -> WidgetModel? {
        if itemType == .widget {
            return WidgetModel(item: item)
        } else {
            return nil
        }
    }

    /// block 渲染模型
    func getBlockModel() -> BlockModel? {
        if itemType == .block {
            guard let scene = dataItem.subType?.getBlockScene(isFromTemplate: false) else {
                Self.logger.error("block(\(dataItem.itemID)) type error")
                return nil
            }
            return BlockModel(item: item, badgeKey: badgeKey(), scene: scene, elementId: item.itemId, sourceData: nil)
        } else {
            return nil
        }
    }

    /// 是否是常用应用
    func isCommon() -> Bool {
        return dataItem.subType == .common
    }

    /// 是否是组织共享应用
    func isShared() -> Bool {
        return item.isSharedByOtherOrganization == true
    }

    /// 是否是纯bot
    func isPureBot() -> Bool {
        return (item.url?.isAllURLEmpty() ?? true) && !(item.botId?.isEmpty ?? true)
    }

    /// 是否是纯链接
    func isPureLink() -> Bool {
        return item.itemType == .link && !(item.linkURL?.isEmpty ?? true)
    }

    /// 是否是添加应用
    func isAddApp() -> Bool {
        return itemType == .addIcon || itemType == .addRect
    }

    func getItemId() -> String? {
        return itemID
    }
    /// 圆形add
    static func makeAddItem(isRect: Bool) -> ItemModel {
        let dataItem = ItemUnit(type: .icon, subType: .systemAdd, itemID: "", item: WPAppItem.buildAddItem())
        var addItem = ItemModel(dataItem: dataItem, isAddRect: isRect)
        addItem.itemType = isRect ? .addRect : .addIcon
        return addItem
    }
    /// 得到addition info 信息
    func additionalInfo() -> ItemModelAdditionInfo? {
        return queryAdditionInfo?()
    }
    /// 判断是否是新应用
    func isNewApp() -> Bool {
        return dataItem.item.isNew ?? false
    }
    /// badge key
    func badgeKey() -> [WorkPlaceBadge.BadgeSingleKey]? {
        /// 只有icon和widget可以展示badge信息
        guard sectionCanDisplayBadge else {
            return nil
        }
        guard itemType == .icon || itemType == .widget || itemType == .block else {
            return nil
        }
        if let appId = item.appId,
           let ability = item.badgeAbility() {
            let key = WorkPlaceBadge.BadgeSingleKey(
                appId: appId,
                ability: ability
            )
            return [key]
        }
        return nil
    }

    /// 根据编辑态构建 tag UI 显示状态
    /// - Parameter editing: 是否在编辑
    /// - Returns: (tagConfig, hiddenTag)
    func makeTagConfig(for editing: Bool) -> (IconTagView.Config, Bool) {
        switch (isRecommand, isShared(), isPureBot(), editing) {
        case (true, _, _, true):                /* 是推荐，编辑时，显示推荐 */
            return (.recommendTag, false)
        case (true, false, false, false):       /* 是推荐，不是共享，不是bot，不编辑时，无tag */
            return (.recommendTag, true)
        case (true, true, _, false):            /* 是推荐，是共享，不编辑时，显示共享 */
            return (.sharedTag, false)
        case (true, false, true, false):        /* 是推荐，不是共享，是bot，不编辑时，显示bot */
            return (.botTag, false)
        case (false, true, _, _):               /* 不是推荐，是共享，显示共享 */
            return (.sharedTag, false)
        case (false, false, true, _):           /* 不是推荐，不是共享，是bot，显示bot */
            return (.botTag, false)
        case (false, false, false, _):          /* 不是推荐，不是共享，不是bot，无tag */
            return (.default, true)
        }
    }
}

/// widget的尺寸
struct WidgetSizeConfig {
    /// 是否是等比缩放
    let isRadioScale: Bool
    /// widget整体高度
    let widgetHeight: CGFloat
    /// widget-navi高度
    let widgetNaviHeight: CGFloat
    /// widget宽度
    let widgetWidth: CGFloat
}

/// 单个app的数据结构
struct SingleAppInfo: Codable {
    /// 应用中心的应用ID (仅用于应用中心的应用标识)
    var appcenterId: String
    /// 开放平台app clientID
    var appId: String
    /// 应用类型
    let itemType: WPAppItem.AppType
    /// 应用图标的key
    var imageKey: String
    /// 应用图标的URL
    let imageURL: String
    /// 应用名称
    var name: String
    /// 应用的描述
    var description: String
    /// 应用pc h5 url
    var pcH5Url: String
    /// 应用mobile h5 url
    var mobileH5Url: String
    /// 应用pc小程序url
    var pcMpUrl: String
    /// 应用移动小程序url
    var mobileMpUrl: String
    /// 机器人id
    var botId: String
    /// 用系统浏览器打开，默认false
    var openBrowser: Bool
    /// 是否为推荐应用
    var isRecommend: Bool
    /// 是否为New应用
    var isNew: Bool
    /// 是否为纯bot
    var isPureBot: Bool {
        pcH5Url.isEmpty && mobileH5Url.isEmpty && pcMpUrl.isEmpty && mobileMpUrl.isEmpty && !botId.isEmpty
    }
    /// 是否是添加添加应用Item(特化逻辑，以后移到后端处理)
    var isAddAppItem: Bool = false
    /// 是否是一方应用
    var isNative: Bool
    /// 一方应用的key
    var nativeAppKey: String
    /// applink
    var mobileAppLink: String
    /// 移动端默认能力（miniprogram，h5，bot）
    var mobileDefaultAbility: WPAppItem.AppAbility?
    /// 是否支持设置角标
    var badgeAuthed: Bool?

    init(item: WPAppItem, isAddAppItem: Bool = false) {
        appcenterId = item.itemId
        appId = item.appId ?? ""
        itemType = item.itemType
        imageKey = item.iconKey ?? ""
        imageURL = item.iconURL ?? ""
        name = item.name
        description = item.desc ?? ""
        mobileH5Url = item.url?.mobileWebURL ?? ""
        mobileMpUrl = item.url?.mobileMiniAppURL ?? ""
        botId = item.botId ?? ""
        self.isAddAppItem = isAddAppItem
        nativeAppKey = item.nativeAppKey ?? ""
        isNative = nativeAppKey.isEmpty ? false : true
        mobileAppLink = item.url?.mobileAppLink ?? ""
        openBrowser = item.openBrowser ?? false
        isNew = item.isNew ?? false
        mobileDefaultAbility = item.mobileDefaultAbility
        badgeAuthed = item.badgeAuthed
        // 缺省参数
        isRecommend = false
        pcMpUrl = ""
        pcH5Url = ""
    }

    func getIconResource() -> LarkImageResource {
        switch itemType {
        case .customLinkInAppList:
            // download from third-party tos
            return LarkImageResource.default(key: imageURL)
        case .normalApplication, .tenantDefineApplication, .personCustom, .native, .nonstandardBlock, .favorite, .link:
            // download from avatar tos
            return LarkImageResource.avatar(
                key: imageKey,
                entityID: appId,
                params: AvatarViewParams(sizeType: .size(avatarSideL))
            )
        @unknown default:
            assertionFailure("should not be here")
            return LarkImageResource.default(key: imageURL)
        }
    }
}
