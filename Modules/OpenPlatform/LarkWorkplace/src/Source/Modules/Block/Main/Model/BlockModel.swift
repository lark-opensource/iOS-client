//
//  BlockModel.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/2/20.
//

import Foundation
import SwiftyJSON
import OPSDK
import Blockit
import OPBlock
import OPBlockInterface
import OPFoundation
import LarkWorkplaceModel
import LKCommonsLogging

// Block 场景
enum BlockScene: Int {
    /// 普通工作台 - 不可移除推荐 block
    case normalRecommend
    /// 普通工作台 - 可移除推荐 block
    case normalDeletableRecommend
    /// 普通工作台 - 常用 block
    case normalCommon
    /// 普通工作台 - 平台 block
    case normalPlatfrom
    /// 模板化 - 常用推荐组件 - 推荐 block
    case templateRecommend
    /// 模板化 - 可移除推荐 block
    case templateDeletableRecommend
    /// 模板化 - 常用推荐组件 - 常用 block
    case templateCommon
    /// 模板化 - 常用推荐组件 - 平台 block
    case templatePlatform
    /// 模板化 - block 组件
    case templateComponent
    /// 开发预览
    case preview
    /// block组件demo
    case demoBlock

    // 用于埋点
    var itemSubType: WPTemplateModule.ComponentDetail.Favorite.AppSubType? {
        switch self {
        case .normalRecommend, .templateRecommend:
            return .recommend
        case .normalDeletableRecommend, .templateDeletableRecommend:
            return .deletableRecommend
        case .normalCommon, .templateCommon:
            return .common
        case .normalPlatfrom, .templatePlatform:
            return .platformBlock
        default:
            return nil
        }
    }
}

// 模板化工作台新增
extension JSON {
    /// 获取文案（根据具体规则获取）
    var i18nText: String {
        let key = WorkplaceTool.curLanguage()
        if let text = self[key].string {
            return text
        } else if let defaultTextUS = self["en_us"].string {
            return defaultTextUS
        } else if let defaultTextCN = self["zh_cn"].string {
            return defaultTextCN
        } else if let defaultTextJP = self["ja_jp"].string {
            return defaultTextJP
        } else {
            return ""
        }
    }

    /// 获取文案
    /// model 形如：
    /// ```
    /// {   "xxx": "xxx"
    ///     .......
    ///     "defaultLanguageKey": "en_us"
    ///     "name": {   "en_us": "xxxx",
    ///                 "zh_cn": "xxxx",
    ///                 "ja_jp": "xxxx" } }
    /// ```
    /// 获取文案策略：
    /// `current language > default language > en_us > zh_cn > ja_jp`
    func i18nText(with defaultLocaleKey: String?) -> String {
        let key = WorkplaceTool.curLanguage()
        if let text = self[key].string {
            return text
        } else if let defaultLocaleKey = defaultLocaleKey,
                  let defaultText = self[defaultLocaleKey].string {
            return defaultText
        } else if let defaultTextUS = self["en_us"].string {
            return defaultTextUS
        } else if let defaultTextCN = self["zh_cn"].string {
            return defaultTextCN
        } else if let defaultTextJP = self["ja_jp"].string {
            return defaultTextJP
        } else {
            return ""
        }
    }
}

// 模板化工作台新增（模板化工作台 Block 组件属性配置）
struct TMPLBlockProps: Codable, Equatable {
    static let logger = Logger.log(TMPLBlockProps.self)

    let blockId: String?
    let itemId: String?
    let showHeader: Bool?
    let isTitleInside: Bool?
    let titleIconUrl: String?
    let schema: String?
    let menuItems: [TMPLMenuItem]?
    let forceUpdate: Bool?
    let templateConfig: JSON?

    private let title: JSON?
    private let defaultLocale: String?

    /// 获取国际化title
    var i18nTitle: String? {
        return title?.i18nText(with: defaultLocale)
    }

    /// 操作菜单选项
    func getActionItems() -> [ActionMenuItem] {
        if let items = menuItems {
            var actionItems: [ActionMenuItem] = []
            for item in items {
                guard let schema = item.schema, !schema.isEmpty else {
                    Self.logger.error("invalid menu item: \(item.i18nName)")
                    continue
                }
                let name = item.i18nName
                let iconUrl = item.iconUrl
                let actItem = ActionMenuItem(name: name, iconUrl: iconUrl, schema: schema)
                actionItems.append(actItem)
            }
            return actionItems
        } else {
            return []
        }
    }
}

/// 模板化工作台菜单项
struct TMPLMenuItem: Codable, Equatable {
    let name: JSON
    let iconUrl: String
    let schema: String?
    let key: String?

    var i18nName: String {
        name.i18nText
    }
}

// 模板化工作台新增（模板化工作台 Block 组件样式配置）
struct TMPLBlockStyles: Codable, Equatable {
    static let autoHightValue = "auto"

    let width: String?
    let height: String?

    // 这几个 margin 暂时没使用到，用了 BaseComponentLayout
    let marginLeft: CGFloat?
    let marginRight: CGFloat?
    let marginTop: CGFloat?
    let marginBottom: CGFloat?

    let backgroundRadius: CGFloat?
}

/// 由工作台 ItemModel 转换而来的 Block 数据模型
struct BlockModel: Equatable {
    let appId: String
    let blockId: String
    let blockTypeId: String
    let title: String
    let iconKey: String
    let previewToken: String?

    let sourceData: [AnyHashable: Any]?

    let badgeKey: WorkPlaceBadgeKey?

    /// 是否是标准小组件
    /// 标准小组件：App
    /// 非标小组件：App 的实例
    let isStandardBlock: Bool
    /// 设置页面的跳转链接
    var settingUrl: String?

    // 目前主要是模板化工作台 Block 没有高度限制，后续不同场景的 Block 展示上可能有不同表现
    let scene: BlockScene

    // 模板化工作台新增（模板化工作台 Block 组件属性配置）
    let editorProps: TMPLBlockProps?

    // 模板化工作台新增（模板化工作台 Block 组件样式配置）
    let styles: TMPLBlockStyles?

    /// 版本类型
    let versionType: OPAppVersionType
    /// 是否处于编辑态
    var isEditing: Bool = false
    /// Block 实例 ID
    let elementId: String
    /// 是否处于工作台门户预览页
    let isPortalPreview: Bool

    // original Block AppItem
    let item: WPAppItem

    init(
        item: WPAppItem,
        badgeKey: WorkPlaceBadgeKey? = nil,
        scene: BlockScene,
        elementId: String,
        editorProps: TMPLBlockProps? = nil,
        styles: TMPLBlockStyles? = nil,
        sourceData: [AnyHashable: Any]? = nil,
        isPortalPreview: Bool = false
    ) {
        self.item = item
        self.appId = item.appId ?? ""
        self.blockId = item.block?.blockId ?? ""
        self.blockTypeId = item.block?.blockTypeId ?? ""
        self.title = item.name
        self.iconKey = item.iconKey ?? ""
        self.previewToken = item.previewToken
        self.sourceData = sourceData
        self.isStandardBlock = item.itemType != .nonstandardBlock
        self.badgeKey = badgeKey

        self.scene = scene
        self.versionType = item.previewToken?.isEmpty == false ? .preview : .current
        self.elementId = elementId
        self.isPortalPreview = isPortalPreview

        self.editorProps = editorProps
        self.styles = styles

        if item.block?.hasSetting == true,
           let url = item.block?.settingURL, !url.isEmpty {
            self.settingUrl = url
        }
    }
}

extension BlockModel {
    /// Block 挂载所需的 UniqueID
    var uniqueId: OPAppUniqueID {
        // 默认态和编辑态采用不同的 uniqueId
        // 避免出现一个 uniqueId 对应多个 Container, API 调用混乱的问题
        // https://bytedance.feishu.cn/docx/MPjZdt9PnoUlqUxG926cWIvAnIf?theme=FOLLOW_SYSTEM&contentTheme=DARK
        let editPrefix = isEditing ? "edit" : ""
        // 工作台门户和门户预览页采用不同的 uniqueId
        // 避免一个 iPad 分栏页面上出现一个 uniqueId 对应多个 Container 的情况
        let portalPreviewPrefix = isPortalPreview ? "portalPreview" : ""
        // 不同场景的 Block 对应不同的 uniqueId(举例：我的常用内和我的常用外)
        let prefix = "\(scene.rawValue)_\(editPrefix)_\(portalPreviewPrefix)_"
        let instanceId = "\(prefix)_\(elementId)"
        return OPAppUniqueID(
            appID: appId,
            identifier: blockTypeId,
            versionType: versionType,
            appType: .block,
            instanceID: instanceId
        )
    }

    /// 比较两个 BlockModel 是否代表同一个 Block 实例
    static func == (lhs: BlockModel, rhs: BlockModel) -> Bool {
        return lhs.uniqueId.isEqual(rhs.uniqueId) && lhs.editorProps == rhs.editorProps
        && lhs.styles == rhs.styles && lhs.settingUrl == rhs.settingUrl && lhs.item.block == rhs.item.block
    }

    /// 是否为自适应高度的 Block
    var isAutoSizeBlock: Bool {
        scene == .templateComponent && styles?.height == TMPLBlockStyles.autoHightValue
    }

    /// 是否是模版工作台常用区域 Block
    var isTemplateCommonAndRecommand: Bool {
        switch scene {
        case .templateCommon, .templateRecommend, .templateDeletableRecommend:
            return true
        default:
            return false
        }
    }

    var isDeletable: Bool {
        switch scene {
        case .normalCommon, .templateCommon, .normalDeletableRecommend, .templateDeletableRecommend:
            return true
        case .normalRecommend, .normalPlatfrom, .templateRecommend, .templatePlatform, .templateComponent, .preview, .demoBlock:
            return false
        }
    }

    var isSortable: Bool {
        switch scene {
        case .normalCommon, .templateCommon:
            return true
        case .normalPlatfrom, .normalRecommend, .normalDeletableRecommend, .templateRecommend,
                .templateDeletableRecommend, .templatePlatform, .templateComponent, .preview, .demoBlock:
            return false
        }
    }

    var isEditable: Bool {
        isDeletable || isSortable
    }

    /// 是否是模版工作台推荐 Block
    var isTemplateRecommand: Bool {
        scene == .templateRecommend || scene == .templateDeletableRecommend
    }

    var isInFavoriteComponent: Bool {
        switch scene {
        case .normalCommon, .templateCommon, .normalRecommend, .templateRecommend, .templateDeletableRecommend, .normalDeletableRecommend, .normalPlatfrom, .templatePlatform:
            return true
        case .templateComponent, .preview, .demoBlock:
            return false
        }
    }

    var isInNativePortal: Bool {
        switch scene {
        case .normalCommon, .normalRecommend, .normalDeletableRecommend, .normalPlatfrom:
            return true
        case .templateRecommend, .templateDeletableRecommend, .templateCommon, .templatePlatform, .templateComponent, .preview, .demoBlock:
            return false
        }
    }

    var isInTemplatePortal: Bool {
        switch scene {
        case .templateRecommend, .templateDeletableRecommend, .templateCommon, .templatePlatform, .templateComponent:
            return true
        case .normalRecommend, .normalDeletableRecommend, .normalCommon, .normalPlatfrom, .preview, .demoBlock:
            return false
        }
    }
}

// MARK: - --- Block Meta 配置数据模型 ---->>>>

/// 最外层整体配置
final class BlockSettings: NSObject, Codable {
    let blockTypeID: String?
    let creator: String?
    let useStartLoading: Bool?
    let darkmode: Bool?
    let showFrame: Bool?
    let workplace: WorkPlaceBlockSettings?
}

/// 工作台相关配置 -> 开发者在开发者工具中设置的配置
final class WorkPlaceBlockSettings: NSObject, Codable {
    static let logger = Logger.log(WorkPlaceBlockSettings.self)
    let needHeader: Bool?
    let consoleEnable: Bool?
    private let title: JSON?
    let titleIconUrl: String?
    let mobileHeaderLink: String?
    let menuItems: [TMPLMenuItem]?

    var i18nTitle: String? {
        title?.i18nText
    }

    /// 操作菜单选项
    func getActionItems(itemAction: @escaping (TMPLMenuItem) -> Void) -> [ActionMenuItem] {
        if let items = menuItems {
            var actionItems: [ActionMenuItem] = []
            for item in items {
                guard let key = item.key, !key.isEmpty else {
                    Self.logger.error("invalid menu item: \(item.i18nName)")
                    continue
                }
                let actItem = ActionMenuItem.developerItem(origin: item, action: itemAction)
                actionItems.append(actItem)
            }
            return actionItems
        } else {
            return []
        }
    }
}

// MARK: - --- Block API 调用数据模型 ---->>>>

/// 对应 api: addMenuItem
struct BlkAPIDataAddMenuItem: Codable {
    let menuItem: TMPLMenuItem
}

/// 对应 api: updateMenuItem
struct BlkAPIDataUpdateMenuItem: Codable {
    let menuItem: BlkAPIDataUpdateMenuItemInfo
}

/// updateMenuItem 的内层数据结构
struct BlkAPIDataUpdateMenuItemInfo: Codable {
    let key: String

    let iconUrl: String?
    let name: JSON?
}

// MARK: - --- Block API 回传数据模型 ---->>>>

/// 对应 api: getHostInfo
struct BlkCBDataHostInfo: Codable {
    static let HostValue = "ios_workplace_block"

    let host: String
    let viewWidth: CGFloat
    let viewHeight: CGFloat
}

final class BlockEntityProvider: OPBlockDataProvider<OPBlockInfo> {
    private let blockInfo: OPBlockInfo?

    init(blockInfo: OPBlockInfo?) {
        self.blockInfo = blockInfo
    }

    override func generateData() -> OPBlockInfo? {
        return blockInfo
    }

    override func getDataType() -> BlockDataSourceType {
        return .entity
    }
}

final class BlockGuideInfoProvider: OPBlockDataProvider<OPBlockGuideInfo> {
    private let blockGuideInfo: OPBlockGuideInfo?

    init(blockGuideInfo: OPBlockGuideInfo?) {
        self.blockGuideInfo = blockGuideInfo
    }

    override func generateData() -> OPBlockGuideInfo? {
        return blockGuideInfo
    }

    override func getDataType() -> BlockDataSourceType {
        return .guideInfo
    }
}

struct WPBlockPrefetchData {
    var blockEntity: OPBlockInfo?
    var blockGuideInfo: OPBlockGuideInfo?
}

// MARK: Block 聚合接口返回
struct WPBlockPrefetchResponseWrap: Codable {
    let data: WPBlockPrefetchResponse
}

struct WPBlockPrefetchResponse: Codable {
    let entity: WPBlockEntityPrefetch?
    let guideInfo: WPBlockGuideInfoPrefetch?

    enum CodingKeys: String, CodingKey {
        case entity = "MGetBlockEntityV2"
        case guideInfo = "GetBlockGuideInfo"
    }
}

struct WPBlockEntityPrefetch: Codable {
    let code: Int
    let msg: String
    let blocks: [String: WPBlockEntityResponse]?
}

struct WPBlockEntityResponse: Codable {
    let status: Int
    let errMessage: String
    let entity: WPBlockEntity?
}

struct WPBlockEntity: Codable {
    let tenantID: Int?
    let blockID: String
    let status: Int?
    let sourceData: String?
    let sourceLink: String
    let appIDStr: String?
    let summary: String
    let appID: Int?
    let owner: String?
    let title: String?
    let blockTypeID: String
    let preview: String?
    let sourceMeta: String
}

struct WPBlockGuideInfoPrefetch: Codable {
    let code: Int
    let msg: String
    var blockExtensions: [String: OPBlockGuideInfo]?

    enum CodingKeys: String, CodingKey {
        case blockExtensions = "block_extensions"
        case code
        case msg
    }
}
